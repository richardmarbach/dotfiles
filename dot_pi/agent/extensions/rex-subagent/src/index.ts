import { randomUUID } from "node:crypto";
import { appendFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { setTimeout as sleep } from "node:timers/promises";
import { StringEnum } from "@earendil-works/pi-ai";
import { CONFIG_DIR_NAME, getAgentDir, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { describeAgents, loadAgents, type AgentDefinition, type AgentDirectory } from "./agents.ts";
import { captureTail, closeTab, openTab, waitForExit, type RexTab } from "./rex.ts";
import {
	DEFAULT_MODE,
	MODES,
	isMode,
	loadRoutingConfig,
	needsRouting,
	parseModelRef,
	planModel,
	decisionRecord,
	routingContext,
	selectRoute,
	type ClassifierOutcome,
	type Mode,
	type RoutingConfig,
	type Selection,
} from "./routing.ts";
import {
	SUBAGENT_FLAG,
	TOOL_NAME,
	buildPiArgs,
	createRun,
	describeToolCall,
	finalResult,
	planSpawn,
	readActivity,
	readConfig,
	readResult,
	writeActivity,
	writeResult,
	type RunConfig,
	type SubagentResult,
} from "./run.ts";

const POLL_MS = 500;

const CHILD_PROMPT = `You are a subagent started by another pi session (the parent agent) in its own Rex tab.
- Work autonomously on the task in the first user message. The user may watch this tab, but do not wait for them unless you are truly blocked.
- Your final assistant message is returned verbatim to the parent agent as a tool result. Make it a self-contained report: what you did, key findings, files changed, and anything left unresolved.`;

interface SubagentDetails {
	label: string;
	agent?: string;
	status: "running" | "done" | "error";
	runDir: string;
	elapsedMs: number;
	keepOpen: boolean;
	model?: string;
	thinking?: string;
	routing?: string;
	activity?: string;
	windowId?: string;
	sessionFile?: string;
}

function agentDirectories(ctx: ExtensionContext): AgentDirectory[] {
	const directories: AgentDirectory[] = [{ path: join(getAgentDir(), "agents"), scope: "user" }];
	if (ctx.isProjectTrusted()) directories.push({ path: join(ctx.cwd, CONFIG_DIR_NAME, "agents"), scope: "project" });
	return directories;
}

const MODE_FLAG = "subagent-mode";
const DECISION_LOG = "rex-subagent-decisions.jsonl";
const MODE_ENTRY = "rex-subagent-mode";

function initialMode(flag: unknown, ctx: ExtensionContext, config: RunConfig | undefined): Mode {
	if (isMode(flag)) return flag;
	const saved = ctx.sessionManager
		.getBranch()
		.findLast((entry) => entry.type === "custom" && entry.customType === MODE_ENTRY) as { data?: { mode?: unknown } } | undefined;
	if (isMode(saved?.data?.mode)) return saved.data.mode;
	if (isMode(config?.mode)) return config.mode;
	return loadRoutingConfig(join(getAgentDir(), "rex-subagent.json")).defaultMode;
}

async function pickClassifier(ctx: ExtensionContext, preferred: string | undefined) {
	const available = await ctx.modelRegistry.getAvailableOfType("classifier");
	const ref = preferred ? parseModelRef(preferred) : undefined;
	return (ref && available.find((m) => m.provider === ref.provider && m.id === ref.id)) ?? available[0];
}

async function sizeTask(
	ctx: ExtensionContext,
	config: RoutingConfig,
	mode: Mode,
	task: string,
	agent: AgentDefinition | undefined,
	signal: AbortSignal | undefined,
): Promise<{ selection?: Selection; failure?: string; result?: ClassifierOutcome }> {
	try {
		const classifier = await pickClassifier(ctx, config.classifier);
		if (!classifier) return { failure: "no classifier available" };
		const timeout = AbortSignal.timeout(config.timeoutMs);
		const context = routingContext(task, agent, config) as Parameters<typeof ctx.modelRegistry.classify>[1];
		const result = await ctx.modelRegistry.classify(classifier, context, {
			signal: signal ? AbortSignal.any([signal, timeout]) : timeout,
		});
		const selection = selectRoute(result, config, mode);
		return selection
			? { selection, result }
			: { failure: `classifier gave no usable answer${result.errorMessage ? `: ${result.errorMessage}` : ""}`, result };
	} catch (error) {
		return { failure: `classifier failed: ${error instanceof Error ? error.message : String(error)}` };
	}
}

const availableModels = (ctx: ExtensionContext) =>
	ctx.modelRegistry.getAvailable().map((model) => ({ provider: model.provider, id: model.id }));

function buildParameters(agents: AgentDefinition[]) {
	const agentParam = agents.length
		? {
				agent: Type.Optional(
					StringEnum(agents.map((agent) => agent.name) as [string, ...string[]], {
						description: "Agent type. Its model, thinking, tools and instructions become defaults.",
					}),
				),
			}
		: {};
	return Type.Object({
		task: Type.String({
			description: "Complete, self-contained instructions. The subagent cannot see this conversation.",
		}),
		...agentParam,
		name: Type.Optional(Type.String({ description: "Short tab label, e.g. 'auth-scout'" })),
		cwd: Type.Optional(Type.String({ description: "Working directory (default: current cwd)" })),
		model: Type.Optional(
			Type.String({
				description:
					"Model, or a family like anthropic/claude-opus-* for its newest version. Omit to let a classifier pick one from the task's size within the session's subagent mode (falls back to the agent's model, then the current model)",
			}),
		),
		thinking: Type.Optional(
			StringEnum(["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const, {
				description:
					"Thinking level. Omit to let a classifier pick one from the task's size (falls back to the agent's level, then the current level)",
			}),
		),
		tools: Type.Optional(
			Type.Array(Type.String(), { description: "Tool allowlist; overrides the agent's tools, e.g. ['read','bash']" }),
		),
		keep_open: Type.Optional(
			Type.Boolean({ description: "Leave the subagent running in its tab after it reports (default: agent's auto-exit)" }),
		),
	});
}

function buildDescription(agents: AgentDefinition[]) {
	const base =
		"Spawn a pi subagent in a new Rex tab to work on a self-contained task with its own context window. Blocks until the subagent finishes and returns its final report. Issue several calls in one message to run subagents in parallel, each in its own tab.";
	if (!agents.length) return base;
	return `${base}\n\nAgent types (pass as \`agent\`; omit for a general-purpose subagent with the current model):\n${describeAgents(agents)}`;
}

function formatElapsed(ms: number) {
	const seconds = Math.round(ms / 1000);
	return seconds < 60 ? `${seconds}s` : `${Math.floor(seconds / 60)}m${seconds % 60}s`;
}

async function awaitResult(
	pi: ExtensionAPI,
	tab: RexTab,
	runDir: string,
	signal: AbortSignal | undefined,
	onTick: (activity: string | undefined) => void,
): Promise<SubagentResult | undefined> {
	const watcher = new AbortController();
	let exited = false;
	const markExited = () => {
		exited = true;
	};
	waitForExit(pi.exec, tab, watcher.signal).then(markExited, markExited);
	try {
		while (true) {
			const result = readResult(runDir);
			if (result) return result;
			if (exited) {
				await sleep(POLL_MS, undefined, { signal });
				return readResult(runDir);
			}
			onTick(readActivity(runDir));
			await sleep(POLL_MS, undefined, { signal });
		}
	} finally {
		watcher.abort();
	}
}

function registerTool(pi: ExtensionAPI, agents: AgentDefinition[], getMode: () => Mode) {
	pi.registerTool({
		name: TOOL_NAME,
		label: "Rex Subagent",
		description: buildDescription(agents),
		promptSnippet: "Delegate a self-contained task to a pi subagent running in its own Rex tab",
		promptGuidelines: [
			"Use rex_subagent for independent, well-scoped tasks (research, scouting, planning, review, isolated changes) that benefit from a fresh context; issue several rex_subagent calls in one message to parallelize.",
			"Pick the rex_subagent agent type whose description best fits the task; omit it only when none fits.",
			"rex_subagent tasks must include all context the subagent needs, because it cannot see this conversation.",
			"Do not let parallel rex_subagent calls edit the same files.",
		],
		parameters: buildParameters(agents),

		async execute(_toolCallId, rawParams, signal, onUpdate, ctx: ExtensionContext) {
			const params = rawParams as { task: string; agent?: string; cwd?: string } & Parameters<typeof planSpawn>[0];
			const session = process.env.REX_SESSION ?? process.env.REX_BLOCK;
			if (!session) throw new Error("neither REX_SESSION nor REX_BLOCK is set; pi must run inside a Rex terminal");

			const available = loadAgents(agentDirectories(ctx));
			const agent = params.agent ? available.find((candidate) => candidate.name === params.agent) : undefined;
			if (params.agent && !agent) {
				throw new Error(
					`Unknown agent "${params.agent}". Available: ${available.map((a) => a.name).join(", ") || "(none)"}`,
				);
			}

			const routingConfig = loadRoutingConfig(join(getAgentDir(), "rex-subagent.json"));
			const mode = getMode();
			const parentModel = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
			let sized: Awaited<ReturnType<typeof sizeTask>> = {};
			if (routingConfig.enabled && needsRouting(params)) {
				onUpdate?.({ content: [{ type: "text", text: `sizing task (${mode})…` }], details: undefined });
				sized = await sizeTask(ctx, routingConfig, mode, params.task, agent, signal);
				if (signal?.aborted) throw new Error("Subagent cancelled before it started");
			}
			const modelPlan = planModel({
				request: params,
				agentModel: agent?.model,
				parentModel,
				mode,
				config: routingConfig,
				catalog: availableModels(ctx),
				selection: sized.selection,
				failure: sized.failure,
			});
			const routing = modelPlan.note;

			const id = randomUUID().slice(0, 8);
			const plan = planSpawn(
				{ ...params, ...modelPlan.request },
				agent && { ...agent, model: modelPlan.agentModel },
				{ model: parentModel, thinking: pi.getThinkingLevel() },
				id.slice(0, 4),
			);
			const { label } = plan;
			const { keepOpen } = plan.config;
			const runDir = join(tmpdir(), "pi-rex-subagents", `${label}-${id}`);
			const started = Date.now();
			createRun(runDir, { ...plan.config, mode });
			if (routingConfig.log) {
				const record = decisionRecord({
					time: new Date(),
					cwd: ctx.cwd,
					mode,
					agent: agent?.name,
					task: params.task,
					result: sized.result,
					model: plan.model,
					thinking: plan.thinking,
					note: routing,
				});
				try {
					appendFileSync(join(getAgentDir(), DECISION_LOG), `${JSON.stringify(record)}\n`);
				} catch {}
			}

			const details = (patch: Partial<SubagentDetails>): SubagentDetails => ({
				label,
				agent: agent?.name,
				status: "running",
				runDir,
				keepOpen,
				model: plan.model,
				thinking: plan.thinking,
				routing,
				elapsedMs: Date.now() - started,
				...patch,
			});

			const command = [
				"pi",
				...buildPiArgs({
					runDir,
					label,
					task: params.task,
					model: plan.model,
					thinking: plan.thinking,
					tools: plan.tools,
				}),
			];
			const tab = await openTab(pi.exec, {
				session,
				label,
				cwd: params.cwd ? resolve(ctx.cwd, params.cwd) : ctx.cwd,
				command,
				signal,
			});

			let lastText = "";
			const tick = (activity: string | undefined) => {
				const update = details({ activity, windowId: tab.windowId });
				const model = [plan.model?.split("/").pop(), plan.thinking].filter(Boolean).join(":");
				const text = `${label}${model ? ` (${model})` : ""} running ${formatElapsed(update.elapsedMs)}${activity ? ` · ${activity}` : ""}`;
				if (text === lastText) return;
				lastText = text;
				onUpdate?.({ content: [{ type: "text", text }], details: update });
			};

			let result: SubagentResult | undefined;
			try {
				result = await awaitResult(pi, tab, runDir, signal, tick);
			} catch (error) {
				if (!signal?.aborted) throw error;
				await closeTab(pi.exec, tab).catch(() => {});
				throw new Error(`Subagent ${label} cancelled; its tab was closed`);
			}

			if (!result) {
				const tail = await captureTail(pi.exec, tab).catch(() => "");
				return {
					content: [
						{
							type: "text",
							text: `Subagent ${label} exited without reporting a result.${tail ? `\n\nLast terminal output:\n${tail}` : ""}`,
						},
					],
					details: details({ status: "error", windowId: tab.windowId }),
					isError: true,
				};
			}

			const modelInfo = [plan.model, plan.thinking].filter(Boolean).join(":");
			const trailer = `\n\n[subagent ${label}${keepOpen ? " (tab left open)" : ""} · ${modelInfo || "default model"}${routing ? ` (${routing})` : ""} · session ${result.sessionFile ?? "n/a"}]`;
			const body = result.status === "error" ? `Subagent failed: ${result.error}\n\n${result.output}` : result.output;
			return {
				content: [{ type: "text", text: `${body.trim() || "(no output)"}${trailer}` }],
				details: details({ status: result.status, windowId: tab.windowId, sessionFile: result.sessionFile }),
				isError: result.status === "error",
			};
		},

		renderCall(args, theme, context) {
			const text = (context.lastComponent as Text | undefined) ?? new Text("", 0, 0);
			const input = args as { task?: string; agent?: string; name?: string };
			const label = [input.agent, input.name].filter(Boolean).join(" ");
			const task = (input.task ?? "").split("\n")[0];
			text.setText(
				theme.fg("toolTitle", theme.bold("rex_subagent ")) +
					theme.fg("accent", label ? `${label} ` : "") +
					theme.fg("dim", task.length > 100 ? `${task.slice(0, 97)}...` : task),
			);
			return text;
		},

		renderResult(result, { expanded, isPartial }, theme, context) {
			const text = (context.lastComponent as Text | undefined) ?? new Text("", 0, 0);
			const info = result.details as SubagentDetails | undefined;
			const body = result.content.find((part) => part.type === "text")?.text ?? "";
			if (isPartial || !info) {
				text.setText(theme.fg("warning", `⏳ ${body}`));
				return text;
			}
			const lines = body.split("\n");
			const shown = expanded ? lines : lines.slice(0, 8);
			const modelInfo = [info.model?.split("/").pop(), info.thinking].filter(Boolean).join(":");
			const summary = [info.label, modelInfo, info.routing && `(${info.routing})`, formatElapsed(info.elapsedMs)]
				.filter(Boolean)
				.join(" · ");
			const header = info.status === "done" ? theme.fg("success", `✓ ${summary}`) : theme.fg("error", `✗ ${summary}`);
			const more =
				!expanded && lines.length > shown.length
					? `\n${theme.fg("dim", `… ${lines.length - shown.length} more lines (${context.keyHint("app.tools.expand", "to expand")})`)}`
					: "";
			text.setText(`${header}\n${shown.join("\n")}${more}`);
			return text;
		},
	});
}

export default function rexSubagentExtension(pi: ExtensionAPI) {
	let runDir: string | undefined;
	let config: RunConfig | undefined;
	let reported = false;
	let mode: Mode = DEFAULT_MODE;
	let toolRegistered = false;

	pi.registerFlag(SUBAGENT_FLAG, {
		description: "Internal: run as a rex_subagent child reporting to this run directory",
		type: "string",
	});
	pi.registerFlag(MODE_FLAG, {
		description: `Which models rex_subagent may pick: ${MODES.join(", ")} (default: ${DEFAULT_MODE})`,
		type: "string",
	});

	const showMode = (ctx: ExtensionContext) => {
		if (toolRegistered) ctx.ui.setStatus("rex-subagent", ctx.ui.theme.fg("dim", `subagents: ${mode}`));
	};

	pi.registerCommand("subagent-mode", {
		description: `Choose which models rex_subagent may pick (${MODES.join(", ")})`,
		getArgumentCompletions: (prefix: string) => {
			const items = MODES.filter((m) => m.startsWith(prefix.trim())).map((m) => ({ value: m, label: m }));
			return items.length ? items : null;
		},
		handler: async (args, ctx) => {
			let next: string | undefined = args.trim() || undefined;
			if (!next && ctx.hasUI) next = await ctx.ui.select(`Subagent models (current: ${mode})`, [...MODES]);
			if (!next) {
				ctx.ui.notify(`Subagent mode: ${mode}`, "info");
				return;
			}
			if (!isMode(next)) {
				ctx.ui.notify(`Unknown mode "${next}". Use one of: ${MODES.join(", ")}`, "error");
				return;
			}
			mode = next;
			pi.appendEntry(MODE_ENTRY, { mode });
			showMode(ctx);
			ctx.ui.notify(`Subagent mode: ${mode}`, "info");
		},
	});

	pi.on("session_start", (_event, ctx) => {
		const flag = pi.getFlag(SUBAGENT_FLAG);
		runDir = typeof flag === "string" && flag ? flag : undefined;
		config = runDir ? readConfig(runDir) : undefined;
		reported = false;
		mode = initialMode(pi.getFlag(MODE_FLAG), ctx, config);
		toolRegistered = !!(process.env.REX_SESSION || process.env.REX_BLOCK) && (!config || config.spawning);
		if (toolRegistered) registerTool(pi, loadAgents(agentDirectories(ctx)), () => mode);
		showMode(ctx);
	});

	pi.on("before_agent_start", (event) => {
		if (!config) return;
		const options = event.systemPromptOptions;
		options.sections.subagent = CHILD_PROMPT;
		if (!config.agent?.prompt) return;
		if (config.agent.promptMode === "replace") options.customPrompt = config.agent.prompt;
		else options.sections.agent = config.agent.prompt;
	});

	pi.on("tool_execution_start", (event) => {
		if (runDir && !reported) writeActivity(runDir, describeToolCall(event.toolName, event.args));
	});

	pi.on("agent_settled", (event, ctx) => {
		if (!runDir || !config || reported || event.aborted) return;
		reported = true;
		const entries = ctx.sessionManager.getBranch() as Parameters<typeof finalResult>[0];
		writeResult(runDir, finalResult(entries, ctx.sessionManager.getSessionFile()));
		if (!config.keepOpen) ctx.shutdown();
	});
}
