/**
 * Harness entry point for the readonly extension's unit tests.
 *
 * Aggregates and runs all unit tests. (Acceptable helper per
 * implementation review; spec §10 lists the four test files, this file
 * plus tests/harness.ts are scaffolding only.)
 *
 * Usage:
 *   bun run tests/run.ts
 *   # or
 *   node --experimental-strip-types tests/run.ts
 */

import { runRegistered } from "./harness.ts";

import "./settings.test.ts";
import "./state.test.ts";
import "./auth.test.ts";
import "./whitelist.test.ts";
import "./strip.test.ts";

runRegistered().then((failures) => {
	process.exit(failures > 0 ? 1 : 0);
});
