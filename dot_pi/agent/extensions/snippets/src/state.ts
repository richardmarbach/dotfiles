import { applySnippets } from "./loader.ts";
import type { Snippet } from "./types.ts";

export interface SnippetState {
	snippets: Snippet[];
	selected: ReadonlySet<string>;
}

export interface ConsumeResult {
	state: SnippetState;
	text: string;
	transformed: boolean;
}

export function consumeSelection(state: SnippetState, text: string, source: string): ConsumeResult {
	if (source === "extension" || text.startsWith("/")) {
		return { state, text, transformed: false };
	}

	const active = state.snippets.filter((snippet) => state.selected.has(snippet.id));
	return {
		state: { snippets: state.snippets, selected: new Set() },
		text: active.length > 0 ? applySnippets(text, active) : text,
		transformed: active.length > 0,
	};
}
