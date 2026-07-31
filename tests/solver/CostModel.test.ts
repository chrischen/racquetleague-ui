import { describe, expect, it } from "vitest";
import * as CostModel from "../../src/lib/rating/solver/CostModel.re.mjs";
import { makePlayer, makePool, toRound, type Match, type Player } from "./fixtures";

const config = (qualityVsVariety: number, advanced?: unknown) => ({
  qualityVsVariety,
  advanced,
});

// The alternation assertions below are independent of the weights; any set does.
const anyWeights = CostModel.weightsForStrategy("SolverRandomBalanced");

describe("CostModel weight mapping", () => {
  it("is monotone in the primary slider", () => {
    let prevSpread = -Infinity;
    let prevPartner = Infinity;
    let sawBalanceOn = false;
    for (let i = 0; i <= 20; i++) {
      const w = CostModel.weightsFromConfig(config(i / 20));
      expect(w.wSpread).toBeGreaterThanOrEqual(prevSpread);
      expect(w.wPartner).toBeLessThanOrEqual(prevPartner);
      // The balance toggle switches on once and never back off.
      if (sawBalanceOn) expect(w.balanceTeams).toBe(true);
      sawBalanceOn = sawBalanceOn || w.balanceTeams;
      prevSpread = w.wSpread;
      prevPartner = w.wPartner;
    }
    expect(sawBalanceOn).toBe(true);
  });

  it("spans the intended range at the slider extremes", () => {
    const variety = CostModel.weightsFromConfig(config(0));
    const quality = CostModel.weightsFromConfig(config(1));
    // Pure variety: quality-blind — no balancing, guardrail-only spread.
    expect(variety.wPartner).toBe(1000);
    expect(variety.balanceTeams).toBe(false);
    expect(variety.wSpread).toBe(50);
    expect(variety.spreadTolerance).toBeCloseTo(0.9, 6);
    // Pure quality: balanced splits, banding at full strength.
    expect(quality.wPartner).toBe(10);
    expect(quality.balanceTeams).toBe(true);
    expect(quality.wSpread).toBe(1000);
    expect(quality.spreadTolerance).toBeCloseTo(0, 6);
  });

  it("never drops the spread floor", () => {
    for (let i = 0; i <= 20; i++) {
      expect(
        CostModel.weightsFromConfig(config(i / 20)).wSpread,
      ).toBeGreaterThanOrEqual(50);
    }
    // Even a custom config with spread tuned to none keeps the carry-match
    // guardrail: "no concern for skill spread" must never mean "strongest
    // carries weakest".
    const custom = CostModel.weightsFromConfig(
      config(0, {
        partnerVariety: 1,
        opponentVariety: 1,
        similarSkill: 0,
        balanceTeams: false,
        avoidRecentRepeats: 1,
        alternateFavored: 0,
      }),
    );
    expect(custom.wSpread).toBeGreaterThanOrEqual(50);
    expect(custom.spreadTolerance).toBeCloseTo(0.9, 6);
  });

  it("keeps the worst-case match cost below the lowest penalty tier", () => {
    // The tier derivation in SolverRound assumes every component is in [0, 1],
    // so maxMatchCost is an exact bound. Adversarial weights must respect it.
    const adversarial = CostModel.weightsFromConfig(
      config(1, {
        partnerVariety: 1,
        opponentVariety: 1,
        similarSkill: 1,
        balanceTeams: true,
        avoidRecentRepeats: 1,
        alternateFavored: 1,
      }),
    );
    expect(CostModel.maxMatchCost(adversarial)).toBeLessThanOrEqual(7000);

    // And a real candidate never exceeds it.
    const players = makePool(4, (i) => [10, 20, 30, 45][i]);
    const match: Match = [
      [players[0], players[3]],
      [players[1], players[2]],
    ];
    const cost = CostModel.candidateCost(
      adversarial,
      CostModel.emptyHistory,
      match,
      1,
    );
    expect(cost).toBeLessThanOrEqual(CostModel.maxMatchCost(adversarial));
    expect(cost).toBeGreaterThanOrEqual(0);
  });

  it("round-trips presets through serialization", () => {
    for (const strategy of [
      "SolverRoundRobin",
      "SolverRandomBalanced",
      "SolverCompetitivePlus",
    ]) {
      const preset = CostModel.presetConfig(strategy);
      const restored = CostModel.configFromJsonString(
        CostModel.configToJsonString(preset),
      );
      expect(restored).toEqual(preset);
      expect(CostModel.weightsFromConfig(restored)).toEqual(
        CostModel.weightsFromConfig(preset),
      );
    }
  });

  it("round-trips a custom config", () => {
    const custom = config(0.42, {
      partnerVariety: 0.1,
      opponentVariety: 0.2,
      similarSkill: 0.3,
      balanceTeams: true,
      avoidRecentRepeats: 0.4,
      alternateFavored: 0.5,
    });
    const restored = CostModel.configFromJsonString(
      CostModel.configToJsonString(custom),
    );
    expect(restored).toEqual(custom);
  });

  it("reads configs stored before spread and balance were separated", () => {
    // The coupled "skillBalance" slider becomes both halves.
    const legacy = JSON.stringify({
      qualityVsVariety: 0.5,
      advanced: {
        partnerVariety: 0.6,
        opponentVariety: 0.4,
        skillBalance: 0.7,
        avoidRecentRepeats: 0.3,
        alternateFavored: 0.2,
      },
    });
    const restored = CostModel.configFromJsonString(legacy);
    expect(restored.advanced.similarSkill).toBeCloseTo(0.7, 6);
    expect(restored.advanced.balanceTeams).toBe(true);
    const low = CostModel.configFromJsonString(
      legacy.replace('"skillBalance":0.7', '"skillBalance":0.1'),
    );
    expect(low.advanced.balanceTeams).toBe(false);
  });

  it("returns nothing for malformed stored config", () => {
    expect(CostModel.configFromJsonString("not json")).toBeUndefined();
    expect(CostModel.configFromJsonString("{}")).toBeUndefined();
  });

  it("derives advanced slider positions that reproduce the primary weights", () => {
    for (const t of [0.15, 0.5, 0.85]) {
      const derived = CostModel.weightsFromConfig(config(t));
      const viaAdvanced = CostModel.weightsFromConfig(
        config(t, CostModel.advancedFromPrimary(t)),
      );
      expect(viaAdvanced.wPartner).toBeCloseTo(derived.wPartner, 0);
      expect(viaAdvanced.balanceTeams).toBe(derived.balanceTeams);
      expect(viaAdvanced.wSpread).toBeCloseTo(derived.wSpread, 0);
      expect(viaAdvanced.spreadTolerance).toBeCloseTo(derived.spreadTolerance, 6);
    }
  });
});

