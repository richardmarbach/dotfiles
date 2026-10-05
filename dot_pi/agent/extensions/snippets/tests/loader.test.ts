import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { applySnippets, loadSnippets, parseSnippet } from "../src/loader.ts";
import type { Snippet } from "../src/types.ts";

function snippet(overrides: Partial<Snippet>): Snippet {
	return {
		id: "test",
		name: "Test",
		description: "",
		placement: "append",
		order: 100,
		body: "body",
		scope: "global",
		path: "/test.md",
		...overrides,
	};
}

test("parses frontmatter and accepts plain markdown", () => {
	const parsed = parseSnippet(
		"verify.md",
		"---\nname: Verify\ndescription: Check it\nplacement: prepend\norder: 5\n---\nRun tests.",
		"global",
		"/verify.md",
	);
	assert.deepEqual(parsed.snippet, snippet({
		id: "verify",
		name: "Verify",
		description: "Check it",
		placement: "prepend",
		order: 5,
		body: "Run tests.",
		path: "/verify.md",
	}));

	const plain = parseSnippet("plain.md", "Just do this.", "global", "/plain.md");
	assert.equal(plain.snippet?.name, "plain");
	assert.equal(plain.snippet?.body, "Just do this.");
	assert.equal(plain.snippet?.placement, "append");
});

test("higher-precedence directories override or disable snippets", () => {
	const root = mkdtempSync(join(tmpdir(), "pi-snippets-"));
	const global = join(root, "global");
	const project = join(root, "project");
	mkdirSync(global);
	mkdirSync(project);

	try {
		writeFileSync(join(global, "shared.md"), "Global body");
		writeFileSync(join(global, "removed.md"), "Remove me");
		writeFileSync(join(project, "shared.md"), "Project body");
		writeFileSync(join(project, "removed.md"), "---\ndisabled: true\n---\n");

		const loaded = loadSnippets([
			{ path: global, scope: "global" },
			{ path: project, scope: "project" },
		]);
		assert.deepEqual(loaded.map((item) => [item.id, item.body, item.scope]), [
			["shared", "Project body", "project"],
		]);
	} finally {
		rmSync(root, { recursive: true, force: true });
	}
});

test("sorts by placement and order and applies around the message", () => {
	const snippets = [
		snippet({ id: "last", body: "Append last", placement: "append", order: 20 }),
		snippet({ id: "first", body: "Prepend first", placement: "prepend", order: 10 }),
		snippet({ id: "second", body: "Append first", placement: "append", order: 10 }),
	];

	assert.equal(
		applySnippets("User message", snippets),
		"Prepend first\n\nUser message\n\nAppend last\n\nAppend first",
	);
});
