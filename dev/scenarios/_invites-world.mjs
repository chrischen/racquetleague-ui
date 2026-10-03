// Shared world for the invite and private-message scenarios (invited.mjs,
// invite-host.mjs, messages.mjs). Not a scenario itself (leading underscore).
//
// You are Mika Sato. Aki Tanaka hosts Thursday Night Doubles and has invited
// you; you host Saturday Morning Drills and have invited Ken and Yui. Dates are
// relative to today in Tokyo, so the events always lie ahead.
//
// Private messages are stored as inbox items: topic "User_<owner>.inbox.direct"
// for one you received, "User_<owner>.sent.direct" for your own copy of one
// you sent, with a JSON payload (see src/lib/DirectMessage.res). An invite's
// note is a private message with context "rsvp_invited". As on the server,
// `viewer.inbox` lists notifications only (a message you received is one, your
// own sent copy is not), and `viewer.directMessages` returns conversations:
// a message row on /notifications opens /messages/<person>.
//
// The mutations below answer the way the server would, so inviting, replying,
// joining and leaving work on the page. Nothing is stored: a reload brings
// back the scenario's starting state.
import { signedInViewer, emptyConnection } from "./_shared.mjs";

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

// A Tokyo wall-clock time `days` after today, as ISO. Tokyo has no DST.
export function tokyoAt(days, hour, minute = 0) {
  const tokyoNow = new Date(Date.now() + 9 * HOUR);
  return new Date(
    Date.UTC(tokyoNow.getUTCFullYear(), tokyoNow.getUTCMonth(), tokyoNow.getUTCDate() + days, hour - 9, minute),
  ).toISOString();
}
const ago = (ms) => new Date(Date.now() - ms).toISOString();
// Today's date in Tokyo plus `days`, as YYYY-MM-DD.
const tokyoDate = (days) => new Date(Date.now() + 9 * HOUR + days * DAY).toISOString().slice(0, 10);

// --- People ------------------------------------------------------------------

// mu/sigma on the app's internal scale; dupr on DUPR's.
function person(id, name, gender, { mu = 22, sigma = 4, dupr = null, bio = null, extra = {} } = {}) {
  return {
    id,
    lineUsername: name,
    fullName: name,
    picture: null,
    gender,
    locale: "en",
    biography: bio,
    selfRating: mu,
    dupr: dupr && {
      duprId: `D${id.slice(-4).toUpperCase()}`,
      doubles: dupr,
      singles: null,
      doublesReliable: true,
      singlesReliable: false,
      doublesReliability: 60,
      syncedAt: ago(3 * DAY),
    },
    rating: () => ({ id: `Rating_${id}`, mu, sigma, ordinal: mu - 3 * sigma }),
    eventRating: (_source, args) => ({ id: `EventRating_${id}_${args.eventId}`, mu, sigma }),
    stripeAccountId: null,
    stripeChargesEnabled: false,
    ...extra,
  };
}

export const me = person("User_mika", "Mika Sato", "female", {
  mu: 23.5,
  dupr: 3.6,
  bio: "Doubles most weeknights. Working on my third-shot drop.",
  extra: { email: "mika@example.com" },
});

