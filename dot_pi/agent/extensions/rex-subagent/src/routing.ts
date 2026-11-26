import { existsSync, readFileSync } from "node:fs";
import type { AgentDefinition } from "./agents.ts";
import { resolveModel, type ModelRef } from "./latest.ts";
import type { SpawnRequest } from "./run.ts";

export const MODES = ["claude", "openai", "mixed"] as const;
export type Mode = (typeof MODES)[number];
export const DEFAULT_MODE: Mode = "claude";

export interface ModelChoice {
	model: string;
	/** Used when the effort question has no answer. */
	thinking: string;
}

export interface Tier {
	size: string;
	description: string;
	models: Record<Mode, ModelChoice>;
}

export interface Effort {
	thinking: string;
	description: string;
}

/** A yes/no question that, when answered yes, replaces the tier's model, e.g. sending reviews to Opus. */
export interface ModelOverride {
	id: string;
	instructions: string;
	criteria: { true: string; false: string };
	threshold: number;
	models: Record<Mode, string>;
}

export interface RoutingConfig {
	enabled: boolean;
	defaultMode: Mode;
	classifier?: string;
	timeoutMs: number;
	minConfidence: number;
	/** Scores round to the nearest tier, except the top tier needs at least this score. */
	topTierMinScore: number;
	log: boolean;
	tiers: Tier[];
	efforts: Effort[];
	overrides: ModelOverride[];
}

export interface ClassifierAnswer {
	type: string;
	score?: number;
	confidence?: number;
	probability?: number;
}

export interface ClassifierOutcome {
	stopReason: string;
	errorMessage?: string;
	answers: Record<string, ClassifierAnswer | undefined>;
}

export interface Selection {
	tier: Tier;
	choice: ModelChoice;
	confidence: number;
	effort?: string;
	override?: string;
}

export const SIZE_QUESTION = "size";
export const EFFORT_QUESTION = "effort";

const SIZE_INSTRUCTIONS =
	"How much work is this task for an autonomous coding agent? Judge only its scope: how many files and steps it involves, and whether the approach is given or must be worked out. Ignore wording about importance, care or risk.";
const EFFORT_INSTRUCTIONS =
	"How much careful reasoning does each step of this task need? Consider subtle logic, edge cases, concurrency, security and how easy a mistake would be to miss. Ignore how much work there is.";

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
	topTierMinScore: 3.6,
	log: true,
	tiers: [
		{
			size: "trivial",
			description:
				"Read or change one specific thing whose location is given or easy to find: look up a value, run one command, make a one-line edit",
			models: {
				claude: { model: haiku, thinking: "low" },
				openai: { model: luna, thinking: "low" },
				mixed: { model: haiku, thinking: "low" },
			},
		},
		{
			size: "small",
			description: "A self-contained change or investigation in one or two files, with the approach already clear from the task",
			models: {
				claude: { model: haiku, thinking: "medium" },
				openai: { model: luna, thinking: "medium" },
				mixed: { model: luna, thinking: "medium" },
			},
		},
		{
			size: "medium",
			description: "Touches several files or needs several steps and some investigation, but the task says what to do",
			models: {
				claude: { model: sonnet, thinking: "medium" },
				openai: { model: sol, thinking: "medium" },
				mixed: { model: sonnet, thinking: "medium" },
			},
		},
		{
			size: "large",
			description: "A feature or refactor across many files, or an investigation where the task names the goal but not the approach",
			models: {
				claude: { model: sonnet, thinking: "high" },
				openai: { model: sol, thinking: "high" },
				mixed: { model: sol, thinking: "high" },
			},
		},
		{
			size: "very large",
			description: "Open-ended design across a whole system: the task asks to decide the approach or architecture, with many unknowns",
			models: {
				claude: { model: opus, thinking: "high" },
				openai: { model: astra, thinking: "high" },
				mixed: { model: opus, thinking: "high" },
			},
		},
	],
	efforts: [
		{ thinking: "low", description: "Mechanical: the steps are obvious and mistakes are easy to spot" },
		{ thinking: "medium", description: "Ordinary care: some judgement, but standard patterns apply" },
		{ thinking: "high", description: "Tricky: subtle logic, edge cases, or reasoning about how parts interact" },
		{ thinking: "xhigh", description: "Hard: concurrency, security, data integrity, or correctness that is easy to get subtly wrong" },
	],
	overrides: [
		{
			id: "review",
			instructions:
				"Does the task explicitly ask for a review, audit or critique of specific existing work (a diff, commit, PR, file, plan or design), with a verdict or a list of problems as the deliverable? General reminders to be careful or to consider security do not make a task a review.",
			criteria: {
				true: "The deliverable is a judgement of named existing work: review findings, an audit report, or a critique",
				false: "The deliverable is a change, a plan, an answer or facts found in the code; this includes searches, investigations and acting on review feedback",
			},
			threshold: 0.7,
			models: { claude: opus, openai: astra, mixed: opus },
		},
	],
};

export const isMode = (value: unknown): value is Mode => MODES.includes(value as Mode);

const tiersValid = (tiers: unknown): tiers is Tier[] =>
	Array.isArray(tiers) && tiers.length > 0 && tiers.every((tier: Tier) => MODES.every((mode) => tier?.models?.[mode]?.model));
const effortsValid = (efforts: unknown): efforts is Effort[] =>
	Array.isArray(efforts) && efforts.length > 0 && efforts.every((effort: Effort) => effort?.thinking && effort.description);
