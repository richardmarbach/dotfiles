/**
 * Tests for the in-place strip helpers used by the context and
 * session_before_compact handlers.
 */

import { stripFromEntryArray, stripFromMessageArray } from "../src/strip.ts";

import { assertDeepEqual, test } from "./harness.ts";

test("stripFromMessageArray: removes our customType entries (role-based message shape)", () => {
	const messages = [
		{ role: "user", content: "hello" },
		{ role: "custom", customType: "readonly-rejection", content: "[readonly] ..." },
		{ role: "assistant", content: "hi" },
		{ role: "custom", customType: "readonly-list", content: "list" },
		{ role: "custom", customType: "other-extension", content: "keep" },
		{ role: "custom", customType: "readonly-degraded", content: "warn" },
	];
	stripFromMessageArray(messages);
	assertDeepEqual(
		messages,
		[
			{ role: "user", content: "hello" },
			{ role: "assistant", content: "hi" },
			{ role: "custom", customType: "other-extension", content: "keep" },
		],
		"only readonly-* customTypes are stripped",
	);
});

test("stripFromMessageArray: empty / non-array inputs are no-ops", () => {
	const empty: unknown[] = [];
	stripFromMessageArray(empty);
	assertDeepEqual(empty, [], "empty stays empty");
	stripFromMessageArray(undefined as unknown as unknown[]);
	stripFromMessageArray(null as unknown as unknown[]);
});

test("stripFromEntryArray: removes custom_message entries (pi.sendMessage shape)", () => {
	// This is the regression that motivated #2 in the review: pi.sendMessage
	// writes type: "custom_message", not type: "custom".
	const entries = [
		{ id: "1", type: "message", role: "user" },
		{
			id: "2",
			type: "custom_message",
			customType: "readonly-rejection",
			content: "[readonly] ...",
			display: true,
		},
		{
			id: "3",
			type: "custom_message",
			customType: "readonly-list",
			content: "Read-only whitelist (3):\n...",
			display: true,
		},
		{
			id: "4",
			type: "custom_message",
			customType: "other-extension",
			content: "keep me",
			display: true,
		},
		{ id: "5", type: "custom", customType: "readonly-degraded", data: {} },
		{ id: "6", type: "message", role: "assistant" },
	];
	stripFromEntryArray(entries);
	assertDeepEqual(
		entries.map((e) => e.id),
		["1", "4", "6"],
		"strips both custom_message (rejection, list) and legacy custom (degraded), keeps unrelated entries",
	);
});

test("stripFromEntryArray: leaves non-custom session entries alone", () => {
	const entries = [
		{ id: "1", type: "message" },
		{ id: "2", type: "compaction" },
		{ id: "3", type: "label" },
		{ id: "4", type: "session_info" },
	];
	stripFromEntryArray(entries);
	assertDeepEqual(
		entries.map((e) => e.id),
		["1", "2", "3", "4"],
		"unrelated entry types untouched",
	);
});

test("stripFromEntryArray: empty / non-array inputs are no-ops", () => {
	const empty: unknown[] = [];
	stripFromEntryArray(empty);
	assertDeepEqual(empty, [], "empty stays empty");
	stripFromEntryArray(undefined as unknown as unknown[]);
	stripFromEntryArray(null as unknown as unknown[]);
});
