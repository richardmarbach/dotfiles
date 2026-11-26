import assert from "node:assert/strict";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { parseAgent } from "../src/agents.ts";
import {
	DEFAULT_ROUTING,
	MODES,
	SIZE_QUESTION,
	allowedProviders,
	loadRoutingConfig,
	needsRouting,
	parseModelRef,
	planModel,
	selectTier,
	sizingContext,
	type Mode,
} from "../src/routing.ts";

const scored = (score: number, confidence = 0.8) => ({
	stopReason: "stop",
	answers: { [SIZE_QUESTION]: { type: "score", score, confidence } },
});

const catalog = [
	"anthropic/claude-haiku-5-5",
	"anthropic/claude-sonnet-5-5",
	"anthropic/claude-opus-5-5",
	"openai-codex/gpt-6-luna",
	"openai-codex/gpt-6.2-sol",
	"openai-codex/gpt-6.2-astra",
].map((ref) => parseModelRef(ref)!);

const plan = (mode: Mode, extra: Partial<Parameters<typeof planModel>[0]> = {}) =>
	planModel({ request: {}, mode, config: DEFAULT_ROUTING, catalog, ...extra });

test("needsRouting only when the caller left model or thinking open", () => {
	assert.equal(needsRouting({}), true);
	assert.equal(needsRouting({ model: "a/b" }), true);
	assert.equal(needsRouting({ thinking: "high" }), true);
	assert.equal(needsRouting({ model: "a/b", thinking: "high" }), false);
});

test("sizingContext lists one criterion per tier and includes the agent role", () => {
	const agent = parseAgent("scout.md", "---\ndescription: Finds things\n---\nScout.", "user", "/s")!;
	const context = sizingContext("find the config loader", agent, DEFAULT_ROUTING.tiers);
	assert.deepEqual(context.state, { task: "find the config loader", agent: { name: "scout", role: "Finds things" } });
	const question = context.questions[SIZE_QUESTION];
	assert.equal(question.type, "score");
	assert.equal(question.criteria.length, DEFAULT_ROUTING.tiers.length);
	assert.match(question.criteria[0], /^trivial: /);
	assert.deepEqual(sizingContext("t", undefined, DEFAULT_ROUTING.tiers).state, { task: "t" });
});

test("selectTier rounds and clamps the score and picks the mode's model", () => {
	const tiers = DEFAULT_ROUTING.tiers;
	assert.equal(selectTier(scored(0.2), DEFAULT_ROUTING, "claude")?.tier, tiers[0]);
	assert.equal(selectTier(scored(2.6), DEFAULT_ROUTING, "claude")?.tier, tiers[3]);
	assert.equal(selectTier(scored(-1), DEFAULT_ROUTING, "claude")?.tier, tiers[0]);
	assert.equal(selectTier(scored(99), DEFAULT_ROUTING, "claude")?.tier, tiers.at(-1));
	assert.equal(selectTier(scored(4), DEFAULT_ROUTING, "openai")?.choice, tiers[4].models.openai);
	assert.equal(selectTier(scored(1, 0.42), DEFAULT_ROUTING, "claude")?.confidence, 0.42);
});

test("selectTier rejects failed, malformed and low-confidence answers", () => {
	assert.equal(selectTier({ stopReason: "error", errorMessage: "401", answers: {} }, DEFAULT_ROUTING, "claude"), undefined);
	assert.equal(selectTier({ stopReason: "stop", answers: {} }, DEFAULT_ROUTING, "claude"), undefined);
	assert.equal(
		selectTier({ stopReason: "stop", answers: { [SIZE_QUESTION]: { type: "bool" } } }, DEFAULT_ROUTING, "claude"),
		undefined,
	);
	assert.equal(selectTier(scored(Number.NaN), DEFAULT_ROUTING, "claude"), undefined);
	assert.equal(selectTier(scored(2, 0.2), { ...DEFAULT_ROUTING, minConfidence: 0.5 }, "claude"), undefined);
});

test("every default tier keeps each mode within its providers", () => {
	assert.deepEqual([...allowedProviders(DEFAULT_ROUTING, "claude")], ["anthropic"]);
	assert.deepEqual([...allowedProviders(DEFAULT_ROUTING, "openai")], ["openai-codex"]);
	assert.deepEqual([...allowedProviders(DEFAULT_ROUTING, "mixed")].sort(), ["anthropic", "openai-codex"]);
});

