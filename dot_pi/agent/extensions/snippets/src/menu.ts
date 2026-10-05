import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth, wrapTextWithAnsi, type KeyId } from "@earendil-works/pi-tui";
import type { Snippet } from "./types.ts";

interface MenuResult {
	confirmed: boolean;
	selected: Set<string>;
}

export async function showSnippetMenu(
	ctx: ExtensionContext,
	snippets: Snippet[],
	selected: ReadonlySet<string>,
): Promise<MenuResult> {
	if (ctx.mode !== "tui" || snippets.length === 0) return { confirmed: false, selected: new Set(selected) };

	const working = new Set([...selected].filter((id) => snippets.some((snippet) => snippet.id === id)));
	const confirmed = await ctx.ui.custom<boolean>((tui, theme, keybindings, done) => {
		let cursor = 0;
		let mode: "list" | "preview" = "list";
		let scroll = 0;

		type SelectionAction = "tui.select.up" | "tui.select.down" | "tui.select.confirm" | "tui.select.cancel";
		const keyMatches = (data: string, action: SelectionAction, fallback: KeyId) =>
			keybindings.matches(data, action) || matchesKey(data, fallback);
		const move = (delta: number) => {
			cursor = (cursor + delta + snippets.length) % snippets.length;
			tui.requestRender();
		};

		return {
			render(width: number): string[] {
				const contentWidth = Math.max(1, width - 2);
				const maxRows = Math.max(4, tui.terminal.rows - 9);
				const title = mode === "list" ? "Prompt snippets" : `Preview: ${snippets[cursor].name}`;
				let rows: string[];
				let help: string;

				if (mode === "list") {
					const allRows = snippets.map((snippet, index) => {
						const pointer = index === cursor ? theme.fg("accent", ">") : " ";
						const marker = working.has(snippet.id) ? theme.fg("success", "[x]") : theme.fg("dim", "[ ]");
						const placement = theme.fg(snippet.placement === "prepend" ? "accent" : "warning", snippet.placement === "prepend" ? "↑" : "↓");
						const description = snippet.description ? theme.fg("dim", ` — ${snippet.description}`) : "";
						return truncateToWidth(`${pointer} ${marker} ${placement} ${theme.bold(snippet.name)}${description}`, contentWidth);
					});
					const start = Math.max(0, Math.min(cursor - maxRows + 1, allRows.length - maxRows));
					rows = allRows.slice(start, start + maxRows);
					help = "↑↓ navigate • Space toggle • Tab preview • Enter apply • Esc cancel";
				} else {
					const snippet = snippets[cursor];
					const metadata = theme.fg("dim", `${snippet.placement} · order ${snippet.order} · ${snippet.scope} · ${snippet.id}`);
					const bodyRows = snippet.body.split("\n").flatMap((line) => wrapTextWithAnsi(line, contentWidth));
					const allRows = [truncateToWidth(metadata, contentWidth), "", ...bodyRows];
					scroll = Math.max(0, Math.min(scroll, Math.max(0, allRows.length - maxRows)));
					rows = allRows.slice(scroll, scroll + maxRows).map((line) => truncateToWidth(line, contentWidth));
					help = "↑↓ scroll • Tab/Esc back";
				}

				const border = theme.fg("accent", "─".repeat(Math.max(1, width)));
				return [
					border,
					truncateToWidth(` ${theme.fg("accent", theme.bold(title))}`, width),
					"",
					...rows.map((row) => ` ${row}`),
					"",
					truncateToWidth(` ${theme.fg("dim", help)}`, width),
					border,
				];
			},
			invalidate() {},
			handleInput(data: string) {
				const up = keyMatches(data, "tui.select.up", Key.up);
				const down = keyMatches(data, "tui.select.down", Key.down);
				const cancel = keyMatches(data, "tui.select.cancel", Key.escape);

				if (mode === "preview") {
					if (up) scroll = Math.max(0, scroll - 1);
					else if (down) scroll++;
					else if (matchesKey(data, Key.tab) || cancel) {
						mode = "list";
						scroll = 0;
					}
					tui.requestRender();
					return;
				}

				if (up) move(-1);
				else if (down) move(1);
				else if (matchesKey(data, Key.space)) {
					const id = snippets[cursor].id;
					working.has(id) ? working.delete(id) : working.add(id);
					tui.requestRender();
				} else if (matchesKey(data, Key.tab)) {
					mode = "preview";
					scroll = 0;
					tui.requestRender();
				} else if (keyMatches(data, "tui.select.confirm", Key.enter)) done(true);
				else if (cancel) done(false);
			},
		};
	});

	return { confirmed: confirmed === true, selected: working };
}
