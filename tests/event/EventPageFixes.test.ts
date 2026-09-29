// Two numbers the event pages derive and got wrong.
//
// The sticky footer's waitlisted row used to show the size of the whole
// waitlist as "#N in queue"; it is the viewer's own place, in join order.
//
// Editing (or copying) an event that has no club started the club picker on
// the organizer's first admin club, and the form sends the picked club, so
// saving moved the event into that club. Only a new event may default to it.
import { describe, expect, it } from "vitest";
import * as EventStickyFooter from "../../src/components/organisms/EventStickyFooter.re.mjs";
import * as ClubActivitySelector from "../../src/components/organisms/ClubActivitySelector.re.mjs";

describe("EventStickyFooter.waitlistPositionOf", () => {
  const waitlist = ["rsvp-10", "rsvp-11", "rsvp-12"];

  it("is the viewer's 1-based place, not the waitlist's size", () => {
    expect(EventStickyFooter.waitlistPositionOf(waitlist, "rsvp-11")).toBe(2);
    expect(EventStickyFooter.waitlistPositionOf(waitlist, "rsvp-10")).toBe(1);
    expect(EventStickyFooter.waitlistPositionOf(waitlist, "rsvp-12")).toBe(3);
  });

  it("is absent when the viewer is not on the waitlist", () => {
    expect(EventStickyFooter.waitlistPositionOf(waitlist, "rsvp-1")).toBeUndefined();
    expect(EventStickyFooter.waitlistPositionOf(waitlist, undefined)).toBeUndefined();
    expect(EventStickyFooter.waitlistPositionOf([], "rsvp-11")).toBeUndefined();
  });
});

// The footer's "going/max" counted the whole main list, waitlist included,
// so a full event read "14/12". Only the players within capacity are going.
describe("EventStickyFooter.goingCountOf", () => {
  it("stops at capacity when the main list runs past it", () => {
    expect(EventStickyFooter.goingCountOf(14, 12)).toBe(12);
    expect(EventStickyFooter.goingCountOf(12, 12)).toBe(12);
  });

  it("counts everyone below capacity", () => {
    expect(EventStickyFooter.goingCountOf(7, 12)).toBe(7);
    expect(EventStickyFooter.goingCountOf(0, 12)).toBe(0);
  });

  it("counts everyone when the event has no cap", () => {
    expect(EventStickyFooter.goingCountOf(14, 0)).toBe(14);
  });
});

describe("ClubActivitySelector.resolveInitialClub", () => {
  const clubs = ["club-shibuya", "club-meguro"];

  it("keeps the event's own club", () => {
    expect(ClubActivitySelector.resolveInitialClub("club-meguro", clubs, true)).toBe("club-meguro");
    expect(ClubActivitySelector.resolveInitialClub("club-meguro", clubs, false)).toBe("club-meguro");
  });

  it("starts a new event on the organizer's first club", () => {
    expect(ClubActivitySelector.resolveInitialClub(undefined, clubs, true)).toBe("club-shibuya");
    expect(ClubActivitySelector.resolveInitialClub(undefined, [], true)).toBeUndefined();
  });

  it("leaves an existing event without a club without one", () => {
    expect(ClubActivitySelector.resolveInitialClub(undefined, clubs, false)).toBeUndefined();
  });
});
