// The worker half of `yarn lab:precompute`. Run it through
// `scripts/lab-precompute.mjs`, not directly.
//
// This is shaped as a vitest file because that is the only runner in the repo
// that resolves the ReScript build output: `SimLab.re.mjs` imports its
// neighbours without extensions, which needs Vite's resolver, and `vite-node`
// externalises `.mjs` before it gets there. It has its own config
// (`scripts/lab-precompute.config.ts`) so `yarn test` never picks it up.
//
// Two modes, chosen by env:
//   LAB_SEED_INDEX=<n>  compute one seed (every field) and write a shard
//   LAB_MERGE=1         assemble every shard, encode, gzip, update the manifest
//
// One seed is ~2,700 solves and ~15 minutes, so the orchestrator runs the
// seeds concurrently and merges at the end.
import { describe, expect, it } from "vitest";
import { gzipSync, constants as zlibConstants } from "node:zlib";
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import * as SimLab from "../src/lib/rating/SimLab.re.mjs";
import * as SimLabArchive from "../src/lib/rating/SimLabArchive.re.mjs";

// Vitest runs from the project root, and the orchestrator sets `cwd` too.
const root = process.cwd();
// Shards are bulky (~6 MB each, untrimmed) and disposable — the merge is what
// produces the committed artefact.
const shardDir = join(root, "node_modules/.cache/matchmaking-lab");
const outDir = join(root, "public", SimLabArchive.assetDir);

const env = (key: string, fallback: string) => process.env[key] ?? fallback;
const num = (key: string, fallback: number) => Number(env(key, String(fallback)));

const config = {
  scenario: env("LAB_SCENARIO", "ColdStart"),
  numPlayers: num("LAB_PLAYERS", 24),
  courts: num("LAB_COURTS", 4),
  numRounds: num("LAB_ROUNDS", 100),
  seed: num("LAB_SEED", 1),
  seedCount: num("LAB_SEEDS", 7),
  tournament: env("LAB_TOURNAMENT", "0") === "1",
};

const slug = () =>
  [
    SimLab.scenarioId(config.scenario),
    `${config.numPlayers}p`,
    `${config.courts}c`,
    `${config.numRounds}r`,
    `${config.seedCount}s`,
    config.tournament ? "tourney" : null,
  ]
    .filter(Boolean)
    .join("-");

const shardPath = (seedIndex: number) => join(shardDir, `${slug()}.seed${seedIndex}.json`);

const seedIndexEnv = process.env.LAB_SEED_INDEX;
const merging = process.env.LAB_MERGE === "1";

