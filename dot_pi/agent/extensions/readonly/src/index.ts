/**
 * Read-only mode extension.
 *
 * Restricts the LLM's visible toolset to a configurable whitelist. Toggled
 * via `--readonly` CLI flag and `/readonly` slash command. The LLM is not
 * told about the mode; the user sees a window-title prefix and a footer
 * indicator.
 *
 * See README.md for the full specification.
 */

import type {
	ExtensionAPI,
	ExtensionCommandContext,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

import { DEFAULT_WHITELIST } from "./defaults.ts";
import {
	allow,
	createState,
	deny,
	disable,
	enable,
	intersectActiveTools,
	matchesWhitelist,
	type ReadonlyState,
	reset,
} from "./state.ts";
import { loadReadonlySettings } from "./settings.ts";
import {
	detectMode,
	isAllowedInputSource,
	isInteractiveMode,
	READONLY_COMMAND_RE,
	type RuntimeMode,
} from "./auth.ts";
import { parseSubcommand, SUBCOMMAND_NAMES } from "./commands.ts";
import { stripFromEntryArray, stripFromMessageArray } from "./strip.ts";
import { applyFooter, applyTitle, clearUi } from "./ui.ts";

const FLAG = "readonly";
const COMMAND = "readonly";

const MSG_LIST = "readonly-list";
const MSG_REJECTION = "readonly-rejection";
const MSG_DEGRADED = "readonly-degraded";

const CONFIRM_TITLE = "Disable read-only mode?";
const CONFIRM_BODY =
	"Tools that can modify files and run shell commands will become available to the agent. Continue?";

const BACKSTOP_REASON = (name: string) => `Tool '${name}' is not currently available`;

interface CustomMessageEntryLike {
	customType?: string;
}

export default function readonlyExtension(pi: ExtensionAPI): void {
	const mode: RuntimeMode = detectMode();
	const interactiveMode = isInteractiveMode(mode);

	let state: ReadonlyState = createState(DEFAULT_WHITELIST, false);
	let loadWarnings: string[] = [];
	let configEmpty = false;
	let degraded = false;

	pi.registerFlag(FLAG, {
		description: "Start in read-only mode (restrict tools to a whitelist)",
		type: "boolean",
		default: false,
	});

	// §22 colors for our custom messages. `readonly-list` gets the default
	// theme per spec, so we don't register a renderer for it.
	pi.registerMessageRenderer(MSG_REJECTION, (msg, _opts, theme) =>
		new Text(theme.fg("warning", String(msg.content ?? "")), 0, 0),
	);
	pi.registerMessageRenderer(MSG_DEGRADED, (msg, _opts, theme) =>
		new Text(theme.fg("error", String(msg.content ?? "")), 0, 0),
	);

	function loadConfig(initiallyEnabled: boolean): void {
		const loaded = loadReadonlySettings({
			defaults: DEFAULT_WHITELIST,
		});
		loadWarnings = loaded.warnings;
		configEmpty = loaded.emptyConfigured;
		state = createState(loaded.whitelist, initiallyEnabled);
	}

	function applyToolsNarrowing(ctx: ExtensionContext): void {
		if (!state.enabled) return;
		try {
			const currentActive = pi.getActiveTools();
			const next = intersectActiveTools(currentActive, state.whitelist);
			pi.setActiveTools(next);
			if (degraded) {
				degraded = false;
			}
		} catch (err) {
			if (!degraded) {
				degraded = true;
				renderDegradedBanner(pi, ctx, err as Error);
			}
		}
	}

	function restoreAllTools(): void {
		try {
			const all = safeGetAllTools(pi).map((t) => t.name);
			pi.setActiveTools(all);
		} catch (err) {
			try {
				console.error(
					`[readonly] failed to restore active tools on disable: ${(err as Error).message}`,
				);
			} catch {
				// non-fatal
			}
		}
	}

	function showWarnings(ctx: ExtensionContext): void {
		if (!ctx.hasUI || loadWarnings.length === 0) return;
		for (const w of loadWarnings) {
			ctx.ui.notify(`[readonly] ${w}`, "warning");
		}
		loadWarnings = [];
	}

	function notifyEnabled(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		const n = state.whitelist.length;
		ctx.ui.notify(`Read-only mode enabled. ${n} tool${n === 1 ? "" : "s"} allowed.`, "info");
	}

	function notifyDisabled(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		ctx.ui.notify("Read-only mode disabled.", "info");
	}

	function sendListMessage(): void {
		const lines = [
			`Read-only whitelist (${state.whitelist.length}):`,
			...state.whitelist.map((t) => `  ${t}`),
		];
		pi.sendMessage({
			customType: MSG_LIST,
			content: lines.join("\n"),
			display: true,
			details: { whitelist: [...state.whitelist] },
		});
	}

	function sendRejectionMessage(sub: string, source: string): void {
		const text = `[readonly] /readonly ${sub} rejected - interactive input required (source=${source})`;
		pi.sendMessage({
			customType: MSG_REJECTION,
			content: text,
			display: true,
			details: { sub, source },
		});
		try {
			console.error(text);
		} catch {
			// console may be redirected; non-fatal.
		}
	}

	function handleStatus(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		const n = state.whitelist.length;
		const onOff = state.enabled ? "ON" : "OFF";
		ctx.ui.notify(`read-only: ${onOff} · ${n} tool${n === 1 ? "" : "s"} allowed`, "info");
	}

	function gateCommand(ctx: ExtensionContext, sub: string): boolean {
		if (!ctx.hasUI) {
			console.error(
				`[readonly] /readonly ${sub} rejected - not available in print/json mode (mode=${mode}).`,
			);
			return false;
		}
		if (!interactiveMode) {
			sendRejectionMessage(sub, mode);
			return false;
		}
		return true;
	}

	pi.registerCommand(COMMAND, {
		description: "Read-only mode: restrict the agent to a tool whitelist",
		getArgumentCompletions: (prefix) => {
			const trimmed = prefix.trimStart();
			const parts = trimmed.split(/\s+/);
			if (parts.length <= 1 && !trimmed.endsWith(" ")) {
				const head = parts[0] ?? "";
				return SUBCOMMAND_NAMES.filter((n) => n.startsWith(head)).map((value) => ({ value, label: value }));
			}
			const sub = parts[0].toLowerCase();
			if (sub === "allow" || sub === "deny") {
				const argPrefix = parts.slice(1).join(" ");
				const allTools = safeGetAllTools(pi).map((t) => t.name);
				return allTools
					.filter((name) => name.startsWith(argPrefix))
					.map((value) => ({ value, label: value }));
			}
			return null;
		},
		handler: async (args, ctx) => {
			const parsed = parseSubcommand(args);

			if (!gateCommand(ctx, parsed.kind)) return;

			switch (parsed.kind) {
				case "enable":
					await handleEnable(ctx);
					return;
				case "disable":
					await handleDisable(ctx);
					return;
				case "allow":
					handleAllow(ctx, parsed.tool);
					return;
				case "deny":
					handleDeny(ctx, parsed.tool);
					return;
				case "list":
					sendListMessage();
					return;
				case "status":
					handleStatus(ctx);
					return;
				case "reset":
					await handleReset(ctx);
					return;
				case "missing-target":
					if (ctx.hasUI) {
						ctx.ui.notify(`/readonly ${parsed.sub} requires a tool name.`, "warning");
					}
					return;
				case "unknown":
					if (ctx.hasUI) {
						ctx.ui.notify(
							`Unknown /readonly subcommand: ${parsed.raw}. Try: ${SUBCOMMAND_NAMES.join(", ")}.`,
							"warning",
						);
					}
					return;
			}
		},
	});

	async function handleEnable(ctx: ExtensionCommandContext): Promise<void> {
		const result = enable(state);
		if (!result.changed) return; // §9: /readonly while already on is a no-op.
		// §7: defer mid-stream tool-set changes until the agent loop is idle
		// so we don't yank tools out from under a streaming turn.
		await ctx.waitForIdle();
		applyToolsNarrowing(ctx);
		applyFooter(ctx, state.enabled);
		applyTitle(pi, ctx, state.enabled);
		notifyEnabled(ctx);
	}

	async function handleDisable(ctx: ExtensionCommandContext): Promise<void> {
		if (!state.enabled) return; // §9: /readonly off while already off is a no-op.
		const ok = await ctx.ui.confirm(CONFIRM_TITLE, CONFIRM_BODY);
		if (!ok) return;
		const result = disable(state);
		if (!result.changed) return; // defensive; confirm path implies on -> off.
		restoreAllTools(); // §6/§7: real transition restores the active tool set.
		applyFooter(ctx, state.enabled);
		// Clear our `[RO] ` prefix once on the transition, then relinquish
		// the title back to pi. We never set it again while off.
		applyTitle(pi, ctx, state.enabled);
		notifyDisabled(ctx);
	}

	function handleAllow(ctx: ExtensionContext, tool: string): void {
		const result = allow(state, tool);
		if (result.changed) applyToolsNarrowing(ctx); // §13: surface change immediately.
	}

	function handleDeny(ctx: ExtensionContext, tool: string): void {
		const result = deny(state, tool);
		if (result.changed) applyToolsNarrowing(ctx); // §13: surface change immediately.
	}

	async function handleReset(ctx: ExtensionCommandContext): Promise<void> {
		reset(state);
		await ctx.waitForIdle();
		applyToolsNarrowing(ctx);
	}

	pi.on("session_start", async (event, ctx) => {
		const flagOn = pi.getFlag(FLAG) === true;

		if (event.reason === "reload") {
			// /reload: preserve on/off state, re-read settings, drop ephemeral whitelist mutations (§14).
			loadConfig(state.enabled);
		} else {
			// startup / new / resume / fork: re-init from CLI flag (§6).
			loadConfig(flagOn);
		}

		showWarnings(ctx);
		applyToolsNarrowing(ctx);
		applyFooter(ctx, state.enabled);
		// Only own the title while read-only is on. When off, pi (or another
		// extension) keeps whatever title was already set.
		if (state.enabled) applyTitle(pi, ctx, true);
		if (configEmpty && state.enabled && ctx.hasUI) {
			ctx.ui.notify(
				"[readonly] active whitelist is empty - agent will have no tools.",
				"warning",
			);
		}
	});

	pi.on("turn_start", async (_event, ctx) => {
		applyToolsNarrowing(ctx);
	});

	pi.on("input", async (event) => {
		if (!READONLY_COMMAND_RE.test(event.text)) return;
		// If the input event sees a /readonly text, it means it came in via a
		// path that skipped the extension command dispatcher (e.g.
		// pi.sendUserMessage). That is always non-interactive.
		if (isAllowedInputSource(event.source)) return;
		sendRejectionMessage(event.text.trim().slice(1) || "(empty)", event.source ?? "unknown");
		return { action: "handled" };
	});

	pi.on("tool_call", async (event) => {
		if (!state.enabled) return;
		if (matchesWhitelist(event.toolName, state.whitelist)) return;
		try {
			console.error(
				`[readonly] tool_call backstop blocked '${event.toolName}' (not on whitelist)`,
			);
		} catch {
			// non-fatal
		}
		return { block: true, reason: BACKSTOP_REASON(event.toolName) };
	});

	pi.on("context", async (event) => {
		// Filter our own audit/info banners out of the LLM's context window.
		const filtered = event.messages.filter((m) => {
			const msg = m as CustomMessageEntryLike;
			if (msg.customType === MSG_REJECTION) return false;
			if (msg.customType === MSG_LIST) return false;
			if (msg.customType === MSG_DEGRADED) return false;
			return true;
		});
		if (filtered.length === event.messages.length) return;
		return { messages: filtered };
	});

	pi.on("session_before_compact", async (event) => {
		// Best-effort: pi's `session_before_compact` contract is to return
		// `{ cancel }` or `{ compaction }`; in-place mutation of
		// `event.preparation` is undocumented and relies on pi passing the
		// preparation arrays by reference into its default summariser. We use
		// it because the alternative is re-implementing summarisation just to
		// drop a banner. Verified manually by running `/readonly list` then
		// `/compact` and inspecting the resulting summary.
		stripFromMessageArray(event.preparation.messagesToSummarize);
		stripFromMessageArray(event.preparation.turnPrefixMessages);
		// branchEntries is a SessionEntry[] list - drop our custom_message entries.
		stripFromEntryArray(event.branchEntries);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		clearUi(ctx);
	});
}

function safeGetAllTools(pi: ExtensionAPI): { name: string }[] {
	try {
		return pi.getAllTools();
	} catch {
		return [];
	}
}

function renderDegradedBanner(pi: ExtensionAPI, ctx: ExtensionContext, err: Error): void {
	const text = "⚠ Read-only enforcement degraded: tool visibility unavailable. Tool-call backstop active.";
	pi.sendMessage({
		customType: MSG_DEGRADED,
		content: text,
		display: true,
		details: { error: err.message },
	});
	if (ctx.hasUI) {
		ctx.ui.notify(text, "error");
	}
	try {
		console.error(`[readonly] setActiveTools failed: ${err.message}`);
	} catch {
		// non-fatal
	}
}


