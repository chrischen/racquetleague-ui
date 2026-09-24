// Per-player role metrics for the role-probe experiment. The side a player was
// on is read from their seat, never assumed, because the solver orients each
// match at random; these pin that and the streak / partner / error
// definitions the experiment's conclusions rest on.
import { describe, expect, it } from "vitest";
import * as SimLab from "../../src/lib/rating/SimLab.re.mjs";
import * as RoleAnalysis from "../../src/lib/rating/RoleAnalysis.re.mjs";

const game = (ids: number[], p: number, s1 = 11, s2 = 5) => ({
  courtIndex: 0,
  team1: [],
  team2: [],
  playerIndices: ids,
  team1Score: s1,
  team2Score: s2,
  predictedWinProb: p,
  trueWinProb: p,
  isBlowout: false,
  isUpset: false,
  predictedDraw: 0.1,
  trueDraw: 0.1,
});

const frame = (round: number, games: any[], mu = [25, 25, 25, 25, 25]) => ({
  round,
  mu,
  sigma: mu.map(() => 5),
  games,
  byes: [],
});

// Five players, truth ascending by index; player 4 sits out as a drop-in.
const result = (frames: any[]) => ({
  truth: [10, 20, 30, 40, 50],
  driftRoles: ["Steady", "Steady", "Steady", "Steady", "Steady"],
  dropIns: [false, false, false, false, true],
  runs: [{ entry: SimLab.strategies[0], frames, fellBackToGreedy: false }],
});

describe("seat and side", () => {
  it("reads the side from the seat, in either orientation", () => {
    const g = game([0, 1, 2, 3], 0.7);
    expect(RoleAnalysis.ownWinProb(g, 0)).toBeCloseTo(0.7, 9);
    expect(RoleAnalysis.ownWinProb(g, 3)).toBeCloseTo(0.3, 9);
    expect(RoleAnalysis.ownWinProb(g, 4)).toBeUndefined();
    expect(RoleAnalysis.partnerOf(g, 0)).toBe(1);
    expect(RoleAnalysis.partnerOf(g, 3)).toBe(2);
    expect(RoleAnalysis.opponentsOf(g, 0)).toEqual([2, 3]);

    const flipped = game([2, 3, 0, 1], 0.3);
    expect(RoleAnalysis.ownWinProb(flipped, 0)).toBeCloseTo(0.7, 9);
    expect(RoleAnalysis.partnerOf(flipped, 0)).toBe(1);
    expect(RoleAnalysis.opponentsOf(flipped, 0)).toEqual([2, 3]);
    expect(RoleAnalysis.ownWon(flipped, 0)).toBe(false);
  });
});

describe("playerRole", () => {
  // Player 0's sides: F, (Even), F, U, with partners 1, 2, 1, 3.
  const frames = [
    frame(0, []),
    frame(1, [game([0, 1, 2, 3], 0.7)]),
    frame(2, [game([2, 3, 0, 2], 0.5)]), // p = 0.5 → Even (ids reuse is fine here)
    frame(3, [game([3, 2, 0, 1], 0.2, 5, 11)]),
    frame(4, [game([0, 3, 1, 2], 0.4, 11, 7)]),
  ];
  const r = result(frames);
  const role = RoleAnalysis.playerRole(r, 0, { fromRound: 1, toRound: 4 }, undefined, 0);

  it("counts streaks and alternations over sided games only", () => {
    expect(role.gamesPlayed).toBe(4);
    expect(role.meaningfulGames).toBe(3);
    // F, F, U: the Even game neither breaks the streak nor offers a switch.
    expect(role.maxRoleStreak).toBe(2);
    expect(role.alternations).toBe(1);
    expect(role.alternationOpportunities).toBe(2);
    expect(role.alternationRate).toBeCloseTo(0.5, 9);
  });

  it("exposes the same side sequence the summary counts", () => {
    expect(RoleAnalysis.sideSequence(r, 0, { fromRound: 1, toRound: 4 }, undefined, 0))
      .toEqual(["Favored", "Even", "Favored", "Unfavored"]);
  });

  it("separates the Even game from the favored share", () => {
    // Own probs 0.7, 0.5, 0.8, 0.4 → 2 of 4 strictly above 0.5.
    expect(role.favoredShare).toBeCloseTo(0.5, 9);
    expect(role.meaningfulFavoredShare).toBeCloseTo(2 / 3, 9);
    expect(role.meanOwnWinProb).toBeCloseTo((0.7 + 0.5 + 0.8 + 0.4) / 4, 9);
    // Won games 1, 3 (as team 2 of a 5-11) and 4; lost game 2 (team 2 of 11-5).
    expect(role.wins).toBe(3);
    expect(role.meanEdge).toBeCloseTo((0.2 + 0 + 0.3 + 0.1) / 4, 9);
  });

  it("measures partners against truth", () => {
    // Partners 1, 2, 1, 3 → truth deltas 10, 20, 10, 30.
    expect(role.distinctPartners).toBe(3);
    expect(role.partnerAdvantage).toBeCloseTo(17.5, 9);
  });

  it("returns empties, not errors, for a player who never played", () => {
    const idle = RoleAnalysis.playerRole(r, 0, { fromRound: 1, toRound: 4 }, undefined, 4);
    expect(idle.gamesPlayed).toBe(0);
    expect(idle.favoredShare).toBeUndefined();
    expect(idle.alternationRate).toBeUndefined();
    expect(idle.isDropIn).toBe(true);
  });

  it("signs rating errors: positive = overrated", () => {
    // Player 0 is truly weakest but rated strongest.
    const f = frame(1, [], [60, 20, 30, 40, 25]);
    const rr = result([frame(0, []), f]);
    expect(RoleAnalysis.signedRankErrors(rr, f)[0]).toBe(4);
    const mu = RoleAnalysis.signedMuErrors(rr, f);
    // Centred over the four regulars: mu mean 37.5, truth mean 25.
    expect(mu[0]).toBeCloseTo(60 - 37.5 - (10 - 25), 9);
    // Trimmed detail (no ratings) yields nothing rather than garbage.
    expect(RoleAnalysis.signedRankErrors(rr, { ...f, mu: [] })).toEqual([]);
  });
});

describe("on a real run", () => {
  it("reconciles with the frame's own rank error", async () => {
    const res = await SimLab.run("ColdStart", 1, 8, 2, 3, undefined, false, undefined, [SimLab.strategies[0]]);
    expect(res.runs.length).toBe(1);
    for (const f of res.runs[0].frames) {
      const errs = RoleAnalysis.signedRankErrors(res, f);
      const meanAbs = errs.reduce((a: number, e: number) => a + Math.abs(e), 0) / errs.length;
      expect(meanAbs).toBeCloseTo(f.rankError, 9);
    }
    const roles = RoleAnalysis.playerRoles(res, 0, { fromRound: 1, toRound: 3 }, undefined);
    expect(roles.length).toBe(8);
    const games = roles.reduce((a: number, p: any) => a + p.gamesPlayed, 0);
    const seats = res.runs[0].frames.slice(1).reduce((a: number, f: any) => a + f.games.length * 4, 0);
    expect(games).toBe(seats);
  }, 120_000);
});
