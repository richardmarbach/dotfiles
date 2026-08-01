/**
 * pi-coms — local pi-to-pi communication.
 *
 * Each pi session listens on a single endpoint (UNIX socket on POSIX, named
 * pipe on Windows) and discovers peers through per-project registry files
 * under ~/.pi/coms/projects/<project>/agents/<name>.json.
 *
 * Sessions keep each other in sync with periodic heartbeats (registry
 * rewrites) and ping/pong probes. The live pool is exposed as a widget above
 * the editor.
 */

import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";
import { parseFrontmatter, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const IS_WINDOWS = process.platform === "win32";
const COMS_DIR = path.join(os.homedir(), ".pi", "coms");
const PROJECTS_DIR = path.join(COMS_DIR, "projects");
const SOCKETS_DIR = path.join(COMS_DIR, "sockets");

const DELIVERY_TIMEOUT_MS = 5_000;
const TICK_INTERVAL_MS = 5_000;
const RECONNECT_INTERVAL_MS = 1_500;
const PING_TIMEOUT_MS = 2_000;
const HEARTBEAT_STALE_AFTER_MS = 60_000;
const GONE_AFTER_MISSES = 2;
const SEND_RETRY_TOTAL_MS = 2_500;
const SEND_RETRY_BASE_DELAY_MS = 150;
const SEND_RETRY_MAX_DELAY_MS = 800;
const BYE_BUDGET_MS = 500;
const COMS_CUSTOM_TYPE = "pi-coms";
const NAME_PATTERN = /^[a-z0-9][a-z0-9._-]{0,62}$/;
const POOL_WIDGET_ID = "pi-coms-pool";
const IDENTITY_DEFER_MS = 1000;
const TEMPLATE_INVOCATION = /^\/([A-Za-z0-9][A-Za-z0-9._-]{0,62})(?:\s|$)/;
const PROJECT_FLAG_DEFAULT = "default";

type PeerInfo = {
	project: string;
	projectPath: string;
	name: string;
	peerId: string;
	pid: number;
	socket: string;
	startedAt: number;
	lastSeen: number;
};

type PromptMessage = {
	type: "prompt";
	msgId: string;
	from: PeerInfo;
	content: string;
};

type ReplyMessage = {
	type: "reply";
	msgId: string;
	inReplyTo: string;
	from: PeerInfo;
	content: string;
};

type PingMessage = { type: "ping"; from?: PeerInfo };
type PongMessage = { type: "pong"; from: PeerInfo };
type ByeMessage = { type: "bye"; from: PeerInfo };
type AckMessage = { type: "ack"; ok: boolean; error?: string };

type WireMessage =
	| PromptMessage
	| ReplyMessage
	| PingMessage
	| PongMessage
	| ByeMessage
	| AckMessage;

type OutboxStatus = "pending" | "replied" | "failed";

type OutboxEntry = {
	msgId: string;
	target: PeerInfo;
	prompt: string;
	sentAt: number;
	status: OutboxStatus;
	reply?: ReplyMessage;
	error?: string;
};

type PoolStatus = "online" | "stale" | "gone";

type PoolEntry = {
	info: PeerInfo;
	status: PoolStatus;
	lastPongAt?: number;
	missCount: number;
	goneTicks: number;
};

function slugify(input: string): string {
	const lower = input.toLowerCase().replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "");
	return lower || "anon";
}

function projectKeyFor(cwd: string): string {
	const abs = path.resolve(cwd);
	const base = slugify(path.basename(abs) || "root");
	const hash = crypto.createHash("sha256").update(abs).digest("hex").slice(0, 8);
	return `${base}-${hash}`;
}

function peerHandle(peer: { project: string; name: string }): string {
	return `${peer.project}/${peer.name}`;
}

function projectDir(project: string): string {
	return path.join(PROJECTS_DIR, project);
}

function agentsDirFor(project: string): string {
	return path.join(projectDir(project), "agents");
}

function endpointPath(peerId: string): string {
	return IS_WINDOWS ? `\\\\.\\pipe\\pi-coms-${peerId}` : path.join(SOCKETS_DIR, `${peerId}.sock`);
}

function endpointExists(endpoint: string): boolean {
	if (IS_WINDOWS) return true;
	return fs.existsSync(endpoint);
}

function processAlive(pid: number): boolean {
	try {
		process.kill(pid, 0);
		return true;
	} catch (err) {
		return (err as NodeJS.ErrnoException).code === "EPERM";
	}
}

function isRegistrationLive(info: PeerInfo): boolean {
	if (!processAlive(info.pid)) return false;
	if (!endpointExists(info.socket)) return false;
	if (info.lastSeen && Date.now() - info.lastSeen > HEARTBEAT_STALE_AFTER_MS * 3) {
		return false;
	}
	return true;
}

function readPeerFile(file: string): PeerInfo | undefined {
	try {
		const raw = JSON.parse(fs.readFileSync(file, "utf-8")) as PeerInfo;
		if (typeof raw.lastSeen !== "number") raw.lastSeen = raw.startedAt;
		return raw;
	} catch {
		return undefined;
	}
}

function listProjects(): string[] {
	try {
		return fs.readdirSync(PROJECTS_DIR).filter((p) => {
			try {
				return fs.statSync(path.join(PROJECTS_DIR, p)).isDirectory();
			} catch {
				return false;
			}
		});
	} catch {
		return [];
	}
}

function listProjectPeers(project: string, ownPeerId: string | undefined, includeSelf: boolean): PeerInfo[] {
	const dir = agentsDirFor(project);
	let files: string[];
	try {
		files = fs.readdirSync(dir);
	} catch {
		return [];
	}
	const out: PeerInfo[] = [];
	for (const f of files) {
		if (!f.endsWith(".json")) continue;
		const fp = path.join(dir, f);
		const info = readPeerFile(fp);
		if (!info) {
			try {
				fs.unlinkSync(fp);
			} catch {}
			continue;
		}
		const isSelf = info.peerId === ownPeerId;
		if (!isSelf && !isRegistrationLive(info)) {
			try {
				fs.unlinkSync(fp);
			} catch {}
			if (!IS_WINDOWS) {
				try {
					fs.unlinkSync(info.socket);
				} catch {}
			}
			continue;
		}
		if (isSelf && !includeSelf) continue;
		out.push(info);
	}
	return out;
}

