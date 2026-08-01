/**
 * Whitelist intersection + prefix-matching tests.
 */

import { intersectActiveTools, matchesWhitelist } from "../src/state.ts";

import { assertDeepEqual, assertEqual, test } from "./harness.ts";

test("matchesWhitelist: exact match", () => {
	assertEqual(matchesWhitelist("read", ["read", "grep"]), true, "exact hit");
	assertEqual(matchesWhitelist("write", ["read", "grep"]), false, "miss");
});

test("matchesWhitelist: prefix match via trailing star", () => {
	const wl = ["coms_*"];
	assertEqual(matchesWhitelist("coms_send", wl), true, "coms_send");
	assertEqual(matchesWhitelist("coms_list", wl), true, "coms_list");
	assertEqual(matchesWhitelist("coms_", wl), true, "boundary: just prefix");
	assertEqual(matchesWhitelist("comsanother", wl), false, "no_ separator");
	assertEqual(matchesWhitelist("read", wl), false, "unrelated");
});

test("matchesWhitelist: literal star not present in real names is still safe", () => {
	const wl = ["literal_only"];
	assertEqual(matchesWhitelist("literal_only", wl), true, "exact only");
	assertEqual(matchesWhitelist("literal_only_extra", wl), false, "no prefix without star");
});

test("matchesWhitelist: empty whitelist matches nothing", () => {
	assertEqual(matchesWhitelist("read", []), false, "empty rejects");
});

test("matchesWhitelist: mixed exact + prefix", () => {
	const wl = ["read", "coms_*", "grep"];
	assertEqual(matchesWhitelist("read", wl), true, "exact");
	assertEqual(matchesWhitelist("coms_send", wl), true, "prefix");
	assertEqual(matchesWhitelist("grep", wl), true, "exact #2");
	assertEqual(matchesWhitelist("bash", wl), false, "miss");
});

test("intersectActiveTools: preserves active order", () => {
	const active = ["read", "bash", "grep", "coms_send", "edit"];
	const wl = ["grep", "read", "coms_*"];
	assertDeepEqual(
		intersectActiveTools(active, wl),
		["read", "grep", "coms_send"],
		"order matches `active`, not `wl`",
	);
});

test("intersectActiveTools: returns empty when no overlap", () => {
	assertDeepEqual(intersectActiveTools(["bash", "edit"], ["read"]), [], "no overlap");
});

test("intersectActiveTools: empty active list yields empty result", () => {
	assertDeepEqual(intersectActiveTools([], ["read"]), [], "empty active");
});

test("intersectActiveTools: prefix entries match dynamically registered tools", () => {
	// Simulates a tool registered after session_start that wasn't on the whitelist verbatim.
	const active = ["read", "coms_send", "coms_brand_new"];
	const wl = ["read", "coms_*"];
	assertDeepEqual(
		intersectActiveTools(active, wl),
		["read", "coms_send", "coms_brand_new"],
		"new tool covered by prefix",
	);
});

test("intersectActiveTools: unknown whitelist entries are noops (no false matches)", () => {
	const active = ["read", "grep"];
	const wl = ["read", "future_tool", "future_*"];
	assertDeepEqual(intersectActiveTools(active, wl), ["read"], "no false positives");
});
