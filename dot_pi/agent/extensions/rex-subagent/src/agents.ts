import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

export type AgentScope = "user" | "project";
export type PromptMode = "append" | "replace";

export interface AgentDefinition {
	name: string;
	description: string;
	prompt: string;
	promptMode: PromptMode;
	tools?: string[];
	model?: string;
	thinking?: string;
	spawning: boolean;
	autoExit: boolean;
	scope: AgentScope;
	path: string;
}

export interface AgentDirectory {
	path: string;
	scope: AgentScope;
}

function unquote(value: string): string {
	const first = value.at(0);
	const last = value.at(-1);
	return value.length >= 2 && first === last && (first === '"' || first === "'") ? value.slice(1, -1) : value;
}

function parseBoolean(value: string | undefined, fallback: boolean): boolean {
	if (value === undefined || value === "") return fallback;
	if (/^(true|yes|1)$/i.test(value)) return true;
	if (/^(false|no|0)$/i.test(value)) return false;
	return fallback;
}

function parseList(value: string | undefined): string[] | undefined {
	const items = (value ?? "")
		.replace(/^\[|\]$/g, "")
		.split(",")
		.map((item) => unquote(item.trim()))
		.filter(Boolean);
	return items.length ? items : undefined;
}

export function parseAgent(filename: string, raw: string, scope: AgentScope, path: string): AgentDefinition | undefined {
	const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)([\s\S]*)$/);
	const metadata: Record<string, string> = {};
	for (const line of match?.[1].split(/\r?\n/) ?? []) {
		const pair = line.match(/^([A-Za-z][\w-]*)\s*:\s*(.*?)\s*$/);
		if (pair) metadata[pair[1].toLowerCase()] = unquote(pair[2]);
	}
	if (parseBoolean(metadata.disabled, false)) return undefined;

	return {
		name: metadata.name || filename.replace(/\.md$/i, ""),
		description: metadata.description || "",
		prompt: (match ? match[2] : raw).trim(),
		promptMode: metadata["system-prompt"]?.toLowerCase() === "replace" ? "replace" : "append",
		tools: parseList(metadata.tools),
		model: metadata.model || undefined,
		thinking: metadata.thinking || undefined,
		spawning: parseBoolean(metadata.spawning, false),
		autoExit: parseBoolean(metadata["auto-exit"], true),
		scope,
		path,
	};
}

function scanDirectory(directory: AgentDirectory): AgentDefinition[] {
	if (!existsSync(directory.path)) return [];
	try {
		return readdirSync(directory.path, { withFileTypes: true })
			.filter((entry) => (entry.isFile() || entry.isSymbolicLink()) && entry.name.toLowerCase().endsWith(".md"))
			.sort((a, b) => a.name.localeCompare(b.name))
			.flatMap((entry) => {
				const path = join(directory.path, entry.name);
				try {
					const agent = parseAgent(entry.name, readFileSync(path, "utf8"), directory.scope, path);
					return agent ? [agent] : [];
				} catch {
					return [];
				}
			});
	} catch {
		return [];
	}
}

export function loadAgents(directories: AgentDirectory[]): AgentDefinition[] {
	const agents = new Map<string, AgentDefinition>();
	for (const directory of directories) {
		for (const agent of scanDirectory(directory)) agents.set(agent.name, agent);
	}
	return [...agents.values()].sort((a, b) => a.name.localeCompare(b.name));
}

export function describeAgents(agents: AgentDefinition[]): string {
	return agents
		.map((agent) => {
			const traits = [
				agent.tools && `tools: ${agent.tools.join(",")}`,
				agent.model && `model: ${agent.model}`,
				agent.thinking && `thinking: ${agent.thinking}`,
			].filter(Boolean);
			return `- ${agent.name}: ${agent.description || "(no description)"}${traits.length ? ` (${traits.join("; ")})` : ""}`;
		})
		.join("\n");
}
