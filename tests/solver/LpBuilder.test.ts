import { describe, expect, it } from "vitest";
import * as CostModel from "../../src/lib/rating/solver/CostModel.re.mjs";
import * as LpBuilder from "../../src/lib/rating/solver/LpBuilder.re.mjs";
import * as SolverPrng from "../../src/lib/rating/solver/SolverPrng.re.mjs";
import * as SolverRound from "../../src/lib/rating/solver/SolverRound.re.mjs";
import { makePool, playerIds, toRound, type Match } from "./fixtures";

function prepare(opts: {
  players: ReturnType<typeof makePool>;
  courts: number;
  rounds?: unknown[];
  strategy?: string;
  requiredPlayerIds?: string[];
  teamConstraints?: Set<string>[];
  avoidAllPlayers?: unknown[];
}) {
  return SolverRound.prepare(
    opts.players,
    opts.rounds ?? [],
    CostModel.weightsForStrategy(opts.strategy ?? "SolverRoundRobin"),
    opts.courts,
    SolverPrng.make(7),
    opts.avoidAllPlayers,
    opts.teamConstraints,
    opts.requiredPlayerIds,
    undefined,
    undefined,
    undefined,
    undefined,
  );
}

describe("LpBuilder", () => {
  it("emits a stable LP for a fixed input", () => {
    // 8 players, 2 courts, one round of history: small enough to eyeball, big
    // enough to exercise the objective, linking rows, court cap and binaries.
    const players = makePool(8, (i) => 20 + i);
    const previous: Match = [
      [players[0], players[1]],
      [players[2], players[3]],
    ];
    const prepared = prepare({
      players,
      courts: 2,
      rounds: [toRound([previous])],
    });

    expect(prepared.model.lp).toMatchSnapshot();
  });

  it("makes seatable required players hard constraints, not penalties", () => {
    const players = makePool(8);
    const prepared = prepare({
      players,
      courts: 2,
      requiredPlayerIds: ["p0", "p7"],
    });
    const { model } = prepared;

    // C(8,4) * 3 = 210 candidate matches. Both required players fit in the 8
    // seats, so they are fixed rather than given slack variables.
    expect(model.candidates).toHaveLength(210);
    expect(model.numVariables).toBe(210 + 8);
    // One linking row per player, the court count, and one fix row each.
    expect(model.numConstraints).toBe(8 + 1 + 2);

    const lp = model.lp;
    expect(lp.startsWith("Minimize")).toBe(true);
    expect(lp.trimEnd().endsWith("End")).toBe(true);
    expect(lp).toContain("Subject To");
    expect(lp).toContain("Binary");
    // The court count is exact: 8 players fill both courts.
    expect(lp).toMatch(/courts:[\s\S]*= 2/);
    expect(lp).toContain("fix0: + z0 = 1");
    expect(lp).toContain("fix1: + z7 = 1");
    expect(lp).not.toContain("req0:");
  });

  it("falls back to slack variables when the required players cannot all fit", () => {
    // Five required players, one court: only four seats exist.
    const prepared = prepare({
      players: makePool(6),
      courts: 1,
      requiredPlayerIds: ["p0", "p1", "p2", "p3", "p4"],
    });
    const lp = prepared.model.lp;
    expect(lp).not.toContain("fix0:");
    expect(lp).toContain("req0: + z0 + s0 >= 1");
    expect(lp).toContain("req4: + z4 + s4 >= 1");
    expect(prepared.model.softRequiredPlayerIndices).toHaveLength(5);
  });

  it("uses only integer coefficients", () => {
    const prepared = prepare({ players: makePool(8, (i) => 20 + i), courts: 2 });
    const objective = prepared.model.lp
      .split("Subject To")[0]
      .replace(/^Minimize\s*\n\s*obj:/, "");
    // Every term is "<sign><integer> <name>".
    const terms = objective.match(/[+-]\s*[\d.]+/g) ?? [];
    expect(terms.length).toBeGreaterThan(0);
    terms.forEach((t) => expect(t.replace(/[+-\s]/g, "")).toMatch(/^\d+$/));
  });

  it("ranks the penalty tiers so no aggregate can reorder them", () => {
    // Every tier live at once: 20 players on 2 courts leaves 12 sitting for 8
    // seats (so back-to-back byes go soft), 9 required players cannot all be
    // seated (so required goes soft), and both constraint kinds are present.
    const players = makePool(20);
    const previous: Match = [
      [players[0], players[1]],
      [players[2], players[3]],
    ];
    const prepared = prepare({
      players,
      courts: 2,
      rounds: [toRound([previous])],
      requiredPlayerIds: players.slice(0, 9).map((p) => p.id),
      avoidAllPlayers: [[players[0], players[1]]],
      teamConstraints: [new Set(["p2", "p3", "p4"])],
    });
    const { courtReward, antiTeamPenalty, poolPenalty, requiredPenalty, backToBackBenefit, regularBudget } =
      prepared.tiers;

    expect(courtReward).toBeGreaterThan(antiTeamPenalty);
    expect(antiTeamPenalty).toBeGreaterThan(poolPenalty);
    expect(poolPenalty).toBeGreaterThan(requiredPenalty);
    expect(requiredPenalty).toBeGreaterThan(backToBackBenefit);
    expect(backToBackBenefit).toBeGreaterThanOrEqual(regularBudget);

    // `regularBudget` really does bound the whole regular objective, which is
    // what makes the tier above it unbuyable. (`candidate.cost` is the regular
    // part; surcharges are the tiers themselves.)
    const worstCost =
      prepared.model.candidates.reduce(
        (a: number, c: { cost: number }) => Math.max(a, c.cost),
        0,
      ) * prepared.matchTarget;
    const worstBenefit =
      SolverRound.costScale *
      CostModel.maxPlayerBenefit *
      4 *
      prepared.matchTarget;
    expect(worstCost + worstBenefit).toBeLessThanOrEqual(regularBudget);
  });

  it("collapses vacuous tiers instead of inflating the coefficient range", () => {
    // Nothing soft, no avoid groups, no pools: the tiers exist but none of them
    // reaches the objective, so the coefficients stay small and the solve fast.
    const prepared = prepare({ players: makePool(16, (i) => 20 + i), courts: 4 });
    expect(prepared.mustPlayIds).toEqual([]);
    expect(prepared.model.softRequiredPlayerIndices).toEqual([]);

    const magnitudes = (prepared.model.lp.split("Subject To")[0].match(/\d+/g) ?? [])
      .map(Number)
      .filter((n) => n > 1);
    expect(Math.max(...magnitudes, 0)).toBeLessThan(1e6);
  });
});

