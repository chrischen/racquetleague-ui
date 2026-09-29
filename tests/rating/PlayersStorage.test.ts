// AiTetsu keeps its session players — walk-ins, and ratings and genders edited
// in offline mode — in localStorage (Rating.Players.savePlayers) and reads them
// back when the page loads (Rating.Players.loadPlayers). Saving used to write
// the gender as the variant's name ("Male"/"Female") while loading only read
// the int form, so every saved player failed to decode and the session came
// back empty. Both forms have been written, so both must keep loading.
import { beforeEach, describe, expect, it } from "vitest";
import * as Rating from "../../src/lib/Rating.re.mjs";
import { makePlayer, type Player } from "../solver/fixtures";

const NS = "evt-storage";
const KEY = `${NS}-playersState`;

// Registered players as AiTetsu builds them from the RSVPs: Relay data attached.
const roster = (): Player[] => [
  { ...makePlayer(1, { id: "user-kenji", name: "Kenji" }), data: { node: "kenji" } as any },
  { ...makePlayer(2, { id: "user-mai", name: "Mai", gender: "Female" }), data: { node: "mai" } as any },
];

// A player as a saved row: no data field.
const stored = (p: Player, gender: unknown) => {
  const { data: _, ...rest } = p;
  return { ...rest, gender };
};

beforeEach(() => localStorage.clear());

describe("Players.savePlayers / loadPlayers", () => {
  it("round-trips edited players and walk-ins", () => {
    const [kenji, mai] = roster();
    const edited = [
      { ...kenji, rating: { mu: 31.5, sigma: 4.1 }, ratingOrdinal: 19.2, paid: true, count: 3 },
      { ...mai, gender: "Male" as const, count: 1 },
      { ...makePlayer(21, { id: "guest-Lisa Brown", name: "Lisa Brown", gender: "Female", mu: 22 }) },
    ];
    Rating.Players.savePlayers(edited, NS);

    const loaded = Rating.Players.loadPlayers(roster(), NS);

    expect(loaded).toEqual([
      edited[0], // Relay data comes from the roster, the rest from storage
      edited[1],
      { ...edited[2], data: undefined },
    ]);
  });

  it("saves the gender the way Player.toJson does", () => {
    const [kenji, mai] = roster();
    Rating.Players.savePlayers([kenji, mai], NS);
    const saved = JSON.parse(localStorage.getItem(KEY)!);
    expect(saved["user-kenji"]).toEqual(Rating.Player.toJson(kenji));
    expect(saved["user-mai"].gender).toBe(0);
    expect(saved["user-kenji"]).not.toHaveProperty("data");
  });

  it.each([
    ["the variant name", "Female", "Male"],
    ["an int", 0, 1],
  ])("loads players saved with the gender as %s", (_, female, male) => {
    const [kenji, mai] = roster();
    const guest = makePlayer(21, { id: "guest-Kaito Mori", name: "Kaito Mori", mu: 27, count: 2 });
    localStorage.setItem(
      KEY,
      JSON.stringify({
        "user-kenji": stored({ ...kenji, count: 4 }, male),
        "user-mai": stored({ ...mai, rating: { mu: 29, sigma: 5 }, count: 2 }, female),
        "guest-Kaito Mori": stored(guest, male),
      }),
    );

    const loaded = Rating.Players.loadPlayers(roster(), NS);

    expect(loaded.map((p: Player) => [p.id, p.gender, p.count, p.rating.mu])).toEqual([
      ["user-kenji", "Male", 4, 25],
      ["user-mai", "Female", 2, 29],
      ["guest-Kaito Mori", "Male", 2, 27],
    ]);
    expect(loaded[0].data).toEqual({ node: "kenji" });
  });

  it("skips an unreadable player and keeps the rest", () => {
    const [kenji] = roster();
    localStorage.setItem(
      KEY,
      JSON.stringify({
        "user-kenji": stored({ ...kenji, count: 5 }, "Male"),
        "guest-Broken": stored(makePlayer(22, { id: "guest-Broken" }), "Unknown"),
      }),
    );
    const loaded = Rating.Players.loadPlayers([kenji], NS);
    expect(loaded.map((p: Player) => [p.id, p.count])).toEqual([["user-kenji", 5]]);
  });
});

describe("Player.fromJson", () => {
  it("reads the gender as an int or as the variant name", () => {
    const mai = makePlayer(2, { id: "user-mai", gender: "Female" });
    expect(Rating.Player.fromJson(stored(mai, 0))).toEqual(mai);
    expect(Rating.Player.fromJson(stored(mai, "Female"))).toEqual(mai);
  });
});
