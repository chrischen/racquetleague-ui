// Soft-constraint semantics: the solver fills every court it physically can,
// breaks the cheapest rule when it has to, and always reports what it broke.

import { beforeAll, describe, expect, it } from "vitest";
import * as CostModel from "../../src/lib/rating/solver/CostModel.re.mjs";
import * as HighsBindings from "../../src/lib/rating/solver/HighsBindings.re.mjs";
import * as SolverPrng from "../../src/lib/rating/solver/SolverPrng.re.mjs";
import * as SolverRound from "../../src/lib/rating/solver/SolverRound.re.mjs";
import { makePool, playerIds, type Match, type Player } from "./fixtures";

let highs: unknown;

beforeAll(async () => {
  highs = await HighsBindings.load();
}, 60_000);

type Violation = { TAG: string; playerIds?: string[]; teamPlayerIds?: string[] };
type SolvedMatch = { match: Match; fallbackReasons: Violation[] };

async function solve(opts: {
  players: Player[];
  courts: number;
  strategy?: string;
  avoidAllPlayers?: Player[][];
  teamConstraints?: Set<string>[];
  requiredPlayerIds?: string[];
  genderMixed?: boolean;
}) {
  return await SolverRound.generateRound(
    opts.players,
    [],
    CostModel.weightsForStrategy(opts.strategy ?? "SolverRandomBalanced"),
    opts.courts,
    SolverPrng.make(3),
    opts.avoidAllPlayers,
    opts.teamConstraints,
    opts.requiredPlayerIds,
    undefined,
    opts.genderMixed,
    5.0,
    highs,
    undefined,
  );
}

const reasonTags = (matches: SolvedMatch[]) =>
  matches.flatMap((m) => m.fallbackReasons.map((r) => r.TAG));

