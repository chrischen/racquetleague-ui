#!/usr/bin/env node
// Precompute a matchmaking-lab run and save it for the UI to load.
//
//   yarn lab:precompute                       # the reference run
//   LAB_ROUNDS=20 LAB_SEEDS=2 yarn lab:precompute
//
// The reference run — cold start, 24 players, 4 courts, 100 rounds, 7 seeds —
// is 18,900 solver calls at ~340 ms each: about 108 minutes in one process.
// Seeds are independent, so each one is forked off on its own and the results
// are merged at the end, which brings the wall clock down to roughly one
// seed's worth plus contention.
//
// Everything the worker needs arrives through the environment (see
// `scripts/precompute-lab-run.ts` for the full list); this file only decides
// how many run at once.
import { spawn } from "node:child_process";
import { cpus } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const vitest = join(root, "node_modules/.bin/vitest");
const configPath = "scripts/lab-precompute.config.ts";

const seedCount = Number(process.env.LAB_SEEDS ?? 7);
// Each fork pins a core with WASM and holds the run in memory. Half the cores
// leaves the machine usable and keeps the shards from thrashing each other.
const lanes = Math.max(1, Math.min(seedCount, Number(process.env.LAB_LANES ?? Math.floor(cpus().length / 2))));

const runVitest = (env, tag) =>
  new Promise((resolve, reject) => {
    const child = spawn(vitest, ["run", "--config", configPath], {
      cwd: root,
      env: { ...process.env, ...env },
      stdio: ["ignore", "inherit", "inherit"],
    });
    child.on("error", reject);
    child.on("close", (code) =>
      code === 0 ? resolve() : reject(new Error(`${tag} failed (exit ${code})`)),
    );
  });

const started = Date.now();
console.log(`precomputing ${seedCount} seeds across ${lanes} lanes`);

// A worklist rather than fixed slices: seeds take slightly different times and
// an idle lane at the end is wasted wall clock.
const queue = Array.from({ length: seedCount }, (_, i) => i);
await Promise.all(
  Array.from({ length: lanes }, async () => {
    for (let seedIndex = queue.shift(); seedIndex !== undefined; seedIndex = queue.shift()) {
      await runVitest({ LAB_SEED_INDEX: String(seedIndex) }, `seed ${seedIndex}`);
    }
  }),
);

await runVitest({ LAB_MERGE: "1" }, "merge");
console.log(`done in ${((Date.now() - started) / 60000).toFixed(1)} minutes`);
