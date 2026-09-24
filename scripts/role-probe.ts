// The worker half of `yarn lab:role-probe`. Run it through
// `scripts/role-probe.mjs`, not directly.
//
// Measures what a streak of one role — always favored, or always unfavored —
// does to a player's rating, with partners still rotating. Each arm pins one
// player's side with `SimLab.roleProbe` (a re-split of the foursome the
// matchmaker chose) and is compared with the unmodified run on the same seed.
//
// A vitest file for the same reason as `precompute-lab-run.ts`: it is the only
// runner that resolves the ReScript build output.
//
// Modes, chosen by env:
//   ROLE_MODE=seed ROLE_SEED_INDEX=<n>  run every arm for one seed, write a shard
//   ROLE_MODE=merge                      paired deltas across seeds, print + write
//   ROLE_MODE=observe                    correlations on the saved lab run, no solving
//   ROLE_MODE=streak-seed / streak-merge natural role streaks from cold start vs chance
//   ROLE_MODE=catchup-seed / catchup-merge  streaks while a returning regular catches up on games
//
// Other env: LAB_SEED (1), LAB_SEEDS (7), LAB_FIELDS ("1" = typical; indices
// into SimLab.fields), LAB_TARGETS ("median" or "median,strongest,weakest"),
// LAB_ARMS (comma list; default all), LAB_ROUNDS (100), LAB_PLAYERS (24),
// LAB_COURTS (4), LAB_SCENARIO (ColdStart).
//
// Two runs on the same seed share the world (truth, drift, form, drop-ins) and
// the outcome random stream, but not bit-for-bit: the solver's 1 s time limit
// lets them diverge once a round hits it. The `null` arm — a probe on a player
// who is not in the pool — measures exactly that noise, so every effect is
// read against it.
import { describe, expect, it } from "vitest";
import { gunzipSync } from "node:zlib";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import * as SimLab from "../src/lib/rating/SimLab.re.mjs";
import * as SimLabArchive from "../src/lib/rating/SimLabArchive.re.mjs";
import * as RoleAnalysis from "../src/lib/rating/RoleAnalysis.re.mjs";

const root = process.cwd();
const outDir = join(root, "node_modules/.cache/matchmaking-lab/role-probe");

const env = (key: string, fallback: string) => process.env[key] ?? fallback;
const num = (key: string, fallback: number) => Number(env(key, String(fallback)));
const list = (key: string, fallback: string) =>
  env(key, fallback).split(",").map((s) => s.trim()).filter(Boolean);

const config = {
  scenario: env("LAB_SCENARIO", "ColdStart"),
  numPlayers: num("LAB_PLAYERS", 24),
  courts: num("LAB_COURTS", 4),
  numRounds: num("LAB_ROUNDS", 100),
  seed: num("LAB_SEED", 1),
  seedCount: num("LAB_SEEDS", 7),
  fields: list("LAB_FIELDS", "1").map(Number),
  targets: list("LAB_TARGETS", "median"),
};

type Arm = { id: string; target?: string; margin?: number; pick?: string };
const ALL_ARMS: Arm[] = [
  { id: "baseline" },
  { id: "null" },
  { id: "fav-near-0", target: "ForceFavored", margin: 0, pick: "Nearest" },
  { id: "unf-near-0", target: "ForceUnfavored", margin: 0, pick: "Nearest" },
  { id: "fav-near-5", target: "ForceFavored", margin: 0.05, pick: "Nearest" },
  { id: "unf-near-5", target: "ForceUnfavored", margin: 0.05, pick: "Nearest" },
  { id: "fav-far-0", target: "ForceFavored", margin: 0, pick: "Farthest" },
  { id: "unf-far-0", target: "ForceUnfavored", margin: 0, pick: "Farthest" },
  { id: "alt-near-0", target: "ForceAlternate", margin: 0, pick: "Nearest" },
];
const armIds = list("LAB_ARMS", ALL_ARMS.map((a) => a.id).join(","));
const arms = ALL_ARMS.filter((a) => armIds.includes(a.id) || a.id === "baseline");
// Arms that do not depend on the target run once per seed and field.
const shared = new Set(["baseline", "null"]);

// One session, two sessions, halfway, the end.
const windows = [...new Set([13, 26, 50, 100, config.numRounds].filter((w) => w <= config.numRounds))]
  .sort((a, b) => a - b);

const cp = SimLab.strategies.find((s: any) => s.id === "cp");
const shardPath = (seedIndex: number) =>
  join(outDir, `role-probe.${config.numRounds}r.seed${seedIndex}.json`);

// Targets are Steady regulars, so drift and drop-in absences do not mix into
// the role effect.
const pickTargets = (res: any): Record<string, number> => {
  const ranks: number[] = SimLab.ranksOf(res.truth);
  const eligible = ranks
    .map((rank, i) => ({ i, rank }))
    .filter(({ i }) => !res.dropIns[i] && res.driftRoles[i] === "Steady");
  const byRank = [...eligible].sort((a, b) => a.rank - b.rank);
  const mid = (res.truth.length - 1) / 2;
  const median = [...eligible].sort((a, b) => Math.abs(a.rank - mid) - Math.abs(b.rank - mid))[0];
  return {
    median: median.i,
    strongest: byRank[byRank.length - 1].i,
    weakest: byRank[0].i,
  };
};

