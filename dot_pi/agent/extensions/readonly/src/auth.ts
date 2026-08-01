/**
 * Source-restriction gate for /readonly commands.
 *
 * Only interactive user input may toggle read-only state or mutate the
 * whitelist. Two enforcement points cover the realistic threat surface:
 *
 * 1. Inside the registered command handler: we cannot read the input source
 *    directly because extension commands are dispatched before the `input`
 *    event fires. Instead we infer the runtime mode (rpc / json / print /
 *    interactive) and reject anything that is not strictly interactive.
 * 2. Inside the `input` event handler: when an extension calls
 *    `pi.sendUserMessage("/readonly ...")` the text is delivered as a user
 *    message (not as a dispatched command) and the input event fires with
 *    `source: "extension"`. We reject those too.
 */

export type InputSource = "interactive" | "rpc" | "extension";

export type RuntimeMode = "interactive" | "rpc" | "json" | "print";

/** Detect pi's runtime mode by parsing the process argv. */
export function detectMode(argv: readonly string[] = process.argv): RuntimeMode {
	for (let i = 0; i < argv.length; i++) {
		const arg = argv[i];
		if (arg === "--print" || arg === "-p") return "print";
		if (arg === "--mode" && i + 1 < argv.length) {
			const m = argv[i + 1];
			if (m === "rpc") return "rpc";
			if (m === "json") return "json";
		}
	}
	return "interactive";
}

/** True when the runtime mode is `interactive`. */
export function isInteractiveMode(mode: RuntimeMode): boolean {
	return mode === "interactive";
}

/** True when the input event's source is `interactive`. */
export function isAllowedInputSource(source: InputSource | undefined): boolean {
	return source === "interactive";
}

/**
 * Spec-shaped wrapper used by the source-restriction checklist (§23):
 * `isAllowedSource(command, source)` returns true iff `source` is an
 * interactive user input that may execute `command`. `command` is
 * currently unused — every `/readonly` subcommand has the same gating —
 * but it is part of the documented surface so we keep the signature.
 */
export function isAllowedSource(_command: string, source: InputSource | undefined): boolean {
	return isAllowedInputSource(source);
}

/** Regex used to match `/readonly` and `/readonly <args>` in raw input text. */
export const READONLY_COMMAND_RE = /^\s*\/readonly(?:\s|$)/i;
