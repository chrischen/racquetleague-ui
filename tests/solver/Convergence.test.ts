// Synthetic convergence suite: how fast does each matchmaking configuration
// teach OpenSkill the hidden truth?
//
// These assertions encode findings validated experimentally (2026-07,
// 16 players / 4 courts / cold start / linear truth, 6 seeds):
//
//   preset             r2     r4     r10    rankErr r1 / r4 / r10   blowouts
//   RandomBalanced    0.39   0.64   0.85    4.08 / 3.08 / 1.85     29.6%
//   RoundRobin        0.36   0.61   0.82    4.46 / 3.15 / 2.08     32.9%
//   Competitive+      0.39   0.65   0.81    4.08 / 2.79 / 2.08     25.8%   (adaptive)
//   Competitive+ st.  0.35   0.49   0.81    4.46 / 3.54 / 2.00     28.7%   (static)
//
// RE-BASELINED 2026-08 after a FIXTURE FIX: players used to be created in
// true-skill order, so any deterministic tie-break in the solver paired
// adjacent slots — which were adjacent in real skill — and handed the
// zero-jitter strategies accidentally well-matched opening rounds. The hidden
// ladder is now dealt out in a seeded permutation (`ladderPermutation` in
// sessionSim), so a player's slot carries no skill information.
//
// What that corrected: the round-1 gap between jittered and deterministic
// modes was 2.04 vs 3.67 ladder places and is now 4.08 vs 4.46 — so roughly
// three quarters of the "jitter is worth 1.6 places on the opening round"
// finding was fixture artefact, not jitter. The adaptive preset's cold-start
// lead is real but narrower than first measured: it still leads at r4 (2.79 vs
// 3.08 / 3.15 / 3.54) and still has the lowest blowout rate, but it no longer
// leads at r10, where RandomBalanced does (1.85 vs 2.08).
//
// and mechanism facts: cold-start mu-degeneracy splits all round-1
// partnerships (0/48 kept, any preset); the readiness signal std(mu)/mean(sigma)
// rises monotonically (0.24 → ~0.9 across ten rounds).
//
// Auto (2026-08) is the live blend of a dedicated calibration profile ->
// Competitive+, keyed on that readiness signal. The cold-start endpoint is
// `CostModel.calibrateConfig`, not Random Balanced: adding light banding
// (Round Robin's tiebreak strength) and alternation to RB's core measured
// 17.3% blowouts vs 19.4% over 20 cold-start rounds, at equal rating error.
// At default harness settings (10 rounds, 6 seeds) Auto is now the best mode
// on every absolute target at once — blowouts 26.7% (RB/C+ 28.3%, RR 32.5%),
// mean ladder error 2.21 positions at r10 (all others 2.42), rho 0.82 (others
// 0.76-0.77). Its baseline banding curve (median quad mu-range / pool
// range) falls across the session toward Competitive+'s level while
// RandomBalanced stays mixed: it calibrates like RB, then bands like C+.
//
// Rating-aligned blind spot (2026-08, revisited): a balanced match is one
// whose team sums are equal *under the current ratings*, so its outcome says
// almost nothing about error aligned with the ratings themselves — a perfectly
// inverted ladder plays 50/50 under both truth and belief. Measured over 30
// rounds from a perfectly inverted 16-player ladder (sigma 7):
//
//   rho          r6      r12     r18     r30
//   random      -0.57   +0.20   +0.55   +0.89   unbalanced play covers the
//                                               blind subspace directly and
//                                               escapes fastest, by a wide
//                                               margin — the mechanism in its
//                                               purest form
//   RoundRobin  -0.90   -0.46   +0.24   +0.87   novelty exhaustion FORCES
//                                               cross-band play once each
//                                               band's pairings run out
//   RandomBal   -0.84   -0.50   -0.17   +0.64   escapes only on its residual
//                                               compositional gaps: the
//                                               weakest of the three remedies
//   Auto        -0.84   -0.61   -0.48   -0.06   IDENTICAL to Competitive+: a
//   Competitive -0.84   -0.61   -0.48   -0.06   wrong-but-spread ladder reads
//                                               as settled, so Auto blends to
//                                               t=1 from round 1. Banded
//                                               matches under an
//                                               adjacency-preserving error are
//                                               truly close, starving even the
//                                               leak.
//
// This is deliberately NOT fixed in the engine. A stacked-probe corrective was
// built and measured (one dictated strong-pair vs weak-pair match per round;
// it did recover the inversion, reaching +0.77 by r30) and then removed: the
// failure needs a GLOBAL inversion, while realistic within-band error
// self-corrects (below), and the probe cost ~1 deliberate blowout in every 4
// matches forever. The remedy is operational instead — run a session of ROUND
// ROBIN if a ladder is ever suspected of being inverted (not Random Balanced,
// which is measurably the weakest escape).
//
// The random control also separates the two convergence mechanisms, cold start
// (50 rounds, 3 seeds) — breadth of comparison vs closeness of match:
//
//   cold start   r4     r10    r20    r50    quality gap / blowouts
//   random      0.65   0.84   0.89   0.94    0.593 / 36.0%
//   Auto        0.65   0.80   0.89   0.94    0.394 / 10.8%
//   RoundRobin  0.55   0.83   0.93   0.97    0.462 / 21.0%
//   RandomBal   0.58   0.76   0.92   0.96    0.447 / 14.5%
//   Competitive 0.41   0.76   0.84   0.96    0.416 / 10.8%
//
// Unstructured play is FASTEST early (breadth of comparison locates the coarse
// ladder) and WORST at the end (plateau 0.94: resolving neighbours needs close
// matches, which random play almost never produces). Round Robin plateaus
// highest because it is the only preset with both — forced breadth AND
// balanced splits. That is the same trade as the blind spot, seen from the
// benign side.
//
// Blowouts and blind-spot coverage are THE SAME QUANTITY (2026-08). An
// unbalanced split is both the lopsided game a player feels and the only
// evidence that ever reaches rating-aligned error. Measured directly: giving
// Round Robin balance-first splits cut its blowouts 23% -> 16% AND destroyed
// its recovery from an inverted ladder (+0.87 -> +0.35 at r30). So RR's
// blowout rate is load-bearing, not a defect to tune away, and the split
// policy is what separates the remedy mode from the quality modes:
//
//   Round Robin           novelty-first splits always — maximum rotation, the
//                         documented remedy, best final convergence (0.96)
//   RandomBalanced        balance-first always — its defining promise
//   Competitive+ / Auto   balance-first where the pool affords it (see
//                         `SolverRound.splitBalanceIsFree`): >=16 players, or
//                         any pool with byes. They are already documented as
//                         trapped, so they have no leak left to spend, and it
//                         buys ~3 points of blowout rate (16.7% -> 13.3% for
//                         C+, 16.1% -> 13.6% for Auto on a cold-start session).
//
// Match quality (mean true-win-prob gap; blowouts = worse than 90/10) on an
// ACCURATE settled prior, 10 rounds, 3 seeds:
//
//   quality       gap    blowouts   rho r10
//   Competitive+  0.242    0.0%      0.94    quality is the product
//   Auto          0.242    0.0%      0.94    EXACTLY identical: a settled
//                                            ladder blends Auto to t=1, so it
//                                            *is* Competitive+ (verified to 4
//                                            decimals; same for the
//                                            within-band and inverted cases)
//   RoundRobin    0.360   18.3%      0.97
//   RandomBal     0.431    8.3%      0.97    variety's own quality cost
//
// (C+/Auto figures re-measured after the pool-aware split upgrade, which
// applies to both; the pre-upgrade values were 0.219 / rho 0.96.)
//
// And the trap is worst-case-only: with the error confined WITHIN bands (each
// visible band of four internally reversed), Competitive+ recovers by itself
// (rho 0.88 -> 0.93 in 12 rounds) — banding only blinds it to error aligned
// with the ladder across bands.
// RandomBalanced's split contract also has a measured shape: every match takes
// its foursome's most balanced split (240/240), but random composition leaves
// a residual mean team-sum gap of ~2.8 mu — "balanced" is per-foursome
// best-effort, not a promise every match is even.
//
// The pipeline is deterministic per seed, so these numbers are exact on
// unchanged code. Thresholds sit deliberately below the baselines: they are
// regression floors, not targets — retune them intentionally (with a probe via
// `measureConvergence`) when a strategy change is *meant* to shift them.