const mean = (xs: number[]) => (xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : NaN);
const sd = (xs: number[]) => {
  if (xs.length < 2) return NaN;
  const m = mean(xs);
  return Math.sqrt(xs.reduce((a, b) => a + (b - m) ** 2, 0) / (xs.length - 1));
};
const se = (xs: number[]) => sd(xs) / Math.sqrt(xs.length);
const dupr = (mu: number | undefined) => (mu === undefined ? NaN : mu / SimLab.muPerDupr);

// The numbers compared across arms, per player per window.
const metrics = (res: any, intId: number, toRound: number) => {
  const r = RoleAnalysis.playerRole(res, 0, { fromRound: 1, toRound }, undefined, intId);
  return {
    games: r.gamesPlayed,
    favoredShare: r.favoredShare ?? NaN,
    meaningfulFavoredShare: r.meaningfulFavoredShare ?? NaN,
    meanEdge: r.meanEdge ?? NaN,
    maxRoleStreak: r.maxRoleStreak,
    alternationRate: r.alternationRate ?? NaN,
    distinctPartners: r.distinctPartners,
    partnerAdvantageDupr: dupr(r.partnerAdvantage),
    calibrationGap:
      r.winRate === undefined || r.meanOwnWinProb === undefined ? NaN : r.winRate - r.meanOwnWinProb,
    signedMuErrorDupr: dupr(r.signedMuError),
    signedRankError: r.signedRankError ?? NaN,
    absRankError: r.absRankError ?? NaN,
    meanAbsRankError: r.meanAbsRankError ?? NaN,
    sigmaDupr: dupr(r.finalSigma),
  };
};

const seedIndexEnv = process.env.ROLE_SEED_INDEX;
const mode = env("ROLE_MODE", seedIndexEnv !== undefined ? "seed" : "");