const overridesValid = (overrides: unknown): overrides is ModelOverride[] =>
	Array.isArray(overrides) &&
	overrides.every((o: ModelOverride) => o?.id && o.instructions && o.criteria && MODES.every((mode) => o.models?.[mode]));

export function loadRoutingConfig(path: string): RoutingConfig {
	if (!existsSync(path)) return DEFAULT_ROUTING;
	try {
		const config = { ...DEFAULT_ROUTING, ...(JSON.parse(readFileSync(path, "utf8")) as Partial<RoutingConfig>) };
		if (!isMode(config.defaultMode)) config.defaultMode = DEFAULT_MODE;
		if (!tiersValid(config.tiers)) config.tiers = DEFAULT_ROUTING.tiers;
		if (!effortsValid(config.efforts)) config.efforts = DEFAULT_ROUTING.efforts;
		if (!overridesValid(config.overrides)) config.overrides = DEFAULT_ROUTING.overrides;
		return config;
	} catch {
		return DEFAULT_ROUTING;
	}
}

export const needsRouting = (request: SpawnRequest) => !request.model || !request.thinking;

export const providerOf = (model: string) => model.split("/")[0];

export function allowedProviders(config: RoutingConfig, mode: Mode): Set<string> {
	return new Set([
		...config.tiers.map((tier) => providerOf(tier.models[mode].model)),
		...config.overrides.map((override) => providerOf(override.models[mode])),
	]);
}

export function routingContext(task: string, agent: AgentDefinition | undefined, config: RoutingConfig) {
	const questions: Record<string, unknown> = {
		[SIZE_QUESTION]: {
			type: "score",
			instructions: SIZE_INSTRUCTIONS,
			criteria: config.tiers.map((tier) => `${tier.size}: ${tier.description}`),
		},
		[EFFORT_QUESTION]: {
			type: "score",
			instructions: EFFORT_INSTRUCTIONS,
			criteria: config.efforts.map((effort) => `${effort.thinking}: ${effort.description}`),
		},
	};
	for (const override of config.overrides) {
		questions[override.id] = { type: "bool", instructions: override.instructions, criteria: override.criteria };
	}
	return {
		state: { task, ...(agent && { agent: { name: agent.name, role: agent.description } }) },
		questions,
	};
}

const finiteScore = (answer: ClassifierAnswer | undefined) =>
	answer?.type === "score" && typeof answer.score === "number" && Number.isFinite(answer.score) ? answer.score : undefined;

const clampIndex = (value: number, length: number) => Math.min(length - 1, Math.max(0, Math.round(value)));

export function tierIndex(score: number, config: RoutingConfig): number {
	const index = clampIndex(score, config.tiers.length);
	return index === config.tiers.length - 1 && index > 0 && score < config.topTierMinScore ? index - 1 : index;
}

export function selectRoute(result: ClassifierOutcome, config: RoutingConfig, mode: Mode): Selection | undefined {
	if (result.stopReason !== "stop") return undefined;
	const sizeAnswer = result.answers[SIZE_QUESTION];
	const size = finiteScore(sizeAnswer);
	if (size === undefined) return undefined;
	const confidence = sizeAnswer?.confidence ?? 0;
	if (confidence < config.minConfidence) return undefined;

	const tier = config.tiers[tierIndex(size, config)];
	const effortScore = finiteScore(result.answers[EFFORT_QUESTION]);
	const effort = effortScore === undefined ? undefined : config.efforts[clampIndex(effortScore, config.efforts.length)].thinking;
	const override = config.overrides.find((o) => (result.answers[o.id]?.probability ?? 0) >= o.threshold);
	return {
		tier,
		choice: { model: override?.models[mode] ?? tier.models[mode].model, thinking: effort ?? tier.models[mode].thinking },
		confidence,
		effort,
		override: override?.id,
	};
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

export function describeSelection(selection: Selection): string {
	const parts = [selection.tier.size, selection.override, selection.effort && `effort ${selection.effort}`].filter(Boolean);
	return `${parts.join(", ")} (${Math.round(selection.confidence * 100)}%)`;
}

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
		if (model && catalog.some((ref) => `${ref.provider}/${ref.id}` === model)) {
			return {
				request: fill(request, model, input.selection.choice.thinking),
				agentModel,
				note: `auto: ${describeSelection(input.selection)}`,
			};
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

export interface DecisionRecord {
	time: string;
	cwd: string;
	mode: Mode;
	agent?: string;
	taskChars: number;
	task: string;
	answers?: Record<string, number | undefined>;
	model?: string;
	thinking?: string;
	note?: string;
}

export function decisionRecord(input: {
	time: Date;
	cwd: string;
	mode: Mode;
	agent?: string;
	task: string;
	result?: ClassifierOutcome;
	model?: string;
	thinking?: string;
	note?: string;
}): DecisionRecord {
	const answers = input.result?.answers;
	return {
		time: input.time.toISOString(),
		cwd: input.cwd,
		mode: input.mode,
		agent: input.agent,
		taskChars: input.task.length,
		task: input.task.length > 400 ? `${input.task.slice(0, 397)}...` : input.task,
		answers:
			answers &&
			Object.fromEntries(Object.entries(answers).map(([id, answer]) => [id, answer?.score ?? answer?.probability])),
		model: input.model,
		thinking: input.thinking,
		note: input.note,
	};
}

export function parseModelRef(ref: string): { provider: string; id: string } | undefined {
	const slash = ref.indexOf("/");
	if (slash <= 0 || slash === ref.length - 1) return undefined;
	return { provider: ref.slice(0, slash), id: ref.slice(slash + 1) };
}
