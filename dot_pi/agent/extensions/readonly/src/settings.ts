/**
 * Settings.json loader + permissive validator for `readOnly.whitelist`.
 *
 * Global: ~/.pi/agent/settings.json
 * Project: <cwd>/.pi/settings.json   (project overrides global)
 *
 * If `readOnly.whitelist` is present in either file, the closer file's value
 * replaces the default wholesale (no array merge).
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import { DEFAULT_WHITELIST } from "./defaults.ts";

export interface LoadedSettings {
	whitelist: string[];
	/** True when the value came from settings.json (even if empty). */
	fromConfig: boolean;
	/** True when settings.json had `readOnly.whitelist: []`. */
	emptyConfigured: boolean;
	/** Non-fatal validation issues to surface to the user / logs. */
	warnings: string[];
}

export interface LoadOptions {
	globalPath?: string;
	projectPath?: string;
	defaults?: readonly string[];
}

export function defaultGlobalSettingsPath(): string {
	return path.join(os.homedir(), ".pi", "agent", "settings.json");
}

export function defaultProjectSettingsPath(cwd: string = process.cwd()): string {
	return path.join(cwd, ".pi", "settings.json");
}

export function loadReadonlySettings(opts: LoadOptions = {}): LoadedSettings {
	const defaults = opts.defaults ?? DEFAULT_WHITELIST;
	const globalPath = opts.globalPath ?? defaultGlobalSettingsPath();
	const projectPath = opts.projectPath ?? defaultProjectSettingsPath();

	const warnings: string[] = [];
	const global = readSettingsFile(globalPath, warnings);
	const project = readSettingsFile(projectPath, warnings);

	// Project takes precedence over global. Either may carry readOnly.whitelist.
	const projectRaw = extractRaw(project);
	const globalRaw = extractRaw(global);
	const source = projectRaw.present ? projectRaw : globalRaw;

	if (!source.present) {
		return {
			whitelist: [...defaults],
			fromConfig: false,
			emptyConfigured: false,
			warnings,
		};
	}

	const v = validateWhitelistShape(source.value, defaults);
	for (const w of v.warnings) warnings.push(w);

	if (v.usedDefaults) {
		return {
			whitelist: [...defaults],
			fromConfig: false,
			emptyConfigured: false,
			warnings,
		};
	}

	const empty = v.whitelist.length === 0;
	if (empty) {
		warnings.push(
			"readOnly.whitelist is empty - agent will have no tools when read-only is active.",
		);
	}

	return {
		whitelist: v.whitelist,
		fromConfig: true,
		emptyConfigured: empty,
		warnings,
	};
}

export interface ShapeValidation {
	whitelist: string[];
	warnings: string[];
	/** True when the raw value was so malformed we fell back to defaults. */
	usedDefaults: boolean;
}

/**
 * Permissive validator (spec §4, Q17 = B).
 *
 * - Wrong shape (not an array) -> warning + fall back to defaults.
 * - Non-string entries -> warning, skipped.
 * - Non-existent tool names accepted (pre-authorize policy).
 * - Empty array stays empty; caller warns separately.
 */
export function validateWhitelistShape(raw: unknown, defaults: readonly string[]): ShapeValidation {
	if (!Array.isArray(raw)) {
		return {
			whitelist: [...defaults],
			warnings: [
				`readOnly.whitelist must be an array of strings; got ${describeShape(raw)}. Falling back to built-in defaults.`,
			],
			usedDefaults: true,
		};
	}

	const out: string[] = [];
	const warnings: string[] = [];
	const seen = new Set<string>();
	for (let i = 0; i < raw.length; i++) {
		const entry = raw[i];
		if (typeof entry !== "string") {
			warnings.push(
				`readOnly.whitelist[${i}] is not a string (got ${describeShape(entry)}); skipping.`,
			);
			continue;
		}
		const trimmed = entry.trim();
		if (!trimmed) {
			warnings.push(`readOnly.whitelist[${i}] is an empty string; skipping.`);
			continue;
		}
		if (seen.has(trimmed)) continue;
		seen.add(trimmed);
		out.push(trimmed);
	}

	return { whitelist: out, warnings, usedDefaults: false };
}

interface RawExtraction {
	present: boolean;
	value: unknown;
}

function extractRaw(parsed: unknown): RawExtraction {
	if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
		return { present: false, value: undefined };
	}
	const ro = (parsed as Record<string, unknown>)["readOnly"];
	if (!ro || typeof ro !== "object" || Array.isArray(ro)) {
		return { present: false, value: undefined };
	}
	if (!("whitelist" in ro)) {
		return { present: false, value: undefined };
	}
	return { present: true, value: (ro as Record<string, unknown>)["whitelist"] };
}

function readSettingsFile(filePath: string, warnings: string[]): unknown {
	let raw: string;
	try {
		raw = fs.readFileSync(filePath, "utf8");
	} catch (err) {
		const code = (err as NodeJS.ErrnoException).code;
		if (code === "ENOENT") return undefined;
		warnings.push(`Failed to read ${filePath}: ${(err as Error).message}`);
		return undefined;
	}
	try {
		return JSON.parse(raw);
	} catch (err) {
		warnings.push(`Failed to parse ${filePath}: ${(err as Error).message}`);
		return undefined;
	}
}

function describeShape(value: unknown): string {
	if (value === null) return "null";
	if (Array.isArray(value)) return "array";
	return typeof value;
}