export const cast = {
  aki: person("User_aki", "Aki Tanaka", "male", { mu: 25.5, dupr: 3.9, bio: "Runs the Thursday group at Shibaura." }),
  ken: person("User_ken", "Ken Watanabe", "male", { mu: 21.5, dupr: 3.4, bio: "New to Tokyo, looking for regular games." }),
  yui: person("User_yui", "Yui Nakamura", "female", { mu: 23, dupr: 3.6, bio: "Lefty. Happy to play any side." }),
  daniel: person("User_daniel", "Daniel Brooks", "male", { mu: 24, bio: "Visiting from Melbourne until the 20th." }),
  emma: person("User_emma", "Emma Clarke", "female", { mu: 23.4, dupr: 3.55, bio: "Former tennis player, two years of pickleball." }),
  haruto: person("User_haruto", "Haruto Kobayashi", "male", { mu: 24.2, dupr: 3.7, bio: "Weekend mornings work best for me." }),
  sora: person("User_sora", "Sora Yamamoto", "female", { mu: 20.5, sigma: 7, bio: null }),
  rina: person("User_rina", "Rina Matsumoto", "female", { mu: 22.8, dupr: 3.5 }),
  takeshi: person("User_takeshi", "Takeshi Ito", "male", { mu: 24.6, dupr: 3.75 }),
  lena: person("User_lena", "Lena Fischer", "female", { mu: 23.9 }),
  jun: person("User_jun", "Jun Sasaki", "male", { mu: 25.1, dupr: 3.85 }),
  noah: person("User_noah", "Noah Kim", "male", { mu: 22.2 }),
  saki: person("User_saki", "Saki Endo", "female", { mu: 24.4, dupr: 3.7 }),
};

const directory = Object.fromEntries([me, ...Object.values(cast)].map((p) => [p.id, p]));

// --- Events ------------------------------------------------------------------

const pickleball = { id: "Activity_pickleball", name: "Pickleball", slug: "pickleball" };

// listType: 0 going, 1 pending approval, 2 invited by the host.
function rsvp(eventKey, user, listType = 0) {
  return {
    id: `Rsvp_${eventKey}_${user.id}`,
    listType,
    joinTime: Date.now() - 2 * DAY,
    message: null,
    payment: null,
    user: { id: user.id },
    rating: { id: `Rating_${user.id}_${eventKey}`, mu: 22, sigma: 4, ordinal: 10 },
  };
}

const connection = (nodes) => ({ ...emptyConnection, edges: nodes.map((node) => ({ cursor: node.id, node })) });

function event(key, fields, rsvps) {
  return {
    id: `Event_${key}`,
    timezone: "Asia/Tokyo",
    listed: true,
    deleted: null,
    shadow: false,
    externalUrl: null,
    minRating: null,
    cancelDeadline: null,
    // Free, so joining skips the card step (a price above 0 asks for one).
    price: 0,
    chargesEnabled: false,
    viewerIsBanned: false,
    smartRsvpThreshold: null,
    club: null,
    activity: pickleball,
    tags: [],
    rsvps: connection(rsvps),
    ...fields,
  };
}

export const thursday = { key: "thursday-doubles", title: "Thursday Night Doubles" };
export const saturday = { key: "saturday-drills", title: "Saturday Morning Drills" };

// Aki's game; you hold an invite unless `viewerListType` says otherwise
// (null: you have no RSVP).
export function thursdayEvent({ viewerListType = 2 } = {}) {
  const going = [cast.aki, cast.lena, cast.jun, cast.noah, cast.saki, cast.takeshi];
  return event(
    thursday.key,
    {
      title: thursday.title,
      details: "Rotating partners, games to 11. Intermediate (3.0–4.0). Balls provided.",
      startDate: () => tokyoAt(2, 19),
      endDate: () => tokyoAt(2, 21),
      maxRsvps: 12,
      tags: ["rec"],
      viewerIsAdmin: false,
      owner: { id: cast.aki.id },
      location: {
        id: "Location_shibaura",
        name: "Shibaura Sports Court",
        details: "Indoor, 4 courts on B1. Bring indoor shoes.",
        address: "3-2-1 Shibaura, Minato-ku, Tokyo",
        links: [],
        coords: { lat: 35.641, lng: 139.748 },
      },
    },
    [
      ...going.map((u) => rsvp(thursday.key, u)),
      ...(viewerListType == null ? [] : [rsvp(thursday.key, me, viewerListType)]),
    ],
  );
}

