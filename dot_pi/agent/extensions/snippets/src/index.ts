import { join } from "node:path";
import {
	CONFIG_DIR_NAME,
	getAgentDir,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { loadSnippets } from "./loader.ts";
import { showSnippetMenu } from "./menu.ts";
import { consumeSelection } from "./state.ts";
import type { Snippet, SnippetDirectory } from "./types.ts";

const WIDGET_ID = "prompt-snippets";

export default function snippetsExtension(pi: ExtensionAPI) {
	let snippets: Snippet[] = [];
	let selected = new Set<string>();

	function directories(ctx: ExtensionContext): SnippetDirectory[] {
		const result: SnippetDirectory[] = [{ path: join(getAgentDir(), "snippets"), scope: "global" }];
		if (ctx.isProjectTrusted()) {
			result.push({ path: join(ctx.cwd, CONFIG_DIR_NAME, "snippets"), scope: "project" });
		}
		return result;
	}

	function refresh(ctx: ExtensionContext) {
		snippets = loadSnippets(directories(ctx));
		selected = new Set([...selected].filter((id) => snippets.some((snippet) => snippet.id === id)));
	}

	function updateWidget(ctx: ExtensionContext) {
		if (ctx.mode !== "tui") return;
		const active = snippets.filter((snippet) => selected.has(snippet.id));
		if (active.length === 0) {
			ctx.ui.setWidget(WIDGET_ID, undefined);
			return;
		}

		ctx.ui.setWidget(WIDGET_ID, (_tui, theme) => ({
			invalidate() {},
			render() {
				const prepended = active.filter((snippet) => snippet.placement === "prepend").map((snippet) => snippet.name);
				const appended = active.filter((snippet) => snippet.placement === "append").map((snippet) => snippet.name);
				return [
					...(prepended.length ? [theme.fg("accent", `↑ ${prepended.join(" · ")}`)] : []),
					...(appended.length ? [theme.fg("warning", `↓ ${appended.join(" · ")}`)] : []),
				];
			},
		}));
	}

	async function openMenu(ctx: ExtensionContext) {
		if (ctx.mode !== "tui") {
			ctx.ui.notify("The snippet picker requires TUI mode", "warning");
			return;
		}

		refresh(ctx);
		if (snippets.length === 0) {
			ctx.ui.notify(`No snippets found in ${join(getAgentDir(), "snippets")}`, "warning");
			return;
		}

		const result = await showSnippetMenu(ctx, snippets, selected);
		if (result.confirmed) selected = result.selected;
		updateWidget(ctx);
	}

	pi.registerCommand("snippets", {
		description: "Choose prompt snippets for the next message",
		handler: async (args, ctx) => {
			if (args.trim() === "clear") {
				selected.clear();
				updateWidget(ctx);
				return;
			}
			await openMenu(ctx);
		},
	});

	pi.registerShortcut("ctrl+\\", {
		description: "Choose prompt snippets for the next message",
		handler: openMenu,
	});

	pi.on("session_start", (_event, ctx) => {
		selected.clear();
		refresh(ctx);
		updateWidget(ctx);
	});

	pi.on("session_shutdown", (_event, ctx) => {
		selected.clear();
		if (ctx.mode === "tui") ctx.ui.setWidget(WIDGET_ID, undefined);
	});

	pi.on("input", (event, ctx) => {
		if (selected.size === 0 || event.source === "extension" || event.text.startsWith("/")) return;
		refresh(ctx);
		const result = consumeSelection({ snippets, selected }, event.text, event.source);
		selected = new Set(result.state.selected);
		updateWidget(ctx);
		if (!result.transformed) return;
		return { action: "transform", text: result.text };
	});
}
