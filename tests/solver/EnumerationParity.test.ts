// Parity between the legacy filter cascade and the solver's shared predicates.
//
// The enumeration refactor pulled candidate generation and the constraint
// definitions out of `find_all_match_combos` so the solver could reuse them.
// The plan's contract (§12) is that the *definitions* of a violation are
// preserved exactly — the two paths only differ in enforcement (legacy filters
// candidates out; the solver admits them with a surcharge and reports them).
//
// These tests state that contract bidirectionally: a match survives the legacy
// filters if and only if the shared predicates score it clean. If someone edits
// one side without the other, this is the suite that goes red.

import { describe, expect, it } from "vitest";
import * as Rating from "../../src/lib/Rating.re.mjs";
import { makePool, playerIds, type Match, type Player } from "./fixtures";

const pairingKey = (match: Match): string =>
  [match[0], match[1]]
    .map((team) => team.map((p) => p.id).sort().join("-"))
    .sort()
    .join("|");

// Legacy entry point. teamConstraints is a NonEmptyArray (option<array<Set>>),
// requiredPlayers an option<Set> — both map to `undefined` when absent.
const legacy = (
  players: Player[],
  opts: {
    priorityPlayers?: Player[];
    avoidAllPlayers?: Player[][];
    teamConstraints?: Set<string>[];
    requiredPlayers?: Set<string>;
  } = {},
): Set<string> =>
  new Set(
    Rating.find_all_match_combos(
      players,
      opts.priorityPlayers ?? [],
      opts.avoidAllPlayers ?? [],
      opts.teamConstraints,
      opts.requiredPlayers,
    ).map(([match]: [Match, number]) => pairingKey(match)),
  );

// The same compliance judgement, expressed through the predicates the solver
// prices candidates with.
const predicateClean = (
  players: Player[],
  match: Match,
  opts: {
    priorityPlayers?: Player[];
    avoidAllPlayers?: Player[][];
    teamConstraints?: Set<string>[];
    requiredPlayers?: Set<string>;
  },
): boolean => {
  const ids = new Set(playerIds(match));

  if (opts.priorityPlayers?.length) {
    if (!opts.priorityPlayers.some((p) => ids.has(p.id))) return false;
  }
  if (Rating.match_antiteam_violations(match, opts.avoidAllPlayers ?? []) > 0) {
    return false;
  }
  if (opts.requiredPlayers && opts.requiredPlayers.size > 0) {
    for (const id of opts.requiredPlayers) if (!ids.has(id)) return false;
  }
  const pools = Rating.pool_constraint_sets(players, opts.teamConstraints ?? []);
  return Rating.match_pool_violations(match, pools) === 0;
};

const predicateSet = (
  players: Player[],
  opts: Parameters<typeof predicateClean>[2],
): Set<string> =>
  new Set(
    (Rating.enumerate_match_candidates(players) as Match[])
      .filter((match) => predicateClean(players, match, opts))
      .map(pairingKey),
  );

const expectParity = (
  players: Player[],
  opts: Parameters<typeof predicateClean>[2],
) => {
  const legacySet = legacy(players, opts);
  const predicted = predicateSet(players, opts);
  expect([...legacySet].sort()).toEqual([...predicted].sort());
  return legacySet;
};

describe("enumeration parity with the legacy filters", () => {
  const players = makePool(8);

  it("agrees with full enumeration when unconstrained", () => {
    const result = expectParity(players, {});
    // C(8,4) * 3 distinct pairings.
    expect(result.size).toBe(210);
  });

  it("agrees on the anti-team rule (at most one member per avoid group)", () => {
    const result = expectParity(players, {
      avoidAllPlayers: [[players[0], players[1], players[2]]],
    });
    expect(result.size).toBeGreaterThan(0);
    expect(result.size).toBeLessThan(210);
  });

  it("ignores single-member avoid groups exactly like the legacy filter", () => {
    expect(legacy(players, { avoidAllPlayers: [[players[0]]] }).size).toBe(210);
    expectParity(players, { avoidAllPlayers: [[players[0]]] });
  });

  it("agrees on partner pools, including the implicit unconstrained pool", () => {
    const result = expectParity(players, {
      teamConstraints: [new Set(["p0", "p1", "p2"])],
    });
    // Constrained players may only partner inside their pool; the rest form
    // the implicit pool. Cross-pool teams are excluded by both paths.
    expect(result.size).toBeGreaterThan(0);
    expect(result.size).toBeLessThan(210);
  });

  it("agrees on required players", () => {
    const required = new Set(["p6", "p7"]);
    const result = expectParity(players, { requiredPlayers: required });
    // Both required in every surviving match: C(6,2) partners * 3 pairings.
    expect(result.size).toBe(45);
  });

  it("agrees that unsatisfiable required players yield nothing", () => {
    expect(
      legacy(players, { requiredPlayers: new Set(["p6", "ghost"]) }).size,
    ).toBe(0);
  });

  it("agrees on priority players (at least one present)", () => {
    expectParity(players, { priorityPlayers: [players[0], players[1]] });
  });

  it("agrees with every filter active at once", () => {
    const opts = {
      priorityPlayers: [players[0]],
      avoidAllPlayers: [[players[2], players[3]]],
      teamConstraints: [new Set(["p4", "p5"])],
      requiredPlayers: new Set(["p0"]),
    };
    const result = expectParity(players, opts);
    expect(result.size).toBeGreaterThan(0);
  });

  it("holds across randomized constraint sets", () => {
    // Cheap LCG so failures reproduce.
    let s = 12345;
    const next = () => ((s = (s * 1664525 + 1013904223) >>> 0), s / 4294967296);
    for (let trial = 0; trial < 10; trial++) {
      const pool = makePool(9, () => 20 + Math.floor(next() * 20));
      const shuffled = [...pool].sort(() => next() - 0.5);
      expectParity(pool, {
        avoidAllPlayers: [shuffled.slice(0, 2 + Math.floor(next() * 3))],
        teamConstraints: [
          new Set(shuffled.slice(3, 5 + Math.floor(next() * 3)).map((p) => p.id)),
        ],
        requiredPlayers: next() > 0.5 ? new Set([pool[0].id]) : undefined,
      });
    }
  });
});