describe("soft constraints", () => {
  it("respects avoid groups and partner pools when a clean round exists", async () => {
    const players = makePool(8);
    const result = await solve({
      players,
      courts: 2,
      avoidAllPlayers: [[players[0], players[1]]],
      teamConstraints: [new Set(["p2", "p3"])],
    });

    expect(result.matches).toHaveLength(2);
    expect(reasonTags(result.matches)).toEqual([]);

    // p0 and p1 on different courts.
    const courts = result.matches.map((m: SolvedMatch) => playerIds(m.match));
    expect(courts.some((ids) => ids.includes("p0") && ids.includes("p1"))).toBe(
      false,
    );
    // p2 and p3 partnered, since that is the only pool either belongs to.
    const teams = result.matches.flatMap((m: SolvedMatch) =>
      [m.match[0], m.match[1]].map((t) => t.map((p) => p.id).sort().join()),
    );
    expect(teams).toContain("p2,p3");
  });

  it("still fills every court when the avoid rule cannot be honoured", async () => {
    // Five players who all want to avoid each other, two courts: only one of
    // them can be kept on a court of their own, so the rule has to break.
    const players = makePool(8);
    const group = players.slice(0, 5);
    const result = await solve({
      players,
      courts: 2,
      avoidAllPlayers: [group],
    });

    expect(result.matches).toHaveLength(2);
    expect(
      result.matches.flatMap((m: SolvedMatch) => playerIds(m.match)),
    ).toHaveLength(8);

    // A violation is per avoid-group, not per offending pair (preserving the
    // legacy `contains_more_than_1_players` definition), so concentrating the
    // offenders on one court is strictly cheaper than spreading them over two.
    const flagged = result.matches.filter(
      (m: SolvedMatch) => m.fallbackReasons.length > 0,
    );
    expect(flagged.length).toBe(1);

    const clean = result.matches.find(
      (m: SolvedMatch) => m.fallbackReasons.length === 0,
    );
    expect(
      playerIds(clean.match).filter((id) => group.some((p) => p.id === id)),
    ).toHaveLength(1);

    flagged.forEach((m: SolvedMatch) => {
      const seated = new Set(playerIds(m.match));
      m.fallbackReasons.forEach((reason) => {
        expect(reason.TAG).toBe("AntiTeam");
        // The reason names the actual offenders on this court.
        expect(reason.playerIds!.length).toBeGreaterThan(1);
        reason.playerIds!.forEach((id) => {
          expect(seated.has(id)).toBe(true);
          expect(group.some((p) => p.id === id)).toBe(true);
        });
      });
    });
  });

  it("breaks partner pools before avoid rules when forced to choose", async () => {
    // p0's only legal partner is p1 — but p0 and p1 must not share a court.
    // Seating both (which filling two courts requires) therefore costs either
    // one avoid-rule breach or two pool breaches. Pools are the cheaper tier.
    const players = makePool(8);
    const result = await solve({
      players,
      courts: 2,
      avoidAllPlayers: [[players[0], players[1]]],
      teamConstraints: [new Set(["p0", "p1"])],
    });

    expect(result.matches).toHaveLength(2);
    const tags = reasonTags(result.matches);
    expect(tags).not.toContain("AntiTeam");
    expect(tags).toContain("PartnerPool");

    result.matches.forEach((m: SolvedMatch) =>
      m.fallbackReasons.forEach((reason) => {
        expect(reason.TAG).toBe("PartnerPool");
        expect(reason.teamPlayerIds).toHaveLength(2);
      }),
    );
  });

  it("reports a required player it could not seat", async () => {
    // Six players, one court: two must sit, and one of them is required.
    // Seating the required player is a lower tier than filling the court, but
    // here both fit — so force the conflict with an oversized avoid group that
    // makes no clean match possible while still filling the court.
    const players = makePool(5);
    const result = await solve({
      players,
      courts: 1,
      requiredPlayerIds: ["p0", "p1", "p2", "p3", "p4"],
    });

    // Only four seats exist, so exactly one required player is left out and
    // that must be reported rather than silently dropped.
    expect(result.matches).toHaveLength(1);
    expect(result.byePlayerIds).toHaveLength(1);
    expect(result.roundViolations).toEqual([
      { TAG: "RequiredPlayerUnseated", playerId: result.byePlayerIds[0] },
    ]);
  });

  it("keeps both teams mixed when gender-mixed is requested", async () => {
    const players = makePool(
      8,
      undefined,
      (i) => (i % 2 === 0 ? "Male" : "Female"),
    );
    const result = await solve({ players, courts: 2, genderMixed: true });

    result.matches.forEach((m: SolvedMatch) =>
      [m.match[0], m.match[1]].forEach((team) =>
        expect(team.some((p) => p.gender === "Female")).toBe(true),
      ),
    );
  });

  it("falls back to unmixed matches, and reports them, rather than producing no round", async () => {
    // Nobody to mix with: every candidate breaks the format, so the courts
    // still fill — but unlike the legacy silent relaxation, every all-male
    // team is flagged.
    const players = makePool(8, undefined, () => "Male");
    const result = await solve({ players, courts: 2, genderMixed: true });
    expect(result.matches).toHaveLength(2);
    result.matches.forEach((m: SolvedMatch) => {
      const genderReasons = m.fallbackReasons.filter(
        (r) => r.TAG === "NotGenderMixed",
      );
      // Both teams of every match lack a woman.
      expect(genderReasons).toHaveLength(2);
    });
  });

  it("fills every court when there are only enough women for some of them", async () => {
    // 12 players, 3 courts, 4 women: at most 4 teams can contain a woman, so
    // at least 2 of the 6 teams must be unmixed. The old hard-filter model
    // went infeasible here and left courts empty; the product requirement is
    // to fill all three, mix where possible, and report the remainder.
    const players = makePool(12, undefined, (i) => (i < 4 ? "Female" : "Male"));
    const result = await solve({ players, courts: 3, genderMixed: true });

    expect(result.matches).toHaveLength(3);
    expect(
      new Set(result.matches.flatMap((m: SolvedMatch) => playerIds(m.match)))
        .size,
    ).toBe(12);

    // Exactly the arithmetic minimum of unmixed teams, every one reported.
    const genderReasons = result.matches.flatMap((m: SolvedMatch) =>
      m.fallbackReasons.filter((r) => r.TAG === "NotGenderMixed"),
    );
    expect(genderReasons).toHaveLength(2);
    genderReasons.forEach((reason) => {
      // The reported team really is all male.
      reason.teamPlayerIds!.forEach((id: string) =>
        expect(Number(id.slice(1))).toBeGreaterThanOrEqual(4),
      );
    });
  });

  it("keeps a locked partnership together even in a mixed round", async () => {
    // p4 and p5 are both men and locked as partners; the pool tier outranks
    // the mixed-format tier, so the lock survives and the unmixed team is
    // reported rather than the lock being broken to satisfy the format.
    const players = makePool(8, undefined, (i) => (i < 4 ? "Female" : "Male"));
    const result = await solve({
      players,
      courts: 2,
      genderMixed: true,
      teamConstraints: [new Set(["p4", "p5"])],
    });

    expect(result.matches).toHaveLength(2);
    const teams = result.matches.flatMap((m: SolvedMatch) =>
      [m.match[0], m.match[1]].map((t) => t.map((p) => p.id).sort().join()),
    );
    expect(teams).toContain("p4,p5");

    const tags = result.matches.flatMap((m: SolvedMatch) =>
      m.fallbackReasons.map((r) => r.TAG),
    );
    expect(tags).not.toContain("PartnerPool");
    expect(tags).toContain("NotGenderMixed");
  });
});
