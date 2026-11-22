import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { describeAgents, loadAgents, parseAgent } from "../src/agents.ts";

const scout = `---
name: scout
description: Quickly investigates a codebase
tools: read,bash
thinking: low
model: openai-codex/gpt-6-luna
spawning: false
auto-exit: true
system-prompt: replace
---

You are a research agent.
`;

test("parseAgent reads frontmatter and body", () => {
	assert.deepEqual(parseAgent("scout.md", scout, "user", "/a/scout.md"), {
		name: "scout",
		description: "Quickly investigates a codebase",
		prompt: "You are a research agent.",
		promptMode: "replace",
		tools: ["read", "bash"],
		model: "openai-codex/gpt-6-luna",
		thinking: "low",
		spawning: false,
		autoExit: true,
		scope: "user",
		path: "/a/scout.md",
	});
});

test("parseAgent applies defaults and accepts list syntax", () => {
	const agent = parseAgent("helper.md", "---\ntools: [read, 'grep']\nauto-exit: no\n---\nHelp.", "project", "/p");
	assert.equal(agent?.name, "helper");
	assert.deepEqual(agent?.tools, ["read", "grep"]);
	assert.equal(agent?.promptMode, "append");
	assert.equal(agent?.autoExit, false);
	assert.equal(agent?.spawning, false);
	assert.equal(agent?.model, undefined);
	assert.equal(parseAgent("plain.md", "Just a prompt", "user", "/x")?.prompt, "Just a prompt");
	assert.equal(parseAgent("off.md", "---\ndisabled: true\n---\nx", "user", "/x"), undefined);
});

test("loadAgents lets project agents override user agents", () => {
	const root = mkdtempSync(join(tmpdir(), "rex-subagent-agents-"));
	try {
		const user = join(root, "user");
		const project = join(root, "project");
		mkdirSync(user);
		mkdirSync(project);
		writeFileSync(join(user, "scout.md"), scout);
		writeFileSync(join(user, "worker.md"), "---\ndescription: Does work\n---\nWork.");
		writeFileSync(join(user, "notes.txt"), "ignored");
		writeFileSync(join(project, "scout.md"), "---\nname: scout\ndescription: Project scout\n---\nLocal.");

		const agents = loadAgents([
			{ path: user, scope: "user" },
			{ path: project, scope: "project" },
			{ path: join(root, "missing"), scope: "project" },
		]);
		assert.deepEqual(agents.map((agent) => [agent.name, agent.scope, agent.description]), [
			["scout", "project", "Project scout"],
			["worker", "user", "Does work"],
		]);
	} finally {
		rmSync(root, { recursive: true, force: true });
	}
});

test("describeAgents lists traits", () => {
	const agent = parseAgent("scout.md", scout, "user", "/a")!;
	assert.equal(
		describeAgents([agent]),
		"- scout: Quickly investigates a codebase (tools: read,bash; model: openai-codex/gpt-6-luna; thinking: low)",
	);
});