describe("role probe", () => {
  it.runIf(mode === "seed")("runs every arm for one seed", async () => {
    const seedIndex = Number(seedIndexEnv);
    const seed = config.seed + seedIndex;
    const t0 = Date.now();
    const rows: any[] = [];
    const population: any[] = [];
    const log = (msg: string) =>
      console.log(`[seed ${seedIndex}] ${msg} · ${((Date.now() - t0) / 60000).toFixed(1)}m`);
    const runArm = (field: any, probe?: unknown) =>
      SimLab.run(
        config.scenario, seed, config.numPlayers, config.courts, config.numRounds,
        field, false, undefined, [cp], probe,
      );

    for (const f of config.fields) {
      const field = SimLab.fields[f];
      const baseline = await runArm(field);
      log(`field ${f} baseline`);
      const targets = pickTargets(baseline);
      const record = (arm: string, target: string, res: any, probe: any) => {
        const intId = targets[target];
        const outcome = probe ? RoleAnalysis.probeOutcome(res, 0, probe) : undefined;
        for (const w of windows)
          rows.push({
            seed, field: f, target, intId, trueRank: SimLab.ranksOf(res.truth)[intId],
            arm, window: w, fellBack: res.runs[0].fellBackToGreedy,
            achieved: outcome?.achieved, achievable: outcome?.achievable, played: outcome?.played,
            ...metrics(res, intId, w),
          });
      };

      // The whole pool on the baseline: the observational set with this
      // many seeds behind it.
      for (const p of RoleAnalysis.playerRoles(baseline, 0, { fromRound: 1, toRound: config.numRounds }, undefined))
        population.push({ seed, field: f, driftRole: baseline.driftRoles[p.intId], ...p });

      const nullRun = arms.some((a) => a.id === "null")
        ? await runArm(field, { playerIntId: -1, target: "ForceFavored", margin: 0, pick: "Nearest" })
        : undefined;
      if (nullRun) log(`field ${f} null`);

      for (const target of config.targets) {
        record("baseline", target, baseline, undefined);
        if (nullRun) record("null", target, nullRun, undefined);
        for (const arm of arms.filter((a) => !shared.has(a.id))) {
          const probe = { playerIntId: targets[target], target: arm.target, margin: arm.margin, pick: arm.pick };
          record(arm.id, target, await runArm(field, probe), probe);
          log(`field ${f} ${target} ${arm.id}`);
        }
      }
    }
    mkdirSync(outDir, { recursive: true });
    writeFileSync(shardPath(seedIndex), JSON.stringify({ seedIndex, seed, config, rows, population }));
    log("done");
    expect(rows.length).toBeGreaterThan(0);
  }, 0);

  it.runIf(mode === "merge")("pairs every arm with its baseline across seeds", () => {
    const rows: any[] = [];
    const population: any[] = [];
    for (let i = 0; i < config.seedCount; i++) {
      const path = shardPath(i);
      if (!existsSync(path)) throw new Error(`Missing shard for seed ${i}: ${path}`);
      const shard = JSON.parse(readFileSync(path, "utf8"));
      rows.push(...shard.rows);
      population.push(...shard.population);
    }
    const key = (r: any) => `${r.seed}|${r.field}|${r.target}|${r.window}`;
    // The reference is the null arm when there is one: it is an unmodified
    // run too, but never the first run in its process, so it does not carry
    // the warm-up rounds where HiGHS misses its time limit and the round falls
    // back to greedy. Baseline minus null is then the noise floor.
    const refArm = env("ROLE_REF", rows.some((r) => r.arm === "null") ? "null" : "baseline");
    const base = new Map(rows.filter((r) => r.arm === refArm).map((r) => [key(r), r]));
    const deltaOf = (r: any, m: string) => r[m] - base.get(key(r))[m];

    const summary: any[] = [];
    const groups = new Map<string, any[]>();
    for (const r of rows) {
      const g = `${r.field}|${r.target}|${r.arm}|${r.window}`;
      if (!groups.has(g)) groups.set(g, []);
      groups.get(g)!.push(r);
    }
    const fmt = (m: number, s: number, d = 3) =>
      Number.isNaN(m) ? "—" : `${m >= 0 ? "+" : ""}${m.toFixed(d)}${Number.isNaN(s) ? "" : ` ±${s.toFixed(d)}`}`;
    for (const [g, rs] of groups) {
      const [field, target, arm, window] = g.split("|");
      const stat = (m: string) => {
        const xs = rs.map((r) => r[m]).filter((x) => !Number.isNaN(x));
        const ds = rs.map((r) => deltaOf(r, m)).filter((x) => !Number.isNaN(x));
        return { mean: mean(xs), se: se(xs), delta: mean(ds), deltaSe: se(ds) };
      };
      summary.push({
        field: Number(field), target, arm, window: Number(window), seeds: rs.length,
        fellBack: rs.filter((r) => r.fellBack).length,
        forcedShare: mean(rs.filter((r) => r.played).map((r) => r.achieved / r.played)),
        achievableShare: mean(rs.filter((r) => r.played).map((r) => r.achievable / r.played)),
        ...Object.fromEntries(
          [
            "signedMuErrorDupr", "signedRankError", "absRankError", "meanAbsRankError", "sigmaDupr",
            "calibrationGap", "favoredShare", "meaningfulFavoredShare", "meanEdge", "maxRoleStreak",
            "alternationRate", "distinctPartners", "partnerAdvantageDupr", "games",
          ].map((m) => [m, stat(m)]),
        ),
      });
    }

    for (const field of config.fields)
      for (const target of config.targets) {
        console.log(`\n=== field ${field} · ${target} player · paired Δ vs ${refArm} (mean ± SE over seeds) ===`);
        for (const window of windows) {
          console.log(`\n-- rounds 1–${window} --`);
          console.log(
            ["arm", "forced", "fav%", "edge", "partners", "partnerAdv", "Δ signed μ (DUPR)", "Δ signed rank", "Δ |rank|", "Δ σ (DUPR)", "calib gap", "fb"]
              .map((h, i) => (i === 0 ? h.padEnd(11) : h.padStart(i >= 6 ? 18 : 11)))
              .join(""),
          );
          for (const s of summary.filter((x) => x.field === field && x.target === target && x.window === window)) {
            const cells = [
              s.arm.padEnd(11),
              (Number.isNaN(s.forcedShare) ? "—" : `${(s.forcedShare * 100).toFixed(0)}%`).padStart(11),
              `${(s.favoredShare.mean * 100).toFixed(0)}%`.padStart(11),
              s.meanEdge.mean.toFixed(3).padStart(11),
              s.distinctPartners.mean.toFixed(1).padStart(11),
              s.partnerAdvantageDupr.mean.toFixed(2).padStart(11),
              fmt(s.signedMuErrorDupr.delta, s.signedMuErrorDupr.deltaSe).padStart(18),
              fmt(s.signedRankError.delta, s.signedRankError.deltaSe, 2).padStart(18),
              fmt(s.absRankError.delta, s.absRankError.deltaSe, 2).padStart(18),
              fmt(s.sigmaDupr.delta, s.sigmaDupr.deltaSe).padStart(18),
              fmt(s.calibrationGap.mean, s.calibrationGap.se).padStart(18),
              String(s.fellBack).padStart(4),
            ];
            console.log(cells.join(""));
          }
        }
      }

    const baseRows = population.filter((p) => !p.isDropIn);
    console.log(`\nbaseline population: ${baseRows.length} regular player-runs`);

    writeFileSync(join(outDir, "role-probe-summary.json"), JSON.stringify({ config, windows, refArm, summary }, null, 2));
    const cols = Object.keys(rows[0]);
    writeFileSync(
      join(outDir, "role-probe-rows.csv"),
      [cols.join(","), ...rows.map((r) => cols.map((c) => r[c] ?? "").join(","))].join("\n"),
    );
    writeFileSync(join(outDir, "role-probe-population.json"), JSON.stringify(population));
    console.log(`wrote ${outDir}`);
    expect(summary.length).toBeGreaterThan(0);
  });

  // ---------------------------------------------------------------------------
  // Observational: the saved lab run, every strategy, no solving
  // ---------------------------------------------------------------------------
  it.runIf(mode === "observe")("correlates role balance with rating error on the saved run", () => {
    const artifact = join(root, "public", SimLabArchive.assetDir, "cold-24p-4c-100r-7s.json.gz");
    const d = SimLabArchive.decode(gunzipSync(readFileSync(artifact)).toString("utf8"));
    if (d.TAG !== "Ok") throw new Error(d._0);

    const pearson = (xs: number[], ys: number[]) => {
      const mx = mean(xs), my = mean(ys);
      let sxy = 0, sxx = 0, syy = 0;
      xs.forEach((x, i) => {
        sxy += (x - mx) * (ys[i] - my);
        sxx += (x - mx) ** 2;
        syy += (ys[i] - my) ** 2;
      });
      return sxy / Math.sqrt(sxx * syy);
    };
    const rank = (xs: number[]) => {
      const order = xs.map((x, i) => [x, i]).sort((a, b) => a[0] - b[0]);
      const out = new Array(xs.length);
      let i = 0;
      while (i < order.length) {
        let j = i;
        while (j + 1 < order.length && order[j + 1][0] === order[i][0]) j++;
        for (let k = i; k <= j; k++) out[order[k][1]] = (i + j) / 2;
        i = j + 1;
      }
      return out;
    };
    const spearman = (xs: number[], ys: number[]) => pearson(rank(xs), rank(ys));
    // Residuals of y on [1, q, q²]: true rank bounds both role balance (the
    // top player is nearly always favored) and rank error (the top player can
    // only be under-ranked), so the raw relation is confounded by position.
    const residualise = (ys: number[], qs: number[]) => {
      const X = qs.map((q) => [1, q, q * q]);
      const A = [0, 1, 2].map((a) => [0, 1, 2].map((b) => X.reduce((s, x) => s + x[a] * x[b], 0)));
      const v = [0, 1, 2].map((a) => X.reduce((s, x, i) => s + x[a] * ys[i], 0));
      // 3x3 solve by Gaussian elimination.
      const M = A.map((row, i) => [...row, v[i]]);
      for (let c = 0; c < 3; c++) {
        const p = M.slice(c).reduce((best, row, i) => (Math.abs(row[c]) > Math.abs(M[best][c]) ? i + c : best), c);
        [M[c], M[p]] = [M[p], M[c]];
        for (let r = 0; r < 3; r++)
          if (r !== c) {
            const f = M[r][c] / M[c][c];
            for (let k = c; k < 4; k++) M[r][k] -= f * M[c][k];
          }
      }
      const beta = M.map((row, i) => row[3] / row[i]);
      return ys.map((y, i) => y - (beta[0] + beta[1] * qs[i] + beta[2] * qs[i] ** 2));
    };

    const rows: any[] = [];
    d._0.byField.forEach((seeds: any[], f: number) => {
      const res = seeds[0];
      res.runs.forEach((run: any, s: number) => {
        if (!run.frames[run.frames.length - 1]?.games?.length) return;
        for (const p of RoleAnalysis.playerRoles(res, s, { fromRound: 1, toRound: 100 }, undefined)) {
          const late = RoleAnalysis.playerRole(res, s, { fromRound: 76, toRound: 100 }, undefined, p.intId);
          rows.push({
            field: f, strategy: run.entry.id, intId: p.intId, q: p.trueRankQuantile,
            drift: res.driftRoles[p.intId], isDropIn: p.isDropIn, games: p.gamesPlayed,
            favoredShare: p.favoredShare, imbalance: Math.abs((p.favoredShare ?? 0.5) - 0.5),
            maxRoleStreak: p.maxRoleStreak, alternationRate: p.alternationRate,
            distinctPartners: p.distinctPartners,
            partnerAdvDupr: dupr(p.partnerAdvantage), meanEdge: p.meanEdge,
            calibrationGap: (p.winRate ?? NaN) - (p.meanOwnWinProb ?? NaN),
            signedMuDupr: dupr(p.signedMuError), signedRank: p.signedRankError,
            absRank: p.absRankError, lateAbsRank: late.meanAbsRankError,
          });
        }
      });
    });

    const strategies = [...new Set(rows.map((r) => r.strategy))];
    const pairs: [string, string][] = [
      ["lateAbsRank", "imbalance"],
      ["lateAbsRank", "maxRoleStreak"],
      ["signedMuDupr", "favoredShare"],
      ["signedMuDupr", "partnerAdvDupr"],
      ["lateAbsRank", "meanEdge"],
    ];
    const summary: any[] = [];
    console.log("\nObservational — seed 0 of the saved run, 3 fields pooled, regulars only.");
    console.log("r = Spearman; r_ctrl = Pearson on residuals after [1,q,q²] in true-rank quantile.\n");
    console.log(
      ["strategy", "n", ...pairs.flatMap(([y, x]) => [`${y}~${x}`, "ctrl"])]
        .map((h, i) => (i === 0 ? h.padEnd(9) : i === 1 ? h.padStart(4) : h.padStart(i % 2 === 0 ? 30 : 7)))
        .join(""),
    );
    for (const s of strategies) {
      const rs = rows.filter((r) => r.strategy === s && !r.isDropIn);
      const cells: string[] = [s.padEnd(9), String(rs.length).padStart(4)];
      const entry: any = { strategy: s, n: rs.length };
      for (const [y, x] of pairs) {
        const ok = rs.filter((r) => Number.isFinite(r[x]) && Number.isFinite(r[y]));
        const ys = ok.map((r) => r[y]), xs = ok.map((r) => r[x]), qs = ok.map((r) => r.q);
        const raw = spearman(xs, ys);
        const ctrl = pearson(residualise(xs, qs), residualise(ys, qs));
        entry[`${y}~${x}`] = { raw, ctrl, n: ok.length };
        cells.push(raw.toFixed(2).padStart(30), ctrl.toFixed(2).padStart(7));
      }
      summary.push(entry);
      console.log(cells.join(""));
    }

    mkdirSync(outDir, { recursive: true });
    writeFileSync(join(outDir, "role-observational-summary.json"), JSON.stringify(summary, null, 2));
    const cols = Object.keys(rows[0]);
    writeFileSync(
      join(outDir, "role-observational.csv"),
      [cols.join(","), ...rows.map((r) => cols.map((c) => r[c] ?? "").join(","))].join("\n"),
    );
    console.log(`\nwrote ${outDir}`);
    expect(rows.length).toBeGreaterThan(0);
  });
  // ---------------------------------------------------------------------------
  // Natural streaks: does a matchmaker, starting from an unrated pool, hand
  // players runs of the same role on its own?
  // ---------------------------------------------------------------------------
  //
  // A player's longest run of one role depends heavily on how lopsided they
  // are — the top player is favored almost every game under any matchmaker —
  // so each player is compared with their OWN games shuffled: same count of
  // favored and unfavored games, random order. Streakier than that is
  // clustering the matchmaker creates; less streaky is alternation working.
  //
  // Sides are read two ways: the matchmaker's own dead zone (what its
  // alternation term looks at; wide while ratings are uncertain) and a fixed
  // 0.45–0.55 win-probability band.

  const streakWindows = [
    { label: "1-13", fromRound: 1, toRound: 13 },
    { label: "14-100", fromRound: 14, toRound: 100 },
    { label: "1-100", fromRound: 1, toRound: 100 },
  ].filter((w) => w.fromRound <= config.numRounds)
    .map((w) => ({ ...w, toRound: Math.min(w.toRound, config.numRounds) }));
  const sideModes: [string, unknown][] = [
    ["matchmaker", "CostModelExact"],
    ["band 0.05", { TAG: "WinProb", _0: 0.05 }],
    // Whoever the ratings pick to win, however narrowly.
    ["any favorite", { TAG: "WinProb", _0: 0 }],
  ];
  const streakStrategies = list("LAB_STREAK_STRATEGIES", "cpa,cp,rr,rndnov");
  const streakShard = (i: number) => join(outDir, `streaks.${config.numRounds}r.seed${i}.json`);

  const mulberry32 = (a: number) => () => {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  const runStats = (seq: string[]) => {
    let max = 0, cur = 0, alt = 0, inLong = 0;
    const runs: number[] = [];
    seq.forEach((s, i) => {
      if (i > 0 && seq[i - 1] === s) cur++;
      else {
        if (i > 0) { alt++; runs.push(cur); }
        cur = 1;
      }
      max = Math.max(max, cur);
    });
    if (seq.length) runs.push(cur);
    for (const r of runs) if (r >= 4) inLong += r;
    return {
      max,
      altRate: seq.length > 1 ? alt / (seq.length - 1) : NaN,
      longShare: seq.length ? inLong / seq.length : NaN,
    };
  };
  const shuffleNull = (seq: string[], seed: number, iters = 400) => {
    const rng = mulberry32(seed);
    const a = [...seq];
    let max = 0, alt = 0, long = 0, atLeast = 0;
    const obs = runStats(seq).max;
    for (let k = 0; k < iters; k++) {
      for (let i = a.length - 1; i > 0; i--) {
        const j = Math.floor(rng() * (i + 1));
        [a[i], a[j]] = [a[j], a[i]];
      }
      const st = runStats(a);
      max += st.max; alt += st.altRate; long += st.longShare;
      if (st.max >= obs) atLeast++;
    }
    return { max: max / iters, altRate: alt / iters, longShare: long / iters, p: atLeast / iters };
  };

  const streakRows = (res: any, source: string, field: number, seed: number) => {
    const rows: any[] = [];
    res.runs.forEach((run: any, s: number) => {
      if (!streakStrategies.includes(run.entry.id)) return;
      if (!run.frames[run.frames.length - 1]?.games?.length) return;
      for (let intId = 0; intId < res.truth.length; intId++) {
        if (res.dropIns[intId]) continue;
        for (const w of streakWindows)
          for (const [modeName, mode] of sideModes) {
            const all: string[] = RoleAnalysis.sideSequence(res, s, w, mode, intId);
            const sided = all.filter((x) => x !== "Even");
            const q = RoleAnalysis.playerRole(res, s, w, undefined, intId).trueRankQuantile;
            const obs = runStats(sided);
            const nul = shuffleNull(sided, seed * 1000003 + s * 1009 + intId * 31 + w.fromRound);
            rows.push({
              source, field, seed, strategy: run.entry.id, fellBack: run.fellBackToGreedy,
              intId, tercile: q < 1 / 3 ? "bottom" : q > 2 / 3 ? "top" : "middle",
              window: w.label, mode: modeName,
              games: all.length, even: all.length - sided.length, sided: sided.length,
              favShare: sided.length ? sided.filter((x) => x === "Favored").length / sided.length : NaN,
              maxStreak: obs.max, expMaxStreak: nul.max, pStreak: nul.p,
              altRate: obs.altRate, expAltRate: nul.altRate,
              longShare: obs.longShare, expLongShare: nul.longShare,
            });
          }
      }
    });
    return rows;
  };

  it.runIf(mode === "streak-seed")("records natural role streaks for one seed", async () => {
    const seedIndex = Number(seedIndexEnv);
    const seed = config.seed + seedIndex;
    const t0 = Date.now();
    // Warm-up: the first solves in a fresh process miss HiGHS's time limit and
    // fall back to greedy, and at cold start the first rounds are exactly
    // what is being measured.
    await SimLab.run("ColdStart", 1, 8, 2, 1, undefined, false, undefined, [cp]);
    const entries = SimLab.strategies.filter((s: any) => streakStrategies.includes(s.id));
    const rows: any[] = [];
    for (const f of config.fields) {
      const res = await SimLab.run(
        config.scenario, seed, config.numPlayers, config.courts, config.numRounds,
        SimLab.fields[f], false, undefined, entries,
      );
      rows.push(...streakRows(res, "fresh", f, seed));
      console.log(`[seed ${seedIndex}] field ${f} · ${((Date.now() - t0) / 60000).toFixed(1)}m`);
    }
    mkdirSync(outDir, { recursive: true });
    writeFileSync(streakShard(seedIndex), JSON.stringify(rows));
    expect(rows.length).toBeGreaterThan(0);
  }, 0);

  it.runIf(mode === "streak-merge")("summarises natural streaks against chance", () => {
    const rows: any[] = [];
    for (let i = 0; i < config.seedCount; i++)
      if (existsSync(streakShard(i))) rows.push(...JSON.parse(readFileSync(streakShard(i), "utf8")));
    const artifact = join(root, "public", SimLabArchive.assetDir, "cold-24p-4c-100r-7s.json.gz");
    if (existsSync(artifact)) {
      const d = SimLabArchive.decode(gunzipSync(readFileSync(artifact)).toString("utf8"));
      if (d.TAG === "Ok")
        d._0.byField.forEach((seeds: any[], f: number) => rows.push(...streakRows(seeds[0], "saved", f, seeds[0].seed)));
    }

    const pct = (x: number) => (Number.isNaN(x) ? "—" : `${(x * 100).toFixed(0)}%`);
    const summary: any[] = [];
    const sources = [...new Set(rows.map((r) => r.source))];
    for (const source of sources)
      for (const [modeName] of sideModes)
        for (const w of streakWindows) {
          const rs0 = rows.filter((r) => r.source === source && r.mode === modeName && r.window === w.label);
          if (!rs0.length) continue;
          const fields = [...new Set(rs0.map((r) => r.field))].join(",");
          console.log(`\n=== ${source} runs (field ${fields}) · sides by ${modeName} · rounds ${w.label} ===`);
          console.log(
            ["strategy", "players", "games", "even", "imbalance", "longest run", "chance", "streaky p<.05",
              "alternation", "chance", "in runs≥4", "chance", "middle: longest", "chance",
              "top: longest", "chance", "bottom: longest", "chance", "worst player"]
              .map((h, i) => (i === 0 ? h.padEnd(9) : h.padStart(i === 7 || i >= 12 ? 16 : 12))).join(""),
          );
          for (const strategy of streakStrategies) {
            const rs = rs0.filter((r) => r.strategy === strategy && r.sided > 1);
            if (!rs.length) continue;
            const mid = rs.filter((r) => r.tercile === "middle");
            const m = (xs: any[], k: string) => mean(xs.map((r) => r[k]).filter((x: number) => !Number.isNaN(x)));
            const all = rs0.filter((r) => r.strategy === strategy);
            const row = {
              source, mode: modeName, window: w.label, strategy, players: rs.length,
              games: m(all, "games"),
              evenShare: all.reduce((a, r) => a + r.even, 0) / all.reduce((a, r) => a + r.games, 0),
              favShare: m(rs, "favShare"),
              maxStreak: m(rs, "maxStreak"), expMaxStreak: m(rs, "expMaxStreak"),
              streakyShare: rs.filter((r) => r.pStreak < 0.05).length / rs.length,
              altRate: m(rs, "altRate"), expAltRate: m(rs, "expAltRate"),
              longShare: m(rs, "longShare"), expLongShare: m(rs, "expLongShare"),
              midMax: m(mid, "maxStreak"), midExp: m(mid, "expMaxStreak"),
              topMax: m(rs.filter((r) => r.tercile === "top"), "maxStreak"),
              topExp: m(rs.filter((r) => r.tercile === "top"), "expMaxStreak"),
              bottomMax: m(rs.filter((r) => r.tercile === "bottom"), "maxStreak"),
              bottomExp: m(rs.filter((r) => r.tercile === "bottom"), "expMaxStreak"),
              imbalance: mean(rs.map((r) => Math.abs(r.favShare - 0.5))),
              worst: Math.max(...rs.map((r) => r.maxStreak)),
            };
            summary.push(row);
            console.log([
              strategy.padEnd(9), String(row.players).padStart(12), row.games.toFixed(1).padStart(12),
              pct(row.evenShare).padStart(12), pct(row.imbalance).padStart(12),
              row.maxStreak.toFixed(2).padStart(12), row.expMaxStreak.toFixed(2).padStart(12),
              pct(row.streakyShare).padStart(16),
              row.altRate.toFixed(2).padStart(12), row.expAltRate.toFixed(2).padStart(12),
              pct(row.longShare).padStart(12), pct(row.expLongShare).padStart(12),
              row.midMax.toFixed(2).padStart(16), row.midExp.toFixed(2).padStart(16),
              row.topMax.toFixed(2).padStart(16), row.topExp.toFixed(2).padStart(16),
              row.bottomMax.toFixed(2).padStart(16), row.bottomExp.toFixed(2).padStart(16),
              String(row.worst).padStart(16),
            ].join(""));
          }
        }
    const fresh = rows.filter((r) => r.source === "fresh");
    console.log(`\nfresh runs that fell back to greedy: ${new Set(fresh.filter((r) => r.fellBack).map((r) => `${r.seed}|${r.strategy}`)).size}`);
    mkdirSync(outDir, { recursive: true });
    writeFileSync(join(outDir, "streaks-summary.json"), JSON.stringify(summary, null, 2));
    const cols = Object.keys(rows[0]);
    writeFileSync(join(outDir, "streaks-rows.csv"),
      [cols.join(","), ...rows.map((r) => cols.map((c) => r[c] ?? "").join(","))].join("\n"));
    console.log(`wrote ${outDir}`);
    expect(summary.length).toBeGreaterThan(0);
  });
  // ---------------------------------------------------------------------------
  // Catch-up streaks: a rated regular misses rounds, comes back behind on
  // games, and the fairness rule schedules them every round until they catch
  // up. Do their sides streak while that lasts?
  // ---------------------------------------------------------------------------

  const catchupShard = (i: number) => join(outDir, `catchup.${config.numRounds}r.seed${i}.json`);
  const catchupStrategies = list("LAB_CATCHUP_STRATEGIES", "cpa");
  // Absent players are Steady regulars at these ladder percentiles.
  const pctIds = (res: any, pcts: number[]) => {
    const ranks: number[] = SimLab.ranksOf(res.truth);
    const eligible = ranks.map((rank, i) => ({ i, rank }))
      .filter(({ i }) => !res.dropIns[i] && res.driftRoles[i] === "Steady");
    return pcts.map((pc) => {
      const want = pc * (res.truth.length - 1);
      return [...eligible].sort((a, b) => Math.abs(a.rank - want) - Math.abs(b.rank - want))[0].i;
    });
  };
  // Arms: who is away, and when. Session 3 is rounds 27-39.
  const catchupArms = (res: any) => {
    const [p25, p50, p75] = pctIds(res, [0.25, 0.5, 0.75]);
    return [
      { id: "whole-session", absences: [{ absentIntId: p50, fromRound: 27, toRound: 39 }] },
      {
        id: "three-whole-session",
        absences: [p25, p50, p75].map((id) => ({ absentIntId: id, fromRound: 27, toRound: 39 })),
      },
      { id: "six-rounds-late", absences: [{ absentIntId: p50, fromRound: 40, toRound: 45 }] },
    ];
  };

  // Games before each round, and whether the player is behind the busiest
  // present player at that point — the matchmaker's own deficit.
  const behindTrack = (res: any, run: any, id: number, absences: any[]) => {
    const n = res.truth.length;
    const count = new Array(n).fill(0);
    const out: { round: number; behind: number; played: boolean }[] = [];
    for (const fr of run.frames.slice(1)) {
      const present = (i: number) =>
        (res.attendance[SimLab.sessionOf(fr.round)]?.[i] ?? true) &&
        !absences.some((a) => a.absentIntId === i && fr.round >= a.fromRound && fr.round <= a.toRound);
      const maxC = Math.max(...count.filter((_, i) => present(i)));
      const played = fr.games.some((g: any) => g.playerIndices.includes(id));
      if (present(id)) out.push({ round: fr.round, behind: maxC - count[id], played });
      fr.games.forEach((g: any) => g.playerIndices.forEach((i: number) => count[i]++));
    }
    return out;
  };

  const sidesIn = (res: any, s: number, id: number, from: number, to: number, modeVal: unknown) =>
    RoleAnalysis.sideSequence(res, s, { fromRound: from, toRound: to }, modeVal, id);

  it.runIf(mode === "catchup-seed")("records catch-up streaks for one seed", async () => {
    const seedIndex = Number(seedIndexEnv);
    const seed = config.seed + seedIndex;
    const t0 = Date.now();
    await SimLab.run("ColdStart", 1, 8, 2, 1, undefined, false, undefined, [cp]);
    const entries = SimLab.strategies.filter((x: any) => catchupStrategies.includes(x.id));
    const field = SimLab.fields[config.fields[0]];
    const go = (absences: any[]) =>
      SimLab.run(config.scenario, seed, config.numPlayers, config.courts, config.numRounds,
        field, false, undefined, entries, undefined, absences);
    const baseline = await go([]);
    const rows: any[] = [];
    for (const arm of catchupArms(baseline)) {
      const res = await go(arm.absences);
      for (const a of arm.absences) {
        const id = a.absentIntId;
        const pct = SimLab.ranksOf(res.truth)[id] / (res.truth.length - 1);
        res.runs.forEach((run: any, s: number) => {
          const track = behindTrack(res, run, id, arm.absences).filter((t) => t.round > a.toRound);
          // The catch-up stretch: from their return until the first round
          // they are no longer behind.
          const end = track.findIndex((t) => t.behind <= 0);
          const stretch = end < 0 ? track : track.slice(0, end);
          if (!stretch.length) return;
          const from = stretch[0].round, to = stretch[stretch.length - 1].round;
          let consecutive = 0;
          for (const t of stretch) { if (!t.played) break; consecutive++; }
          for (const [modeName, modeVal] of sideModes) {
            const sided = (r: any) => sidesIn(r, s, id, from, to, modeVal).filter((x: string) => x !== "Even");
            const here = sided(res), there = sided(baseline);
            const h = runStats(here), b = runStats(there);
            const nh = shuffleNull(here, seed * 7919 + id * 13 + from), nb = shuffleNull(there, seed * 7919 + id * 13 + from + 1);
            rows.push({
              seed, strategy: run.entry.id, arm: arm.id, intId: id, pct: Math.round(pct * 100),
              mode: modeName, from, to, rounds: stretch.length, startBehind: stretch[0].behind,
              playedEvery: consecutive === stretch.length, consecutive,
              games: stretch.filter((t) => t.played).length,
              sided: here.length, favShare: here.length ? here.filter((x: string) => x === "Favored").length / here.length : NaN,
              longest: h.max, chance: nh.max, pStreak: nh.p, altRate: h.altRate, chanceAlt: nh.altRate,
              seq: here.map((x: string) => x[0]).join(""),
              baseSided: there.length,
              baseFavShare: there.length ? there.filter((x: string) => x === "Favored").length / there.length : NaN,
              baseLongest: b.max, baseChance: nb.max, baseAltRate: b.altRate,
              baseSeq: there.map((x: string) => x[0]).join(""),
            });
          }
        });
      }
      console.log(`[seed ${seedIndex}] ${arm.id} · ${((Date.now() - t0) / 60000).toFixed(1)}m`);
    }
    mkdirSync(outDir, { recursive: true });
    writeFileSync(catchupShard(seedIndex), JSON.stringify(rows));
    expect(rows.length).toBeGreaterThan(0);
  }, 0);

  it.runIf(mode === "catchup-merge")("summarises catch-up streaks", () => {
    const rows: any[] = [];
    for (let i = 0; i < config.seedCount; i++)
      if (existsSync(catchupShard(i))) rows.push(...JSON.parse(readFileSync(catchupShard(i), "utf8")));
    const m = (xs: any[], k: string) => mean(xs.map((r) => r[k]).filter((x: number) => !Number.isNaN(x)));
    const summary: any[] = [];
    for (const [modeName] of sideModes) {
      console.log(`\n=== catch-up stretches · sides by ${modeName} ===`);
      console.log(["arm", "strategy", "players", "rounds", "behind at return", "played every round",
        "sided", "one-sidedness", "longest run", "chance", "streaky p<.05", "alternation", "chance",
        "| same rounds unmodified: sided", "one-sidedness", "longest", "alternation"]
        .map((h, i) => (i < 2 ? h.padEnd(20) : h.padStart(i === 13 ? 32 : 14))).join(""));
      for (const arm of [...new Set(rows.map((r) => r.arm))])
        for (const strategy of catchupStrategies) {
          const rs = rows.filter((r) => r.arm === arm && r.strategy === strategy && r.mode === modeName);
          if (!rs.length) continue;
          const oneSided = (k: string) => mean(rs.filter((r) => !Number.isNaN(r[k])).map((r) => Math.abs(r[k] - 0.5) * 2));
          const row = {
            mode: modeName, arm, strategy, players: rs.length, rounds: m(rs, "rounds"),
            startBehind: m(rs, "startBehind"), playedEvery: rs.filter((r) => r.playedEvery).length / rs.length,
            sided: m(rs, "sided"), oneSided: oneSided("favShare"), longest: m(rs, "longest"), chance: m(rs, "chance"),
            streaky: rs.filter((r) => r.pStreak < 0.05).length / rs.length,
            altRate: m(rs, "altRate"), chanceAlt: m(rs, "chanceAlt"),
            baseSided: m(rs, "baseSided"), baseOneSided: oneSided("baseFavShare"),
            baseLongest: m(rs, "baseLongest"), baseAltRate: m(rs, "baseAltRate"),
          };
          summary.push(row);
          const f = (x: number, d = 2) => (Number.isNaN(x) ? "—" : x.toFixed(d));
          const pc = (x: number) => (Number.isNaN(x) ? "—" : `${(x * 100).toFixed(0)}%`);
          console.log([arm.padEnd(20), strategy.padEnd(20), String(row.players).padStart(14), f(row.rounds, 1).padStart(14),
            f(row.startBehind, 1).padStart(14), pc(row.playedEvery).padStart(14), f(row.sided, 1).padStart(14),
            pc(row.oneSided).padStart(14), f(row.longest).padStart(14), f(row.chance).padStart(14),
            pc(row.streaky).padStart(14), f(row.altRate).padStart(14), f(row.chanceAlt).padStart(14),
            f(row.baseSided, 1).padStart(32), pc(row.baseOneSided).padStart(14), f(row.baseLongest).padStart(14),
            f(row.baseAltRate).padStart(14)].join(""));
        }
    }
    console.log("\nsequences (matchmaker sides; F/U only, Even games dropped) — catch-up vs same rounds unmodified:");
    for (const r of rows.filter((r) => r.mode === "matchmaker"))
      console.log(`  seed ${r.seed} ${r.arm.padEnd(20)} p${String(r.pct).padEnd(3)} rounds ${r.from}-${r.to} ` +
        `${(r.seq || "-").padEnd(30)} | ${r.baseSeq || "-"}`);
    writeFileSync(join(outDir, "catchup-summary.json"), JSON.stringify(summary, null, 2));
    const cols = Object.keys(rows[0]);
    writeFileSync(join(outDir, "catchup-rows.csv"),
      [cols.join(","), ...rows.map((r) => cols.map((c) => r[c] ?? "").join(","))].join("\n"));
    console.log(`wrote ${outDir}`);
    expect(summary.length).toBeGreaterThan(0);
  });
});