describe("precompute lab run", () => {
  it.runIf(seedIndexEnv !== undefined)("computes one seed across every field", async () => {
    const seedIndex = Number(seedIndexEnv);
    const seed = config.seed + seedIndex;
    const perField: unknown[] = [];
    const t0 = Date.now();
    let solves = 0;
    const total = config.numRounds * SimLab.strategies.length * SimLab.fields.length;
    for (const field of SimLab.fields) {
      perField.push(
        await SimLab.run(
          config.scenario,
          seed,
          config.numPlayers,
          config.courts,
          config.numRounds,
          field,
          config.tournament,
          () => {
            solves++;
            // One line every 5%, so eight concurrent shards stay readable.
            if (solves % Math.ceil(total / 20) === 0) {
              const mins = (Date.now() - t0) / 60000;
              const eta = (mins / solves) * (total - solves);
              console.log(
                `[seed ${seedIndex}] ${solves}/${total} solves · ${mins.toFixed(1)}m elapsed · ~${eta.toFixed(1)}m left`,
              );
            }
          },
        ),
      );
    }
    mkdirSync(shardDir, { recursive: true });
    writeFileSync(shardPath(seedIndex), JSON.stringify({ seedIndex, seed, perField }));
    console.log(`[seed ${seedIndex}] done in ${((Date.now() - t0) / 60000).toFixed(1)}m`);
    expect(perField.length).toBe(SimLab.fields.length);
  }, 0);

  // Shards are a plain `JSON.stringify` of the run, so they hit the hazard
  // `SimLabArchive.wireFrame` documents: ReScript's `None` is `undefined`, and
  // `undefined` inside an array serialises as `null`. `qualityByBand` is the
  // one such array. Its holes have to be restored before encoding, or a band
  // with no games would round-trip as quality 0 — a round of perfect blowouts.
  const reviveShard = (r: any) => {
    for (const run of r.runs)
      for (const frame of run.frames)
        frame.qualityByBand = frame.qualityByBand.map((v: number | null) =>
          v === null ? undefined : v,
        );
    return r;
  };

  it.runIf(merging)("merges the shards into a saved run", () => {
    // [field][seed] — the order the lab holds in state, and the order the
    // seeds were dealt, so seed 0 of each field is the one keeping detail.
    const byField: unknown[][] = SimLab.fields.map(() => []);
    for (let seedIndex = 0; seedIndex < config.seedCount; seedIndex++) {
      const path = shardPath(seedIndex);
      if (!existsSync(path)) throw new Error(`Missing shard for seed ${seedIndex}: ${path}`);
      const shard = JSON.parse(readFileSync(path, "utf8"));
      shard.perField.forEach((r: unknown, f: number) => byField[f].push(reviveShard(r)));
    }

    const label = [
      `${config.scenario}`,
      `${config.numPlayers} players`,
      `${config.courts} courts`,
      `${config.numRounds} rounds`,
      `${config.seedCount} seeds`,
      config.tournament ? "tournament" : null,
    ]
      .filter(Boolean)
      .join(" · ");

    const json = SimLabArchive.encode(
      byField,
      label,
      config.scenario,
      config.numPlayers,
      config.courts,
      config.numRounds,
      config.seed,
      config.seedCount,
      config.tournament,
      new Date().toISOString(),
    );

    // Round-trip before writing. `encode` is the only producer of this format
    // and `decode` the only consumer, so if they disagree the artefact is
    // worthless and there is no reason to ship it.
    const back = SimLabArchive.decode(json);
    if (back.TAG !== "Ok") throw new Error(`Encoded run does not decode: ${back._0}`);
    expect(back._0.byField.length).toBe(SimLab.fields.length);
    expect(back._0.byField[0].length).toBe(config.seedCount);
    expect(back._0.byField[0][0].runs.length).toBe(SimLab.strategies.length);
    // Detail on the primary seed, none on the rest — the whole reason the file
    // fits.
    expect(back._0.byField[0][0].runs[0].frames.at(-1).games.length).toBe(config.courts);
    if (config.seedCount > 1)
      expect(back._0.byField[0][1].runs[0].frames.at(-1).games.length).toBe(0);
    // A band with no games must stay a hole rather than becoming 0, which
    // would read as a round of perfect blowouts. The pre-play frame has no
    // games at all, so every band there is empty.
    expect(
      back._0.byField[0][0].runs[0].frames[0].qualityByBand.every(
        (v: unknown) => v === undefined,
      ),
    ).toBe(true);

    const file = `${slug()}.json.gz`;
    const gz = gzipSync(Buffer.from(json, "utf8"), { level: zlibConstants.Z_BEST_COMPRESSION });
    mkdirSync(outDir, { recursive: true });
    writeFileSync(join(outDir, file), gz);

    // Manifest: replace this slug's entry, keep every other saved run.
    const manifestPath = join(outDir, SimLabArchive.manifestFile);
    const existing = existsSync(manifestPath)
      ? JSON.parse(readFileSync(manifestPath, "utf8"))
      : { version: SimLabArchive.version, runs: [] };
    const runs = (existing.version === SimLabArchive.version ? existing.runs : []).filter(
      (r: { file: string }) => r.file !== file,
    );
    runs.push({
      file,
      label,
      scenario: config.scenario,
      numPlayers: config.numPlayers,
      courts: config.courts,
      numRounds: config.numRounds,
      seedCount: config.seedCount,
      tournament: config.tournament,
      bytes: gz.length,
    });
    runs.sort((a: { file: string }, b: { file: string }) => a.file.localeCompare(b.file));
    writeFileSync(
      manifestPath,
      JSON.stringify({ version: SimLabArchive.version, runs }, null, 2) + "\n",
    );

    console.log(
      `wrote ${file}: ${(json.length / 1024 / 1024).toFixed(1)} MB JSON -> ${(gz.length / 1024).toFixed(0)} KB gzipped`,
    );
  }, 0);
});