// Your game: three going, Ken and Yui invited, three seats open.
export function saturdayEvent() {
  return event(
    saturday.key,
    {
      title: saturday.title,
      details: "Drills for the first hour (dinks, drops, resets), then match play. 3.0–3.8.",
      startDate: () => tokyoAt(4, 9),
      endDate: () => tokyoAt(4, 11),
      maxRsvps: 8,
      viewerIsAdmin: true,
      owner: { id: me.id },
      location: {
        id: "Location_toyosu",
        name: "Toyosu Park Courts",
        details: "Outdoor, 2 courts by the water. Parking at the Toyosu Park lot.",
        address: "6-1 Toyosu, Koto-ku, Tokyo",
        links: [],
        coords: { lat: 35.652, lng: 139.794 },
      },
    },
    [
      rsvp(saturday.key, me),
      rsvp(saturday.key, cast.rina),
      rsvp(saturday.key, cast.takeshi),
      rsvp(saturday.key, cast.ken, 2),
      rsvp(saturday.key, cast.yui, 2),
    ],
  );
}

// --- Inbox -------------------------------------------------------------------

// A private message as an inbox row. `copy` is "received" (from them to you)
// or "sent" (your own copy). `minutes` is how long ago it was written.
export function directMessage({ id, copy, from, to, body, minutes, read = true, about = null, invite = false, replyTo = null }) {
  const owner = copy === "received" ? to : from;
  return {
    id,
    topic: `${owner.id}.${copy === "received" ? "inbox" : "sent"}.direct`,
    payload: JSON.stringify({
      fromUserId: from.id,
      fromUserName: from.lineUsername,
      toUserId: to.id,
      toUserName: to.lineUsername,
      body,
      ...(replyTo ? { replyTo } : {}),
      ...(about ? { eventId: `Event_${about.key}`, eventName: about.title } : {}),
      ...(invite ? { context: "rsvp_invited" } : {}),
    }),
    createdAt: () => ago(minutes * MINUTE),
    isRead: read,
    // Not part of the schema: what the mutations below need to answer a reply.
    meta: { from, about, expired: false },
  };
}

// An event notification (src/components/molecules/NotificationRow.res).
export function eventNotice({ id, about, activityType, actor, minutes, read = true, details = null }) {
  return {
    id,
    topic: `${me.id}.inbox.${activityType}`,
    payload: JSON.stringify({
      eventId: ["Event", about.key],
      eventName: about.title,
      activityType,
      actorUserName: actor.lineUsername,
      ...(details ? { details } : {}),
    }),
    createdAt: () => ago(minutes * MINUTE),
    isRead: read,
    meta: {},
  };
}

// --- Mocks -------------------------------------------------------------------

// The candidates the invite tools offer on your Saturday game.
const availability = (user, intervals) => ({
  id: `AvailabilityDay_${user.id}`,
  activityId: pickleball.id,
  localDate: tokyoDate(4),
  updatedAt: ago(DAY),
  userId: user.id,
  user: { id: user.id },
  intervals,
});

const recommendation = (user, { availability, fit, strong = false, dupr, established = true, openInvites = 0, shortfall = 0, score }) => ({
  availability,
  fit,
  strong,
  score,
  shortfall,
  openInvites,
  nearestGoingDupr: 3.6,
  rating: { dupr, established, mu: 23, sigma: established ? 3 : 7, source: established ? "dupr" : "self" },
  user: { id: user.id },
});

/**
 * Builds a scenario's mocks. `inbox` is newest-first; `thursdayInvite` is your
 * RSVP on Aki's game (2 invited, 0 going, null none).
 */
