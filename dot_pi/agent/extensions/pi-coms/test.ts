/**
 * Real-socket integration tests for pi-coms's auto-injection delivery model.
 *
 * Two or three extension instances run in this same process, each with its
 * own factory closure (outbox/inbox/pool). Sockets are UUID-based; registration
 * files live under ~/.pi/coms/projects/<unique-per-test>/agents/ and are
 * cleaned up at the end.
 *
 * No mocks. Real net.createServer, real setTimeout, real fs. Each test has a
 * 5s wall-clock cap so a regression hangs the test, not the suite.
 *
 * Run: bun run test.ts
 */

import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";
import type {
	ExtensionAPI,
	ExtensionContext,
	ExtensionHandler,
	SessionStartEvent,
	ToolDefinition,
} from "@earendil-works/pi-coding-agent";

import comsFactory from "./index.ts";

const COMS_DIR = path.join(os.homedir(), ".pi", "coms");
const PROJECTS_DIR = path.join(COMS_DIR, "projects");

type RecordedUserMessage = { text: string; deliverAs?: "steer" | "followUp" };

class FakeEventBus {
	private listeners = new Map<string, Set<(data: unknown) => void>>();
	on(channel: string, handler: (data: unknown) => void): () => void {
		const set = this.listeners.get(channel) ?? new Set();
		set.add(handler);
		this.listeners.set(channel, set);
		return () => set.delete(handler);
	}
	emit(channel: string, data: unknown) {
		for (const h of this.listeners.get(channel) ?? []) {
			try {
				h(data);
			} catch {}
		}
	}
}

class FakePi {
	tools = new Map<string, ToolDefinition<any, any, any>>();
	flags = new Map<string, string | boolean>();
	flagDefaults = new Map<string, string | boolean | undefined>();
	handlers = new Map<string, ExtensionHandler<any, any>[]>();
	userMessages: RecordedUserMessage[] = [];
	events = new FakeEventBus();

	on(event: string, handler: ExtensionHandler<any, any>) {
		const list = this.handlers.get(event) ?? [];
		list.push(handler);
		this.handlers.set(event, list);
	}

	registerTool(def: ToolDefinition<any, any, any>) {
		this.tools.set(def.name, def);
	}

	registerCommand() {}
	registerShortcut() {}
	registerMessageRenderer() {}

	registerFlag(name: string, options: { default?: boolean | string }) {
		this.flagDefaults.set(name, options.default);
	}

	getFlag(name: string): boolean | string | undefined {
		if (this.flags.has(name)) return this.flags.get(name);
		return this.flagDefaults.get(name);
	}

	setFlag(name: string, value: string | boolean) {
		this.flags.set(name, value);
	}

	sendUserMessage(content: string | unknown, options?: { deliverAs?: "steer" | "followUp" }) {
		if (typeof content !== "string") return;
		this.userMessages.push({ text: content, deliverAs: options?.deliverAs });
	}

	sendMessage() {}
	appendEntry() {}
	setSessionName() {}
	getSessionName() {
		return undefined;
	}
	setLabel() {}
	async exec() {
		return { stdout: "", stderr: "", exitCode: 0 } as never;
	}
	getActiveTools(): string[] {
		return [];
	}
	getAllTools(): never[] {
		return [];
	}
	setActiveTools() {}
	getCommands(): never[] {
		return [];
	}
	async setModel() {
		return true;
	}
	getThinkingLevel(): "off" {
		return "off";
	}
	setThinkingLevel() {}
	registerProvider() {}
	unregisterProvider() {}

	async runTool<T = any>(name: string, params: Record<string, unknown>): Promise<{ text: string; details: T; isError?: boolean }> {
		const def = this.tools.get(name);
		if (!def) throw new Error(`tool ${name} not registered`);
		const ctx: ExtensionContext = makeCtx();
		const result = await def.execute(`call-${crypto.randomUUID()}`, params as never, undefined, undefined, ctx);
		const text = (result.content?.[0] as { text?: string })?.text ?? "";
		return {
			text,
			details: (result as { details?: T }).details as T,
			isError: (result as { isError?: boolean }).isError,
		};
	}
}

function makeCtx(): ExtensionContext {
	return {
		hasUI: false,
		ui: {
			notify() {},
			setWidget() {},
		} as never,
		isIdle: () => true,
	} as never;
}