describe("LpBuilder decoding", () => {
  const makeColumns = (model: { candidates: unknown[] }, selected: number[]) => {
    const columns: Record<string, { Primal: number }> = {};
    model.candidates.forEach((_, i) => {
      columns[`x${i}`] = { Primal: selected.includes(i) ? 1 : 0 };
    });
    return columns;
  };

  it("reads back exactly the selected candidates", () => {
    const prepared = prepare({ players: makePool(8), courts: 2 });
    const picked = [3, 17];
    expect(
      LpBuilder.selectedCandidateIndices(
        prepared.model,
        makeColumns(prepared.model, picked),
      ),
    ).toEqual(picked);
  });

  it("tolerates the small numeric slop binaries come back with", () => {
    const prepared = prepare({ players: makePool(8), courts: 2 });
    const columns = makeColumns(prepared.model, []);
    columns["x5"] = { Primal: 0.9999999 };
    columns["x6"] = { Primal: 1e-9 };
    expect(
      LpBuilder.selectedCandidateIndices(prepared.model, columns),
    ).toEqual([5]);
  });

  it("surfaces an unseated required player as a round violation", () => {
    const players = makePool(8);
    const prepared = prepare({
      players,
      courts: 1,
      requiredPlayerIds: ["p7"],
    });
    // Hand-pick a match that excludes p7 — the slack variable would be 1 here.
    const index = prepared.model.candidates.findIndex(
      (c: { match: Match }) => !playerIds(c.match).includes("p7"),
    );
    const decoded = SolverRound.decode(prepared, [index], "Optimal", 0, 0);

    expect(decoded.matches).toHaveLength(1);
    expect(decoded.byePlayerIds).toContain("p7");
    expect(decoded.roundViolations).toEqual([
      { TAG: "RequiredPlayerUnseated", playerId: "p7" },
    ]);
  });

  it("refuses a solution that double-books a player", () => {
    const prepared = prepare({ players: makePool(8), courts: 2 });
    const first = prepared.model.candidates[0] as { match: Match };
    const overlapping = prepared.model.candidates.findIndex(
      (c: { match: Match }, i: number) =>
        i > 0 &&
        playerIds(c.match).some((id) => playerIds(first.match).includes(id)),
    );
    expect(
      SolverRound.decode(prepared, [0, overlapping], "Optimal", 0, 0),
    ).toBeUndefined();
  });

  it("refuses an all-bye solution", () => {
    const prepared = prepare({ players: makePool(8), courts: 2 });
    expect(SolverRound.decode(prepared, [], "Optimal", 0, 0)).toBeUndefined();
  });
});
