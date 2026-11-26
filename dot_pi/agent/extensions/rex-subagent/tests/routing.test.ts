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
	EFFORT_QUESTION,
	decisionRecord,
	describeSelection,
	routingContext,
	selectRoute,
	tierIndex,
	type Mode,
} from "../src/routing.ts";

const scored = (score: number, confidence = 0.8, extra: Record<string, { type: string; score?: number; probability?: number }> = {}) => ({
	stopReason: "stop",
	answers: { [SIZE_QUESTION]: { type: "score", score, confidence }, ...extra },
});
const effort = (score: number) => ({ [EFFORT_QUESTION]: { type: "score", score } });
const review = (probability: number) => ({ review: { type: "bool", probability } });

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

test("routingContext asks size, effort and each override in one call", () => {
	const agent = parseAgent("scout.md", "---\ndescription: Finds things\n---\nScout.", "user", "/s")!;
	const context = routingContext("find the config loader", agent, DEFAULT_ROUTING);
	assert.deepEqual(context.state, { task: "find the config loader", agent: { name: "scout", role: "Finds things" } });
	assert.deepEqual(Object.keys(context.questions), [SIZE_QUESTION, EFFORT_QUESTION, "review"]);
	const size = context.questions[SIZE_QUESTION] as { type: string; criteria: string[]; instructions: string };
	assert.equal(size.type, "score");
	assert.equal(size.criteria.length, DEFAULT_ROUTING.tiers.length);
	assert.match(size.criteria[0], /^trivial: /);
	assert.match(size.instructions, /Ignore wording about importance/);
	const effortQ = context.questions[EFFORT_QUESTION] as { criteria: string[] };
	assert.deepEqual(effortQ.criteria.map((c) => c.split(":")[0]), ["low", "medium", "high", "xhigh"]);
	assert.equal((context.questions.review as { type: string }).type, "bool");
	assert.deepEqual(routingContext("t", undefined, DEFAULT_ROUTING).state, { task: "t" });
});

test("tierIndex rounds but makes the top tier harder to reach", () => {
	assert.equal(tierIndex(0.4, DEFAULT_ROUTING), 0);
	assert.equal(tierIndex(2.5, DEFAULT_ROUTING), 3);
	assert.equal(tierIndex(3.55, DEFAULT_ROUTING), 3);
	assert.equal(tierIndex(3.6, DEFAULT_ROUTING), 4);
	assert.equal(tierIndex(9, DEFAULT_ROUTING), 4);
	assert.equal(tierIndex(-1, DEFAULT_ROUTING), 0);
});

test("selectRoute maps size to a tier and picks the mode's model", () => {
	const tiers = DEFAULT_ROUTING.tiers;
	assert.equal(selectRoute(scored(0.2), DEFAULT_ROUTING, "claude")?.tier, tiers[0]);
	assert.equal(selectRoute(scored(2.6), DEFAULT_ROUTING, "claude")?.tier, tiers[3]);
	assert.equal(selectRoute(scored(3.5), DEFAULT_ROUTING, "claude")?.tier, tiers[3]);
	assert.equal(selectRoute(scored(-1), DEFAULT_ROUTING, "claude")?.tier, tiers[0]);
	assert.equal(selectRoute(scored(99), DEFAULT_ROUTING, "claude")?.tier, tiers.at(-1));
	assert.deepEqual(selectRoute(scored(4), DEFAULT_ROUTING, "openai")?.choice, tiers[4].models.openai);
	assert.equal(selectRoute(scored(1, 0.42), DEFAULT_ROUTING, "claude")?.confidence, 0.42);
});

test("selectRoute rejects failed, malformed and low-confidence answers", () => {
	assert.equal(selectRoute({ stopReason: "error", errorMessage: "401", answers: {} }, DEFAULT_ROUTING, "claude"), undefined);
	assert.equal(selectRoute({ stopReason: "stop", answers: {} }, DEFAULT_ROUTING, "claude"), undefined);
	assert.equal(
		selectRoute({ stopReason: "stop", answers: { [SIZE_QUESTION]: { type: "bool" } } }, DEFAULT_ROUTING, "claude"),
		undefined,
	);
	assert.equal(selectRoute(scored(Number.NaN), DEFAULT_ROUTING, "claude"), undefined);
	assert.equal(selectRoute(scored(2, 0.2), { ...DEFAULT_ROUTING, minConfidence: 0.5 }, "claude"), undefined);
});