describe("CostModel preset profiles", () => {
  // The presets are named profiles, deliberately off the qualityVsVariety
  // axis; these pin the structural properties each use case depends on.
  const rr = CostModel.weightsForStrategy("SolverRoundRobin"); // Round Robin
  const rb = CostModel.weightsForStrategy("SolverRandomBalanced"); // Random Balanced
  const cp = CostModel.weightsForStrategy("SolverCompetitivePlus"); // Competitive+

  it("keeps novelty dominant in the novelty-first presets", () => {
    // One repeated partnership (repeatFloor 0.4 of the normalized scale) must
    // outweigh the entire quality swing of a match, or quality could buy a
    // repeat and the round-robin contract breaks. Balance is absent: it is a
    // hard filter, not a weight, so it cannot participate in this trade.
    for (const w of [rr, rb]) {
      expect(0.4 * w.wPartner).toBeGreaterThan(
        w.wSpread + w.wAlternate + w.wNoise,
      );
    }
  });

  it("distinguishes the novelty-first presets by their spread tiebreak", () => {
    // Balance is boolean, and on, for both.
    for (const w of [rr, rb]) expect(w.balanceTeams).toBe(true);
    // Round Robin starts competitive: tiebreak-sized banding, tight shape,
    // deterministic.
    expect(rr.wSpread).toBe(140);
    expect(rr.spreadTolerance).toBeCloseTo(0.25, 6);
    expect(rr.wNoise).toBe(0);
    // Random Balanced is skill-blind in composition: guardrail floor only,
    // wide tolerance, with tie-breaking jitter.
    expect(rb.wSpread).toBe(50);
    expect(rb.spreadTolerance).toBeCloseTo(0.9, 6);
    expect(rb.wNoise).toBeGreaterThan(0);
    // Split policy: Random Balanced keeps its defining promise — the balanced
    // split — even over a fresh partnership; the whist-contract modes never do.
    expect(rb.splitBalanceFirst).toBe(true);
    expect(rr.splitBalanceFirst).toBe(false);
    expect(cp.splitBalanceFirst).toBe(false);
  });

  it("tunes Competitive+ spread to max, per its use case", () => {
    expect(cp.balanceTeams).toBe(true);
    expect(cp.wSpread).toBeGreaterThan(800);
    expect(cp.spreadTolerance).toBeLessThan(0.2);
  });

  it("rotates cohorts only in leveled play, and never at the cost of a game", () => {
    // Competitive+ fills the court strongest-first among fairness ties, so
    // bands break together; rotation-driven modes stay skill-blind.
    expect(cp.wCohort).toBe(600);
    expect(rr.wCohort).toBe(0);
    expect(rb.wCohort).toBe(0);
    // The cap sits below one game of count-deficit, so cohort ordering can
    // reorder ties but never trade play time.
    expect(CostModel.maxCohortWeight).toBeLessThan(4000 / 3);
  });

  it("keeps Competitive+ on the slider axis, plus the cohort guardrail", () => {
    expect(cp).toEqual({
      ...CostModel.weightsFromConfig({ qualityVsVariety: 0.85, advanced: undefined }),
      wCohort: CostModel.maxCohortWeight,
    });
  });

  it("keeps every profile inside the penalty-tier contract", () => {
    for (const w of [rr, rb, cp]) {
      expect(CostModel.maxMatchCost(w)).toBeLessThanOrEqual(7000);
    }
  });
});

