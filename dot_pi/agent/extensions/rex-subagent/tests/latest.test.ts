import assert from "node:assert/strict";
import test from "node:test";
import { resolveLatest, resolveModel } from "../src/latest.ts";

const catalog = [
	"anthropic/claude-opus-4-5",
	"anthropic/claude-opus-4-5-20251101",
	"anthropic/claude-opus-4-8",
	"anthropic/claude-opus-5",
	"anthropic/claude-opus-5-5",
	"anthropic/claude-haiku-4-5-20251001",
	"anthropic/claude-sonnet-5-5",
	"openai-codex/gpt-5.6-sol",
	"openai-codex/gpt-6-sol",
	"openai-codex/gpt-6.1-sol",
	"openai-codex/gpt-6.2-sol",
	"openai-codex/gpt-6-luna",
	"openai-codex/gpt-6.2-astra",
	"openrouter/anthropic/claude-opus-9",
].map((ref) => {
	const slash = ref.indexOf("/");
	return { provider: ref.slice(0, slash), id: ref.slice(slash + 1) };
});

test("resolveLatest picks the highest version in a family", () => {
	assert.equal(resolveLatest("anthropic/claude-opus-*", catalog), "anthropic/claude-opus-5-5");
	assert.equal(resolveLatest("openai-codex/gpt-*-sol", catalog), "openai-codex/gpt-6.2-sol");
	assert.equal(resolveLatest("openai-codex/gpt-*-luna", catalog), "openai-codex/gpt-6-luna");
	assert.equal(resolveLatest("anthropic/claude-sonnet-*", catalog), "anthropic/claude-sonnet-5-5");
});

test("resolveLatest picks up a newly released model", () => {
	const released = [...catalog, { provider: "anthropic", id: "claude-opus-6" }, { provider: "openai-codex", id: "gpt-7-sol" }];
	assert.equal(resolveLatest("anthropic/claude-opus-*", released), "anthropic/claude-opus-6");
	assert.equal(resolveLatest("openai-codex/gpt-*-sol", released), "openai-codex/gpt-7-sol");
});

test("resolveLatest ignores dated snapshots, other providers and other families", () => {
	assert.equal(resolveLatest("anthropic/claude-haiku-*", catalog), undefined);
	assert.equal(resolveLatest("openai-codex/gpt-*-terra", catalog), undefined);
	assert.equal(resolveLatest("anthropic/claude-opus-*", catalog.filter((m) => m.provider !== "anthropic")), undefined);
});

test("resolveModel passes concrete refs through", () => {
	assert.equal(resolveModel("anthropic/claude-opus-4-5", catalog), "anthropic/claude-opus-4-5");
	assert.equal(resolveModel("anything/at-all", []), "anything/at-all");
	assert.equal(resolveModel(undefined, catalog), undefined);
	assert.equal(resolveModel("anthropic/claude-opus-*", catalog), "anthropic/claude-opus-5-5");
});
