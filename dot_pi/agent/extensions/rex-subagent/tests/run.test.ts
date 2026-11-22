import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
	buildPiArgs,
	createRun,
	describeToolCall,
	finalResult,
	planSpawn,
	readActivity,
	readConfig,
	readResult,
	slugLabel,
	writeActivity,
	writeResult,
} from "../src/run.ts";
import { parseAgent } from "../src/agents.ts";

function withDir(fn: (dir: string) => void) {
	const dir = mkdtempSync(join(tmpdir(), "rex-subagent-test-"));
	try {
		fn(join(dir, "run"));
	} finally {
		rmSync(dir, { recursive: true, force: true });
	}
}

const assistant = (content: unknown, extra: Record<string, unknown> = {}) => ({
	type: "message",
	message: { role: "assistant", content, ...extra },
});

test("run directory round-trips config, activity and result", () => {
	withDir((dir) => {
		const config = { keepOpen: true, spawning: false, agent: { name: "scout", prompt: "p", promptMode: "append" as const } };
		createRun(dir, config);
		assert.deepEqual(readConfig(dir), config);
		assert.equal(readResult(dir), undefined);
		assert.equal(readActivity(dir), undefined);

		writeActivity(dir, "bash: ls");
		assert.equal(readActivity(dir), "bash: ls");

		const result = { status: "done" as const, output: "ok", finishedAt: "now" };
		writeResult(dir, result);
		assert.deepEqual(readResult(dir), result);
	});
});

test("readConfig defaults to closing the tab", () => {
	withDir((dir) => assert.deepEqual(readConfig(dir), { keepOpen: false, spawning: false }));
});

const parent = { model: "anthropic/opus", thinking: "high" };

test("planSpawn without an agent inherits the parent", () => {
	assert.deepEqual(planSpawn({}, undefined, parent, "abcd"), {
		label: "subagent-abcd",
		model: "anthropic/opus",
		thinking: "high",
		tools: undefined,
		config: { keepOpen: false, spawning: false, agent: undefined },
	});
});

test("planSpawn uses agent defaults and lets the call override them", () => {
	const agent = parseAgent(
		"scout.md",
		"---\ntools: read,bash\nthinking: low\nmodel: x/luna\nauto-exit: false\nsystem-prompt: replace\n---\nScout.",
		"user",
		"/s",
	)!;
	const plan = planSpawn({}, agent, parent, "abcd");
	assert.equal(plan.label, "scout-abcd");
	assert.equal(plan.model, "x/luna");
	assert.equal(plan.thinking, "low");
	assert.deepEqual(plan.tools, ["read", "bash"]);
	assert.deepEqual(plan.config, {
		keepOpen: true,
		spawning: false,
		agent: { name: "scout", prompt: "Scout.", promptMode: "replace" },
	});

	const overridden = planSpawn(
		{ name: "Auth Scout", model: "y/m", thinking: "max", tools: ["read"], keep_open: false },
		agent,
		parent,
		"abcd",
	);
	assert.equal(overridden.label, "auth-scout");
	assert.equal(overridden.model, "y/m");
	assert.equal(overridden.thinking, "max");
	assert.deepEqual(overridden.tools, ["read"]);
	assert.equal(overridden.config.keepOpen, false);
});

test("planSpawn keeps rex_subagent available to spawning agents", () => {
	const agent = parseAgent("lead.md", "---\ntools: read\nspawning: true\n---\nLead.", "user", "/l")!;
	const plan = planSpawn({}, agent, parent, "abcd");
	assert.deepEqual(plan.tools, ["read", "rex_subagent"]);
	assert.equal(plan.config.spawning, true);
});

test("buildPiArgs puts the task after --", () => {
	assert.deepEqual(
		buildPiArgs({ runDir: "/r", label: "scout", task: "-x 'y'", model: "a/b", thinking: "high", tools: ["read", "bash"] }),
		["--rex-subagent", "/r", "--name", "scout", "--model", "a/b", "--thinking", "high", "--tools", "read,bash", "--", "-x 'y'"],
	);
	assert.deepEqual(buildPiArgs({ runDir: "/r", label: "s", task: "t" }), ["--rex-subagent", "/r", "--name", "s", "--", "t"]);
});

test("finalResult returns the last assistant text", () => {
	const result = finalResult(
		[
			assistant([{ type: "text", text: "first" }]),
			{ type: "message", message: { role: "user", content: "hi" } },
			assistant([
				{ type: "thinking", thinking: "hmm" },
				{ type: "text", text: "final " },
				{ type: "text", text: "report" },
			]),
			{ type: "custom" },
		],
		"/s.jsonl",
	);
	assert.equal(result.status, "done");
	assert.equal(result.output, "final \nreport");
	assert.equal(result.sessionFile, "/s.jsonl");
});

test("finalResult reports model errors and empty sessions", () => {
	const failed = finalResult([assistant([], { stopReason: "error", errorMessage: "overloaded" })]);
	assert.equal(failed.status, "error");
	assert.equal(failed.error, "overloaded");
	assert.equal(finalResult([]).status, "error");
});

test("slugLabel normalizes names", () => {
	assert.equal(slugLabel("Auth Scout!", "x"), "auth-scout");
	assert.equal(slugLabel("  ", "fallback"), "fallback");
	assert.equal(slugLabel(undefined, "fallback"), "fallback");
});

test("describeToolCall summarizes the first line", () => {
	assert.equal(describeToolCall("bash", { command: "ls\npwd" }), "bash: ls");
	assert.equal(describeToolCall("read", { path: "a.ts" }), "read: a.ts");
	assert.equal(describeToolCall("custom", {}), "custom");
	assert.equal(describeToolCall("bash", { command: "x".repeat(200) }).length, 120);
});
