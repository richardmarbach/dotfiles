/**
 * Settings.json loader + validator tests.
 *
 * Real fs, real tmpdir. No mocks.
 */

import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import { DEFAULT_WHITELIST } from "../src/defaults.ts";
import { loadReadonlySettings, validateWhitelistShape } from "../src/settings.ts";

import { assert, assertDeepEqual, assertEqual, test } from "./harness.ts";

function tmpFile(suffix: string): string {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), "readonly-test-"));
	return path.join(dir, suffix);
}

function writeJson(p: string, value: unknown): void {
	fs.mkdirSync(path.dirname(p), { recursive: true });
	fs.writeFileSync(p, JSON.stringify(value), "utf8");
}

test("loadReadonlySettings: missing files fall back to defaults", () => {
	const globalPath = tmpFile("global.json");
	const projectPath = tmpFile("project.json");
	const loaded = loadReadonlySettings({
		globalPath,
		projectPath,
		defaults: DEFAULT_WHITELIST,
	});
	assertDeepEqual(loaded.whitelist, [...DEFAULT_WHITELIST], "uses defaults");
	assertEqual(loaded.fromConfig, false, "fromConfig=false");
	assertEqual(loaded.emptyConfigured, false, "emptyConfigured=false");
	assertEqual(loaded.warnings.length, 0, "no warnings");
});

test("loadReadonlySettings: malformed json produces warning + defaults", () => {
	const globalPath = tmpFile("global.json");
	fs.mkdirSync(path.dirname(globalPath), { recursive: true });
	fs.writeFileSync(globalPath, "{not valid json", "utf8");
	const projectPath = tmpFile("project.json");
	const loaded = loadReadonlySettings({ globalPath, projectPath, defaults: DEFAULT_WHITELIST });
	assertDeepEqual(loaded.whitelist, [...DEFAULT_WHITELIST], "defaults");
	assertEqual(loaded.fromConfig, false, "fromConfig=false");
	assert(loaded.warnings.some((w) => w.includes("Failed to parse")), "parse warning surfaced");
});

test("loadReadonlySettings: project overrides global", () => {
	const globalPath = tmpFile("global.json");
	const projectPath = tmpFile("project.json");
	writeJson(globalPath, { readOnly: { whitelist: ["read", "grep"] } });
	writeJson(projectPath, { readOnly: { whitelist: ["read"] } });
	const loaded = loadReadonlySettings({ globalPath, projectPath, defaults: DEFAULT_WHITELIST });
	assertDeepEqual(loaded.whitelist, ["read"], "project wins");
	assertEqual(loaded.fromConfig, true, "fromConfig=true");
});

test("loadReadonlySettings: global value used when project absent", () => {
	const globalPath = tmpFile("global.json");
	const projectPath = tmpFile("project.json");
	writeJson(globalPath, { readOnly: { whitelist: ["read", "grep"] } });
	const loaded = loadReadonlySettings({ globalPath, projectPath, defaults: DEFAULT_WHITELIST });
	assertDeepEqual(loaded.whitelist, ["read", "grep"], "global value");
	assertEqual(loaded.fromConfig, true, "fromConfig=true");
});

test("loadReadonlySettings: empty array is honored with warning", () => {
	const globalPath = tmpFile("global.json");
	const projectPath = tmpFile("project.json");
	writeJson(projectPath, { readOnly: { whitelist: [] } });
	const loaded = loadReadonlySettings({ globalPath, projectPath, defaults: DEFAULT_WHITELIST });
	assertDeepEqual(loaded.whitelist, [], "empty whitelist");
	assertEqual(loaded.fromConfig, true, "fromConfig=true");
	assertEqual(loaded.emptyConfigured, true, "emptyConfigured=true");
	assert(loaded.warnings.some((w) => w.includes("empty")), "empty warning emitted");
});

test("loadReadonlySettings: wrong shape -> defaults + warning", () => {
	const globalPath = tmpFile("global.json");
	const projectPath = tmpFile("project.json");
	writeJson(projectPath, { readOnly: { whitelist: "read,grep" } });
	const loaded = loadReadonlySettings({ globalPath, projectPath, defaults: DEFAULT_WHITELIST });
	assertDeepEqual(loaded.whitelist, [...DEFAULT_WHITELIST], "falls back to defaults");
	assertEqual(loaded.fromConfig, false, "fromConfig=false");
	assert(loaded.warnings.some((w) => w.includes("must be an array")), "shape warning surfaced");
});

test("loadReadonlySettings: missing readOnly key falls back to defaults", () => {
	const globalPath = tmpFile("global.json");
	const projectPath = tmpFile("project.json");
	writeJson(projectPath, { otherKey: 42 });
	const loaded = loadReadonlySettings({ globalPath, projectPath, defaults: DEFAULT_WHITELIST });
	assertDeepEqual(loaded.whitelist, [...DEFAULT_WHITELIST], "defaults");
	assertEqual(loaded.fromConfig, false, "fromConfig=false");
});

test("validateWhitelistShape: non-string entries skipped with warnings", () => {
	const v = validateWhitelistShape(["read", 42, null, "grep", "", "  read  "], DEFAULT_WHITELIST);
	assertDeepEqual(v.whitelist, ["read", "grep"], "valid entries kept, dupes after trim deduped");
	assertEqual(v.usedDefaults, false, "did not fall back to defaults");
	assertEqual(v.warnings.length, 3, "three warnings: number, null, empty string");
});

test("validateWhitelistShape: non-array -> defaults + warning", () => {
	const v = validateWhitelistShape({ wrong: "shape" }, DEFAULT_WHITELIST);
	assertDeepEqual(v.whitelist, [...DEFAULT_WHITELIST], "fell back to defaults");
	assertEqual(v.usedDefaults, true, "usedDefaults=true");
	assertEqual(v.warnings.length, 1, "one warning");
});

test("validateWhitelistShape: empty array allowed (caller warns)", () => {
	const v = validateWhitelistShape([], DEFAULT_WHITELIST);
	assertDeepEqual(v.whitelist, [], "empty list passes through");
	assertEqual(v.usedDefaults, false, "did not fall back");
	assertEqual(v.warnings.length, 0, "no warnings from shape validator");
});

test("validateWhitelistShape: non-existent tool names accepted (pre-authorization)", () => {
	const v = validateWhitelistShape(["read", "made_up_tool", "future_tool_*"], DEFAULT_WHITELIST);
	assertDeepEqual(v.whitelist, ["read", "made_up_tool", "future_tool_*"], "all kept");
	assertEqual(v.warnings.length, 0, "no warnings for unknown tools");
});

test("settings: unique tmpdir prevents test interference", () => {
	const a = tmpFile("a.json");
	const b = tmpFile("b.json");
	assert(a !== b, "distinct tmp paths");
	assert(crypto.randomBytes(1).length === 1, "node:crypto available");
});