async function startPeer(opts: { name: string; project: string }): Promise<FakePi> {
	const pi = new FakePi();
	pi.setFlag("name", opts.name);
	pi.setFlag("project", opts.project);
	comsFactory(pi as unknown as ExtensionAPI);

	const startHandlers = pi.handlers.get("session_start") ?? [];
	const event: SessionStartEvent = { type: "session_start", reason: "new" };
	for (const h of startHandlers) {
		await h(event, makeCtx());
	}
	const inputHandlers = pi.handlers.get("input") ?? [];
	for (const h of inputHandlers) {
		await h({ type: "input", text: "", source: "interactive" } as never, makeCtx());
	}
	return pi;
}

async function shutdownPeer(pi: FakePi) {
	const handlers = pi.handlers.get("session_shutdown") ?? [];
	for (const h of handlers) {
		await h({ type: "session_shutdown", reason: "quit" } as never, makeCtx());
	}
}

function waitFor(predicate: () => boolean, timeoutMs: number, label: string): Promise<void> {
	const start = Date.now();
	return new Promise((resolve, reject) => {
		const tick = () => {
			if (predicate()) return resolve();
			if (Date.now() - start > timeoutMs) return reject(new Error(`waitFor timed out: ${label}`));
			setTimeout(tick, 10);
		};
		tick();
	});
}

function withDeadline<T>(p: Promise<T>, ms: number, label: string): Promise<T> {
	return Promise.race([
		p,
		new Promise<T>((_, rej) => setTimeout(() => rej(new Error(`deadline exceeded: ${label}`)), ms)),
	]);
}

type Test = { name: string; fn: () => Promise<void> };
const tests: Test[] = [];
function test(name: string, fn: () => Promise<void>) {
	tests.push({ name, fn });
}

function assert(cond: unknown, msg: string): asserts cond {
	if (!cond) throw new Error(`assertion failed: ${msg}`);
}

function assertEqual<T>(actual: T, expected: T, msg: string) {
	if (actual !== expected) throw new Error(`assertion failed: ${msg} (got ${JSON.stringify(actual)}, expected ${JSON.stringify(expected)})`);
}

function newProject(label: string) {
	return `t-${label}-${crypto.randomBytes(4).toString("hex")}`;
}

function cleanupProject(project: string) {
	const dir = path.join(PROJECTS_DIR, project);
	try {
		fs.rmSync(dir, { recursive: true, force: true });
	} catch {}
}

const RESULT_PREFIX = "📬 Reply received via pi-coms";
const INBOUND_PREFIX = "📨 Incoming pi-coms prompt";

function results(pi: FakePi): RecordedUserMessage[] {
	return pi.userMessages.filter((m) => m.text.includes(RESULT_PREFIX));
}

function inbounds(pi: FakePi): RecordedUserMessage[] {
	return pi.userMessages.filter((m) => m.text.includes(INBOUND_PREFIX));
}

