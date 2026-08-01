/**
 * Source-restriction gate + command-parser tests.
 */

import {
	detectMode,
	isAllowedInputSource,
	isAllowedSource,
	isInteractiveMode,
	READONLY_COMMAND_RE,
} from "../src/auth.ts";
import { parseSubcommand } from "../src/commands.ts";

import { assert, assertEqual, test } from "./harness.ts";

test("detectMode: defaults to interactive", () => {
	assertEqual(detectMode(["node", "pi"]), "interactive", "no mode flags");
});

test("detectMode: --print and -p map to print", () => {
	assertEqual(detectMode(["node", "pi", "--print"]), "print", "--print");
	assertEqual(detectMode(["node", "pi", "-p"]), "print", "-p");
});

test("detectMode: --mode rpc / json", () => {
	assertEqual(detectMode(["node", "pi", "--mode", "rpc"]), "rpc", "rpc");
	assertEqual(detectMode(["node", "pi", "--mode", "json"]), "json", "json");
});

test("detectMode: unknown mode value stays interactive", () => {
	assertEqual(detectMode(["node", "pi", "--mode", "weird"]), "interactive", "fallback");
});

test("isInteractiveMode: only true for interactive", () => {
	assertEqual(isInteractiveMode("interactive"), true, "interactive");
	assertEqual(isInteractiveMode("rpc"), false, "rpc");
	assertEqual(isInteractiveMode("json"), false, "json");
	assertEqual(isInteractiveMode("print"), false, "print");
});

test("isAllowedInputSource: only interactive passes", () => {
	assertEqual(isAllowedInputSource("interactive"), true, "interactive");
	assertEqual(isAllowedInputSource("rpc"), false, "rpc");
	assertEqual(isAllowedInputSource("extension"), false, "extension");
	assertEqual(isAllowedInputSource(undefined), false, "undefined");
});

test("isAllowedSource(command, source): matches §23 checklist signature", () => {
	for (const cmd of ["on", "off", "allow read", "deny bash", "list", "status", "reset"]) {
		assertEqual(isAllowedSource(cmd, "interactive"), true, `${cmd}: interactive allowed`);
		assertEqual(isAllowedSource(cmd, "rpc"), false, `${cmd}: rpc denied`);
		assertEqual(isAllowedSource(cmd, "extension"), false, `${cmd}: extension denied`);
		assertEqual(isAllowedSource(cmd, undefined), false, `${cmd}: undefined denied`);
	}
});

test("READONLY_COMMAND_RE: matches /readonly forms", () => {
	assert(READONLY_COMMAND_RE.test("/readonly"), "bare");
	assert(READONLY_COMMAND_RE.test("/readonly on"), "on");
	assert(READONLY_COMMAND_RE.test("/readonly off"), "off");
	assert(READONLY_COMMAND_RE.test("/readonly allow read"), "allow ...");
	assert(READONLY_COMMAND_RE.test("  /readonly  list"), "leading whitespace");
	assert(READONLY_COMMAND_RE.test("/Readonly status"), "case insensitive");
});

test("READONLY_COMMAND_RE: does not match other commands", () => {
	assert(!READONLY_COMMAND_RE.test("/readonly-helper"), "no hyphenated false-positive");
	assert(!READONLY_COMMAND_RE.test("/read"), "different command");
	assert(!READONLY_COMMAND_RE.test("readonly on"), "no leading slash");
	assert(!READONLY_COMMAND_RE.test("/foo readonly"), "readonly not at start");
});

test("parseSubcommand: bare arg -> enable", () => {
	assertEqual(parseSubcommand("").kind, "enable", "bare enables");
	assertEqual(parseSubcommand("   ").kind, "enable", "whitespace-only enables");
});

test("parseSubcommand: on/off mapped", () => {
	assertEqual(parseSubcommand("on").kind, "enable", "on");
	assertEqual(parseSubcommand("off").kind, "disable", "off");
	assertEqual(parseSubcommand("OFF").kind, "disable", "case-insensitive");
});

test("parseSubcommand: allow / deny with target", () => {
	const a = parseSubcommand("allow grep");
	assertEqual(a.kind, "allow", "allow recognized");
	if (a.kind === "allow") assertEqual(a.tool, "grep", "tool captured");
	const d = parseSubcommand("deny  bash");
	assertEqual(d.kind, "deny", "deny recognized");
	if (d.kind === "deny") assertEqual(d.tool, "bash", "tool captured");
});

test("parseSubcommand: allow / deny without target reports missing", () => {
	const a = parseSubcommand("allow");
	assertEqual(a.kind, "missing-target", "missing reported");
	if (a.kind === "missing-target") assertEqual(a.sub, "allow", "sub recorded");
	const d = parseSubcommand("deny    ");
	assertEqual(d.kind, "missing-target", "missing reported (whitespace tail)");
});

test("parseSubcommand: list / status / reset", () => {
	assertEqual(parseSubcommand("list").kind, "list", "list");
	assertEqual(parseSubcommand("status").kind, "status", "status");
	assertEqual(parseSubcommand("reset").kind, "reset", "reset");
});

test("parseSubcommand: unknown subcommand reported", () => {
	const u = parseSubcommand("ralph");
	assertEqual(u.kind, "unknown", "unknown reported");
	if (u.kind === "unknown") assertEqual(u.raw, "ralph", "raw captured");
});
