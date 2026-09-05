// Moving recorded history between Event Manager instances.
//
// Two things here are unforgiving and so are pinned hard. First, every stored
// round index — rating adjustments, solver round warnings, the round the user is
// watching — has to move with the rounds the merge reorders, and the manager
// filters those on exact equality, so a wrong index is not a near miss but a
// silent disappearance. Second, an imported match keeps its id because that id is
// the server's idempotency key; minting a new one would let the same match sync
// twice from two devices.
import { describe, expect, it } from "vitest";
import * as Transfer from "../../src/lib/rating/EventStateTransfer.re.mjs";
import * as Rating from "../../src/lib/Rating.re.mjs";
import { makePlayer, type Player } from "../solver/fixtures";

type Match = [Player[], Player[]];
type Entity = {
  id: string;
  match: Match;
  score: [number, number] | undefined;
  createdAt: Date;
  synced: boolean;
};
type Adjustment = {
  playerId: string;
  differential: number;
  appliedAtRound: number;
  timestamp: number;
};

const unwrap = (r: any) => {
  if (r.TAG !== "Ok") throw new Error(r._0);
  return r._0;
};

const pool = (n: number): Player[] =>
  Array.from({ length: n }, (_, i) => makePlayer(i, { id: `p${i}` }));

const P = pool(8);

// One court, four players, scored. `ms` is the round's position in time.
const match = (id: string, ms: number, players: Player[] = P): Entity => ({
  id,
  match: [
    [players[0], players[1]],
    [players[2], players[3]],
  ],
  score: [11, 5],
  createdAt: new Date(ms),
  synced: false,
});

const round = (id: string, ms: number, players: Player[] = P): Entity[] => [
  match(id, ms, players),
];

const unscored = (id: string, ms: number): Entity[] => [
  { ...match(id, ms), score: undefined },
];

const adjustment = (
  playerId: string,
  appliedAtRound: number,
  timestamp = 1000,
  differential = 1.5,
): Adjustment => ({ playerId, differential, appliedAtRound, timestamp });

const encode = (rounds: Entity[][], adjustments: Adjustment[] = []) =>
  Transfer.encode("evt", 1_700_000_000_000, rounds, adjustments);

const decode = (text: string) => unwrap(Transfer.decode(text));

const plan = (
  existingRounds: Entity[][],
  payload: any,
  opts: {
    adjustments?: Adjustment[];
    roundViolations?: Record<string, unknown[]>;
    currentRoundInt?: number;
    players?: Player[];
  } = {},
) =>
  Transfer.plan(
    existingRounds,
    opts.adjustments ?? [],
    opts.roundViolations ?? {},
    opts.currentRoundInt ?? existingRounds.length,
    opts.players ?? P,
    payload,
  );

// Round identity for order assertions: the id of a round's first match.
const order = (rounds: Entity[][]) => rounds.map((r) => r[0]?.id);

describe("wire format", () => {
  it("round-trips a scored history", () => {
    const rounds = [round("a", 100), round("b", 200)];
    const adjustments = [adjustment("p0", -1), adjustment("p1", 1)];

    const payload = decode(encode(rounds, adjustments));

    expect(payload.rounds.map((r: Entity[]) => r.map((m) => m.id))).toEqual([["a"], ["b"]]);
    const first = payload.rounds[0][0];
    expect(first.score).toEqual([11, 5]);
    expect(first.createdAt.getTime()).toBe(100);
    expect(first.match[0].map((p: Player) => p.id)).toEqual(["p0", "p1"]);
    expect(first.match[1].map((p: Player) => p.id)).toEqual(["p2", "p3"]);
    expect(first.match[0][0].rating).toEqual(P[0].rating);
    expect(payload.adjustments).toEqual(adjustments);
  });

  it("marks decoded matches as already synced", () => {
    // The whole point of preserving ids: this history is the exporting
    // instance's to sync, and a re-sync is a server-side no-op.
    const payload = decode(encode([round("a", 100)]));
    expect(payload.rounds[0][0].synced).toBe(true);
  });

  it("exports only scored matches and drops rounds left empty", () => {
    const mixed = [match("scored", 100), { ...match("open", 100), score: undefined }];
    const payload = decode(encode([mixed, unscored("future", 200)]));

    expect(payload.rounds).toHaveLength(1);
    expect(payload.rounds[0].map((m: Entity) => m.id)).toEqual(["scored"]);
  });

  it("compacts adjustment indices onto the rounds that survive export", () => {
    // Rounds [scored, unscored, scored]: index 2 becomes 1, past-the-end
    // becomes 2, and a seed adjustment stays a seed adjustment.
    const rounds = [round("a", 100), unscored("skip", 150), round("c", 200)];
    const payload = decode(
      encode(rounds, [
        adjustment("p0", -1, 1),
        adjustment("p1", 2, 2),
        adjustment("p2", 3, 3),
      ]),
    );

    expect(payload.adjustments.map((a: Adjustment) => a.appliedAtRound)).toEqual([-1, 1, 2]);
  });

  it("refuses anything it cannot read", () => {
    expect(Transfer.decode("not json").TAG).toBe("Error");
    expect(Transfer.decode(JSON.stringify({ format: "something-else", version: 1 })).TAG).toBe(
      "Error",
    );

    const bumped = JSON.parse(encode([round("a", 100)]));
    bumped.version = 2;
    const refused = Transfer.decode(JSON.stringify(bumped));
    expect(refused.TAG).toBe("Error");
    expect(refused._0).toContain("v2");

    const broken = JSON.parse(encode([round("a", 100)]));
    delete broken.rounds[0].matches[0].score;
    expect(Transfer.decode(JSON.stringify(broken)).TAG).toBe("Error");
  });
});

