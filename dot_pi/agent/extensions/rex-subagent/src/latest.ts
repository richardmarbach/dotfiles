export interface ModelRef {
	provider: string;
	id: string;
}

const VERSION = String.raw`(\d+(?:[.-]\d+)*)`;
const SNAPSHOT = /\d{8}/;

const escape = (text: string) => text.replace(/[.+?^${}()|[\]\\]/g, "\\$&");

export const isFamilyPattern = (ref: string) => ref.includes("*");

function versionKey(version: string): number[] | undefined {
	if (SNAPSHOT.test(version)) return undefined;
	return version.split(/[.-]/).map(Number);
}

function compareVersions(a: number[], b: number[]): number {
	for (let i = 0; i < Math.max(a.length, b.length); i++) {
		const diff = (a[i] ?? -1) - (b[i] ?? -1);
		if (diff) return diff;
	}
	return 0;
}

/** Resolves `provider/name-*-suffix` to the highest-versioned matching model; `*` stands for the version. */
export function resolveLatest(pattern: string, models: readonly ModelRef[]): string | undefined {
	const slash = pattern.indexOf("/");
	if (slash <= 0 || !isFamilyPattern(pattern)) return undefined;
	const provider = pattern.slice(0, slash);
	const matcher = new RegExp(`^${pattern.slice(slash + 1).split("*").map(escape).join(VERSION)}$`);
	let best: { id: string; key: number[] } | undefined;
	for (const model of models) {
		if (model.provider !== provider) continue;
		const match = model.id.match(matcher);
		if (!match) continue;
		const key = versionKey(match.slice(1).join("."));
		if (key && (!best || compareVersions(key, best.key) > 0)) best = { id: model.id, key };
	}
	return best && `${provider}/${best.id}`;
}

/** Returns concrete refs unchanged; family patterns resolve to their newest model, or undefined if none is available. */
export const resolveModel = (ref: string | undefined, models: readonly ModelRef[]) =>
	ref && isFamilyPattern(ref) ? resolveLatest(ref, models) : ref;