function parseInboxMsgId(text: string): string {
	const m = text.match(/Message id: `([^`]+)`/);
	if (!m) throw new Error(`could not parse msgId from: ${text.slice(0, 120)}`);
	return m[1];
}

type FakePeerInfo = {
	project: string;
	projectPath: string;
	name: string;
	peerId: string;
	pid: number;
	socket: string;
	startedAt: number;
	lastSeen: number;
};

type FakePeer = {
	info: FakePeerInfo;
	regPath: string;
	sockPath: string;
	server?: net.Server;
};

// Synthetic peer used to exercise scenarios that require fine control over
// reachability (start listening / stop listening / replace socket with regular
// file / etc.) without instantiating a full pi-coms session.
async function startFakePeer(name: string, project: string): Promise<FakePeer> {
	const peerId = crypto.randomUUID();
	const sockPath = path.join(COMS_DIR, "sockets", `fake-${peerId}.sock`);
	const info: FakePeerInfo = {
		project,
		projectPath: path.resolve(process.cwd()),
		name,
		peerId,
		pid: process.pid,
		socket: sockPath,
		startedAt: Date.now(),
		lastSeen: Date.now(),
	};
	const regPath = path.join(PROJECTS_DIR, project, "agents", `${name}.json`);
	fs.mkdirSync(path.dirname(sockPath), { recursive: true });
	fs.mkdirSync(path.dirname(regPath), { recursive: true });
	fs.writeFileSync(regPath, JSON.stringify(info, null, 2));
	const fp: FakePeer = { info, regPath, sockPath };
	await listenFakePeer(fp);
	return fp;
}

async function listenFakePeer(fp: FakePeer): Promise<void> {
	try { fs.unlinkSync(fp.sockPath); } catch {}
	const server = net.createServer((sock) => {
		sock.setEncoding("utf-8");
		let buf = "";
		sock.on("data", (chunk: string) => {
			buf += chunk;
			const idx = buf.indexOf("\n");
			if (idx < 0) return;
			const line = buf.slice(0, idx);
			try {
				const msg = JSON.parse(line) as { type?: string };
				if (msg.type === "ping") {
					sock.write(`${JSON.stringify({ type: "pong", from: fp.info })}\n`);
				} else {
					sock.write(`${JSON.stringify({ type: "ack", ok: true })}\n`);
				}
			} catch {
				sock.write(`${JSON.stringify({ type: "ack", ok: false, error: "bad" })}\n`);
			}
			sock.end();
		});
		sock.on("error", () => {});
	});
	await new Promise<void>((resolve, reject) => {
		server.once("error", reject);
		server.listen(fp.sockPath, () => {
			server.off("error", reject);
			resolve();
		});
	});
	fp.server = server;
}

// Stop the fake server. When keepSocketFile=true, leaves a regular file at the
// socket path so endpointExists() still returns true (peer "looks alive") but
// any connect() attempt fails. That's the unreachable-but-registered scenario
// the sticky-pool / retry / recovery tests need.
async function stopFakePeerListener(fp: FakePeer, keepSocketFile: boolean): Promise<void> {
	if (fp.server) {
		await new Promise<void>((res) => fp.server!.close(() => res()));
		fp.server = undefined;
	}
	try { fs.unlinkSync(fp.sockPath); } catch {}
	if (keepSocketFile) {
		fs.writeFileSync(fp.sockPath, "");
	}
}

function refreshFakeHeartbeat(fp: FakePeer) {
	fp.info.lastSeen = Date.now();
	fs.writeFileSync(fp.regPath, JSON.stringify(fp.info, null, 2));
}

async function cleanupFakePeer(fp: FakePeer): Promise<void> {
	await stopFakePeerListener(fp, false);
	try { fs.unlinkSync(fp.regPath); } catch {}
}

// ─── Test 1: Send-and-auto-deliver ──────────────────────────────────────────
test("coms_send + B replies → A receives result injection with msgId + reply content", async () => {
	const project = newProject("send-deliver");
	const a = await startPeer({ name: "alice", project });
	const b = await startPeer({ name: "bob", project });

	const sendA = await a.runTool<{ message_id: string }>("coms_send", { peer: `${project}/bob`, prompt: "hi" });
	const msgId = sendA.details.message_id;
	assert(sendA.text.includes("Delivered prompt"), "tool returns delivery confirmation");
	assert(sendA.text.includes("don't need to wait or poll") || sendA.text.includes("do not need to wait"), "steer text present");

	await new Promise((r) => setTimeout(r, 30));
	const bMsgId = parseInboxMsgId(inbounds(b)[0].text);
	await b.runTool("coms_end", { message_id: bMsgId, reply: "pong" });

	await waitFor(() => results(a).length >= 1, 2_000, "A receives result injection");
	const injected = results(a);
	assertEqual(injected.length, 1, "exactly one result injection");
	assert(injected[0].text.includes(msgId), "injection carries the original msgId");
	assert(injected[0].text.includes("pong"), "injection carries the reply content");
	assert(injected[0].text.includes("status=replied"), "injection reflects replied status");

	await shutdownPeer(a);
	await shutdownPeer(b);
	cleanupProject(project);
});

// ─── Test 2: Send-fails-synchronously injects ───────────────────────────────
test("coms_send to nonexistent peer returns isError AND injects failure result", async () => {
	const project = newProject("send-fails-resolve");
	const a = await startPeer({ name: "alice", project });

	// Peer is unknown — resolve fails before any wire send. That path doesn't
	// produce an outbox entry (and therefore no injection); it's the early
	// "not found" branch. Assert that case independently.
	const sendNotFound = await a.runTool("coms_send", { peer: `${project}/nope`, prompt: "x" });
	assertEqual(sendNotFound.isError, true, "unknown-peer send returns isError");
	assertEqual(results(a).length, 0, "unknown-peer send does NOT inject (no outbox entry)");

	// Now the real "connect-fails AFTER outbox entry exists" path: register a
	// peer, then shut down its server but reconstruct a non-socket file at the
	// socket path so `isRegistrationLive` sees a present endpoint and the
	// resolver hands the PeerInfo back. The connect inside sendToPeer then
	// fails (regular file, not a listening socket), exercising the catch block
	// inside coms_send.execute that mutates the entry to `failed` and injects.
	const b = await startPeer({ name: "bob", project });
	const bRegPath = path.join(PROJECTS_DIR, project, "agents", "bob.json");
	const bInfo = JSON.parse(fs.readFileSync(bRegPath, "utf-8"));
	await shutdownPeer(b);
	fs.mkdirSync(path.dirname(bRegPath), { recursive: true });
	fs.writeFileSync(bRegPath, JSON.stringify(bInfo, null, 2));
	fs.writeFileSync(bInfo.socket, "");

	const sendStale = await a.runTool<{ message_id: string }>("coms_send", { peer: `${project}/bob`, prompt: "y" });
	assertEqual(sendStale.isError, true, "stale-peer send returns isError");
	await waitFor(() => results(a).length === 1, 1_000, "stale-peer send injects failure");
	const fail = results(a)[0];
	assert(fail.text.includes(sendStale.details.message_id), "injection carries the failed msgId");
	assert(fail.text.includes("status=failed"), "injection reflects failed status");

	// Clean up the bogus socket file we created.
	try { fs.unlinkSync(bInfo.socket); } catch {}

	await shutdownPeer(a);
	cleanupProject(project);
});

// ─── Test 3: Multiple outstanding sends, replies arbitrary order ────────────
test("two concurrent outstanding sends; replies in C-then-B order; each result keyed by msgId", async () => {
	const project = newProject("multi");
	const a = await startPeer({ name: "alice", project });
	const b = await startPeer({ name: "bob", project });
	const c = await startPeer({ name: "carol", project });

	const m1 = (await a.runTool<{ message_id: string }>("coms_send", { peer: `${project}/bob`, prompt: "to-b" })).details.message_id;
	const m2 = (await a.runTool<{ message_id: string }>("coms_send", { peer: `${project}/carol`, prompt: "to-c" })).details.message_id;

	await new Promise((r) => setTimeout(r, 30));
	const cMsgId = parseInboxMsgId(inbounds(c)[0].text);
	await c.runTool("coms_end", { message_id: cMsgId, reply: "carol-reply" });

	await waitFor(() => results(a).length >= 1, 1_500, "first result lands");

	const bMsgId = parseInboxMsgId(inbounds(b)[0].text);
	await b.runTool("coms_end", { message_id: bMsgId, reply: "bob-reply" });

	await waitFor(() => results(a).length >= 2, 1_500, "second result lands");

	const injected = results(a);
	assertEqual(injected.length, 2, "exactly two result injections");
	const m1Match = injected.find((m) => m.text.includes(m1));
	const m2Match = injected.find((m) => m.text.includes(m2));
	assert(m1Match, "m1 result injection found");
	assert(m2Match, "m2 result injection found");
	assert(m1Match.text.includes("bob-reply") && !m1Match.text.includes("carol-reply"), "m1 carries bob's reply, not carol's");
	assert(m2Match.text.includes("carol-reply") && !m2Match.text.includes("bob-reply"), "m2 carries carol's reply, not bob's");

	await shutdownPeer(a);
	await shutdownPeer(b);
	await shutdownPeer(c);
	cleanupProject(project);
});

// ─── Test 4: Peer-goes-gone marks in-flight failed ──────────────────────────
test("peer eviction (shutdown + force-tick) terminalizes in-flight outbox + injects failure", async () => {
	const project = newProject("peer-gone");
	const a = await startPeer({ name: "alice", project });
	const b = await startPeer({ name: "bob", project });

	const sendA = await a.runTool<{ message_id: string }>("coms_send", { peer: `${project}/bob`, prompt: "knock" });
	const msgId = sendA.details.message_id;
	assertEqual(results(a).length, 0, "no result yet (B still up)");

	// Clean shutdown: removes B's registration. Next forced tick on A should
	// see B's registration gone, prune the pool entry, and terminalize A's
	// outbox entry targeting B's peerId.
	await shutdownPeer(b);
	a.events.emit("pi-coms:force-tick", undefined);

	await waitFor(() => results(a).length === 1, 1_500, "A receives peer-gone failure injection");
	const fail = results(a)[0];
	assert(fail.text.includes(msgId), "failure carries the original msgId");
	assert(fail.text.includes("status=failed"), "status=failed");
	assert(fail.text.includes("peer went offline"), "error text mentions peer offline");

	await shutdownPeer(a);
	cleanupProject(project);
});

// ─── Test 5: coms_get reflects current state ────────────────────────────────
test("coms_get returns pending before reply, replied after; injection happens in between", async () => {
	const project = newProject("get");
	const a = await startPeer({ name: "alice", project });
	const b = await startPeer({ name: "bob", project });

	const sendA = await a.runTool<{ message_id: string }>("coms_send", { peer: `${project}/bob`, prompt: "ping" });
	const msgId = sendA.details.message_id;

	const before = await a.runTool<{ status?: string }>("coms_get", { message_id: msgId });
	assertEqual(before.details.status, "pending", "pre-reply status=pending");

	await new Promise((r) => setTimeout(r, 30));
	const bMsgId = parseInboxMsgId(inbounds(b)[0].text);
	await b.runTool("coms_end", { message_id: bMsgId, reply: "pong" });

	await waitFor(() => results(a).length === 1, 1_500, "result injection landed");

	const after = await a.runTool<{ status?: string }>("coms_get", { message_id: msgId });
	assertEqual(after.details.status, "replied", "post-reply status=replied");
	assert(after.text.includes("pong"), "coms_get text echoes the reply content");

	await shutdownPeer(a);
	await shutdownPeer(b);
	cleanupProject(project);
});

// ─── Test 6: coms_await is no longer registered ─────────────────────────────
test("coms_await is not registered as a tool after factory load", async () => {
	const project = newProject("no-await");
	const a = await startPeer({ name: "alice", project });

	assertEqual(a.tools.has("coms_await"), false, "coms_await is not registered");
	assertEqual(a.tools.has("coms_send"), true, "coms_send is still registered");
	assertEqual(a.tools.has("coms_get"), true, "coms_get is still registered");
	assertEqual(a.tools.has("coms_end"), true, "coms_end is still registered");
	assertEqual(a.tools.has("coms_list"), true, "coms_list is still registered");

	await shutdownPeer(a);
	cleanupProject(project);
});

// ─── Test 7: Sticky pool when peer looks alive but socket is dead ────────
test("transient unreachability does not evict pool entry or fail outbox while registration is alive", async () => {
	const project = newProject("sticky-pool");
	const a = await startPeer({ name: "alice", project });
	const fp = await startFakePeer("bob", project);

	// Healthy send populates A's pool with bob as online.
	const send = await a.runTool<{ message_id: string }>("coms_send", { peer: `${project}/bob`, prompt: "knock" });
	assertEqual(send.isError, undefined, "initial send succeeded against the fake peer");
	const msgId = send.details.message_id;

	// Replace bob's listener with a regular file. endpointExists() still
	// returns true; processAlive() returns true (it's our pid); lastSeen is
	// fresh — so the registration looks live, but connect() fails.
	await stopFakePeerListener(fp, true);

	// Hammer the tick. Pre-fix, after POOL_RETAIN_AFTER_GONE_TICKS=3 ticks the
	// entry would be evicted and the outbox would be terminalized as failed.
	for (let i = 0; i < 6; i++) {
		refreshFakeHeartbeat(fp);
		a.events.emit("pi-coms:force-tick", undefined);
		await new Promise((r) => setTimeout(r, 30));
	}

	assertEqual(results(a).length, 0, "no failure injection while registration is still alive");
	const get = await a.runTool<{ status?: string }>("coms_get", { message_id: msgId });
	assertEqual(get.details.status, "pending", "outbox stays pending across many failed pings");

	// Bob is still listed (registration file present).
	const list = await a.runTool<{ peers: Array<{ peer: { name: string } }> }>("coms_list", {});
	assert(
		list.details.peers.some((p) => p.peer.name === "bob"),
		"bob still appears in coms_list while registration is alive",
	);

	await cleanupFakePeer(fp);
	await shutdownPeer(a);
	cleanupProject(project);
});

// ─── Test 8: Recovery loop restores a peer when it becomes reachable again ──
test("recovery loop brings a peer back online once its socket is listening again", async () => {
	const project = newProject("recovery");
	const a = await startPeer({ name: "alice", project });
	const fp = await startFakePeer("bob", project);

	// Populate A's pool with bob via a healthy round-trip.
	const firstSend = await a.runTool("coms_send", { peer: `${project}/bob`, prompt: "hello" });
	assertEqual(firstSend.isError, undefined, "initial send succeeded");

	// Take bob offline (registration looks alive, but no listener).
	await stopFakePeerListener(fp, true);
	refreshFakeHeartbeat(fp);
	a.events.emit("pi-coms:force-tick", undefined);
	await new Promise((r) => setTimeout(r, 50));

	// Restart bob's listener. No external signal to A — only the recovery
	// loop's probing should bring bob back to online.
	await listenFakePeer(fp);
	refreshFakeHeartbeat(fp);
	a.events.emit("pi-coms:force-recovery", undefined);
	await new Promise((r) => setTimeout(r, 100));

	// Subsequent send should go through without retry pain.
	const secondSend = await a.runTool("coms_send", { peer: `${project}/bob`, prompt: "again" });
	assertEqual(secondSend.isError, undefined, "send after recovery succeeded");
	assertEqual(results(a).length, 0, "no failure injections across the down/up cycle");

	await cleanupFakePeer(fp);
	await shutdownPeer(a);
	cleanupProject(project);
});

// ─── Test 9: coms_send retries through a brief reachability gap ───────────
test("coms_send retries on transient connect failure and ultimately succeeds", async () => {
	const project = newProject("send-retry");
	const a = await startPeer({ name: "alice", project });
	const fp = await startFakePeer("bob", project);

	// First connect attempt will fail (no listener, but socket file present).
	await stopFakePeerListener(fp, true);
	refreshFakeHeartbeat(fp);

	// Bring bob back well within SEND_RETRY_TOTAL_MS so sendWithRetry can land.
	const restart = setTimeout(() => {
		void (async () => {
			await listenFakePeer(fp);
			refreshFakeHeartbeat(fp);
		})();
	}, 400);

	const send = await a.runTool("coms_send", { peer: `${project}/bob`, prompt: "knock" });
	clearTimeout(restart);
	assertEqual(send.isError, undefined, "send eventually succeeded via retry");
	assertEqual(results(a).length, 0, "no failure injection on a successful retry");

	await cleanupFakePeer(fp);
	await shutdownPeer(a);
	cleanupProject(project);
});

// ─── Test 10: Peer restart under same handle terminalizes old outbox ──────
test("peer restarting under same handle fails outbox to old peerId and accepts sends to the new one", async () => {
	const project = newProject("peer-restart");
	const a = await startPeer({ name: "alice", project });
	const b1 = await startPeer({ name: "bob", project });

	const send = await a.runTool<{ message_id: string }>("coms_send", { peer: `${project}/bob`, prompt: "hi" });
	assertEqual(send.isError, undefined, "send to bob1 succeeded");
	const msgId = send.details.message_id;

	// bob1 exits cleanly; bob2 boots under the same handle with a new peerId.
	await shutdownPeer(b1);
	const b2 = await startPeer({ name: "bob", project });

	a.events.emit("pi-coms:force-tick", undefined);

	await waitFor(() => results(a).length === 1, 1_500, "A receives failure injection for the old peerId");
	const fail = results(a)[0];
	assert(fail.text.includes(msgId), "failure injection references the original msgId");
	assert(fail.text.includes("status=failed"), "injection reflects failed status");
	assert(fail.text.includes("peer went offline"), "failure cites peer-offline");

	// New send to the same handle resolves to bob2.
	const resend = await a.runTool("coms_send", { peer: `${project}/bob`, prompt: "hi-take-2" });
	assertEqual(resend.isError, undefined, "send to bob2 succeeded");

	await shutdownPeer(a);
	await shutdownPeer(b2);
	cleanupProject(project);
});

async function main() {
	let passed = 0;
	let failed = 0;
	for (const t of tests) {
		try {
			await withDeadline(t.fn(), 5_000, `test "${t.name}" overall deadline`);
			console.log(`PASS  ${t.name}`);
			passed++;
		} catch (err) {
			console.error(`FAIL  ${t.name}\n      ${(err as Error).message}`);
			failed++;
		}
	}
	console.log(`\n${passed} passed, ${failed} failed`);
	process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
	console.error(err);
	process.exit(1);
});