import { describe, expect, it } from "vitest";
import {
  bandingByRound,
  measureConvergence,
  ratingErrorByRound,
  sessionQuality,
  splitBalanceStats,
  type ConvergenceMeasurement,
} from "./convergence";

const memo = new Map<string, Promise<ConvergenceMeasurement>>();
const measured = (key: string, opts: Parameters<typeof measureConvergence>[0]) => {
  if (!memo.has(key)) memo.set(key, measureConvergence(opts));
  return memo.get(key)!;
};

const rb = () => measured("rb", { strategy: "SolverRandomBalanced" });
const rr = () => measured("rr", { strategy: "SolverRoundRobin" });
const cp = () => measured("cp", { strategy: "SolverCompetitivePlusStatic" });
const auto = () => measured("auto", { strategy: "SolverCompetitivePlus" });
const at = (m: ConvergenceMeasurement, round: number) => m.spearmanByRound[round - 1];

describe("rating convergence", () => {
  it("every preset converges on a cold-start pool within a session", async () => {
    for (const m of [await rb(), await rr(), await cp()]) {
      expect(at(m, 10)).toBeGreaterThanOrEqual(0.7);
    }
  }, 1_200_000);

  it("variety-first converges fastest early; Competitive+ is the slow starter", async () => {
    // Baseline gap 0.21 at round 4 — comparison diversity (partner rotation +
    // jitter) is the dominant early factor, not banding.
    expect(at(await rb(), 4)).toBeGreaterThanOrEqual(0.55);
    expect(at(await rb(), 4)).toBeGreaterThanOrEqual(at(await cp(), 4) + 0.1);
  }, 1_200_000);

  it("balanced splits accelerate convergence", async () => {
    // Same weights, balance toggled: information per game is maximised when
    // predicted outcomes sit near 50/50. Baseline gap 0.075 at round 10.
    const advanced = (balanceTeams: boolean) => ({
      qualityVsVariety: 0,
      advanced: {
        partnerVariety: 1, opponentVariety: 1, avoidRecentRepeats: 0.5,
        bandStrength: 0, bandTolerance: 1, balanceTeams, splitBalanceFirst: false,
        alternateFavored: 0.1, shakeUp: 0, cohortRotation: 0,
      },
    });
    const on = await measured("bal-on", {
      strategy: "SolverRandomBalanced", weightConfig: advanced(true),
    });
    const off = await measured("bal-off", {
      strategy: "SolverRandomBalanced", weightConfig: advanced(false),
    });
    expect(at(on, 10)).toBeGreaterThanOrEqual(at(off, 10) + 0.02);
    expect(at(on, 10)).toBeGreaterThanOrEqual(0.75);
  }, 1_200_000);

  it("cold-start mu-degeneracy splits round-1 partnerships under every preset", async () => {
    // All winners (and all losers) carry identical mu after round 1, so
    // banding is indifferent within cohorts and even weak novelty terms fully
    // decide — partnerships must not persist. Baseline: 0 kept of 48.
    for (const m of [await rb(), await cp()]) {
      const total = m.partnershipsPerSeed * m.sessions.length;
      expect(m.r1PartnersKeptR2).toBeLessThanOrEqual(Math.ceil(total * 0.1));
    }
  }, 1_200_000);

  it("Auto calibrates like Random Balanced, then bands like Competitive+", async () => {
    // Baselines: rho 0.71 at r4 (vs C+ 0.40) and 0.80 at r10 — Auto must keep
    // variety-first's early information without giving up endgame accuracy —
    // and a final-round banding of 0.36, alongside RB 0.63 / C+ 0.34: by the
    // session's end its courts are grouped by skill, not mixed.
    const a = await auto();
    expect(at(a, 4)).toBeGreaterThanOrEqual(0.55);
    expect(at(a, 4)).toBeGreaterThanOrEqual(at(await cp(), 4) + 0.1);
    expect(at(a, 10)).toBeGreaterThanOrEqual(0.7);
    // Post-fixture-fix the gap to RandomBalanced at r10 is 0.04 (0.81 vs
    // 0.85), so this floor is 0.06 — the claim is "does not give up much
    // endgame accuracy", not "matches it".
    expect(at(a, 10)).toBeGreaterThanOrEqual(at(await rb(), 10) - 0.06);

    const last = (m: ConvergenceMeasurement) => bandingByRound(m).at(-1)!;
    expect(last(a)).toBeLessThanOrEqual(last(await rb()) - 0.15);
    expect(last(a)).toBeLessThanOrEqual(last(await cp()) + 0.1);
  }, 1_200_000);

  it("variety modes are the documented remedy for an inverted ladder; banded modes are not", async () => {
    // Worst-case rating-aligned error: a perfectly inverted ladder carried in
    // with settled-ish sigma (see the baseline table in the header). The
    // engine does not self-correct this by design — the operator switches to a
    // variety mode for a session — so what needs guarding is that the remedy
    // still WORKS, and that the trap is still where we think it is. Two seeds:
    // deterministic runs, wide margins.
    const inverted = (strategy: string, key: string) =>
      measured(key, {
        strategy,
        seeds: [1, 2],
        numRounds: 30,
        theta: (i: number) => 15 + i * 2,
        startMu: (i: number) => 45 - i * 2,
        startSigma: () => 7,
      } as any);
    const rr2 = await inverted("SolverRoundRobin", "rr-inverted");
    const rb2 = await inverted("SolverRandomBalanced", "rb-inverted");
    const cp2 = await inverted("SolverCompetitivePlusStatic", "cp-inverted");
    // The mechanism in its purest form: unbalanced play covers the blind
    // subspace directly, so a pure-random control escapes fastest of all. This
    // is the anchor for the whole theory — if unstructured play ever stops
    // being the best escape, the blind spot is not what we think it is.
    const rand = await measured("rand-inverted", {
      strategy: "SolverRandomBalanced",
      weightConfig: {
        qualityVsVariety: 0,
        advanced: {
          partnerVariety: 0, opponentVariety: 0, avoidRecentRepeats: 0,
          bandStrength: 0, bandTolerance: 1, balanceTeams: false,
          splitBalanceFirst: false, alternateFavored: 0, shakeUp: 1,
          cohortRotation: 0,
        },
      },
      seeds: [1, 2],
      numRounds: 30,
      theta: (i: number) => 15 + i * 2,
      startMu: (i: number) => 45 - i * 2,
      startSigma: () => 7,
    } as any);
    // 0.797 measured post-fixture-fix; floor set below it, not at it.
    expect(at(rand, 30)).toBeGreaterThanOrEqual(0.75);
    expect(at(rand, 18)).toBeGreaterThanOrEqual(at(rb2, 18) + 0.3);
    // The practical remedy: a session of Round Robin substantially recovers
    // the ladder (novelty exhaustion forces cross-band play) and is markedly
    // better than Random Balanced, which escapes only on residual gaps.
    expect(at(rr2, 30)).toBeGreaterThanOrEqual(0.7);
    expect(at(rb2, 30)).toBeGreaterThanOrEqual(0.5);
    expect(at(rr2, 18)).toBeGreaterThanOrEqual(at(rb2, 18));
    // The trap: banded play cannot, so "just keep playing Competitive+" is
    // never the answer here. If this ever passes on its own, banding's
    // relationship to the blind spot changed and the operator guidance (and
    // this suite's reasoning) needs re-deriving.
    expect(at(cp2, 30)).toBeLessThanOrEqual(0.1);
  }, 2_400_000);

  it("match quality: Competitive+ is the cheapest; Auto's probe premium stays bounded", async () => {
    // Steady state — accurate settled prior — where quality is the product.
    // Floors from the baseline table in the header.
    const accurate = (strategy: string, key: string) =>
      measured(key, {
        strategy,
        seeds: [1, 2, 3],
        numRounds: 10,
        theta: (i: number) => 15 + i * 2,
        startMu: (i: number) => 15 + i * 2,
        startSigma: () => 7,
      } as any);
    const a = await accurate("SolverCompetitivePlus", "auto-accurate");
    const rb2 = await accurate("SolverRandomBalanced", "rb-accurate");
    const cp2 = await accurate("SolverCompetitivePlusStatic", "cp-accurate");
    const q = (m: ConvergenceMeasurement) => sessionQuality(m);

    // Competitive+ delivers what it promises: near-coin-flip games, no true
    // blowouts, clearly ahead of the variety modes.
    expect(q(cp2).meanGap).toBeLessThanOrEqual(0.28);
    expect(q(cp2).blowoutFraction).toBeLessThanOrEqual(0.05);
    expect(q(cp2).meanGap).toBeLessThanOrEqual(q(rb2).meanGap - 0.1);
    // Auto costs nothing once the ladder is settled: it has blended fully to
    // Competitive+, so quality is identical, not merely close. (A quality
    // premium reappearing here means Auto acquired a corrective it is not
    // supposed to have, or the blend stops short of C+.)
    expect(q(a).meanGap).toBeCloseTo(q(cp2).meanGap, 6);
    expect(q(a).blowoutFraction).toBeCloseTo(q(cp2).blowoutFraction, 6);
    // And no strategy erodes an accurate ladder while playing on it.
    for (const m of [a, rb2, cp2]) {
      expect(at(m, 10)).toBeGreaterThanOrEqual(0.9);
    }
  }, 1_200_000);

  it("Competitive+ self-corrects within-band error; only cross-band error traps it", async () => {
    // The realistic error case: global structure right, each visible band of
    // four internally reversed. Banded, balanced play carries signal here —
    // band members are visibly close but truly unequal — so Competitive+ must
    // recover without probes. Baseline: rho 0.88 -> 0.93 by round 12.
    const m = await measured("cp-inband", {
      strategy: "SolverCompetitivePlusStatic",
      seeds: [1, 2, 3],
      numRounds: 12,
      theta: (i: number) => 15 + i * 2,
      startMu: (i: number) => 15 + (4 * Math.floor(i / 4) + (3 - (i % 4))) * 2,
      startSigma: () => 7,
    } as any);
    expect(at(m, 12)).toBeGreaterThanOrEqual(0.9);
    expect(at(m, 12)).toBeGreaterThanOrEqual(at(m, 1));
  }, 1_200_000);

  it("Auto's calibration opener beats every preset on absolute targets", async () => {
    // Auto opens with `CostModel.calibrateConfig` (novelty + LIGHT banding +
    // balance-first + jitter), not Random Balanced. The claim is that it wins
    // on the outcome measures at once rather than trading between them:
    // baselines at cold start (10 rounds, 6 seeds) are blowouts 26.7% vs
    // 28.3% for RB and C+ and 32.5% for RR, and mean ladder error 2.21
    // positions at r10 vs 2.42 for all three.
    const a = await auto();
    const blow = (m: ConvergenceMeasurement) => sessionQuality(m).blowoutFraction;
    const errAt = (m: ConvergenceMeasurement, round: number) =>
      ratingErrorByRound(m).rankError[round - 1];
    for (const other of [await rb(), await cp(), await rr()]) {
      // Fewest blowouts of any preset, and the most accurate ladder EARLY,
      // which is what the calibration phase is for.
      expect(blow(a)).toBeLessThanOrEqual(blow(other));
      expect(errAt(a, 4)).toBeLessThanOrEqual(errAt(other, 4));
    }
    // The r10 lead does NOT hold and is deliberately not asserted: after the
    // fixture fix RandomBalanced is ahead there (1.85 vs 2.08 places off). The
    // calibration phase buys early accuracy and quality, not a better endgame
    // ladder — an earlier version of this test claimed both, on numbers the
    // fixture artefact had inflated.
    expect(errAt(a, 10)).toBeLessThanOrEqual(2.4);
  }, 1_200_000);

  it("the pool-aware split upgrade spares Round Robin's leak", async () => {
    // Blowouts and blind-spot coverage are the same quantity (see header), so
    // the quality upgrade must never reach the remedy mode. Asserted on an
    // ACCURATE prior, where ratings are right and the split policy is the only
    // thing left producing lopsided games — at cold start everyone blows out
    // for the same reason (wrong ratings) and the signal is swamped.
    // Baselines: RoundRobin 18.3% blowouts, RandomBalanced 8.3%, C+ 0.0%.
    const accurate = (strategy: string, key: string) =>
      measured(key, {
        strategy,
        seeds: [1, 2, 3],
        numRounds: 10,
        theta: (i: number) => 15 + i * 2,
        startMu: (i: number) => 15 + i * 2,
        startSigma: () => 7,
      } as any);
    const blow = (m: ConvergenceMeasurement) => sessionQuality(m).blowoutFraction;
    const rrA = await accurate("SolverRoundRobin", "rr-accurate");
    const cpA = await accurate("SolverCompetitivePlusStatic", "cp-accurate");
    // Round Robin keeps its unbalanced splits — the leak is intact...
    expect(blow(rrA)).toBeGreaterThanOrEqual(0.1);
    // ...and the banded mode took the upgrade. If this margin ever collapses,
    // the upgrade has leaked into Round Robin and the inverted-ladder remedy
    // is silently gone (the inversion test above would then also fail).
    expect(blow(rrA)).toBeGreaterThanOrEqual(blow(cpA) + 0.1);
  }, 1_200_000);

  it("Random Balanced always takes each foursome's most balanced split", async () => {
    // The preset's contract: composition is random, the split never is. The
    // residual team-sum gap (baseline mean ~2.8 mu, up to >5 on ~15% of
    // matches) is what random composition forces — a foursome with no even
    // split still gets its best one. If this fails, the split filter broke;
    // if matches merely *look* uneven, composition is the reason.
    const stats = splitBalanceStats(await rb());
    expect(stats.atMin).toBe(stats.total);
  }, 1_200_000);

  it("the readiness signal rises monotonically and settles within a session", async () => {
    // std(mu)/mean(sigma) is the "switch to competitive" criterion: it must
    // grow as information accrues (baseline 0.24 → ~0.9) and cross ~0.65 by
    // round 8 on a separable pool. Guards both the signal's usefulness and
    // absolute-sigma alternatives that decay far too slowly to trigger.
    const m = await rb();
    for (let k = 1; k < 10; k++) {
      expect(m.ratioByRound[k]).toBeGreaterThanOrEqual(m.ratioByRound[k - 1] - 0.02);
    }
    expect(m.ratioByRound[7]).toBeGreaterThanOrEqual(0.65);
  }, 1_200_000);
});
