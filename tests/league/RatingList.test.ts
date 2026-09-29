// Leaderboard ranks. The ratings connection pages with keyset cursors (a
// rating's ordinal and id, no offset) and the schema has no rank field, so a
// rank is only shown when it is exact. Before this, a page opened with
// ?after= or ?before= numbered its rows from 1 again, and "Your standing"
// counted only the players loaded so far.
import { describe, expect, it } from "vitest";
import * as RatingList from "../../src/components/organisms/RatingList.re.mjs";

const { rankOf, viewerRank } = RatingList;

describe("row ranks", () => {
  it("numbers rows from 1 when the window starts at the top", () => {
    expect(rankOf(true, 0)).toBe(1);
    expect(rankOf(true, 19)).toBe(20);
  });

  it("gives no rank on a window that starts further down", () => {
    expect(rankOf(false, 0)).toBeUndefined();
    expect(rankOf(false, 5)).toBeUndefined();
  });
});

describe("the viewer's standing", () => {
  // The first page of a table sorted by ordinal, best first.
  const firstPage = [40, 38, 35, 33, 30];

  it("counts the players above once the viewer's own row is loaded", () => {
    expect(viewerRank([...firstPage, 29, 28], 30, true, true, false)).toBe(5);
  });

  it("counts them once a lower-rated player is loaded, even if the viewer isn't", () => {
    expect(viewerRank(firstPage, 34, false, true, false)).toBe(4);
  });

  it("counts them when the whole table is loaded", () => {
    expect(viewerRank(firstPage, 10, false, true, true)).toBe(6);
  });

  it("gives no rank while players above the viewer may still be unloaded", () => {
    // Everyone loaded outranks the viewer and more pages follow.
    expect(viewerRank(firstPage, 20, false, true, false)).toBeUndefined();
  });

  it("gives no rank on a window that doesn't start at the top", () => {
    expect(viewerRank(firstPage, 34, true, false, true)).toBeUndefined();
  });

  it("doesn't count a tie as outranking the viewer", () => {
    expect(viewerRank([40, 35, 35, 30], 35, true, true, true)).toBe(2);
  });
});
