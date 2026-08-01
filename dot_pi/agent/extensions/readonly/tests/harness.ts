/**
 * Minimal in-process test harness. No mocking libraries: tests use real fs
 * (tmpdir) and real module imports.
 */

type TestFn = () => void | Promise<void>;
type Registered = { name: string; fn: TestFn };

const REGISTRY: Registered[] = [];

export function test(name: string, fn: TestFn): void {
	REGISTRY.push({ name, fn });
}

export function assert(cond: unknown, msg: string): asserts cond {
	if (!cond) throw new Error(`assertion failed: ${msg}`);
}

export function assertEqual<T>(actual: T, expected: T, msg: string): void {
	if (actual !== expected) {
		throw new Error(
			`assertion failed: ${msg} (got ${JSON.stringify(actual)}, expected ${JSON.stringify(expected)})`,
		);
	}
}

export function assertDeepEqual(actual: unknown, expected: unknown, msg: string): void {
	const a = JSON.stringify(actual);
	const b = JSON.stringify(expected);
	if (a !== b) {
		throw new Error(`assertion failed: ${msg} (got ${a}, expected ${b})`);
	}
}

export async function runRegistered(): Promise<number> {
	let pass = 0;
	let fail = 0;
	for (const t of REGISTRY) {
		try {
			await t.fn();
			console.log(`  ok   ${t.name}`);
			pass++;
		} catch (err) {
			fail++;
			const msg = err instanceof Error ? err.stack ?? err.message : String(err);
			console.log(`  FAIL ${t.name}\n         ${msg.split("\n").join("\n         ")}`);
		}
	}
	console.log(`\n${pass} passed, ${fail} failed (${REGISTRY.length} total)`);
	return fail;
}
