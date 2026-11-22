import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Exec = ExtensionAPI["exec"];

export interface RexTab {
	session: string;
	windowId: string;
	blockId: string;
}

export async function openTab(
	exec: Exec,
	options: { session: string; label: string; cwd: string; command: string[]; signal?: AbortSignal },
): Promise<RexTab> {
	const result = await exec(
		"rex",
		[
			"window",
			"new",
			"-s",
			options.session,
			options.label,
			"-c",
			options.cwd,
			"--focus=false",
			"--json",
			"--",
			...options.command,
		],
		{ signal: options.signal, timeout: 15_000 },
	);
	if (result.code !== 0) throw new Error(`rex window new failed: ${(result.stderr || result.stdout).trim()}`);
	const created = JSON.parse(result.stdout) as { window_id?: string; block_ids?: string[] };
	if (!created.window_id || !created.block_ids?.[0]) throw new Error(`Unexpected rex output: ${result.stdout}`);
	return { session: options.session, windowId: created.window_id, blockId: created.block_ids[0] };
}

export async function waitForExit(exec: Exec, tab: RexTab, signal: AbortSignal) {
	await exec("rex", ["wait", "-s", tab.session, tab.blockId], { signal });
}

export async function closeTab(exec: Exec, tab: RexTab) {
	await exec("rex", ["window", "close", "-s", tab.session, tab.windowId], { timeout: 10_000 });
}

export async function captureTail(exec: Exec, tab: RexTab, lines = 40): Promise<string> {
	const result = await exec("rex", ["capture", "-s", tab.session, "-b", tab.blockId, "--trim"], { timeout: 10_000 });
	if (result.code !== 0) return "";
	return result.stdout.trimEnd().split("\n").slice(-lines).join("\n");
}
