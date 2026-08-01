/**
 * State machine + transition tests.
 */

import { allow, createState, deny, disable, enable, reset } from "../src/state.ts";

import { assertDeepEqual, assertEqual, test } from "./harness.ts";

test("enable: idempotent when already on", () => {
	const s = createState(["read"], true);
	const r1 = enable(s);
	assertEqual(r1.changed, false, "no change");
	assertEqual(s.enabled, true, "still on");
});

test("enable: transitions when off", () => {
	const s = createState(["read"], false);
	const r = enable(s);
	assertEqual(r.changed, true, "transition recorded");
	assertEqual(s.enabled, true, "now on");
});

test("disable: idempotent when already off", () => {
	const s = createState(["read"], false);
	const r = disable(s);
	assertEqual(r.changed, false, "no change");
	assertEqual(s.enabled, false, "still off");
});

test("disable: transitions when on", () => {
	const s = createState(["read"], true);
	const r = disable(s);
	assertEqual(r.changed, true, "transition recorded");
	assertEqual(s.enabled, false, "now off");
});

test("allow: adds new entry", () => {
	const s = createState(["read"], true);
	const r = allow(s, "grep");
	assertEqual(r.changed, true, "added");
	assertDeepEqual(s.whitelist, ["read", "grep"], "appended");
});

test("allow: no-op when already present", () => {
	const s = createState(["read", "grep"], true);
	const r = allow(s, "grep");
	assertEqual(r.changed, false, "no-op");
	assertDeepEqual(s.whitelist, ["read", "grep"], "unchanged");
});

test("allow: pre-authorizes non-existent tools", () => {
	const s = createState(["read"], true);
	allow(s, "future_tool");
	allow(s, "future_*");
	assertDeepEqual(s.whitelist, ["read", "future_tool", "future_*"], "added regardless of existence");
});

test("allow: trims and rejects empty", () => {
	const s = createState(["read"], true);
	const r1 = allow(s, "  ");
	assertEqual(r1.changed, false, "blank rejected");
	const r2 = allow(s, "  grep  ");
	assertEqual(r2.changed, true, "trimmed and added");
	assertDeepEqual(s.whitelist, ["read", "grep"], "trimmed");
});

test("deny: removes existing entry", () => {
	const s = createState(["read", "grep"], true);
	const r = deny(s, "grep");
	assertEqual(r.changed, true, "removed");
	assertDeepEqual(s.whitelist, ["read"], "shrunk");
});

test("deny: no-op when not present", () => {
	const s = createState(["read"], true);
	const r = deny(s, "grep");
	assertEqual(r.changed, false, "no-op");
	assertDeepEqual(s.whitelist, ["read"], "unchanged");
});

test("deny: built-in critical tool removable (no pinned tools)", () => {
	const s = createState(["read", "grep"], true);
	const r = deny(s, "read");
	assertEqual(r.changed, true, "allowed");
	assertDeepEqual(s.whitelist, ["grep"], "removed");
});

test("reset: restores configured whitelist after mutations", () => {
	const s = createState(["read", "grep"], true);
	allow(s, "subagent");
	deny(s, "read");
	assertDeepEqual(s.whitelist, ["grep", "subagent"], "mutated");
	const r = reset(s);
	assertEqual(r.changed, true, "reset changed");
	assertDeepEqual(s.whitelist, ["read", "grep"], "restored");
});

test("reset: idempotent when already at baseline", () => {
	const s = createState(["read", "grep"], true);
	const r = reset(s);
	assertEqual(r.changed, false, "no change");
	assertDeepEqual(s.whitelist, ["read", "grep"], "unchanged");
});

test("createState: configuredWhitelist preserved across allow/deny", () => {
	const s = createState(["read"], false);
	allow(s, "grep");
	deny(s, "read");
	assertDeepEqual(s.whitelist, ["grep"], "active mutated");
	assertDeepEqual([...s.configuredWhitelist], ["read"], "configured preserved");
});