describe("merging into the timeline", () => {
  it("prepends rounds that were played earlier", () => {
    const payload = decode(encode([round("i0", 100), round("i1", 200)]));
    const result = plan([round("e0", 300)], payload, { currentRoundInt: 1 });

    expect(order(result.rounds)).toEqual(["i0", "i1", "e0"]);
    expect(result.counts.importedRounds).toBe(2);
    expect(result.counts.importedMatches).toBe(2);
  });

  it("appends rounds that were played later", () => {
    const payload = decode(encode([round("i0", 900)]));
    const result = plan([round("e0", 100), round("e1", 200)], payload);

    expect(order(result.rounds)).toEqual(["e0", "e1", "i0"]);
  });

  it("interleaves without reordering either source", () => {
    // Neither source is monotonic in `createdAt`, and neither may be resorted:
    // a round's stamp is rewritten to "now" when its first score lands, so
    // within one instance the recorded order is the truth.
    const existing = [round("e0", 100), round("e1", 50), round("e2", 300)];
    const payload = decode(encode([round("i0", 200), round("i1", 150)]));

    const result = plan(existing, payload, { currentRoundInt: 3 });

    expect(order(result.rounds)).toEqual(["e0", "e1", "i0", "i1", "e2"]);
  });

  it("keeps unplayed draws at the end, whatever their timestamps say", () => {
    // Generated rounds are stamped event start + 10 minutes each, so the draws
    // still waiting to be played carry the earliest stamps in the list. They
    // must not sort in front of rounds actually played later in the day.
    const existing = [round("played", 500), unscored("draw1", 60), unscored("draw2", 70)];
    const payload = decode(encode([round("i0", 600)]));

    const result = plan(existing, payload, { currentRoundInt: 1 });

    expect(order(result.rounds)).toEqual(["played", "i0", "draw1", "draw2"]);
  });
});

describe("what an import refuses to take", () => {
  it("skips matches it already has, so re-importing is a no-op", () => {
    const existing = [round("a", 100), round("b", 200)];
    const payload = decode(encode(existing));

    const result = plan(existing, payload);

    expect(result.counts.importedMatches).toBe(0);
    expect(result.counts.skippedDuplicates).toBe(2);
    expect(order(result.rounds)).toEqual(["a", "b"]);
    expect(result.currentRoundInt).toBe(2);
  });

  it("counts an id repeated inside one payload only once", () => {
    const payload = decode(encode([round("dup", 100), round("dup", 200)]));
    const result = plan([], payload, { currentRoundInt: 0 });

    expect(result.counts.importedMatches).toBe(1);
    expect(result.counts.skippedDuplicates).toBe(1);
  });

  it("silently drops matches whose players are not in this event", () => {
    const stranger = makePlayer(99, { id: "stranger" });
    const outside = [
      { ...match("outside", 100), match: [[P[0], P[1]], [P[2], stranger]] as Match },
    ];
    const payload = decode(encode([outside, round("fine", 200)]));

    const result = plan([], payload, { currentRoundInt: 0 });

    expect(result.counts.skippedMissingPlayers).toBe(1);
    expect(result.counts.importedMatches).toBe(1);
    expect(order(result.rounds)).toEqual(["fine"]);
  });

  it("re-attaches the local RSVP node while keeping the recorded snapshot", () => {
    // The replay rates from the embedded players, so the exported ratings and
    // counts must survive; only the relay fragment comes from this instance.
    const local = pool(4).map((p) => ({ ...p, data: { node: p.id } as any }));
    const played = [
      {
        ...match("m", 100),
        match: [
          [{ ...P[0], rating: { mu: 31, sigma: 4 }, count: 7 }, P[1]],
          [P[2], P[3]],
        ] as Match,
      },
    ];
    const payload = decode(encode([played]));

    const result = plan([], payload, { currentRoundInt: 0, players: local });

    const imported = result.rounds[0][0].match[0][0];
    expect(imported.rating).toEqual({ mu: 31, sigma: 4 });
    expect(imported.count).toBe(7);
    expect(imported.data).toEqual({ node: "p0" });
    expect(result.rounds[0][0].synced).toBe(true);
  });
});

