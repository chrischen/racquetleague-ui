#!/usr/bin/env node
// Role-streak experiment: does always being favored (or unfavored) bias a
// player's rating, with partners still rotating?
//
//   yarn lab:role-probe                                   # typical field, median player, 7 seeds
//   LAB_TARGETS=median,strongest,weakest yarn lab:role-probe
//   ROLE_MODE=observe yarn lab:role-probe                 # saved run only, no solving
//   ROLE_MODE=streaks yarn lab:role-probe                 # natural streaks from cold start
//   ROLE_MODE=catchup yarn lab:role-probe                 # streaks while a returning player catches up
//   LAB_ROUNDS=10 LAB_SEEDS=1 LAB_LANES=1 yarn lab:role-probe   # smoke test
//
// Seeds are independent, so each runs in its own fork; a merge pass pairs
// every arm with its baseline. Results land in
// node_modules/.cache/matchmaking-lab/role-probe/.
import { spawn } from "node:child_process";
import { cpus } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const vitest = join(root, "node_modules/.bin/vitest");
const configPath = "scripts/role-probe.config.ts";

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
const seedMode = { streaks: "streak-seed", catchup: "catchup-seed" }[process.env.ROLE_MODE] ?? "seed";
const mergeMode = { streaks: "streak-merge", catchup: "catchup-merge" }[process.env.ROLE_MODE] ?? "merge";
if (process.env.ROLE_MODE === "observe") {
  await runVitest({ ROLE_MODE: "observe" }, "observe");
} else {
  const seedCount = Number(process.env.LAB_SEEDS ?? 7);
  // Half the cores: more lanes push rounds into the solver's 1 s time limit.
  const lanes = Math.max(1, Math.min(seedCount, Number(process.env.LAB_LANES ?? Math.floor(cpus().length / 2))));
  console.log(`role probe: ${seedCount} seeds across ${lanes} lanes`);
  const queue = Array.from({ length: seedCount }, (_, i) => i);
  await Promise.all(
    Array.from({ length: lanes }, async () => {
      for (let i = queue.shift(); i !== undefined; i = queue.shift()) {
        await runVitest({ ROLE_MODE: seedMode, ROLE_SEED_INDEX: String(i) }, `seed ${i}`);
      }
    }),
  );
  await runVitest({ ROLE_MODE: mergeMode }, "merge");
}
console.log(`done in ${((Date.now() - started) / 60000).toFixed(1)} minutes`);
