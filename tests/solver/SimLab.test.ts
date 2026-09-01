// The visualisation lab drives the real solver and the real rating pipeline,
// so it can drift from the harness the convergence suite measures with. These
// pin the parts a viewer would silently get wrong: that every scenario builds
// the prior it claims to, that a run actually produces rounds, and that the
// metrics agree with the ones the suite asserts on.
import { describe, expect, it } from "vitest";
import * as SimLab from "../../src/lib/rating/SimLab.re.mjs";
import * as Rating from "../../src/lib/Rating.re.mjs";
import * as SolverPrng from "../../src/lib/rating/solver/SolverPrng.re.mjs";

const run = (scenario: string, opts: Partial<{ rounds: number; players: number; courts: number }> = {}) =>
  SimLab.run(
    scenario,
    1,
    opts.players ?? 8,
    opts.courts ?? 2,
    opts.rounds ?? 3,
    undefined,
    false,
    undefined,
  );

describe("SimLab scenarios", () => {
  it("builds the prior each scenario claims", () => {
    // The ladder is an S curve with two outliers, not a linear ramp.
    const truth = (i: number) => SimLab.trueSkill(i, 8, SimLab.variedField);
    // (scenario, slot, ladder rank, poolSize). Slot and rank are independent in
    // a real run; here they are passed equal so each scenario's shape can be
    // read off directly.
    const mu = (scenario: string, rank: number) =>
      SimLab.startingRating(scenario, rank, rank, 8, SimLab.variedField).mu;

    // Cold start: everyone identical, so nothing is known.
    expect(mu("ColdStart", 0)).toBe(mu("ColdStart", 7));
    // Accurate: visible == true.
    expect(mu("AccuratePrior", 3)).toBeCloseTo(truth(3), 6);
    // Inverted: the exact mirror — strongest reads weakest.
    expect(mu("Inverted", 0)).toBeCloseTo(truth(7), 6);
    expect(mu("Inverted", 7)).toBeCloseTo(truth(0), 6);
    // The distribution itself: a bunched middle between two outliers.
    const ladder = Array.from({ length: 18 }, (_, i) => SimLab.trueSkill(i, 18, SimLab.variedField));
    expect(ladder[0]).toBeLessThan(ladder[1] - 8); // beginner, far below
    expect(ladder[17]).toBeGreaterThan(ladder[16] + 8); // ringer, far above
    // The tight field is the other room: a bunched pack with nobody outside it.
    const tight = Array.from({ length: 18 }, (_, i) => SimLab.trueSkill(i, 18, SimLab.tightField));
    expect(tight[0]).toBeGreaterThan(ladder[0] + 8); // no beginner far below
    expect(tight[17]).toBeLessThan(ladder[17] - 8); // no ringer far above
    const midGap = tight[9] - tight[8];
    const edgeGap = tight[16] - tight[15];
    expect(midGap).toBeGreaterThan(0.1); // tight, but not a tie
    expect(edgeGap).toBeGreaterThan(midGap * 2); // and the edges still spread
    // Within-band: each band of four reversed, global order intact.
    expect(mu("WithinBandInverted", 0)).toBeCloseTo(truth(3), 6);
    expect(mu("WithinBandInverted", 4)).toBeCloseTo(truth(7), 6);
    // Newcomers: flagged players sit at the default rating regardless of skill.
    expect(SimLab.isFlagged("NewcomerInjection", 1, 8)).toBe(true);
    expect(mu("NewcomerInjection", 1)).toBe(25);
    expect(mu("NewcomerInjection", 0)).toBeCloseTo(truth(0), 6);
  });

  it("a player's slot carries no information about their skill", () => {
    // The fixture used to create players in true-skill order, so any
    // deterministic tie-break in the solver paired adjacent slots — which were
    // adjacent in real skill — and handed the zero-jitter strategies
    // accidentally well-matched opening rounds. If slot order ever correlates
    // with the ladder again, that artefact is back.
    const ranks = SimLab.ladderPermutation(1, 18);
    expect([...ranks].sort((a: number, b: number) => a - b)).toEqual(
      Array.from({ length: 18 }, (_, i) => i),
    );
    const identity = ranks.every((r: number, i: number) => r === i);
    expect(identity).toBe(false);
    // Deterministic per seed, and different across seeds.
    expect(SimLab.ladderPermutation(1, 18)).toEqual(ranks);
    expect(SimLab.ladderPermutation(2, 18)).not.toEqual(ranks);
  });

  it("metrics agree with the convergence suite's definitions", () => {
    const truth = [1, 2, 3, 4];
    // Perfect ordering.
    expect(SimLab.spearman([1, 2, 3, 4], truth)).toBeCloseTo(1, 6);
    expect(SimLab.rankError([1, 2, 3, 4], truth)).toBe(0);
    // Exactly reversed.
    expect(SimLab.spearman([4, 3, 2, 1], truth)).toBeCloseTo(-1, 6);
    expect(SimLab.rankError([4, 3, 2, 1], truth)).toBe(2);
    // Scale and offset must not matter — both are standardised.
    expect(SimLab.muError([10, 20, 30, 40], truth)).toBeCloseTo(0, 6);
  });

  it("runs every strategy through the real solver and scores every match", async () => {
    const result = await run("ColdStart");
    expect(result.runs.length).toBe(SimLab.strategies.length);
    for (const r of result.runs) {
      // One frame before play, then one per round.
      expect(r.entry.id).toBeTruthy();
      expect(r.frames.length).toBe(4);
      expect(r.frames[0].games.length).toBe(0);
      for (let k = 1; k < r.frames.length; k++) {
        const frame = r.frames[k];
        expect(frame.games.length).toBe(2); // two courts
        for (const g of frame.games) {
          // A real result: one side reached 11, probabilities are probabilities.
          expect(Math.max(g.team1Score, g.team2Score)).toBe(11);
          expect(g.predictedWinProb).toBeGreaterThan(0);
          expect(g.predictedWinProb).toBeLessThan(1);
          expect(g.trueWinProb).toBeGreaterThan(0);
          expect(g.trueWinProb).toBeLessThan(1);
        }
        expect(frame.blowoutRate).not.toBeUndefined();
        // The typical-game statistic: the literal median of this round's
        // per-game draw probabilities, present whenever games were played.
        const qs = frame.games.map((g: any) => g.trueDraw).sort((a: number, b: number) => a - b);
        const expected = qs.length % 2
          ? qs[qs.length >> 1]
          : (qs[qs.length / 2 - 1] + qs[qs.length / 2]) / 2;
        expect(frame.medianDrawProb).toBeCloseTo(expected, 10);
      }
      // No games yet, no typical game.
      expect(r.frames[0].medianDrawProb).toBeUndefined();
    }
  }, 300_000);

  it("every engine fills every court, every round", async () => {
    // The open-play builders allocate courts themselves rather than going
    // through the solver, so an empty court is a real failure mode: US style
    // splits the pool into two levels and neither may have four spare players.
    const result = await SimLab.run("ColdStart", 1, 18, 3, 6, undefined, false, undefined);
    for (const r of result.runs) {
      for (let k = 1; k < r.frames.length; k++) {
        expect(r.frames[k].games.length).toBe(3);
      }
      // And nobody is on two courts at once.
      for (let k = 1; k < r.frames.length; k++) {
        const seated = r.frames[k].games.flatMap((g: any) => [...g.team1, ...g.team2]);
        expect(new Set(seated).size).toBe(seated.length);
      }
    }
  }, 600_000);

  it("the typical field is about a 1.0 DUPR spread", () => {
    const sk = Array.from({ length: 18 }, (_, i) =>
      SimLab.trueSkill(i, 18, SimLab.typicalField));
    const spread = Rating.guessDupr(Math.max(...sk)) - Rating.guessDupr(Math.min(...sk));
    expect(spread).toBeGreaterThan(0.8);
    expect(spread).toBeLessThan(1.1);
    // And no outliers: the ends are not detached from the pack.
    expect(sk[1] - sk[0]).toBeLessThan(4);
  });

  it("drift picks the documented shares and holds them for the run", async () => {
    const roles = SimLab.driftRoles(18, 1);
    const count = (r: string) => roles.filter((x: string) => x === r).length;
    expect(count("Slipping")).toBe(1); // ~5%
    expect(count("ImprovingFast")).toBe(1); // ~5%
    expect(count("Improving")).toBe(4); // ~20%
    expect(count("Steady")).toBe(12);
    // Same seed, same people — every strategy in a run faces one world.
    expect(SimLab.driftRoles(18, 1)).toEqual(roles);
    expect(SimLab.driftRoles(18, 2)).not.toEqual(roles);
    // Truth actually moves, and only for those six.
    const base = Array.from({ length: 18 }, (_, i) => SimLab.trueSkill(i, 18, SimLab.typicalField));
    const later = SimLab.truthAt(base, roles, 30);
    const moved = base.filter((v: number, i: number) => Math.abs(later[i] - v) > 0.01);
    expect(moved.length).toBe(6);
  });

  it("tournament mode caps how many partners anyone gets", async () => {
    // Squads of four give three partners; 18 players leaves two squads of five,
    // so four is the worst case. Without it players meet a dozen partners.
    const t = await SimLab.run("ColdStart", 1, 18, 3, 15, SimLab.typicalField, true, undefined);
    const maxPartners = (result: any) =>
      Math.max(...result.runs.map((run: any) => {
        const partners = new Map<string, Set<string>>();
        for (const f of run.frames.slice(1)) for (const g of f.games)
          for (const team of [g.team1, g.team2])
            for (const [a, b] of [[team[0], team[1]], [team[1], team[0]]]) {
              if (!partners.has(a)) partners.set(a, new Set());
              partners.get(a)!.add(b);
            }
        return Math.max(...[...partners.values()].map((x) => x.size));
      }));
    expect(maxPartners(t)).toBeLessThanOrEqual(4);
    const free = await SimLab.run("ColdStart", 1, 18, 3, 15, SimLab.typicalField, false, undefined);
    expect(maxPartners(free)).toBeGreaterThan(6);
    // And every court still fills.
    for (const run of t.runs)
      for (let k = 1; k < run.frames.length; k++)
        expect(run.frames[k].games.length).toBe(3);
  }, 900_000);

  it("the progress total is an upper bound the run never passes", async () => {
    // The counter is driven by a per-round callback while the total is computed
    // up front, so the two are easy to drift apart — the total once said two
    // fields while the run did three, and the progress readout sailed past it.
    const rounds = 4, seeds = 2;
    const total = rounds * SimLab.strategies.length * SimLab.fields.length * seeds;
    let fired = 0;
    for (let i = 0; i < seeds; i++)
      for (const field of SimLab.fields)
        await SimLab.run("ColdStart", 1 + i, 18, 3, rounds, field, false, () => { fired++; });
    expect(fired).toBe(total);
  }, 900_000);

  it("drift tapers toward a hard cap of half a DUPR", () => {
    // Improvement is a saturating curve: fastest early, slowing as the player
    // settles, never passing the cap. Drift was once linear and unbounded,
    // which un-tightened the tight room mid-run and made long-horizon results
    // partly a measure of drift response.
    const cap = 0.5 * (Rating.duprToMu(4.0) - Rating.duprToMu(3.0));
    const at = (round: number) => SimLab.driftAt("ImprovingFast", round);
    expect(at(40) / cap).toBeCloseTo(1 - Math.exp(-1), 3); // ~63% by round 40
    expect(at(100) / cap).toBeCloseTo(1 - Math.exp(-2.5), 3); // ~92% by round 100
    expect(at(40) - at(0)).toBeGreaterThan(at(100) - at(60)); // decelerating
    for (const r of [10, 50, 100, 1000]) expect(at(r)).toBeLessThan(cap + 1e-9);
    // The gradual movers follow the same arc at 0.15 DUPR, slipping mirrored.
    expect(SimLab.driftAt("Slipping", 100)).toBeCloseTo(-0.3 * at(100), 6);
    expect(SimLab.driftAt("Steady", 100)).toBe(0);
  });

  it("match quality reads composition, not rating confidence", () => {
    // The quality of a game between known skills is a property of who is on
    // the court. `trueDraw` once kept each player's live sigma, so the SAME
    // matchup read as higher quality later in the session — every strategy's
    // quality curve climbed with confidence rather than with better matches,
    // and the Random baseline, whose composition cannot improve, climbed all
    // session anyway.
    const team = (ids: number[], sigma: number) =>
      ids.map((i) => ({ intId: i, rating: { mu: 25, sigma } }));
    const truth = [30, 20, 26, 24];
    const confident = SimLab.drawProbability([team([0, 1], 0.5), team([2, 3], 0.5)], truth);
    const uncertain = SimLab.drawProbability([team([0, 1], 25 / 3), team([2, 3], 25 / 3)], truth);
    expect(confident).toBeCloseTo(uncertain, 12);
    // And it still orders compositions: a stacked split reads worse than an
    // even one of the same four players.
    const stacked = SimLab.drawProbability([team([0, 2], 0.5), team([1, 3], 0.5)], truth);
    expect(stacked).toBeLessThan(confident);
    // And it stays a probability. The first fix here pinned truth-sigma to 0,
    // where openskill's draw heuristic leaves its calibrated regime and a
    // near-even match reads MORE than certain — Balanced Round Robin's median
    // game quality came out at 102%.
    const dead = SimLab.drawProbability([team([0, 1], 1), team([2, 3], 1)], [30, 26, 29, 27]);
    expect(dead).toBeGreaterThan(0.5);
    expect(dead).toBeLessThanOrEqual(1);
  });

  it("JP-style splits an obviously lopsided foursome even at a cold start", () => {
    // The split is the organiser's eyes, not the database. It used to read
    // the visible ratings, so at a cold start — every mu identical — it never
    // fired, exactly when the style is supposed to earn its edge over random;
    // and once ratings converged, the "rating-free" baseline was quietly
    // borrowing the knowledge of the system it is a control for.
    const prng = SolverPrng.fromSeedString("jp-split");
    const quad = [0, 1, 2, 3].map((i) => ({
      intId: i,
      id: `p${i}`,
      name: `P${i}`,
      rating: { mu: 25, sigma: 25 / 3 }, // cold start: nothing visible to split on
    }));
    // A 28-mu pair gap is over a full DUPR — far past the half-DUPR bar for
    // "obviously unbalanced".
    const truth = [40, 38, 12, 10];
    const strongIn = (team: any[]) => team.filter((p) => p.intId <= 1).length;
    for (let k = 0; k < 10; k++) {
      const [t1, t2] = SimLab.splitJapan(quad, truth, prng);
      expect(new Set(t1.concat(t2).map((p: any) => p.intId)).size).toBe(4);
      // Each side gets exactly one of the two strong players.
      expect(strongIn(t1)).toBe(1);
      expect(strongIn(t2)).toBe(1);
    }

    // Below the bar, nobody bothers: a 4-mu pair gap (~0.15 DUPR) is left to
    // chance, so across draws the strong pair sometimes stays stacked. This is
    // what makes the style tail-only — the threshold was once ~0.35 DUPR in a
    // typical room, which fired on ordinary foursomes and quietly turned a
    // "we only fix the obvious ones" culture into a bulk intervention.
    const mild = [30, 28, 26, 24];
    let stacked = 0;
    for (let k = 0; k < 20; k++) {
      const [t1] = SimLab.splitJapan(quad, mild, prng);
      if (strongIn(t1) !== 1) stacked++;
    }
    expect(stacked).toBeGreaterThan(0);
  });

  it("a US-style blowout is run back once, never chained", async () => {
    // The revenge rule once had no memory: any blowout from the previous
    // round carried, and a genuinely mismatched foursome blows out every time
    // it plays — so it carried forever. Measured, 84 of 120 US games were
    // repeats, with chains up to 30 rounds: three of four courts frozen on
    // the same drubbing all session. A blowout may now carry exactly once;
    // only a TIGHT result (which a blowout cannot be) keeps a group on court
    // beyond that, and that decays at 50% per round.
    const matchKey = (g: any) => {
      const side = (t: string[]) => [...t].sort().join("+");
      return [side(g.team1), side(g.team2)].sort().join(" vs ");
    };
    const res = await SimLab.run("ColdStart", 1, 24, 4, 20, SimLab.typicalField, false, undefined);
    const frames = res.runs.find((x: any) => x.entry.id === "us").frames.slice(1);
    for (let k = 0; k + 2 < frames.length; k++) {
      const later = new Map(frames[k + 2].games.map((g: any) => [matchKey(g), g]));
      for (const g of frames[k + 1].games) {
        const key = matchKey(g);
        const inPrev = frames[k].games.some((p: any) => matchKey(p) === key);
        // Third consecutive appearance is only legal via the tight-game stay,
        // and a blowout is never tight.
        if (inPrev && g.isBlowout) expect(later.has(key)).toBe(false);
      }
    }
  }, 900_000);

  it("is deterministic per seed", async () => {
    const [a, b] = await Promise.all([run("ColdStart"), run("ColdStart")]);
    const ladder = (r: any) => r.runs.map((x: any) => x.frames.at(-1).mu);
    expect(ladder(a)).toEqual(ladder(b));
  }, 300_000);

  it("an inverted ladder starts wrong and stays measurable", async () => {
    const result = await run("Inverted", { rounds: 2 });
    for (const r of result.runs) {
      // Round 0 is the prior: a perfect inversion reads as rho = -1.
      expect(r.frames[0].spearman).toBeCloseTo(-1, 6);
      // And the ladder error is the maximum a pool of 8 can carry.
      expect(r.frames[0].rankError).toBe(4);
    }
  }, 300_000);
});