describe("everything filed against a round index moves with it", () => {
  it("shifts existing adjustments and re-homes seed adjustments", () => {
    // Two rounds arrive in front, so what was "before round 0" is now "before
    // round 2" — the position it actually held in this instance's timeline.
    const payload = decode(encode([round("i0", 100), round("i1", 150)]));
    const result = plan([round("e0", 300)], payload, {
      currentRoundInt: 1,
      adjustments: [adjustment("p0", -1, 1), adjustment("p1", 0, 2)],
    });

    expect(result.adjustments.map((a: Adjustment) => a.appliedAtRound)).toEqual([2, 2]);
  });

  it("leaves seed adjustments alone when nothing is inserted before them", () => {
    const payload = decode(encode([round("i0", 900)]));
    const result = plan([round("e0", 100)], payload, {
      currentRoundInt: 1,
      adjustments: [adjustment("p0", -1)],
    });

    expect(result.adjustments[0].appliedAtRound).toBe(-1);
  });

  it("keeps a past-the-end adjustment after the last existing round", () => {
    const payload = decode(encode([round("i0", 50)]));
    const result = plan([round("e0", 100)], payload, {
      currentRoundInt: 1,
      adjustments: [adjustment("p0", 1)],
    });

    // e0 moved to index 1, so "after e0" is index 2.
    expect(order(result.rounds)).toEqual(["i0", "e0"]);
    expect(result.adjustments[0].appliedAtRound).toBe(2);
  });

  it("lands an imported adjustment before the surviving round it preceded", () => {
    // Payload round 0 is dropped for a missing player, so an adjustment filed
    // against payload round 1 still belongs in front of that round.
    const stranger = makePlayer(99, { id: "stranger" });
    const dropped = [
      { ...match("dropped", 100), match: [[P[0], P[1]], [P[2], stranger]] as Match },
    ];
    const payload = decode(
      encode([dropped, round("kept", 200)], [adjustment("p0", 1, 5)]),
    );

    const result = plan([round("e0", 50)], payload, { currentRoundInt: 1 });

    expect(order(result.rounds)).toEqual(["e0", "kept"]);
    expect(result.adjustments).toHaveLength(1);
    expect(result.adjustments[0].appliedAtRound).toBe(1);
  });

  it("drops imported adjustments for unknown players and ones already held", () => {
    // The two timelines file this adjustment against different rounds — the
    // local copy sits before e0, the imported one before i0 — and it is still
    // one adjustment. Taking both would double the rating change it applies.
    const shared = adjustment("p0", 0, 7);
    const payload = decode(
      encode([round("i0", 50)], [shared, adjustment("stranger", 0, 8)]),
    );

    const result = plan([round("e0", 100)], payload, {
      currentRoundInt: 1,
      adjustments: [shared],
    });

    expect(result.adjustments).toHaveLength(1);
    expect(result.counts.skippedAdjustments).toBe(2);
  });

  it("does not accumulate adjustments when an export is imported twice", () => {
    // The second import brings one new round and one already-held round, so it
    // is not blocked as a whole — and its adjustments must still not double up.
    const shared = adjustment("p0", -1, 7);
    const first = decode(encode([round("i0", 50)], [shared]));
    const afterFirst = plan([round("e0", 100)], first, { currentRoundInt: 1 });

    const second = decode(encode([round("i0", 50), round("i1", 60)], [shared]));
    const afterSecond = plan(afterFirst.rounds, second, {
      currentRoundInt: afterFirst.currentRoundInt,
      adjustments: afterFirst.adjustments,
    });

    expect(afterSecond.counts.importedMatches).toBe(1);
    expect(afterSecond.counts.skippedDuplicates).toBe(1);
    expect(
      afterSecond.adjustments.filter((a: Adjustment) => a.playerId === "p0"),
    ).toHaveLength(1);
  });

  it("moves solver round warnings onto the rounds they describe", () => {
    const payload = decode(encode([round("i0", 50)]));
    const warning = [{ TAG: "BackToBackBye", playerId: "p0" }];

    const result = plan([round("e0", 100), round("e1", 200)], payload, {
      currentRoundInt: 2,
      roundViolations: { "1": warning },
    });

    expect(order(result.rounds)).toEqual(["i0", "e0", "e1"]);
    expect(result.roundViolations).toEqual({ "2": warning });
  });
});