export function worldMocks({ inbox, thursdayInvite = 2 }) {
  const byId = Object.fromEntries(inbox.map((m) => [m.id, m]));
  const rows = () => inbox.map(({ meta, ...row }) => row);
  // As the server answers: your own sent copies are not notifications, and a
  // private message belongs to the conversation with whoever is on the other
  // side of it.
  const isDirect = (row) => row.topic.endsWith(".direct");
  const isSentCopy = (row) => row.topic.endsWith(".sent.direct");
  const counterpartOf = (row) => {
    const payload = JSON.parse(row.payload);
    return isSentCopy(row) ? payload.toUserId : payload.fromUserId;
  };
  const notifications = () => rows().filter((row) => !isSentCopy(row));
  const unread = notifications().filter((m) => !m.isRead).length;
  const events = {
    [`Event_${thursday.key}`]: () => thursdayEvent({ viewerListType: thursdayInvite }),
    [`Event_${saturday.key}`]: saturdayEvent,
  };

  return {
    Query: {
      viewer: {},
      event: (_source, args) => events[args.id]?.() ?? null,
      availabilityUsersForDay: () => [
        availability(cast.haruto, [{ startHour: 8, endHour: 12 }]),
        availability(cast.emma, [{ startHour: 9, endHour: 11 }]),
        availability(cast.sora, [{ startHour: 14, endHour: 17 }]),
      ],
      inviteRecommendations: () => ({
        freeSeats: 3,
        femaleSeatsNeeded: 1,
        errors: null,
        recommendations: [
          recommendation(cast.emma, { availability: "available", fit: "balanced", dupr: 3.55, score: 0.94 }),
          recommendation(cast.haruto, { availability: "available", fit: "balanced", strong: true, dupr: 3.7, score: 0.9 }),
          recommendation(cast.saki, { availability: "unknown", fit: "balanced", dupr: 3.7, openInvites: 1, score: 0.71 }),
          recommendation(cast.sora, { availability: "unavailable", fit: "unbalanced", dupr: 3.1, established: false, shortfall: 0.3, score: 0.42 }),
        ],
      }),
    },
    Viewer: signedInViewer({
      userId: me.id,
      viewerMetadata: { id: `ViewerMetadata_${me.id}`, unreadInboxCount: unread },
      inbox: (_source, args) => connection(notifications().slice(0, args.first ?? 50)),
      // Newest first, like the inbox list it is cut from.
      directMessages: (_source, args) =>
        connection(
          rows().filter((row) => isDirect(row) && (args.withUserId == null || counterpartOf(row) === args.withUserId)),
        ),
    }),
    User: (source) => directory[source.id] ?? {},
    Mutation: {
      // The invite becomes an "invited" RSVP on the event.
      inviteToEvent: (_source, args) => ({
        errors: null,
        edge: {
          cursor: `Rsvp_${args.eventId}_${args.userId}`,
          node: { id: `Rsvp_${args.eventId.replace(/^Event_/, "")}_${args.userId}`, listType: 2, user: { id: args.userId }, rating: null },
        },
      }),
      // A reply answers a message you received, back to its sender.
      sendDirectMessage: (_source, { input }) => {
        const original = byId[input.replyToMessageId];
        const body = (input.body ?? "").trim();
        if (!body) return { errors: [{ message: "EMPTY_MESSAGE" }], message: null };
        if (!original || original.meta.expired) return { errors: [{ message: "MESSAGE_NOT_FOUND" }], message: null };
        const sent = directMessage({
          id: `DM_sent_${Date.now()}`,
          copy: "sent",
          from: me,
          to: original.meta.from,
          body,
          minutes: 0,
          about: original.meta.about,
          replyTo: original.id,
        });
        const { meta, ...message } = sent;
        return { errors: null, message: { ...message, createdAt: new Date().toISOString() } };
      },
      // Joining converts your invite into a going RSVP, under the same id.
      joinEvent: (_source, args) => ({
        errors: null,
        edge: {
          cursor: "joined",
          node: { id: `Rsvp_${args.eventId.replace(/^Event_/, "")}_${me.id}`, listType: 0, user: { id: me.id }, rating: null },
        },
      }),
      leaveEvent: (_source, args) => ({
        errors: null,
        eventIds: [`Rsvp_${args.eventId.replace(/^Event_/, "")}_${me.id}`],
      }),
    },
  };
}

// Marks a message as too old to answer: the server has cleared it out.
export function expired(message) {
  return { ...message, meta: { ...message.meta, expired: true } };
}
