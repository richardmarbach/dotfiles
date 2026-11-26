import { existsSync, readFileSync } from "node:fs";
import type { AgentDefinition } from "./agents.ts";
import { resolveModel, type ModelRef } from "./latest.ts";
import type { SpawnRequest } from "./run.ts";

export const MODES = ["claude", "openai", "mixed"] as const;
export type Mode = (typeof MODES)[number];
export const DEFAULT_MODE: Mode = "claude";

export interface ModelChoice {
	model: string;
	thinking: string;
}

export interface Tier {
	size: string;
	description: string;
	models: Record<Mode, ModelChoice>;
}

export interface RoutingConfig {
	enabled: boolean;
	defaultMode: Mode;
	classifier?: string;
	timeoutMs: number;
	minConfidence: number;
	tiers: Tier[];
}

export interface SizingAnswer {
	type: string;
	score?: number;
	confidence?: number;
}

export interface SizingResult {
	stopReason: string;
	errorMessage?: string;
	answers: Record<string, SizingAnswer | undefined>;
}

export interface Selection {
	tier: Tier;
	choice: ModelChoice;
	confidence: number;
}

export const SIZE_QUESTION = "size";

const haiku = "anthropic/claude-haiku-*";
const sonnet = "anthropic/claude-sonnet-*";
const opus = "anthropic/claude-opus-*";
const luna = "openai-codex/gpt-*-luna";
const sol = "openai-codex/gpt-*-sol";
const astra = "openai-codex/gpt-*-astra";

export const DEFAULT_ROUTING: RoutingConfig = {
	enabled: true,
	defaultMode: DEFAULT_MODE,
	classifier: "typesafe/jev-latest",
	timeoutMs: 10_000,
	minConfidence: 0,
	tiers: [
		{
			size: "trivial",
			description: "A lookup or one-line change: find a file, read a value, run one command, rename a symbol",
			models: {
				claude: { model: haiku, thinking: "low" },
				openai: { model: luna, thinking: "low" },
				mixed: { model: haiku, thinking: "low" },
			},
		},
		{
			size: "small",
			description: "A focused task in one or two files with a clear approach, such as a small bug fix or a short summary",
			models: {
				claude: { model: haiku, thinking: "medium" },
				openai: { model: luna, thinking: "medium" },
				mixed: { model: luna, thinking: "medium" },
			},
		},
		{
			size: "medium",
			description: "Several files or steps, some investigation needed, but the approach is mostly known",
			models: {
				claude: { model: sonnet, thinking: "medium" },
				openai: { model: sol, thinking: "medium" },
				mixed: { model: sonnet, thinking: "medium" },
			},
		},
		{
			size: "large",
			description: "A multi-file feature, refactor or review that needs careful reasoning about how parts interact",
			models: {
				claude: { model: sonnet, thinking: "xhigh" },
				openai: { model: sol, thinking: "xhigh" },
				mixed: { model: sol, thinking: "xhigh" },
			},
		},
		{
			size: "very large",
			description: "Open-ended, ambiguous or high-risk work: architecture, planning across a system, subtle correctness or security",
			models: {
				claude: { model: opus, thinking: "high" },
				openai: { model: astra, thinking: "high" },
				mixed: { model: opus, thinking: "high" },
			},
		},
	],
};

export const isMode = (value: unknown): value is Mode => MODES.includes(value as Mode);

export function loadRoutingConfig(path: string): RoutingConfig {
	if (!existsSync(path)) return DEFAULT_ROUTING;
	try {
		const overrides = JSON.parse(readFileSync(path, "utf8")) as Partial<RoutingConfig>;
		const config = { ...DEFAULT_ROUTING, ...overrides };
		if (!isMode(config.defaultMode)) config.defaultMode = DEFAULT_MODE;
		const tiersValid =
			Array.isArray(config.tiers) && config.tiers.length > 0 && config.tiers.every((tier) => MODES.every((mode) => tier.models?.[mode]?.model));
		return tiersValid ? config : { ...config, tiers: DEFAULT_ROUTING.tiers };
	} catch {
		return DEFAULT_ROUTING;
	}
}