describe("where the organiser is left standing", () => {
  it("advances past imported rounds when starting from nothing", () => {
    const payload = decode(encode([round("i0", 100), round("i1", 200)]));
    const result = plan([], payload, { currentRoundInt: 0 });

    // Generation from round 0 replaces every round, so imported history must not
    // be left sitting in the future.
    expect(result.currentRoundInt).toBe(2);
  });

  it("keeps the organiser on the same round when history is prepended", () => {
    const existing = [round("e0", 300), round("e1", 400)];
    const payload = decode(encode([round("i0", 10), round("i1", 20), round("i2", 30)]));

    const result = plan(existing, payload, { currentRoundInt: 2 });

    expect(order(result.rounds)).toEqual(["i0", "i1", "i2", "e0", "e1"]);
    expect(result.currentRoundInt).toBe(5);
  });

  it("moves forward when imported rounds land after the current one", () => {
    const existing = [round("e0", 100), unscored("draw", 60)];
    const payload = decode(encode([round("i0", 500)]));

    const result = plan(existing, payload, { currentRoundInt: 1 });

    expect(order(result.rounds)).toEqual(["e0", "i0", "draw"]);
    expect(result.currentRoundInt).toBe(2);
  });
});

describe("end to end, two devices", () => {
  it("merges a morning's play into an afternoon's and replays through the rating engine", () => {
    const two = (id: string, ms: number, a: number, b: number, c: number, d: number,
                 score: [number, number] | undefined): Entity => ({
      id,
      match: [[P[a], P[b]], [P[c], P[d]]],
      score,
      createdAt: new Date(ms),
      synced: false,
    });

    // Device A ran two rounds on two courts this morning, off a seed adjustment.
    const deviceA = [
      [two("a1", 1000, 0, 1, 2, 3, [11, 5]), two("a2", 1000, 4, 5, 6, 7, [11, 9])],
      [two("b1", 2000, 0, 2, 1, 3, [7, 11]), two("b2", 2000, 4, 6, 5, 7, [11, 2])],
    ];
    const seed = adjustment("p0", -1, 500, 2);

    // Device B recorded one afternoon round and is holding an unplayed draw.
    const deviceB = [
      [two("c1", 9000, 0, 3, 1, 2, [11, 8])],
      [two("draw", 300, 4, 5, 6, 7, undefined)],
    ];

    const payload = decode(Transfer.encode("evt", Date.now(), deviceA, [seed]));
    const result = plan(deviceB, payload, {
      currentRoundInt: 1,
      roundViolations: { "1": [] },
    });

    // Morning before afternoon, draw last.
    expect(order(result.rounds)).toEqual(["a1", "b1", "c1", "draw"]);
    expect(result.counts.importedMatches).toBe(4);
    expect(result.currentRoundInt).toBe(3);
    // Imported matches arrive synced; device B's own unsynced round must not be
    // quietly marked as sent just because an import passed through.
    const byId = new Map(result.rounds.flat().map((m) => [m.id, m]));
    expect(["a1", "a2", "b1", "b2"].every((id) => byId.get(id)!.synced)).toBe(true);
    expect(byId.get("c1")!.synced).toBe(false);

    // The seed adjustment came from before device A's first round, which is now
    // the first round overall, so it is a seed adjustment here too.
    expect(result.adjustments).toEqual([{ ...seed, appliedAtRound: -1 }]);

    // The merged timeline has to survive the real replay: every player has
    // played, and the adjustment has moved p0 off the default.
    const replayed = Rating.toPlayerStateWithAdjustments(result.rounds, P, result.adjustments);
    expect(replayed.every((p: Player) => p.count >= 2)).toBe(true);
    expect(replayed.find((p: Player) => p.id === "p0")!.rating.mu).not.toBeCloseTo(25, 3);
    expect(replayed.every((p: Player) => Number.isFinite(p.rating.mu))).toBe(true);
  });
});
