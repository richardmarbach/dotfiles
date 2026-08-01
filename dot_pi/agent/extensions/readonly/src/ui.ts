/**
 * UI surface for read-only mode: window title prefix and footer status.
 *
 * Title:  `[RO] pi - <basename(cwd)>` while on; we relinquish the title
 *         while off, only touching it once during the on→off transition
 *         to clear our prefix.
 * Footer: yellow `read-only` while on, cleared while off.
 */

import * as path from "node:path";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "readonly";

export function makeTitle(cwd: string, enabled: boolean, sessionName?: string): string {
	const base = path.basename(cwd) || "pi";
	const session = sessionName ? `${sessionName} - ${base}` : base;
	const core = `pi - ${session}`;
	return enabled ? `[RO] ${core}` : core;
}

/**
 * Update the footer status only. Title is owned via {@link applyTitle}
 * so that we don't stomp on whatever pi (or other extensions) set while
 * read-only is off.
 */
export function applyFooter(ctx: ExtensionContext, enabled: boolean): void {
	if (!ctx.hasUI) return;
	if (enabled) {
		ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("warning", "read-only"));
	} else {
		ctx.ui.setStatus(STATUS_KEY, undefined);
	}
}

/**
 * Set the window title to reflect `enabled`. Callers should only invoke
 * this on transitions (enable / disable) or when starting up while
 * enabled. While read-only is off, pi (and other extensions) own the
 * title and we leave it alone.
 */
export function applyTitle(pi: ExtensionAPI, ctx: ExtensionContext, enabled: boolean): void {
	if (!ctx.hasUI) return;
	const sessionName = safeGetSessionName(pi);
	ctx.ui.setTitle(makeTitle(ctx.cwd ?? process.cwd(), enabled, sessionName));
}

export function clearUi(ctx: ExtensionContext): void {
	if (!ctx.hasUI) return;
	ctx.ui.setStatus(STATUS_KEY, undefined);
}

function safeGetSessionName(pi: ExtensionAPI): string | undefined {
	try {
		return pi.getSessionName();
	} catch {
		return undefined;
	}
}
