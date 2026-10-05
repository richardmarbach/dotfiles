import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import type { Snippet, SnippetDirectory, SnippetPlacement, SnippetScope } from "./types.ts";

interface ParsedSnippet {
	id: string;
	snippet?: Snippet;
	disabled: boolean;
}

function unquote(value: string): string {
	const first = value.at(0);
	const last = value.at(-1);
	return value.length >= 2 && first === last && (first === '"' || first === "'")
		? value.slice(1, -1)
		: value;
}

function parseBoolean(value: string | undefined): boolean {
	return /^(true|yes|1)$/i.test(value ?? "");
}

export function parseSnippet(filename: string, raw: string, scope: SnippetScope, path: string): ParsedSnippet {
	let body = raw.trim();
	const metadata: Record<string, string> = {};
	const frontmatter = raw.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)([\s\S]*)$/);

	if (frontmatter) {
		body = frontmatter[2].trim();
		for (const line of frontmatter[1].split(/\r?\n/)) {
			const pair = line.match(/^([A-Za-z][\w-]*)\s*:\s*(.*?)\s*$/);
			if (pair) metadata[pair[1].toLowerCase()] = unquote(pair[2]);
		}
	}

	const id = filename.replace(/\.md$/i, "");
	if (parseBoolean(metadata.disabled)) return { id, disabled: true };
	if (!body) return { id, disabled: false };

	const placement: SnippetPlacement = metadata.placement?.toLowerCase() === "prepend" ? "prepend" : "append";
	const parsedOrder = Number(metadata.order);

	return {
		id,
		disabled: false,
		snippet: {
			id,
			name: metadata.name || filename.replace(/\.md$/i, ""),
			description: metadata.description || "",
			placement,
			order: Number.isFinite(parsedOrder) && metadata.order !== "" ? parsedOrder : 100,
			body,
			scope,
			path,
		},
	};
}

function scanDirectory(directory: SnippetDirectory): ParsedSnippet[] {
	if (!existsSync(directory.path)) return [];

	try {
		return readdirSync(directory.path, { withFileTypes: true })
			.filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith(".md"))
			.sort((a, b) => a.name.localeCompare(b.name))
			.flatMap((entry) => {
				const path = join(directory.path, entry.name);
				try {
					return [parseSnippet(entry.name, readFileSync(path, "utf8"), directory.scope, path)];
				} catch {
					return [];
				}
			});
	} catch {
		return [];
	}
}

export function loadSnippets(directories: SnippetDirectory[]): Snippet[] {
	const snippets = new Map<string, Snippet>();

	for (const directory of directories) {
		for (const parsed of scanDirectory(directory)) {
			if (parsed.disabled) {
				snippets.delete(parsed.id);
				continue;
			}
			if (parsed.snippet) snippets.set(parsed.id, parsed.snippet);
		}
	}

	return [...snippets.values()].sort(
		(a, b) =>
			(a.placement === b.placement ? 0 : a.placement === "prepend" ? -1 : 1) ||
			a.order - b.order ||
			a.name.localeCompare(b.name),
	);
}

export function applySnippets(text: string, snippets: Snippet[]): string {
	const prepended = snippets.filter((snippet) => snippet.placement === "prepend").map((snippet) => snippet.body);
	const appended = snippets.filter((snippet) => snippet.placement === "append").map((snippet) => snippet.body);
	return [...prepended, text, ...appended].filter((part) => part.length > 0).join("\n\n");
}
