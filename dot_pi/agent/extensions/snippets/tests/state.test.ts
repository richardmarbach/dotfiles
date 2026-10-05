import assert from "node:assert/strict";
import test from "node:test";
import { consumeSelection, type SnippetState } from "../src/state.ts";
import type { Snippet } from "../src/types.ts";

const snippets: Snippet[] = [
	{
		id: "context",
		name: "Context",
		description: "",
		placement: "prepend",
		order: 10,
		body: "Extra context",
		scope: "global",
		path: "/context.md",
	},
	{
		id: "verify",
		name: "Verify",
		description: "",
		placement: "append",
		order: 20,
		body: "Verify the result",
		scope: "global",
		path: "/verify.md",
	},
];

function state(): SnippetState {
	return { snippets, selected: new Set(["context", "verify"]) };
}

test("applies a selection once and clears it", () => {
	const first = consumeSelection(state(), "Implement it", "interactive");
	assert.equal(first.transformed, true);
	assert.equal(first.text, "Extra context\n\nImplement it\n\nVerify the result");
	assert.deepEqual([...first.state.selected], []);

	const second = consumeSelection(first.state, "Another message", "interactive");
	assert.equal(second.transformed, false);
	assert.equal(second.text, "Another message");
});

test("preserves the selection for slash commands", () => {
	const original = state();
	const result = consumeSelection(original, "/review src/index.ts", "interactive");
	assert.equal(result.transformed, false);
	assert.equal(result.text, "/review src/index.ts");
	assert.deepEqual([...result.state.selected], ["context", "verify"]);
});

test("preserves the selection for extension-injected messages", () => {
	const original = state();
	const result = consumeSelection(original, "Subagent result", "extension");
	assert.equal(result.transformed, false);
	assert.equal(result.text, "Subagent result");
	assert.deepEqual([...result.state.selected], ["context", "verify"]);
});

test("clears stale selections on a regular message", () => {
	const result = consumeSelection({ snippets, selected: new Set(["missing"]) }, "Hello", "rpc");
	assert.equal(result.transformed, false);
	assert.deepEqual([...result.state.selected], []);
});