function describeEntry(entry: OutboxEntry): string {
	const ageS = Math.round((Date.now() - entry.sentAt) / 100) / 10;
	const header = `message_id=${entry.msgId} to=${peerHandle(entry.target)} age=${ageS}s status=${entry.status}`;
	switch (entry.status) {
		case "pending":
			return `${header}\nNo reply yet. The reply will arrive as a user message when it lands; coms_get to poll explicitly.`;
		case "replied":
			return `${header}\n\n--- Reply from ${peerHandle(entry.reply!.from)} ---\n${entry.reply!.content}\n--- End reply ---`;
		case "failed":
			return `${header}\nDelivery failed: ${entry.error ?? "unknown error"}`;
	}
}

function injectResultBody(entry: OutboxEntry): string {
	return [
		`📬 Reply received via pi-coms: message_id=**${entry.msgId}** from ${peerHandle(entry.target)} has resolved.`,
		``,
		`--- Result ---`,
		describeEntry(entry),
		`--- End result ---`,
	].join("\n");
}

type IdentitySources = {
	name?: string;
	project?: string;
	purpose?: string;
	color?: string;
	explicit?: boolean;
};

type RawTemplateFrontmatter = {
	name?: unknown;
	project?: unknown;
	purpose?: unknown;
	description?: unknown;
	color?: unknown;
	explicit?: unknown;
};

// Resolve a /<name> template to a file for frontmatter inference. Only the two
// filesystem locations pi loads by default are covered — pi.prompts package dirs,
// the settings `prompts` array, and explicit --prompt-template paths are NOT
// scanned here. Templates registered through those routes are still invocable as
// /name, but identity falls back to cwd defaults for them. Re-implementing pi's
// full loader would duplicate internal logic; revisit when a public resolver is
// exposed via ExtensionAPI.
function findPromptTemplateFile(name: string, cwd: string): string | undefined {
	const candidates = [
		path.join(cwd, ".pi", "prompts", `${name}.md`),
		path.join(os.homedir(), ".pi", "agent", "prompts", `${name}.md`),
	];
	for (const file of candidates) {
		try {
			if (fs.statSync(file).isFile()) return file;
		} catch {}
	}
	return undefined;
}

function identityFromTemplate(templateName: string, cwd: string): IdentitySources {
	const file = findPromptTemplateFile(templateName, cwd);
	if (!file) return {};
	let raw: string;
	try {
		raw = fs.readFileSync(file, "utf-8");
	} catch {
		return {};
	}
	let fm: RawTemplateFrontmatter;
	try {
		fm = parseFrontmatter<RawTemplateFrontmatter>(raw).frontmatter;
	} catch {
		return {};
	}
	const out: IdentitySources = {};
	if (typeof fm.name === "string" && fm.name.trim()) out.name = fm.name.trim();
	if (typeof fm.project === "string" && fm.project.trim()) out.project = fm.project.trim();
	if (typeof fm.purpose === "string" && fm.purpose.trim()) out.purpose = fm.purpose.trim();
	else if (typeof fm.description === "string" && fm.description.trim()) out.purpose = fm.description.trim();
	if (typeof fm.color === "string" && fm.color.trim()) out.color = fm.color.trim();
	if (typeof fm.explicit === "boolean") out.explicit = fm.explicit;
	return out;
}

function entryDetails(entry: OutboxEntry): Record<string, unknown> {
	return {
		message_id: entry.msgId,
		status: entry.status,
		target: entry.target,
		sent_at: entry.sentAt,
		reply: entry.reply
			? { content: entry.reply.content, from: entry.reply.from, message_id: entry.reply.msgId }
			: undefined,
		error: entry.error,
	};
}