test("planModel resolves the selected tier to the newest model in its family", () => {
	for (const mode of MODES) {
		const selection = selectTier(scored(4), DEFAULT_ROUTING, mode)!;
		const result = plan(mode, { selection });
		assert.equal(result.note, "auto: very large (80%)");
		assert.equal(result.request.thinking, "high");
		assert.equal(result.request.model, mode === "openai" ? "openai-codex/gpt-6.2-astra" : "anthropic/claude-opus-5-5");
	}
});

test("planModel keeps explicit call values", () => {
	const selection = selectTier(scored(0), DEFAULT_ROUTING, "claude")!;
	const result = plan("claude", { request: { model: "x/y", thinking: "max" }, selection });
	assert.deepEqual(result.request, { model: "x/y", thinking: "max" });
	assert.equal(plan("openai", { request: { model: "anthropic/claude-opus-*" } }).request.model, "anthropic/claude-opus-5-5");
	assert.equal(plan("claude", { request: { thinking: "max" }, selection }).request.thinking, "max");
});

test("planModel falls back to the agent's model when the mode allows it", () => {
	const result = plan("claude", { agentModel: "anthropic/claude-sonnet-*", failure: "no classifier available" });
	assert.deepEqual(result.request, { model: undefined });
	assert.equal(result.agentModel, "anthropic/claude-sonnet-5-5");
	assert.equal(result.note, "defaults: no classifier available");
	assert.equal(plan("mixed", { parentModel: "openai-codex/gpt-6-luna" }).request.model, undefined);
});

test("planModel replaces a default the mode forbids with the mode's middle tier", () => {
	const result = plan("openai", { agentModel: "anthropic/claude-sonnet-*", failure: "timeout" });
	assert.deepEqual(result.request, { model: "openai-codex/gpt-6.2-sol", thinking: "medium" });
	assert.equal(result.note, "openai fallback: medium; timeout");
	assert.equal(plan("claude", { parentModel: "openai-codex/gpt-6-luna" }).request.model, "anthropic/claude-sonnet-5-5");
});

test("planModel treats an unavailable tier model as a classifier failure", () => {
	const selection = selectTier(scored(4), DEFAULT_ROUTING, "claude")!;
	const noOpus = catalog.filter((ref) => ref.id !== "claude-opus-5-5");
	const result = plan("claude", { selection, catalog: noOpus, agentModel: "anthropic/claude-haiku-*" });
	assert.equal(result.request.model, undefined);
	assert.equal(result.agentModel, "anthropic/claude-haiku-5-5");
	assert.equal(result.note, "defaults: anthropic/claude-opus-* unavailable");
});

test("loadRoutingConfig merges overrides and survives bad files", () => {
	const dir = mkdtempSync(join(tmpdir(), "rex-routing-test-"));
	try {
		const path = join(dir, "rex-subagent.json");
		assert.equal(loadRoutingConfig(path), DEFAULT_ROUTING);

		writeFileSync(path, JSON.stringify({ enabled: false, timeoutMs: 500, defaultMode: "openai" }));
		const partial = loadRoutingConfig(path);
		assert.equal(partial.enabled, false);
		assert.equal(partial.timeoutMs, 500);
		assert.equal(partial.defaultMode, "openai");
		assert.deepEqual(partial.tiers, DEFAULT_ROUTING.tiers);

		const choice = { model: "a/b", thinking: "low" };
		const tiers = [{ size: "any", description: "everything", models: { claude: choice, openai: choice, mixed: choice } }];
		writeFileSync(path, JSON.stringify({ tiers }));
		assert.deepEqual(loadRoutingConfig(path).tiers, tiers);

		writeFileSync(path, JSON.stringify({ defaultMode: "nope", tiers: [{ size: "x", models: { claude: choice } }] }));
		assert.equal(loadRoutingConfig(path).defaultMode, "claude");
		assert.deepEqual(loadRoutingConfig(path).tiers, DEFAULT_ROUTING.tiers);

		writeFileSync(path, "{nope");
		assert.equal(loadRoutingConfig(path), DEFAULT_ROUTING);
	} finally {
		rmSync(dir, { recursive: true, force: true });
	}
});

test("parseModelRef splits provider from model id", () => {
	assert.deepEqual(parseModelRef("openrouter/typesafe/jev-1.13"), { provider: "openrouter", id: "typesafe/jev-1.13" });
	assert.equal(parseModelRef("bare"), undefined);
	assert.equal(parseModelRef("/x"), undefined);
	assert.equal(parseModelRef("x/"), undefined);
});
