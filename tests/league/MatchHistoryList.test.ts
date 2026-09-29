// How a match card reads. From a player's page their team is on the left and
// the result is theirs; with no player (an event's results) the team that won
// on the score is on the left, so no card reads as a loss. Before this, the
// left side without a player was always the recorded losers and every scored
// match read LOSS.
import { describe, expect, it } from "vitest";
import * as MatchHistoryList from "../../src/components/organisms/MatchHistoryList.re.mjs";

const { winnersOnLeft, isUnscored, favoredSide, evenBelow, readFromLeft } = MatchHistoryList;

describe("which team sits on the left", () => {
  it("puts the player's team on the left on their page, whatever the score", () => {
    expect(winnersOnLeft(true, 11, 7)).toBe(true);
    expect(winnersOnLeft(false, 11, 7)).toBe(false);
  });

  it("puts the team that won on the score on the left with no player", () => {
    expect(winnersOnLeft(undefined, 11, 7)).toBe(true);
    // The winners/losers split is vestigial: the score decides.
    expect(winnersOnLeft(undefined, 7, 11)).toBe(false);
  });

  it("keeps the recorded order for a draw with no player", () => {
    expect(winnersOnLeft(undefined, 10, 10)).toBe(true);
    expect(winnersOnLeft(undefined, -1, -1)).toBe(true);
  });
});

describe("unscored draws", () => {
  it("recognises the (-1, -1) sentinel", () => {
    expect(isUnscored(-1, -1)).toBe(true);
  });

  it("treats real scores, including 0 and ties, as scored", () => {
    expect(isUnscored(0, 0)).toBe(false);
    expect(isUnscored(10, 10)).toBe(false);
    expect(isUnscored(11, 0)).toBe(false);
  });
});

// A match without a score used to show a made-up 21-18.
describe("reading a match from the left", () => {
  it("shows a recorded score, left team first", () => {
    expect(readFromLeft(undefined, [11, 7])).toEqual({
      winnersLeft: true,
      isWin: true,
      isLoss: false,
      shownScore: [11, 7],
    });
    expect(readFromLeft(false, [11, 7])).toEqual({
      winnersLeft: false,
      isWin: false,
      isLoss: true,
      shownScore: [7, 11],
    });
  });

  it("shows no score for an unscored draw", () => {
    expect(readFromLeft(undefined, [-1, -1])).toEqual({
      winnersLeft: true,
      isWin: false,
      isLoss: false,
      shownScore: undefined,
    });
  });

  it("shows no score for a match without one; its recorded winners won", () => {
    expect(readFromLeft(undefined, undefined)).toEqual({
      winnersLeft: true,
      isWin: true,
      isLoss: false,
      shownScore: undefined,
    });
    expect(readFromLeft(true, undefined)?.isWin).toBe(true);
    expect(readFromLeft(false, undefined)).toEqual({
      winnersLeft: false,
      isWin: false,
      isLoss: true,
      shownScore: undefined,
    });
    expect(readFromLeft(undefined, [11])?.shownScore).toBeUndefined();
  });
});

describe("the pre-match favourite", () => {
  it("calls a near coin flip even, from either side", () => {
    expect(favoredSide(0.5)).toBe("even");
    expect(favoredSide(0.53)).toBe("even");
    expect(favoredSide(0.47)).toBe("even");
    expect(favoredSide(evenBelow - 0.001)).toBe("even");
  });

  it("names the favourite at or beyond the threshold", () => {
    expect(favoredSide(evenBelow)).toBe("left");
    expect(favoredSide(0.81)).toBe("left");
    expect(favoredSide(1 - evenBelow)).toBe("right");
    expect(favoredSide(0.3)).toBe("right");
  });
});