export default function (pi: ExtensionAPI) {
	// ━━ Register identity CLI flags so pi's parser accepts them. ━━━━━━━━━
	// Without these, pi 0.73+ rejects the invocation with "Unknown options:
	// --name, --project, ..." before this extension's hooks ever fire.
	pi.registerFlag("name", {
		description: "Override agent name (otherwise from frontmatter or auto-generated)",
		type: "string",
		default: undefined,
	});
	pi.registerFlag("purpose", {
		description: "Override agent purpose (otherwise from frontmatter description)",
		type: "string",
		default: undefined,
	});
	pi.registerFlag("project", {
		description: "Project namespace for peer discovery",
		type: "string",
		default: "default",
	});
	pi.registerFlag("color", {
		description: "Hex color #RRGGBB (otherwise from frontmatter or palette fallback)",
		type: "string",
		default: undefined,
	});
	pi.registerFlag("explicit", {
		description: "Hide this agent from auto-discovery; only addressable by exact name",
		type: "boolean",
		default: false,
	});

	const peerId = crypto.randomUUID();
	const socketPath = endpointPath(peerId);
	const startedAt = Date.now();

	let projectPath = path.resolve(process.cwd());
	let project = projectKeyFor(projectPath);
	let peerName = slugify(path.basename(projectPath) || `pi-${process.pid}`);
	let registrationPath = path.join(agentsDirFor(project), `${peerName}.json`);

	let server: net.Server | undefined;
	let currentCtx: ExtensionContext | undefined;

	const outbox = new Map<string, OutboxEntry>();
	const inbox = new Map<string, PeerInfo>();
	const pool = new Map<string, PoolEntry>();
	const activeConnections = new Set<net.Socket>();

	let tickTimer: NodeJS.Timeout | undefined;
	let tickInFlight = false;
	let widgetTui: { requestRender: () => void } | undefined;
	let cleanedUp = false;
	let exitHookInstalled = false;

	const selfInfo = (): PeerInfo => ({
		project,
		projectPath,
		name: peerName,
		peerId,
		pid: process.pid,
		socket: socketPath,
		startedAt,
		lastSeen: Date.now(),
	});

	function ensureDirs() {
		fs.mkdirSync(agentsDirFor(project), { recursive: true });
		if (!IS_WINDOWS) fs.mkdirSync(SOCKETS_DIR, { recursive: true });
	}

	function pickUniqueName(base: string): string {
		const sanitized = slugify(base);
		let candidate = sanitized;
		let n = 2;
		while (true) {
			const file = path.join(agentsDirFor(project), `${candidate}.json`);
			if (!fs.existsSync(file)) return candidate;
			const info = readPeerFile(file);
			if (!info || !isRegistrationLive(info)) {
				try {
					fs.unlinkSync(file);
				} catch {}
				return candidate;
			}
			candidate = `${sanitized}-${n++}`;
		}
	}

	function writeRegistration() {
		ensureDirs();
		const tmp = `${registrationPath}.${process.pid}.tmp`;
		fs.writeFileSync(tmp, JSON.stringify(selfInfo(), null, 2));
		fs.renameSync(tmp, registrationPath);
	}

	function removeRegistration() {
		if (!identityFinalized) return;
		try {
			fs.unlinkSync(registrationPath);
		} catch {}
	}

	function closeServer() {
		for (const sock of activeConnections) {
			try {
				sock.destroy();
			} catch {}
		}
		activeConnections.clear();
		if (server) {
			try {
				server.close();
			} catch {}
			server = undefined;
		}
		if (!IS_WINDOWS) {
			try {
				fs.unlinkSync(socketPath);
			} catch {}
		}
	}

	function resolveOutbox(reply: ReplyMessage): boolean {
		const entry = outbox.get(reply.inReplyTo);
		if (!entry || entry.status !== "pending") return false;
		entry.status = "replied";
		entry.reply = reply;
		injectResult(entry);
		return true;
	}

	// Unconditional injection of an outbox entry's terminal result as a user
	// message. Called once per pending→replied|failed transition. Mirrors the
	// delivery channel used by injectIncomingPrompt so the agent observes the
	// result on its next turn without polling.
	function injectResult(entry: OutboxEntry) {
		const text = injectResultBody(entry);
		const idle = currentCtx?.isIdle() ?? true;
		if (idle) {
			pi.sendUserMessage(text);
		} else {
			pi.sendUserMessage(text, { deliverAs: "followUp" });
		}
	}

	// Walks the outbox and terminalizes every pending entry whose target peer
	// has been evicted from the pool (registration file removed, or sustained
	// gone for POOL_RETAIN_AFTER_GONE_TICKS). Keyed on peerId (UUID), not on
	// handle, so a same-name peer restarting under a fresh peerId does not
	// consume old entries. Each terminalized entry triggers injectResult.
	function failOutboxForPeer(peerId: string, reason: string) {
		for (const entry of outbox.values()) {
			if (entry.status !== "pending") continue;
			if (entry.target.peerId !== peerId) continue;
			entry.status = "failed";
			entry.error = reason;
			injectResult(entry);
		}
	}

	function markPoolGone(handle: string) {
		const entry = pool.get(handle);
		if (!entry) return;
		entry.status = "gone";
		entry.missCount = Math.max(entry.missCount, GONE_AFTER_MISSES);
	}

	function injectIncomingPrompt(msg: PromptMessage) {
		inbox.set(msg.msgId, msg.from);
		upsertPool(msg.from, "online");
		const text = formatIncomingPrompt(msg);
		const idle = currentCtx?.isIdle() ?? true;
		if (idle) {
			pi.sendUserMessage(text);
		} else {
			pi.sendUserMessage(text, { deliverAs: "followUp" });
		}
		if (currentCtx?.hasUI) {
			currentCtx.ui.notify(`Incoming prompt from ${peerHandle(msg.from)}`, "info");
		}
	}

	function handleMessage(msg: WireMessage, sock: net.Socket) {
		if (msg.type === "ping") {
			if (msg.from) upsertPool(msg.from, "online");
			const pong: PongMessage = { type: "pong", from: selfInfo() };
			sock.write(`${JSON.stringify(pong)}\n`);
			sock.end();
			return;
		}
		if (msg.type === "prompt") {
			try {
				injectIncomingPrompt(msg);
				sock.write(`${JSON.stringify({ type: "ack", ok: true } satisfies AckMessage)}\n`);
			} catch (err) {
				sock.write(
					`${JSON.stringify({ type: "ack", ok: false, error: (err as Error).message } satisfies AckMessage)}\n`,
				);
			}
			sock.end();
			return;
		}
		if (msg.type === "reply") {
			upsertPool(msg.from, "online");
			const matched = resolveOutbox(msg);
			if (matched) {
				sock.write(`${JSON.stringify({ type: "ack", ok: true } satisfies AckMessage)}\n`);
			} else {
				pi.sendMessage({
					customType: COMS_CUSTOM_TYPE,
					content: `Late reply from ${peerHandle(msg.from)} (msg ${msg.msgId}, in reply to ${msg.inReplyTo}): ${msg.content}`,
					display: true,
				});
				sock.write(
					`${JSON.stringify({
						type: "ack",
						ok: false,
						error: "no pending request for that message id",
					} satisfies AckMessage)}\n`,
				);
			}
			sock.end();
			return;
		}
		if (msg.type === "bye") {
			markPoolGone(peerHandle(msg.from));
			widgetTui?.requestRender();
			sock.write(`${JSON.stringify({ type: "ack", ok: true } satisfies AckMessage)}\n`);
			sock.end();
			return;
		}
		sock.write(
			`${JSON.stringify({ type: "ack", ok: false, error: "unsupported message type" } satisfies AckMessage)}\n`,
		);
		sock.end();
	}

	function handleConnection(sock: net.Socket) {
		activeConnections.add(sock);
		sock.setEncoding("utf-8");
		let buf = "";
		let handled = false;
		sock.on("data", (chunk) => {
			buf += chunk;
			const idx = buf.indexOf("\n");
			if (idx < 0 || handled) return;
			handled = true;
			const line = buf.slice(0, idx);
			let msg: WireMessage;
			try {
				msg = JSON.parse(line) as WireMessage;
			} catch (err) {
				sock.write(
					`${JSON.stringify({ type: "ack", ok: false, error: `invalid JSON: ${(err as Error).message}` } satisfies AckMessage)}\n`,
				);
				sock.end();
				return;
			}
			handleMessage(msg, sock);
		});
		sock.on("error", () => {});
		sock.on("close", () => activeConnections.delete(sock));
	}

	let restartingServer = false;

	async function startServer() {
		ensureDirs();
		if (!IS_WINDOWS) {
			try {
				fs.unlinkSync(socketPath);
			} catch {}
		}
		await new Promise<void>((resolve, reject) => {
			server = net.createServer(handleConnection);
			server.once("error", reject);
			server!.listen(socketPath, () => {
				server!.off("error", reject);
				resolve();
			});
		});
		if (!IS_WINDOWS) {
			try {
				fs.chmodSync(socketPath, 0o600);
			} catch {}
		}
		// Permanent error handler. A late server error (socket file removed by
		// another peer's prune, OS oddity, etc.) leaves this session unreachable
		// unless we recreate the listener. The recovery loop also checks the
		// socket file each tick and triggers a restart if it disappeared.
		server!.on("error", (err) => {
			if (cleanedUp) return;
			if (currentCtx?.hasUI) {
				currentCtx.ui.notify(`pi-coms: server error (${err.message}); attempting restart`, "warning");
			}
			void restartServer();
		});
	}

	async function restartServer(): Promise<boolean> {
		if (cleanedUp || restartingServer) return false;
		restartingServer = true;
		try {
			if (server) {
				try {
					server.close();
				} catch {}
				server = undefined;
			}
			await startServer();
			try {
				if (identityFinalized) writeRegistration();
			} catch {}
			return true;
		} catch (err) {
			if (currentCtx?.hasUI) {
				currentCtx.ui.notify(`pi-coms: server restart failed: ${(err as Error).message}`, "error");
			}
			return false;
		} finally {
			restartingServer = false;
		}
	}

	function sendWire<R extends WireMessage>(
		target: PeerInfo,
		msg: WireMessage,
		expect: WireMessage["type"],
		timeoutMs: number,
	): Promise<R> {
		return new Promise((resolve, reject) => {
			const sock = net.createConnection(target.socket);
			let buf = "";
			let settled = false;
			const finish = (fn: () => void) => {
				if (settled) return;
				settled = true;
				clearTimeout(timer);
				try {
					sock.destroy();
				} catch {}
				fn();
			};
			const timer = setTimeout(() => {
				finish(() => reject(new Error(`timed out waiting for ${expect} from ${peerHandle(target)}`)));
			}, timeoutMs);
			sock.setEncoding("utf-8");
			sock.on("connect", () => {
				sock.write(`${JSON.stringify(msg)}\n`);
			});
			sock.on("data", (chunk) => {
				buf += chunk;
				const idx = buf.indexOf("\n");
				if (idx < 0) return;
				const line = buf.slice(0, idx);
				try {
					const reply = JSON.parse(line) as WireMessage;
					if (reply.type === expect) {
						finish(() => resolve(reply as R));
					} else {
						finish(() => reject(new Error(`expected ${expect}, got ${reply.type}`)));
					}
				} catch (err) {
					finish(() => reject(err as Error));
				}
			});
			sock.on("error", (err) => finish(() => reject(err)));
			sock.on("close", () => finish(() => reject(new Error(`connection to ${peerHandle(target)} closed early`))));
		});
	}

	function sendToPeer(target: PeerInfo, msg: PromptMessage | ReplyMessage, timeoutMs = DELIVERY_TIMEOUT_MS) {
		return sendWire<AckMessage>(target, msg, "ack", timeoutMs);
	}

	function pingPeer(target: PeerInfo): Promise<PongMessage> {
		const msg: PingMessage = { type: "ping", from: selfInfo() };
		return sendWire<PongMessage>(target, msg, "pong", PING_TIMEOUT_MS);
	}

	function sendBye(target: PeerInfo): Promise<AckMessage> {
		const msg: ByeMessage = { type: "bye", from: selfInfo() };
		return sendWire<AckMessage>(target, msg, "ack", PING_TIMEOUT_MS);
	}

	// Send-with-retry wraps sendWire so a transient connect/ack failure does not
	// terminalize an outbox entry. Between attempts the peer's registry entry is
	// re-resolved — picks up a peer that restarted under the same handle with a
	// fresh socket path. Bails immediately when the registration file is gone
	// (the peer is actually offline, not just slow). Budget is in wall-clock; an
	// individual attempt still observes its own per-attempt timeout.
	async function sendWithRetry<R extends WireMessage>(
		handle: string,
		initialTarget: PeerInfo,
		msg: WireMessage,
		expect: WireMessage["type"],
		perAttemptTimeoutMs: number,
		totalBudgetMs: number = SEND_RETRY_TOTAL_MS,
	): Promise<{ result: R; target: PeerInfo; attempts: number }> {
		const deadline = Date.now() + totalBudgetMs;
		let target = initialTarget;
		let delay = SEND_RETRY_BASE_DELAY_MS;
		let lastErr: Error | undefined;
		let attempts = 0;
		while (true) {
			attempts++;
			try {
				const result = await sendWire<R>(target, msg, expect, perAttemptTimeoutMs);
				return { result, target, attempts };
			} catch (err) {
				lastErr = err as Error;
				const refreshed = resolvePeerHandle(handle);
				if (!refreshed) {
					throw new Error(
						`peer ${handle} is no longer reachable (after ${attempts} attempt${attempts === 1 ? "" : "s"}): ${lastErr.message}`,
					);
				}
				target = refreshed;
				const remaining = deadline - Date.now();
				if (remaining <= 0) break;
				await new Promise((r) => setTimeout(r, Math.min(delay, remaining)));
				delay = Math.min(delay * 2, SEND_RETRY_MAX_DELAY_MS);
			}
		}
		throw new Error(
			`send to ${handle} failed after ${attempts} attempt${attempts === 1 ? "" : "s"} (${totalBudgetMs}ms budget): ${lastErr?.message ?? "unknown"}`,
		);
	}



	function upsertPool(info: PeerInfo, status: PoolStatus = "online") {
		const key = peerHandle(info);
		const existing = pool.get(key);
		if (existing) {
			existing.info = info;
			if (status === "online") {
				existing.status = "online";
				existing.lastPongAt = Date.now();
				existing.missCount = 0;
				existing.goneTicks = 0;
			}
		} else {
			pool.set(key, {
				info,
				status,
				lastPongAt: status === "online" ? Date.now() : undefined,
				missCount: 0,
				goneTicks: 0,
			});
		}
	}

	function listPeersScoped(scope: "current" | "all" | string, includeSelf = false): PeerInfo[] {
		if (scope === "current") return listProjectPeers(project, peerId, includeSelf);
		if (scope === "all") {
			const out: PeerInfo[] = [];
			for (const p of listProjects()) out.push(...listProjectPeers(p, peerId, includeSelf));
			return out;
		}
		return listProjectPeers(scope, peerId, includeSelf);
	}

	function pruneIfDead(info: PeerInfo): boolean {
		if (info.peerId === peerId) return false;
		const file = path.join(agentsDirFor(info.project), `${info.name}.json`);
		const current = readPeerFile(file);
		if (!current) {
			if (!IS_WINDOWS) {
				try {
					fs.unlinkSync(info.socket);
				} catch {}
			}
			return true;
		}
		if (current.peerId !== info.peerId) return false;
		if (isRegistrationLive(current)) return false;
		try {
			fs.unlinkSync(file);
		} catch {}
		if (!IS_WINDOWS) {
			try {
				fs.unlinkSync(current.socket);
			} catch {}
		}
		return true;
	}

	function resolvePeerHandle(handle: string): PeerInfo | undefined {
		let proj = project;
		let name = handle;
		const slash = handle.indexOf("/");
		if (slash >= 0) {
			proj = handle.slice(0, slash);
			name = handle.slice(slash + 1);
		}
		const file = path.join(agentsDirFor(proj), `${name}.json`);
		const info = readPeerFile(file);
		if (!info) return undefined;
		if (info.peerId !== peerId && !isRegistrationLive(info)) {
			try {
				fs.unlinkSync(file);
			} catch {}
			if (!IS_WINDOWS) {
				try {
					fs.unlinkSync(info.socket);
				} catch {}
			}
			return undefined;
		}
		return info;
	}

	async function runTick() {
		if (tickInFlight || cleanedUp) return;
		tickInFlight = true;
		try {
			try {
				writeRegistration();
			} catch {}

			const discovered = new Map<string, PeerInfo>();
			for (const p of listProjectPeers(project, peerId, false)) {
				discovered.set(peerHandle(p), p);
			}
			for (const entry of pool.values()) {
				if (entry.info.project === project) continue;
				const refreshed = resolvePeerHandle(peerHandle(entry.info));
				if (refreshed) discovered.set(peerHandle(refreshed), refreshed);
			}

			for (const [key, info] of discovered) {
				const existing = pool.get(key);
				if (!existing) {
					pool.set(key, { info, status: "stale", missCount: 0, goneTicks: 0 });
				} else if (existing.info.peerId !== info.peerId) {
					// Same handle, different peerId — the previous occupant exited
					// and a fresh session registered under the same name. The old
					// peer's outbox entries cannot be answered; terminalize them and
					// reset the pool entry so the next probe targets the new peer.
					failOutboxForPeer(existing.info.peerId, "peer went offline");
					existing.info = info;
					existing.status = "stale";
					existing.missCount = 0;
					existing.goneTicks = 0;
					existing.lastPongAt = undefined;
				} else {
					existing.info = info;
				}
			}

			// Self-heal: if our own listening socket file disappeared (e.g. another
			// peer's prune saw us as stale and removed it), the kernel listener is
			// still up but no peer can connect. Recreate it.
			if (!IS_WINDOWS && identityFinalized && !fs.existsSync(socketPath)) {
				void restartServer();
			}

			const probes: Array<Promise<void>> = [];
			for (const [key, entry] of pool) {
				if (!discovered.has(key) && entry.info.project === project) {
					entry.status = "gone";
					entry.missCount = Math.max(entry.missCount, GONE_AFTER_MISSES);
				}
				probes.push(
					(async () => {
						try {
							await pingPeer(entry.info);
							entry.status = "online";
							entry.lastPongAt = Date.now();
							entry.missCount = 0;
							entry.goneTicks = 0;
						} catch {
							entry.missCount++;
							if (entry.missCount >= GONE_AFTER_MISSES) entry.status = "gone";
							else if (entry.status === "online") entry.status = "stale";
						}
					})(),
				);
			}
			await Promise.all(probes);

			// Sticky-pool eviction: a pool entry is removed only when the peer's
			// registration file is truly gone (pruneIfDead via missing file, dead
			// pid, or stale lastSeen). Transient ping flapping no longer evicts
			// — the recovery loop keeps probing and brings the entry back online
			// as soon as the peer is responsive again.
			for (const [key, entry] of [...pool]) {
				if (entry.status === "gone" && pruneIfDead(entry.info)) {
					pool.delete(key);
					failOutboxForPeer(entry.info.peerId, "peer went offline");
					continue;
				}
				entry.goneTicks = 0;
			}
		} finally {
			tickInFlight = false;
			widgetTui?.requestRender();
		}
	}

	function startTickLoop() {
		if (tickTimer) return;
		void runTick();
		tickTimer = setInterval(() => {
			void runTick();
		}, TICK_INTERVAL_MS);
		if (typeof tickTimer.unref === "function") tickTimer.unref();
	}

	// Public hook on the shared event bus. Primarily intended for tests and
	// diagnostics that need a sync probe of the pool/outbox. Safe but wasteful
	// to fire frequently; the existing tickInFlight guard inside runTick makes
	// concurrent invocations a no-op rather than a re-entrant tick.
	pi.events.on("pi-coms:force-tick", () => {
		void runTick();
	});

	function stopTickLoop() {
		if (tickTimer) {
			clearInterval(tickTimer);
			tickTimer = undefined;
		}
	}

	let recoveryTimer: NodeJS.Timeout | undefined;
	let recoveryInFlight = false;

	// Recovery loop: faster cadence than runTick, but only touches pool entries
	// that are not currently "online". Each candidate is re-resolved against its
	// registry file (catches peer-restart-with-new-socket) and pinged. Successful
	// pings restore status=online; failures are silently retained — runTick is
	// the authority on eviction.
	async function runRecovery() {
		if (recoveryInFlight || tickInFlight || cleanedUp) return;
		recoveryInFlight = true;
		try {
			const candidates = [...pool.entries()].filter(([, e]) => e.status !== "online");
			if (candidates.length === 0) return;
			const probes = candidates.map(async ([key, entry]) => {
				const handle = peerHandle(entry.info);
				const refreshed = resolvePeerHandle(handle);
				if (refreshed && refreshed.peerId !== entry.info.peerId) {
					failOutboxForPeer(entry.info.peerId, "peer went offline");
					entry.info = refreshed;
					entry.status = "stale";
					entry.missCount = 0;
					entry.goneTicks = 0;
					entry.lastPongAt = undefined;
				} else if (refreshed) {
					entry.info = refreshed;
				} else {
					// resolvePeerHandle returns undefined only when the registry
					// entry is missing or stale (and it has already pruned the
					// file). Peer truly left — evict and terminalize.
					pool.delete(key);
					failOutboxForPeer(entry.info.peerId, "peer went offline");
					return;
				}
				try {
					await pingPeer(entry.info);
					entry.status = "online";
					entry.lastPongAt = Date.now();
					entry.missCount = 0;
					entry.goneTicks = 0;
				} catch {
					// Stay stale/gone. Next recovery pass will try again; runTick
					// owns the eviction decision.
				}
			});
			await Promise.all(probes);
		} finally {
			recoveryInFlight = false;
			widgetTui?.requestRender();
		}
	}

	function startRecoveryLoop() {
		if (recoveryTimer) return;
		recoveryTimer = setInterval(() => void runRecovery(), RECONNECT_INTERVAL_MS);
		if (typeof recoveryTimer.unref === "function") recoveryTimer.unref();
	}

	function stopRecoveryLoop() {
		if (recoveryTimer) {
			clearInterval(recoveryTimer);
			recoveryTimer = undefined;
		}
	}

	// Test/diagnostic hook — symmetric with pi-coms:force-tick. The runRecovery
	// guard short-circuits concurrent invocations to a no-op.
	pi.events.on("pi-coms:force-recovery", () => {
		void runRecovery();
	});

	function installPoolWidget(ctx: ExtensionContext) {
		if (!ctx.hasUI) return;
		ctx.ui.setWidget(POOL_WIDGET_ID, (tui, theme) => {
			widgetTui = tui;
			return {
				render: (width: number) => renderPoolLines(theme, width),
				invalidate: () => {},
			};
		});
	}

	function renderPoolLines(theme: any, width = Number.POSITIVE_INFINITY): string[] {
		const lines: string[] = [];
		const clamp = (line: string) => (Number.isFinite(width) ? truncateToWidth(line, width) : line);
		const selfLabel = `pi-coms · ${peerHandle(selfInfo())} (this session)`;
		lines.push(clamp(theme.fg("accent", selfLabel)));
		const sorted = [...pool.values()].sort((a, b) => peerHandle(a.info).localeCompare(peerHandle(b.info)));
		if (sorted.length === 0) {
			lines.push(clamp(theme.fg("muted", "  (no peers yet)")));
			return lines;
		}
		for (const e of sorted) {
			let dot: string;
			let statusLabel: string;
			if (e.status === "online") {
				dot = theme.fg("success", "●");
				statusLabel = theme.fg("success", "online");
			} else if (e.status === "stale") {
				dot = theme.fg("warning", "◐");
				const ageS = e.lastPongAt ? Math.round((Date.now() - e.lastPongAt) / 1000) : undefined;
				statusLabel = theme.fg("warning", ageS != null ? `stale ${ageS}s` : "stale");
			} else {
				dot = theme.fg("muted", "○");
				statusLabel = theme.fg("muted", "gone");
			}
			const handle = peerHandle(e.info);
			lines.push(clamp(`  ${dot} ${handle}  ${theme.fg("dim", `pid=${e.info.pid}`)}  ${statusLabel}`));
		}
		return lines;
	}

	function syncFileCleanup() {
		if (identityFinalized) {
			try {
				fs.unlinkSync(registrationPath);
			} catch {}
		}
		if (!IS_WINDOWS) {
			try {
				fs.unlinkSync(socketPath);
			} catch {}
		}
	}

	function installExitHook() {
		if (exitHookInstalled) return;
		exitHookInstalled = true;
		process.once("exit", syncFileCleanup);
	}

	async function shutdownClean() {
		if (cleanedUp) return;
		cleanedUp = true;
		stopTickLoop();
		stopRecoveryLoop();

		const targets = [...pool.values()].filter((e) => e.status !== "gone");
		if (targets.length > 0) {
			const byeBudget = new Promise<void>((r) => setTimeout(r, BYE_BUDGET_MS));
			await Promise.race([
				Promise.allSettled(targets.map((e) => sendBye(e.info))),
				byeBudget,
			]);
		}

		for (const entry of outbox.values()) {
			if (entry.status === "pending") {
				entry.status = "failed";
				entry.error = "session shutting down";
			}
			// Intentionally not calling injectResult here: the session is tearing
			// down, sendUserMessage during shutdown is at best wasted and at worst
			// racy against extension teardown. The agent will not get a next turn
			// to observe the injection anyway.
		}
		outbox.clear();
		inbox.clear();
		pool.clear();

		if (currentCtx?.hasUI) {
			try {
				currentCtx.ui.setWidget(POOL_WIDGET_ID, undefined);
			} catch {}
		}

		removeRegistration();
		closeServer();
	}

	let identityFinalized = false;
	let deferTimer: NodeJS.Timeout | undefined;

	function identityFromFlags(): IdentitySources {
		const out: IdentitySources = {};
		const nameFlag = pi.getFlag("name");
		if (typeof nameFlag === "string" && nameFlag.trim()) out.name = nameFlag.trim();
		const projectFlag = pi.getFlag("project");
		if (typeof projectFlag === "string" && projectFlag.trim() && projectFlag !== PROJECT_FLAG_DEFAULT) {
			out.project = projectFlag.trim();
		}
		const purposeFlag = pi.getFlag("purpose");
		if (typeof purposeFlag === "string" && purposeFlag.trim()) out.purpose = purposeFlag.trim();
		const colorFlag = pi.getFlag("color");
		if (typeof colorFlag === "string" && colorFlag.trim()) out.color = colorFlag.trim();
		const explicitFlag = pi.getFlag("explicit");
		if (typeof explicitFlag === "boolean" && explicitFlag) out.explicit = true;
		return out;
	}

	function applyIdentity(name: string | undefined, proj: string | undefined) {
		// Both name and project can flow in from untrusted prompt-template frontmatter, so
		// run them through the same NAME_PATTERN guard. slugify alone is not enough: it
		// keeps '.' which would let ".." escape ~/.pi/coms/projects/<project>/.
		if (name) {
			const slug = slugify(name);
			if (NAME_PATTERN.test(slug)) peerName = slug;
		}
		if (proj) {
			const slug = slugify(proj);
			if (NAME_PATTERN.test(slug)) project = slug;
		}
	}

	function finalizeIdentity(templateName: string | undefined, ctx: ExtensionContext | undefined) {
		if (identityFinalized) return;
		identityFinalized = true;
		if (deferTimer) {
			clearTimeout(deferTimer);
			deferTimer = undefined;
		}

		const cli = identityFromFlags();
		const fm = templateName ? identityFromTemplate(templateName, projectPath) : {};
		// pi 0.78+ owns `--name` as a core flag (stored as the session name) before it can
		// reach this extension's registered flag, so getFlag("name") comes back empty. Fall
		// back to the core session name so `--name foo` still drives the coms handle.
		const sessionName = (() => {
			try {
				return ctx?.sessionManager?.getSessionName?.();
			} catch {
				return undefined;
			}
		})();
		applyIdentity(cli.name ?? sessionName ?? fm.name, cli.project ?? fm.project);

		ensureDirs();
		peerName = pickUniqueName(peerName);
		registrationPath = path.join(agentsDirFor(project), `${peerName}.json`);
		writeRegistration();
		startTickLoop();
		startRecoveryLoop();
		if (ctx?.hasUI) {
			const src =
				templateName && !cli.name && !sessionName && (fm.name || fm.project)
					? ` (from template /${templateName})`
					: "";
			ctx.ui.notify(`pi-coms: ${peerHandle(selfInfo())} registered${src}.`, "info");
		}
	}

	pi.on("session_start", async (event, ctx) => {
		currentCtx = ctx;
		cleanedUp = false;
		identityFinalized = false;
		ensureDirs();
		try {
			await startServer();
		} catch (err) {
			if (ctx.hasUI) ctx.ui.notify(`pi-coms: failed to start server: ${(err as Error).message}`, "error");
			return;
		}
		installExitHook();
		installPoolWidget(ctx);

		const freshLaunch = event.reason === "startup" || event.reason === "new";
		if (!freshLaunch) {
			finalizeIdentity(undefined, ctx);
			return;
		}

		deferTimer = setTimeout(() => {
			deferTimer = undefined;
			finalizeIdentity(undefined, ctx);
		}, IDENTITY_DEFER_MS);
		if (typeof deferTimer.unref === "function") deferTimer.unref();
	});

	pi.on("input", async (event, ctx) => {
		if (identityFinalized) return;
		// Identity should reflect the human's launching turn, not a /command another
		// extension synthesized. Let the defer timer finalize from CLI + defaults instead.
		if (event.source === "extension") return;
		const m = event.text.match(TEMPLATE_INVOCATION);
		finalizeIdentity(m?.[1], ctx ?? currentCtx);
	});

	pi.on("session_shutdown", async () => {
		await shutdownClean();
	});

	pi.registerTool({
		name: "coms_list",
		label: "List Coms Peers",
		description:
			"List other pi sessions on the local coms bus. Defaults to the current project; pass project='all' to list every project, or a specific project key to scope elsewhere. Each peer includes its current pool status (online/stale/gone).",
		promptSnippet:
			"coms_list discovers other pi sessions reachable on this machine, by default scoped to the current project, with live pool status.",
		promptGuidelines: [
			"Call coms_list before coms_send to look up peer handles.",
			"Pass project='all' to coms_list when you need to reach a session outside the current project.",
			"Prefer peers with status='online'. A 'stale' peer may still respond; a 'gone' peer almost certainly won't.",
		],
		parameters: Type.Object({
			project: Type.Optional(
				Type.String({
					description:
						"Project key to scope the listing to. Default = current project. Use 'all' to list every project on this machine.",
				}),
			),
		}),
		async execute(_toolCallId, params) {
			const scope = (params.project ?? "current") as "current" | "all" | string;
			const peers = listPeersScoped(scope);
			const enriched = peers.map((p) => {
				const entry = pool.get(peerHandle(p));
				return { peer: p, status: entry?.status ?? "stale", lastPongAt: entry?.lastPongAt };
			});
			if (enriched.length === 0) {
				const where = scope === "current" ? "the current project" : scope === "all" ? "the coms bus" : `project ${scope}`;
				return { content: [{ type: "text", text: `No other pi sessions in ${where}.` }], details: undefined };
			}
			const lines = enriched.map(
				({ peer, status, lastPongAt }) =>
					`- handle: ${peerHandle(peer)}\n  name: ${peer.name}\n  project: ${peer.project}\n  cwd: ${peer.projectPath}\n  pid: ${peer.pid}\n  status: ${status}${lastPongAt ? `\n  last_pong_at: ${new Date(lastPongAt).toISOString()}` : ""}\n  started_at: ${new Date(peer.startedAt).toISOString()}`,
			);
			return {
				content: [
					{
						type: "text",
						text: `Pi coms peers (${scope === "current" ? `project ${project}` : scope === "all" ? "all projects" : `project ${scope}`}):\n${lines.join("\n")}`,
					},
				],
				details: { peers: enriched, self: peerHandle(selfInfo()), project },
			};
		},
	});

	pi.registerTool({
		name: "coms_send",
		label: "Send Coms Prompt",
		description:
			"Send a prompt to another pi session over the coms bus. Returns a message_id immediately; the prompt is delivered but this call does not wait for the reply. The outbox entry persists for the life of the session — the reply (or a failure, e.g. the peer going offline) will arrive as a user message when it lands. You do not need to wait or poll.",
		promptSnippet:
			"coms_send delivers a prompt to another local pi session and returns a message_id; the reply is later injected as a user message.",
		promptGuidelines: [
			"Use coms_send when you want to dispatch work to another pi session. After sending, end your turn or keep working on other tasks — the harness will resume the conversation when the reply lands.",
			"Pass a peer handle: a bare name resolves in the current project; use 'project/name' to reach across projects. Discover handles with coms_list.",
			"Do not wait or poll. coms_get exists for explicit state checks but is rarely needed; the reply arrives proactively as a user message.",
		],
		parameters: Type.Object({
			peer: Type.String({
				description:
					"Peer handle. Bare name (e.g. 'alice') resolves in the current project; use '<project>/<name>' to target another project.",
			}),
			prompt: Type.String({ description: "The prompt to send to the other session." }),
		}),
		async execute(_toolCallId, params) {
			const target = resolvePeerHandle(params.peer);
			if (!target) {
				return {
					content: [
						{
							type: "text",
							text: `Peer ${params.peer} not found on the coms bus. Use coms_list to see current peers.`,
						},
					],
					details: undefined,
					isError: true,
				};
			}

			const msgId = crypto.randomUUID();
			const entry: OutboxEntry = {
				msgId,
				target,
				prompt: params.prompt,
				sentAt: Date.now(),
				status: "pending",
			};
			outbox.set(msgId, entry);

			const wireMsg: PromptMessage = { type: "prompt", msgId, from: selfInfo(), content: params.prompt };
			let ack: AckMessage;
			let delivered: PeerInfo = target;
			try {
				const r = await sendWithRetry<AckMessage>(
					params.peer,
					target,
					wireMsg,
					"ack",
					DELIVERY_TIMEOUT_MS,
				);
				ack = r.result;
				delivered = r.target;
				// Re-resolution may have landed on a fresh peerId (peer restarted
				// between our resolvePeerHandle and the first successful send).
				// Update the outbox entry so reply correlation uses the live peer.
				if (delivered.peerId !== target.peerId) {
					entry.target = delivered;
				}
			} catch (err) {
				entry.status = "failed";
				entry.error = (err as Error).message;
				injectResult(entry);
				markPoolGone(peerHandle(target));
				return {
					content: [{ type: "text", text: `Failed to deliver prompt to ${peerHandle(target)}: ${entry.error}` }],
					details: entryDetails(entry),
					isError: true,
				};
			}
			if (!ack.ok) {
				entry.status = "failed";
				entry.error = ack.error ?? "rejected by recipient";
				injectResult(entry);
				return {
					content: [{ type: "text", text: `Peer ${peerHandle(delivered)} rejected the prompt: ${entry.error}` }],
					details: entryDetails(entry),
					isError: true,
				};
			}

			upsertPool(delivered, "online");
			widgetTui?.requestRender();

			return {
				content: [
					{
						type: "text",
						text: `Delivered prompt to ${peerHandle(target)}. message_id=${msgId}\nThe reply will arrive as a user message when it lands; you do not need to wait or poll.`,
					},
				],
				details: entryDetails(entry),
			};
		},
	});

	pi.registerTool({
		name: "coms_get",
		label: "Get Coms Reply Status",
		description:
			"Read the current status (pending, replied, failed) of a message previously sent with coms_send. Diagnostic only — replies are delivered proactively as injected user messages, so polling is rarely required.",
		promptSnippet:
			"coms_get reads the current state of a sent pi-coms prompt. Replies arrive proactively as user messages; coms_get is for explicit state checks.",
		promptGuidelines: [
			"Under normal flow you do NOT need coms_get — a reply to your coms_send is injected as a user message automatically when it lands.",
			"Use coms_get only for explicit state checks (e.g. confirming a send is still pending vs already-resolved-but-not-yet-acted-on).",
		],
		parameters: Type.Object({
			message_id: Type.String({ description: "The message_id returned by coms_send." }),
		}),
		async execute(_toolCallId, params) {
			const entry = outbox.get(params.message_id);
			if (!entry) {
				return {
					content: [{ type: "text", text: `No sent message with id ${params.message_id} in this session.` }],
					details: undefined,
					isError: true,
				};
			}
			return { content: [{ type: "text", text: describeEntry(entry) }], details: entryDetails(entry) };
		},
	});

	pi.registerTool({
		name: "coms_end",
		label: "End Coms Prompt (reply)",
		description:
			"Reply to an incoming prompt that another pi session sent to this session via the coms bus. This ends the request from the sender's side.",
		promptSnippet:
			"coms_end sends the final reply back to a pi session that previously prompted us. Call it exactly once per incoming prompt.",
		promptGuidelines: [
			"Call coms_end exactly once per incoming pi-coms prompt, using the message_id from the original prompt.",
			"coms_end ends the request on the sender's side; do not call it before you have a final answer.",
		],
		parameters: Type.Object({
			message_id: Type.String({ description: "The message_id from the incoming prompt." }),
			reply: Type.String({ description: "The final reply to send back to the other session." }),
		}),
		async execute(_toolCallId, params) {
			const sender = inbox.get(params.message_id);
			if (!sender) {
				return {
					content: [
						{
							type: "text",
							text: `No incoming prompt found with message id ${params.message_id}. It may already have been replied to, or this session may have restarted since the prompt arrived.`,
						},
					],
					details: undefined,
					isError: true,
				};
			}

			const live = resolvePeerHandle(peerHandle(sender));
			const target = live ?? sender;
			if (!endpointExists(target.socket)) {
				inbox.delete(params.message_id);
				markPoolGone(peerHandle(sender));
				return {
					content: [
						{
							type: "text",
							text: `Sender ${peerHandle(sender)} is no longer reachable; their endpoint is gone.`,
						},
					],
					details: undefined,
					isError: true,
				};
			}

			const replyMsg: ReplyMessage = {
				type: "reply",
				msgId: crypto.randomUUID(),
				inReplyTo: params.message_id,
				from: selfInfo(),
				content: params.reply,
			};
			try {
				const { result: ack, target: deliveredTo } = await sendWithRetry<AckMessage>(
					peerHandle(sender),
					target,
					replyMsg,
					"ack",
					DELIVERY_TIMEOUT_MS,
				);
				if (!ack.ok) {
					return {
						content: [{ type: "text", text: `Sender rejected the reply: ${ack.error ?? "unknown error"}` }],
						details: undefined,
						isError: true,
					};
				}
				inbox.delete(params.message_id);
				upsertPool(deliveredTo, "online");
				widgetTui?.requestRender();
				return {
					content: [{ type: "text", text: `Reply delivered to ${peerHandle(sender)}.` }],
					details: { to: peerHandle(sender), reply_message_id: replyMsg.msgId },
				};
			} catch (err) {
				markPoolGone(peerHandle(sender));
				return {
					content: [{ type: "text", text: `Failed to deliver reply: ${(err as Error).message}` }],
					details: undefined,
					isError: true,
				};
			}
		},
	});

	pi.registerCommand("coms", {
		description:
			"List other pi sessions in the current project. '/coms all' lists every project; '/coms reconnect' forces an immediate discover + ping sweep.",
		handler: async (args, ctx) => {
			const arg = args.trim();
			if (arg === "reconnect" || arg === "refresh") {
				await runTick();
				await runRecovery();
				const peers = listPeersScoped("current");
				const lines = peers.map((p) => {
					const status = pool.get(peerHandle(p))?.status ?? "stale";
					return `${peerHandle(p)}  status=${status}  pid=${p.pid}`;
				});
				const body = lines.length === 0 ? "(no other peers in this project)" : lines.join("\n");
				ctx.ui.notify(`pi-coms: forced reconnect complete.\n${body}`, "info");
				return;
			}
			const scope = arg === "all" ? "all" : "current";
			const peers = listPeersScoped(scope);
			if (peers.length === 0) {
				ctx.ui.notify(scope === "all" ? "No other pi sessions on the coms bus." : "No other peers in this project.", "info");
				return;
			}
			const lines = peers.map((p) => {
				const status = pool.get(peerHandle(p))?.status ?? "stale";
				return `${peerHandle(p)}  status=${status}  cwd=${p.projectPath}  pid=${p.pid}`;
			});
			ctx.ui.notify(`Pi coms peers:\n${lines.join("\n")}`, "info");
		},
	});

}

function formatIncomingPrompt(msg: PromptMessage): string {
	return [
		`📨 Incoming pi-coms prompt from **${msg.from.project}/${msg.from.name}** (peer_id \`${msg.from.peerId}\`).`,
		`Message id: \`${msg.msgId}\``,
		`Sender cwd: \`${msg.from.projectPath}\``,
		``,
		`--- Prompt ---`,
		msg.content,
		`--- End prompt ---`,
		``,
		`Work through this as you would any task. When you have a final answer, call the \`coms_end\` tool with \`message_id="${msg.msgId}"\` and your reply text. The sender is waiting on that reply.`,
	].join("\n");
}