describe("CostModel side derivation", () => {
  // Ratings at the time of the match, not current ratings.
  const strongThen = (id: string) =>
    makePlayer(0, { id, name: id, mu: 40, sigma: 2 });
  const weakThen = (id: string) => makePlayer(0, { id, name: id, mu: 20, sigma: 2 });

  it("uses the ratings the match was played at, not current ones", () => {
    const historicMatch: Match = [
      [strongThen("a"), strongThen("b")],
      [weakThen("c"), weakThen("d")],
    ];
    const rounds = [toRound([historicMatch])];

    // Current ratings are the exact inverse of the historical ones: naively
    // recomputing sides from these would flip every side in the fixture.
    const current: Player[] = [
      makePlayer(0, { id: "a", mu: 20, sigma: 2 }),
      makePlayer(1, { id: "b", mu: 20, sigma: 2 }),
      makePlayer(2, { id: "c", mu: 40, sigma: 2 }),
      makePlayer(3, { id: "d", mu: 40, sigma: 2 }),
    ];

    const history = CostModel.buildHistory(rounds, current);
    expect(history.lastSide.get("a")).toBe("Favored");
    expect(history.lastSide.get("b")).toBe("Favored");
    expect(history.lastSide.get("c")).toBe("Unfavored");
    expect(history.lastSide.get("d")).toBe("Unfavored");
  });

  it("treats a dead-zone match as Even and leaves the demand unchanged", () => {
    const evenMatch: Match = [
      [strongThen("a"), weakThen("b")],
      [strongThen("c"), weakThen("d")],
    ];
    const [side1, side2] = CostModel.matchSides(evenMatch);
    expect(side1).toBe("Even");
    expect(side2).toBe("Even");

    const lopsided: Match = [
      [strongThen("a"), strongThen("b")],
      [weakThen("c"), weakThen("d")],
    ];
    const players = ["a", "b", "c", "d"].map((id, i) =>
      makePlayer(i, { id, mu: 30, sigma: 2 }),
    );

    // Round 0 sets a side; round 1 is Even and must not overwrite it.
    const history = CostModel.buildHistory(
      [toRound([lopsided], 0), toRound([evenMatch], 1)],
      players,
    );
    expect(history.lastSide.get("a")).toBe("Favored");
    expect(history.lastSide.get("c")).toBe("Unfavored");
  });

  it("charges an alternation mismatch only for a repeated non-Even side", () => {
    const lopsided: Match = [
      [strongThen("a"), strongThen("b")],
      [weakThen("c"), weakThen("d")],
    ];
    const players = ["a", "b", "c", "d"].map((id, i) =>
      makePlayer(i, { id, mu: 30, sigma: 2 }),
    );
    const history = CostModel.buildHistory([toRound([lopsided])], players);

    // Same sides again: all four players repeat.
    expect(CostModel.costParts(anyWeights, history, lopsided).alternate).toBe(1);

    // Roles reversed — a/b are now the underdogs, c/d the favourites — so
    // nobody repeats a side.
    const reversed: Match = [
      [weakThen("a"), weakThen("b")],
      [strongThen("c"), strongThen("d")],
    ];
    expect(CostModel.costParts(anyWeights, history, reversed).alternate).toBe(0);

    // A dead-zone match never counts as a repeat either.
    const even: Match = [
      [strongThen("a"), weakThen("c")],
      [strongThen("b"), weakThen("d")],
    ];
    expect(CostModel.costParts(anyWeights, history, even).alternate).toBe(0);

    // No history at all: nothing to repeat.
    expect(CostModel.costParts(anyWeights, CostModel.emptyHistory, lopsided).alternate).toBe(
      0,
    );
  });
});

describe("CostModel bye fairness", () => {
  it("ranks games-played deficit above bye streak", () => {
    const behind = makePlayer(0, { id: "behind", count: 3 });
    const caughtUp = makePlayer(1, { id: "caught", count: 4 });
    const players = [behind, caughtUp];

    // `caught` has the longer streak; `behind` has played one game fewer.
    const history = {
      ...CostModel.emptyHistory,
      maxPlayedCount: 4,
      avgPlayedCount: 3.5,
      roundsSinceLastBye: new Map([
        ["behind", 0],
        ["caught", 6],
      ]),
    };

    const benefitBehind = CostModel.playerBenefit(anyWeights, history, behind, false);
    const benefitCaught = CostModel.playerBenefit(anyWeights, history, caughtUp, false);
    expect(benefitBehind).toBeGreaterThan(benefitCaught);
    expect(players).toHaveLength(2);
  });

  it("stays within its declared bound", () => {
    const history = {
      ...CostModel.emptyHistory,
      maxPlayedCount: 99,
      roundsSinceLastBye: new Map([["p0", 99]]),
    };
    const benefit = CostModel.playerBenefit(
      CostModel.weightsForStrategy("SolverCompetitivePlus"), // cohort at its cap
      history,
      makePlayer(0, { count: 0 }),
      true,
    );
    expect(benefit).toBeLessThanOrEqual(CostModel.maxPlayerBenefit);
  });
});