export const needsRouting = (request: SpawnRequest) => !request.model || !request.thinking;

export const providerOf = (model: string) => model.split("/")[0];

export function allowedProviders(config: RoutingConfig, mode: Mode): Set<string> {
	return new Set(config.tiers.map((tier) => providerOf(tier.models[mode].model)));
}

export function sizingContext(task: string, agent: AgentDefinition | undefined, tiers: Tier[]) {
	return {
		state: {
			task,
			...(agent && { agent: { name: agent.name, role: agent.description } }),
		},
		questions: {
			[SIZE_QUESTION]: {
				type: "score" as const,
				instructions:
					"How large and difficult is this task for an autonomous coding agent? Consider the amount of work, how much reasoning it needs, ambiguity, and the cost of getting it wrong.",
				criteria: tiers.map((tier) => `${tier.size}: ${tier.description}`),
			},
		},
	};
}

export function selectTier(result: SizingResult, config: RoutingConfig, mode: Mode): Selection | undefined {
	if (result.stopReason !== "stop") return undefined;
	const answer = result.answers[SIZE_QUESTION];
	if (answer?.type !== "score" || typeof answer.score !== "number" || !Number.isFinite(answer.score)) return undefined;
	const confidence = answer.confidence ?? 0;
	if (confidence < config.minConfidence) return undefined;
	const index = Math.min(config.tiers.length - 1, Math.max(0, Math.round(answer.score)));
	const tier = config.tiers[index];
	return { tier, choice: tier.models[mode], confidence };
}

export function fallbackSelection(config: RoutingConfig, mode: Mode): Selection {
	const tier = config.tiers[Math.floor((config.tiers.length - 1) / 2)];
	return { tier, choice: tier.models[mode], confidence: 0 };
}

export interface ModelPlanInput {
	request: SpawnRequest;
	agentModel?: string;
	parentModel?: string;
	mode: Mode;
	config: RoutingConfig;
	catalog: readonly ModelRef[];
	selection?: Selection;
	failure?: string;
}

export interface ModelPlan {
	request: SpawnRequest;
	agentModel?: string;
	note?: string;
}

const fill = (request: SpawnRequest, model: string, thinking: string): SpawnRequest => ({
	...request,
	model: request.model ?? model,
	thinking: request.thinking ?? thinking,
});

/**
 * Explicit call values always win. A classifier tier fills what the call left open. Without one, the agent's or
 * parent's model is kept only if the mode allows its provider; otherwise the mode's middle tier stands in, so openai
 * mode never silently falls back to a Claude default.
 */
export function planModel(input: ModelPlanInput): ModelPlan {
	const { config, mode, catalog } = input;
	const request = { ...input.request, model: resolveModel(input.request.model, catalog) ?? input.request.model };
	const agentModel = resolveModel(input.agentModel, catalog);
	let failure = input.failure;

	if (input.selection) {
		const model = resolveModel(input.selection.choice.model, catalog);
		const label = `${input.selection.tier.size} (${Math.round(input.selection.confidence * 100)}%)`;
		if (model && catalog.some((ref) => `${ref.provider}/${ref.id}` === model)) {
			return { request: fill(request, model, input.selection.choice.thinking), agentModel, note: `auto: ${label}` };
		}
		failure = `${input.selection.choice.model} unavailable`;
	}

	const note = failure && `defaults: ${failure}`;
	const fallbackModel = request.model ?? agentModel ?? input.parentModel;
	if (request.model || (fallbackModel && allowedProviders(config, mode).has(providerOf(fallbackModel)))) {
		return { request, agentModel, note };
	}
	const { tier, choice } = fallbackSelection(config, mode);
	const model = resolveModel(choice.model, catalog);
	if (!model) return { request, agentModel, note };
	return { request: fill(request, model, choice.thinking), agentModel, note: `${mode} fallback: ${tier.size}${failure ? `; ${failure}` : ""}` };
}

export function parseModelRef(ref: string): { provider: string; id: string } | undefined {
	const slash = ref.indexOf("/");
	if (slash <= 0 || slash === ref.length - 1) return undefined;
	return { provider: ref.slice(0, slash), id: ref.slice(slash + 1) };
}
