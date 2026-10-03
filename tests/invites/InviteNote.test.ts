// The invite note rules, enforced in the composer only: a note must say
// something, and it may not repeat the note just sent to someone else.
//
// "Long enough" is weighted: a Chinese, Japanese or Korean character counts
// as two, so the minimum is about 10 characters in those languages and 20
// elsewhere.
import { describe, expect, it } from "vitest";
import * as InviteNote from "../../src/lib/InviteNote.re.mjs";

// ReScript compiles labelled arguments positionally: message, previous.
const check = (message: string, previous?: string) => InviteNote.check(message, previous);
const LONG = "Saturday doubles at 10, want to join us?";

describe("InviteNote.check", () => {
  it("requires a note", () => {
    expect(check("   ")).toBe("Empty");
  });

  it("says how many more characters a short note needs", () => {
    expect(check("Come play")).toEqual({ TAG: "TooShort", _0: InviteNote.minLength - 9 });
  });

  it("counts the trimmed note", () => {
    const padded = `   ${"x".repeat(InviteNote.minLength - 1)}   `;
    expect(check(padded)).toEqual({ TAG: "TooShort", _0: 1 });
    expect(check("x".repeat(InviteNote.minLength))).toBeUndefined();
  });

  it("accepts a new note", () => {
    expect(check(LONG, "Thought you'd be a good fit for this one.")).toBeUndefined();
  });

  it("refuses the previous note pasted again", () => {
    expect(check(LONG, LONG)).toBe("SameAsPrevious");
  });

  it("ignores case and spacing when comparing", () => {
    expect(check(`  saturday doubles at 10,\n  want to JOIN us?  `, LONG)).toBe("SameAsPrevious");
  });

  it("accepts any note when nothing has been sent yet", () => {
    expect(check(LONG, undefined)).toBeUndefined();
  });
});

describe("InviteNote weighted length", () => {
  it("counts Chinese, Japanese and Korean characters as two", () => {
    expect(InviteNote.weightedLength("abc")).toBe(3);
    expect(InviteNote.weightedLength("土曜日")).toBe(6);
    expect(InviteNote.weightedLength("よろしく")).toBe(8);
    expect(InviteNote.weightedLength("같이 쳐요")).toBe(9);
    expect(InviteNote.weightedLength("、。！")).toBe(6);
  });

  it("counts Thai, Vietnamese and emoji as one each", () => {
    expect(InviteNote.weightedLength("มาเล่นกัน")).toBe(9);
    expect(InviteNote.weightedLength("Chơi cùng")).toBe(9);
    expect(InviteNote.weightedLength("🏓")).toBe(1);
  });

  it("accepts a short but real Japanese note", () => {
    // 18 characters: "Doubles on Saturday, want to join?"
    expect(check("土曜日のダブルス、一緒にどうですか？")).toBeUndefined();
  });

  it("accepts a Korean or Chinese sentence", () => {
    expect(check("토요일 복식 같이 치실래요?")).toBeUndefined();
    expect(check("周六双打，一起来吗？")).toBeUndefined();
  });

  it("asks a bare greeting for more, counted in its own script", () => {
    // 4 characters, 8 units: 12 units short, so 6 more Japanese characters.
    expect(check("よろしく")).toEqual({ TAG: "TooShort", _0: 6 });
  });

  it("puts the line at ten characters in Japanese", () => {
    expect(check("一二三四五六七八九十")).toBeUndefined();
    expect(check("一二三四五六七八九")).toEqual({ TAG: "TooShort", _0: 1 });
  });

  it("still asks English for twenty", () => {
    expect(check("Come play with us!")).toEqual({ TAG: "TooShort", _0: 2 });
  });

  it("still refuses a repeated Japanese note", () => {
    const note = "土曜日のダブルス、一緒にどうですか？";
    expect(check(note, note)).toBe("SameAsPrevious");
  });
});

