import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { AgentDefinition, PromptMode } from "./agents.ts";

export interface RunConfig {
	keepOpen: boolean;
	spawning: boolean;
	agent?: { name: string; prompt: string; promptMode: PromptMode };
}

export interface SpawnRequest {
	name?: string;
	model?: string;
	thinking?: string;
	tools?: string[];
	keep_open?: boolean;
}

export interface SpawnPlan {
	label: string;
	model?: string;
	thinking?: string;
	tools?: string[];
	config: RunConfig;
}

export interface SubagentResult {
	status: "done" | "error";
	output: string;
	error?: string;
	sessionFile?: string;
	finishedAt: string;
}

export interface SpawnOptions {
	runDir: string;
	label: string;
	task: string;
	model?: string;
	thinking?: string;
	tools?: string[];
}

interface MessageEntry {
	type: string;
	message?: {
		role?: string;
		content?: unknown;
		stopReason?: string;
		errorMessage?: string;
	};
}

export const SUBAGENT_FLAG = "rex-subagent";
export const TOOL_NAME = "rex_subagent";

const paths = (dir: string) => ({
	config: join(dir, "config.json"),
	result: join(dir, "result.json"),
	activity: join(dir, "activity"),
});

function writeAtomic(path: string, data: string) {
	const tmp = `${path}.${process.pid}.tmp`;
	writeFileSync(tmp, data);
	renameSync(tmp, path);
}

function readJson<T>(path: string): T | undefined {
	if (!existsSync(path)) return undefined;
	try {
		return JSON.parse(readFileSync(path, "utf8")) as T;
	} catch {
		return undefined;
	}
}

export function createRun(dir: string, config: RunConfig) {
	mkdirSync(dir, { recursive: true });
	writeAtomic(paths(dir).config, JSON.stringify(config));
}

export const readConfig = (dir: string): RunConfig => ({
	keepOpen: false,
	spawning: false,
	...readJson<Partial<RunConfig>>(paths(dir).config),
});

export const writeResult = (dir: string, result: SubagentResult) =>
	writeAtomic(paths(dir).result, JSON.stringify(result));

export const readResult = (dir: string) => readJson<SubagentResult>(paths(dir).result);

export const writeActivity = (dir: string, line: string) => writeAtomic(paths(dir).activity, line);

export function readActivity(dir: string): string | undefined {
	try {
		return readFileSync(paths(dir).activity, "utf8");
	} catch {
		return undefined;
	}
}

export function slugLabel(name: string | undefined, fallback: string): string {
	const slug = (name ?? "")
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, 40);
	return slug || fallback;
}

export function planSpawn(
	request: SpawnRequest,
	agent: AgentDefinition | undefined,
	parent: { model?: string; thinking?: string },
	id: string,
): SpawnPlan {
	const spawning = agent?.spawning ?? false;
	const baseTools = request.tools ?? agent?.tools;
	const tools = spawning && baseTools && !baseTools.includes(TOOL_NAME) ? [...baseTools, TOOL_NAME] : baseTools;
	return {
		label: slugLabel(request.name, `${agent?.name ?? "subagent"}-${id}`),
		model: request.model ?? agent?.model ?? parent.model,
		thinking: request.thinking ?? agent?.thinking ?? parent.thinking,
		tools,
		config: {
			keepOpen: request.keep_open ?? !(agent?.autoExit ?? true),
			spawning,
			agent: agent && { name: agent.name, prompt: agent.prompt, promptMode: agent.promptMode },
		},
	};
}

export function buildPiArgs(options: SpawnOptions): string[] {
	const args = [`--${SUBAGENT_FLAG}`, options.runDir, "--name", options.label];
	if (options.model) args.push("--model", options.model);
	if (options.thinking) args.push("--thinking", options.thinking);
	if (options.tools?.length) args.push("--tools", options.tools.join(","));
	args.push("--", options.task);
	return args;
}

export function finalResult(entries: MessageEntry[], sessionFile?: string): SubagentResult {
	const finishedAt = new Date().toISOString();
	for (let i = entries.length - 1; i >= 0; i--) {
		const message = entries[i].message;
		if (entries[i].type !== "message" || message?.role !== "assistant") continue;
		const output = Array.isArray(message.content)
			? message.content
					.filter((part): part is { type: "text"; text: string } => part?.type === "text")
					.map((part) => part.text)
					.join("\n")
					.trim()
			: "";
		if (message.stopReason === "error") {
			return { status: "error", output, error: message.errorMessage ?? "Model request failed", sessionFile, finishedAt };
		}
		return { status: "done", output, sessionFile, finishedAt };
	}
	return { status: "error", output: "", error: "Subagent produced no assistant message", sessionFile, finishedAt };
}

export function describeToolCall(toolName: string, args: unknown): string {
	const input = (args ?? {}) as Record<string, unknown>;
	const detail = [input.command, input.path, input.pattern, input.query, input.url].find(
		(value): value is string => typeof value === "string",
	);
	const line = detail ? `${toolName}: ${detail}` : toolName;
	const firstLine = line.split("\n")[0];
	return firstLine.length > 120 ? `${firstLine.slice(0, 117)}...` : firstLine;
}
