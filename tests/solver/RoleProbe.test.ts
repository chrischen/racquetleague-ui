// The role probe pins one player to the favored or unfavored side by
// re-splitting the foursome the matchmaker chose. These pin that it does
// exactly that and nothing else: same four on the court, the target met
// whenever any split can meet it.
//
// Runs are compared by outcome, not frame by frame: the solver's 1 s time
// limit makes two runs on the same seed diverge after a few rounds whenever a
// round hits the limit, so no test here assumes bit-identical replays.
import { describe, expect, it } from "vitest";
import * as SimLab from "../../src/lib/rating/SimLab.re.mjs";
import * as RoleAnalysis from "../../src/lib/rating/RoleAnalysis.re.mjs";

const cp = SimLab.strategies.find((s: any) => s.id === "cp");
const ROUNDS = 10;

const runWith = (probe: unknown, scenario = "ColdStart", field = SimLab.typicalField) =>
  SimLab.run(scenario, 1, 24, 4, ROUNDS, field, false, undefined, [cp], probe);

// The regular player nearest the middle of the true ladder.
const medianPlayer = (res: any) => {
  const ranks = SimLab.ranksOf(res.truth);
  const mid = (res.truth.length - 1) / 2;
  let best = -1;
  res.truth.forEach((_: number, i: number) => {
    if (res.dropIns[i]) return;
    if (best < 0 || Math.abs(ranks[i] - mid) < Math.abs(ranks[best] - mid)) best = i;
  });
  return best;
};

// Just enough of a player for the win-probability model.
const pl = (intId: number, mu: number) => ({ intId, id: `p${intId}`, rating: { mu, sigma: 2 } });
const ids = (match: any) => [match[0].map((p: any) => p.intId), match[1].map((p: any) => p.intId)];

describe("applyRoleProbe", () => {
  // Player 0 (mu 25) partnered with the weakest, facing the two strongest.
  const match = [[pl(0, 25), pl(1, 15)], [pl(2, 35), pl(3, 30)]];
  const probe = (target: string, pick = "Nearest", margin = 0) => ({ playerIntId: 0, target, margin, pick });

  it("keeps the matchmaker's split when it already meets the target", () => {
    expect(SimLab.applyRoleProbe(match, probe("ForceUnfavored"), undefined)).toBe(match);
  });

  it("re-splits the same four, keeping the probed player's side of the court", () => {
    // Favored needs a stronger partner: player 3 gives 55 v 50.
    const out = SimLab.applyRoleProbe(match, probe("ForceFavored"), undefined);
    expect(ids(out)).toEqual([[0, 3], [1, 2]]);
    expect(SimLab.ownWinProbIn(out, 0)).toBeGreaterThan(0.5);
    // Team 2 orientation is preserved too.
    const flipped = [match[1], match[0]];
    expect(ids(SimLab.applyRoleProbe(flipped, probe("ForceFavored"), undefined))).toEqual([[1, 2], [0, 3]]);
  });

  it("Nearest takes the least one-sided achieving split, Farthest the most", () => {
    // Favored splits: partner 2 (60 v 45) and partner 3 (55 v 50).
    expect(ids(SimLab.applyRoleProbe(match, probe("ForceFavored"), undefined))).toEqual([[0, 3], [1, 2]]);
    expect(ids(SimLab.applyRoleProbe(match, probe("ForceFavored", "Farthest"), undefined))).toEqual([[0, 2], [1, 3]]);
    const near = SimLab.applyRoleProbe([[pl(0, 25), pl(2, 35)], [pl(1, 15), pl(3, 30)]], probe("ForceFavored", "Nearest", 0), undefined);
    // Already favored with 2, so Nearest keeps the matchmaker's split.
    expect(ids(near)).toEqual([[0, 2], [1, 3]]);
    const far = SimLab.applyRoleProbe(match, probe("ForceUnfavored", "Farthest"), undefined);
    // Most unfavored: partner 1 (40 v 65) — the matchmaker's own split.
    expect(ids(far)).toEqual([[0, 1], [2, 3]]);
  });

  it("alternates against the last sided game", () => {
    const afterFavored = SimLab.applyRoleProbe(match, probe("ForceAlternate"), 0.7);
    expect(SimLab.ownWinProbIn(afterFavored, 0)).toBeLessThan(0.5);
    const afterUnfavored = SimLab.applyRoleProbe(match, probe("ForceAlternate"), 0.3);
    expect(SimLab.ownWinProbIn(afterUnfavored, 0)).toBeGreaterThan(0.5);
  });

  it("leaves matches without the player, or with no achieving split, alone", () => {
    const other = { ...probe("ForceFavored"), playerIntId: 9 };
    expect(SimLab.applyRoleProbe(match, other, undefined)).toBe(match);
    // A ringer cannot be made the underdog.
    const ringer = [[pl(0, 60), pl(1, 15)], [pl(2, 20), pl(3, 18)]];
    expect(SimLab.applyRoleProbe(ringer, probe("ForceUnfavored"), undefined)).toBe(ringer);
  });
});

describe("role probe", () => {
  it("runs only the entries asked for", async () => {
    const res = await runWith(undefined);
    expect(res.runs.length).toBe(1);
    expect(res.runs[0].entry.id).toBe("cp");
  }, 300_000);

  it("holds the player to the target whenever a split allows it", async () => {
    const baseline = await runWith(undefined);
    const player = medianPlayer(baseline);
    for (const target of ["ForceFavored", "ForceUnfavored", "ForceAlternate"]) {
      for (const margin of [0, 0.05]) {
        const probe = { playerIntId: player, target, margin, pick: "Nearest" };
        const res = await runWith(probe);
        const out = RoleAnalysis.probeOutcome(res, 0, probe);
        expect(out.played).toBeGreaterThan(0);
        expect(out.achievable).toBeGreaterThan(0);
        expect(out.achieved).toBe(out.achievable);
      }
    }
  }, 300_000);

  it("the Farthest pick is at least as one-sided as Nearest", async () => {
    const baseline = await runWith(undefined);
    const player = medianPlayer(baseline);
    const near = { playerIntId: player, target: "ForceFavored", margin: 0, pick: "Nearest" };
    const far = { ...near, pick: "Farthest" };
    const a = RoleAnalysis.probeOutcome(await runWith(near), 0, near);
    const b = RoleAnalysis.probeOutcome(await runWith(far), 0, far);
    expect(b.achieved).toBe(b.achievable);
    expect(b.meanEdge).toBeGreaterThanOrEqual(a.meanEdge - 1e-9);
  }, 300_000);

  it("leaves the match alone when no split can meet the target", async () => {
    // With accurate ratings on the varied field, the ringer cannot be made an
    // underdog in most foursomes.
    const baseline = await runWith(undefined, "AccuratePrior", SimLab.variedField);
    const ranks = SimLab.ranksOf(baseline.truth);
    const ringer = ranks.indexOf(ranks.length - 1);
    const probe = { playerIntId: ringer, target: "ForceUnfavored", margin: 0, pick: "Nearest" };
    const res = await runWith(probe, "AccuratePrior", SimLab.variedField);
    const out = RoleAnalysis.probeOutcome(res, 0, probe);
    expect(out.achieved).toBe(out.achievable);
    expect(out.achievable).toBeLessThan(out.played);
  }, 300_000);
});
