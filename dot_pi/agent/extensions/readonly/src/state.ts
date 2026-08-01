/**
 * Pure state machine + whitelist matching helpers for read-only mode.
 *
 * Holds no I/O and no pi APIs - safe to unit test in isolation.
 */

export interface ReadonlyState {
	enabled: boolean;
	/** Active whitelist - mutated by /readonly allow|deny, reset by /readonly reset. */
	whitelist: string[];
	/** Frozen baseline used by /readonly reset and /reload. Sourced from settings.json or DEFAULT_WHITELIST. */
	readonly configuredWhitelist: readonly string[];
}

export interface TransitionResult {
	changed: boolean;
}

export function createState(configuredWhitelist: readonly string[], initiallyEnabled: boolean): ReadonlyState {
	return {
		enabled: initiallyEnabled,
		whitelist: [...configuredWhitelist],
		configuredWhitelist,
	};
}

export function enable(state: ReadonlyState): TransitionResult {
	if (state.enabled) return { changed: false };
	state.enabled = true;
	return { changed: true };
}

export function disable(state: ReadonlyState): TransitionResult {
	if (!state.enabled) return { changed: false };
	state.enabled = false;
	return { changed: true };
}

export function allow(state: ReadonlyState, tool: string): TransitionResult {
	const t = tool.trim();
	if (!t) return { changed: false };
	if (state.whitelist.includes(t)) return { changed: false };
	state.whitelist.push(t);
	return { changed: true };
}

export function deny(state: ReadonlyState, tool: string): TransitionResult {
	const t = tool.trim();
	if (!t) return { changed: false };
	const i = state.whitelist.indexOf(t);
	if (i === -1) return { changed: false };
	state.whitelist.splice(i, 1);
	return { changed: true };
}

export function reset(state: ReadonlyState): TransitionResult {
	const next = [...state.configuredWhitelist];
	const changed = !sameSet(state.whitelist, next);
	state.whitelist = next;
	return { changed };
}

/**
 * Does `toolName` match any entry on `whitelist`?
 *
 * Entries with a trailing `*` are treated as prefix matches: `"coms_*"`
 * matches `"coms_send"`, `"coms_list"`. Everything else is exact match.
 *
 * No general globs (no mid-string `*`, no character classes).
 */
export function matchesWhitelist(toolName: string, whitelist: readonly string[]): boolean {
	for (const entry of whitelist) {
		if (entry.endsWith("*")) {
			const prefix = entry.slice(0, -1);
			if (toolName.startsWith(prefix)) return true;
		} else if (entry === toolName) {
			return true;
		}
	}
	return false;
}

/**
 * Compute the intersection of `currentActive` and `whitelist`, preserving
 * `currentActive`'s order.
 *
 * Used at turn_start: we narrow the already-active set further rather than
 * overwriting it, so other extensions' restrictions are preserved.
 */
export function intersectActiveTools(currentActive: readonly string[], whitelist: readonly string[]): string[] {
	return currentActive.filter((name) => matchesWhitelist(name, whitelist));
}

function sameSet(a: readonly string[], b: readonly string[]): boolean {
	if (a.length !== b.length) return false;
	const setA = new Set(a);
	for (const x of b) {
		if (!setA.has(x)) return false;
	}
	return true;
}
