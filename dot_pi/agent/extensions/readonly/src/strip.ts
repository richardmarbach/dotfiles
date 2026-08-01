/**
 * In-place filtering of session entries / messages produced by this
 * extension via `pi.sendMessage(...)`.
 *
 * Used by the `context` and `session_before_compact` handlers to keep
 * our own audit/info banners out of the LLM's view. Pure functions with
 * no pi-side imports so they can be unit-tested in isolation.
 */

const READONLY_CUSTOM_TYPES: ReadonlySet<string> = new Set([
	"readonly-rejection",
	"readonly-list",
	"readonly-degraded",
]);

interface CustomMessageLike {
	type?: string;
	customType?: string;
}

/**
 * Mutate `arr` in place, removing any entries whose `customType` is one
 * of our banner types. Used for message arrays (`AgentMessage[]`) where
 * the discriminant is `role: "custom"` and a `customType` field exists.
 */
export function stripFromMessageArray(arr: unknown[]): void {
	if (!Array.isArray(arr)) return;
	for (let i = arr.length - 1; i >= 0; i--) {
		const entry = arr[i] as CustomMessageLike;
		if (READONLY_CUSTOM_TYPES.has(entry?.customType ?? "")) {
			arr.splice(i, 1);
		}
	}
}

/**
 * Mutate `arr` in place, removing any session entries we wrote.
 *
 * `pi.sendMessage(...)` writes entries with `type: "custom_message"`
 * (see `CustomMessageEntry` in session-manager.d.ts). The older
 * `type: "custom"` discriminant is for non-LLM extension state, which
 * we don't use, but we accept both shapes for robustness.
 */
export function stripFromEntryArray(arr: unknown[]): void {
	if (!Array.isArray(arr)) return;
	for (let i = arr.length - 1; i >= 0; i--) {
		const entry = arr[i] as CustomMessageLike;
		const t = entry?.type;
		if (t !== "custom" && t !== "custom_message") continue;
		if (READONLY_CUSTOM_TYPES.has(entry?.customType ?? "")) {
			arr.splice(i, 1);
		}
	}
}