test("selectRoute takes thinking from effort, falling back to the tier's", () => {
	const tiers = DEFAULT_ROUTING.tiers;
	const withEffort = selectRoute(scored(0, 0.9, effort(2.8)), DEFAULT_ROUTING, "claude")!;
	assert.deepEqual(withEffort.choice, { model: tiers[0].models.claude.model, thinking: "xhigh" });
	assert.equal(withEffort.effort, "xhigh");
	assert.equal(selectRoute(scored(2, 0.9, effort(-3)), DEFAULT_ROUTING, "claude")!.choice.thinking, "low");
	const noEffort = selectRoute(scored(2), DEFAULT_ROUTING, "claude")!;
	assert.equal(noEffort.choice.thinking, tiers[2].models.claude.thinking);
	assert.equal(noEffort.effort, undefined);
});

test("selectRoute sends reviews to the review model whatever their size", () => {
	const small = selectRoute(scored(1, 0.9, { ...review(0.95), ...effort(1) }), DEFAULT_ROUTING, "claude")!;
	assert.deepEqual(small.choice, { model: "anthropic/claude-opus-*", thinking: "medium" });
	assert.equal(small.override, "review");
	assert.equal(small.tier.size, "small");
	assert.equal(selectRoute(scored(1, 0.9, review(0.95)), DEFAULT_ROUTING, "openai")!.choice.model, "openai-codex/gpt-*-astra");
	const notReview = selectRoute(scored(1, 0.9, review(0.5)), DEFAULT_ROUTING, "claude")!;
	assert.equal(notReview.override, undefined);
	assert.equal(notReview.choice.model, DEFAULT_ROUTING.tiers[1].models.claude.model);
});

test("describeSelection names the size, override and effort", () => {
	const selection = selectRoute(scored(1, 0.9, { ...review(0.95), ...effort(2) }), DEFAULT_ROUTING, "claude")!;
	assert.equal(describeSelection(selection), "small, review, effort high (90%)");
	assert.equal(describeSelection(selectRoute(scored(0, 0.5), DEFAULT_ROUTING, "claude")!), "trivial (50%)");
});

test("every default tier keeps each mode within its providers", () => {
	assert.deepEqual([...allowedProviders(DEFAULT_ROUTING, "claude")], ["anthropic"]);
	assert.deepEqual([...allowedProviders(DEFAULT_ROUTING, "openai")], ["openai-codex"]);
	assert.deepEqual([...allowedProviders(DEFAULT_ROUTING, "mixed")].sort(), ["anthropic", "openai-codex"]);
});

test("planModel resolves the selected tier to the newest model in its family", () => {
	for (const mode of MODES) {
		const selection = selectRoute(scored(4), DEFAULT_ROUTING, mode)!;
		const result = plan(mode, { selection });
		assert.equal(result.note, "auto: very large (80%)");
		assert.equal(result.request.thinking, "high");
		assert.equal(result.request.model, mode === "openai" ? "openai-codex/gpt-6.2-astra" : "anthropic/claude-opus-5-5");
	}
});

test("planModel keeps explicit call values", () => {
	const selection = selectRoute(scored(0), DEFAULT_ROUTING, "claude")!;
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
	const selection = selectRoute(scored(4), DEFAULT_ROUTING, "claude")!;
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

test("decisionRecord keeps scores and truncates long tasks", () => {
	const record = decisionRecord({
		time: new Date("2026-01-02T03:04:05Z"),
		cwd: "/repo",
		mode: "claude",
		agent: "reviewer",
		task: "x".repeat(500),
		result: scored(1.2, 0.9, { ...review(0.97), ...effort(1.8) }),
		model: "anthropic/claude-opus-5-5",
		thinking: "high",
		note: "auto: small, review, effort high (90%)",
	});
	assert.equal(record.time, "2026-01-02T03:04:05.000Z");
	assert.equal(record.taskChars, 500);
	assert.equal(record.task.length, 400);
	assert.deepEqual(record.answers, { [SIZE_QUESTION]: 1.2, review: 0.97, [EFFORT_QUESTION]: 1.8 });
	assert.equal(decisionRecord({ time: new Date(), cwd: "/", mode: "openai", task: "t" }).answers, undefined);
});

test("parseModelRef splits provider from model id", () => {
	assert.deepEqual(parseModelRef("openrouter/typesafe/jev-1.13"), { provider: "openrouter", id: "typesafe/jev-1.13" });
	assert.equal(parseModelRef("bare"), undefined);
	assert.equal(parseModelRef("/x"), undefined);
	assert.equal(parseModelRef("x/"), undefined);
});
