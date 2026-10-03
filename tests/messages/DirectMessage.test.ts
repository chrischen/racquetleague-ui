// Private messages in the inbox: decoding the two copies and grouping them
// into one conversation per person.
//
// The server stores each message twice under one id: the recipient's copy
// ("User_<to>.inbox.direct") and the sender's ("User_<from>.sent.direct").
// The viewer's inbox therefore holds both sides of every conversation. A
// reply answers the latest message the other person sent, because the server
// only accepts answers to a message the viewer received.
import { describe, expect, it } from "vitest";
import * as DM from "../../src/lib/DirectMessage.re.mjs";

const ME = "User_11111111-1111-1111-1111-111111111111";
const RIN = "User_22222222-2222-2222-2222-222222222222";
const KEN = "User_33333333-3333-3333-3333-333333333333";
const EVENT = "Event_44444444-4444-4444-4444-444444444444";

const names: Record<string, string> = { [ME]: "Me", [RIN]: "Rin", [KEN]: "Ken" };

// ReScript compiles labelled arguments positionally: id, topic, payload, createdAt.
const row = (
  id: string,
  copy: "inbox" | "sent",
  from: string,
  to: string,
  body: string,
  createdAt: string,
  extra: Record<string, string> = {},
) =>
  DM.decode(
    id,
    `${ME}.${copy}.direct`,
    JSON.stringify({
      fromUserId: from,
      fromUserName: names[from],
      toUserId: to,
      toUserName: names[to],
      body,
      ...extra,
    }),
    createdAt,
  );

describe("decode", () => {
  it("reads both copies", () => {
    const received = row("a", "inbox", RIN, ME, "hi", "2026-10-01T10:00:00.000Z");
    const sent = row("b", "sent", ME, RIN, "hello", "2026-10-01T11:00:00.000Z");
    expect(received.copy).toBe("Received");
    expect(sent.copy).toBe("Sent");
    expect(DM.counterpart(received)).toEqual([RIN, "Rin"]);
    expect(DM.counterpart(sent)).toEqual([RIN, "Rin"]);
  });

  it("recognises an invite's note", () => {
    const invite = row("a", "inbox", RIN, ME, "come play", "2026-10-01T10:00:00.000Z", {
      eventId: EVENT,
      eventName: "Saturday doubles",
      context: "rsvp_invited",
    });
    expect(DM.isInvite(invite)).toBe(true);
  });

  it("ignores rows that are not private messages", () => {
    expect(DM.decode("a", `${ME}.inbox.rsvp_added`, "{}", "2026-10-01")).toBeUndefined();
    expect(DM.decode("a", `${ME}.inbox.direct`, "not json", "2026-10-01")).toBeUndefined();
    expect(DM.decode("a", `${ME}.inbox.direct`, undefined, "2026-10-01")).toBeUndefined();
    expect(DM.decode("a", `${ME}.inbox.direct`, '{"body":"x"}', "2026-10-01")).toBeUndefined();
  });
});

describe("threadPath", () => {
  it("puts a conversation at /messages/<person>", () => {
    expect(DM.threadPath(RIN)).toBe(`/messages/${RIN}`);
  });
});

describe("conversations", () => {
  const messages = [
    row("1", "inbox", RIN, ME, "come play", "2026-10-01T10:00:00.000Z", {
      eventId: EVENT,
      eventName: "Saturday doubles",
      context: "rsvp_invited",
    }),
    row("2", "sent", ME, RIN, "count me in", "2026-10-01T11:00:00.000Z", {
      eventId: EVENT,
      eventName: "Saturday doubles",
    }),
    row("3", "sent", ME, KEN, "thanks!", "2026-10-02T09:00:00.000Z"),
    row("4", "inbox", RIN, ME, "great", "2026-10-01T12:00:00.000Z"),
  ];
  const convs = DM.conversations(messages);

  it("groups by the other person, most recently active first", () => {
    expect(convs.map((c: any) => c.withUserName)).toEqual(["Ken", "Rin"]);
  });

  it("orders each conversation oldest first", () => {
    const rin = convs[1];
    expect(rin.messages.map((m: any) => m.body)).toEqual(["come play", "count me in", "great"]);
  });

  it("answers the latest message they sent", () => {
    expect(convs[1].replyTarget.id).toBe("4");
  });

  it("offers no reply until they have written", () => {
    expect(convs[0].replyTarget).toBeUndefined();
  });

  it("keeps the event the conversation is about", () => {
    expect(convs[1].event).toEqual([EVENT, "Saturday doubles"]);
    expect(convs[0].event).toBeUndefined();
  });

  it("shows a just-sent reply once, even after the server returns it too", () => {
    const again = row("5", "sent", ME, RIN, "see you", "2026-10-01T13:00:00.000Z");
    const merged = DM.conversations([...messages, again, again]);
    const rin = merged.find((c: any) => c.withUserId === RIN);
    expect(rin.messages.filter((m: any) => m.id === "5").length).toBe(1);
  });
});
