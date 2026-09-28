import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import { connection, endDate, payment, rsvps, rsvpsFrom, startDate } from "./StoryFixturesEvent.gen";
import { availabilityDays, recommendations } from "./StoryFixturesEventPage.gen";
import { make as PkRSVPSectionStory, query } from "./PkRSVPSectionStory.gen";

// The Participants card on the pickleball event page: how full the event is,
// the skill curve of who's going, then the confirmed chips (strongest first),
// the waitlist, pending requests and invites. Players see a notice when the
// event restricts levels or admits by Smart RSVP. The organizer also gets the
// Smart RSVP controls, the swipe review for pending requests, "charge all"
// on events that collect payments, "add player" on club events, and invite
// suggestions (EventInvites). Kenji W. owns the event; the players are the
// StoryFixturesEvent roster. Thursday 15 October 2026, 19:00-21:00 in Tokyo.

// Join requests awaiting the organizer (listType 1), with the note each left
// and a profile biography, which the swipe review shows.
const NOTES = [
  "初心者ですが、よろしくお願いします！",
  "Played with Kenji at Ariake last month, happy to fill any spot.",
  null,
  "Can only stay until 20:30, hope that's OK.",
  "友達と一緒に参加したいです。",
];
const BIOS = [
  "週末ピックルボーラー。ダブルス大好きです。",
  "Former squash player, two years of pickleball. Usually at Shibaura on weekends.",
  null,
  "Just moved to Tokyo from Vancouver. Solid 3.5, working on my resets.",
  "テニス歴10年、ピックルボールは半年です。",
];
const pending = (start: number, count: number) =>
  rsvpsFrom(start, count).map((r, i) => ({
    ...r,
    listType: 1,
    message: NOTES[i % NOTES.length],
    user: { ...r.user, biography: BIOS[i % BIOS.length] },
  }));
const invited = (start: number, count: number) => rsvpsFrom(start, count).map((r) => ({ ...r, listType: 2 }));

// A viewer who isn't on the roster, rated for this event.
const player = (eventRating: { mu: number; sigma: number } | null) =>
  signedInViewer({
    user: { id: "user-1", dupr: null, eventRating: eventRating && { id: "rating-evt-user-1", ...eventRating } },
  });
// The organizer, who plays in their own event.
const ORGANIZER = signedInViewer({
  userId: "user-kenji",
  user: { id: "user-kenji", dupr: null, eventRating: { id: "rating-evt-kenji", mu: 36.1, sigma: 3.0 } },
});

const EVENT = {
  title: "Thursday Night Doubles",
  startDate,
  endDate,
  timezone: "Asia/Tokyo",
  maxRsvps: 12,
  price: null,
  chargesEnabled: false,
  shadow: false,
  minRating: null,
  smartRsvpThreshold: null,
  viewerIsAdmin: false,
  tags: [],
  club: null,
  activity: { id: "act-pickleball", slug: "pickleball" },
  location: { id: "loc-ariake", name: "Ariake Tennis Forest Park" },
  owner: { id: "user-kenji", lineUsername: "Kenji W." },
  rsvps: connection(rsvps(9)),
};

// What the organizer's invite suggestions load (EventInvites' own queries).
const INVITE_SOURCES = {
  inviteRecommendations: recommendations(5),
  availabilityUsersForDay: availabilityDays("2026-10-15"),
};
const NO_INVITE_SOURCES = {
  inviteRecommendations: { recommendations: [] },
  availabilityUsersForDay: [],
};

type Mocks = Record<string, unknown>;
const organizer = (event: Mocks, query: Mocks = {}, types: Mocks = {}) => ({
  relay: {
    mocks: {
      Query: { ...NO_INVITE_SOURCES, ...query },
      Viewer: ORGANIZER,
      Event: { viewerIsAdmin: true, ...event },
      ...types,
    },
  },
});

const meta = {
  title: "Organisms/PkRSVPSection",
  component: PkRSVPSectionStory,
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { event: {}, viewer: {} },
        Viewer: player(null),
        Event: EVENT,
      },
    },
  },
} satisfies Meta<typeof PkRSVPSectionStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A player's view of a casual event: 9 of 12 going, the skill curve and the
    confirmed chips; the host is starred. */
export const PlayerView: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("9/12 joined")).toBeVisible();
    await expect(canvas.getByText("Confirmed · 9")).toBeVisible();
  },
};

/** A competitive event shows each player's rating; "View more" opens the
    level statistics (top-6 average, median, men/women, spread). */
export const CompetitiveStats: Story = {
  parameters: { relay: { mocks: { Event: { tags: ["comp"], rsvps: connection(rsvps(12)), maxRsvps: 16 } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "View more" }));
    await expect(await canvas.findByText("TOP 6 AVG")).toBeVisible();
    await expect(canvas.getByText("SPREAD")).toBeVisible();
  },
};

/** Full: 12 confirmed, two more on the waitlist in join order, and a red bar. */
export const FullWithWaitlist: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(14)) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    // Renders as "12/12 joined· +2 waitlist": the translated " · +N waitlist"
    // loses its leading space. Matched loosely so fixing that keeps it green.
    await expect(canvas.getByText(/12\/12 joined\s*· \+2 waitlist/)).toBeVisible();
    await expect(canvas.getByText("Waitlist · 2")).toBeVisible();
  },
};

/** A level-restricted event the viewer is rated below: an amber notice with
    their rating range; joining would put them on the pending list. */
export const BelowMinimumRating: Story = {
  parameters: {
    relay: { mocks: { Viewer: player({ mu: 24.5, sigma: 4.2 }), Event: { minRating: 30, tags: ["comp"] } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("LEVEL RESTRICTION")).toBeVisible();
    await expect(canvas.getByText(/is below the minimum/)).toBeVisible();
  },
};

/** The same restriction for a player rated above it: a quiet grey note. */
export const MeetsMinimumRating: Story = {
  parameters: {
    relay: { mocks: { Viewer: player({ mu: 36.5, sigma: 2.1 }), Event: { minRating: 30, tags: ["comp"] } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/Requires DUPR .*\+ to join/)).toBeVisible();
  },
};

/** Smart RSVP admits by level rather than join time: the player is told
    their request will be reviewed. Four requests are already waiting. */
export const SmartRsvpPlayer: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: { smartRsvpThreshold: 0.05, rsvps: connection([...rsvps(8), ...pending(9, 4)]) },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("SMART RSVP")).toBeVisible();
    await expect(canvas.getByText("Pending · 4")).toBeVisible();
    await expect(canvas.queryByRole("button", { name: /Swipe review|Review/ })).toBeNull();
  },
};

/** The organizer on a Smart RSVP event: "Preview Smart RSVP" marks the
    requests the next run would admit, and the button becomes "Run Smart RSVP
    now". */
export const OrganizerSmartRsvp: Story = {
  parameters: organizer(
    { smartRsvpThreshold: 0.05, rsvps: connection([...rsvps(8), ...pending(9, 4)]) },
    { previewSmartRsvps: { errors: null, rsvps: [{ id: "rsvp-aoi" }, { id: "rsvp-mei" }] } },
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Preview Smart RSVP" }));
    await expect(await canvas.findByRole("button", { name: "Run Smart RSVP now" })).toBeVisible();
    await expect(canvas.getByText(/Smart RSVP would admit 2 of 4 pending requests/)).toBeVisible();
    await expect(canvas.getAllByTitle("Would be admitted")).toHaveLength(2);
  },
};

/** A full Smart RSVP event: "Smart Waitlist" ranks the pending requests onto
    the waitlist. */
export const OrganizerFullSmartWaitlist: Story = {
  parameters: organizer({ maxRsvps: 8, smartRsvpThreshold: 0.05, rsvps: connection([...rsvps(8), ...pending(8, 5)]) }),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: "Smart Waitlist" })).toBeVisible();
  },
};

/** "Swipe review" opens the pending requests as cards, one at a time: the
    player's level, rating, biography and the note they left. */
export const OrganizerSwipeReview: Story = {
  parameters: { layout: "fullscreen", ...organizer({ rsvps: connection([...rsvps(8), ...pending(9, 4)]) }) },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Review 4 pending requests with swipe cards" }));
    const body = within(canvasElement.ownerDocument.body);
    await expect(await body.findByRole("dialog", { name: "Review requests" })).toBeVisible();
    await waitFor(() => expect(body.getByRole("button", { name: "Approve あおい" })).toBeVisible());
  },
};

/** A priced event on a club that collects payments: the card icon charges
    every saved card. One is declined, and the error is listed. */
export const OrganizerChargePlayers: Story = {
  parameters: organizer(
    {
      price: 1500,
      chargesEnabled: true,
      rsvps: connection(
        rsvps(9).map((r, i) => ({ ...r, payment: payment(r.id, i === 0 ? 1 : i === 6 ? 3 : 5) })),
      ),
    },
    {},
    // What captureEventRsvpPayments answers: one error per declined card.
    { CaptureEventPaymentsResult: { payments: [], errors: [{ message: "Rin: Your card was declined." }] } },
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByTitle("Charge all payments"));
    await expect(await canvas.findByText(/Rin: Your card was declined/)).toBeVisible();
  },
};

/** A club event: the organizer's "add player" searches the club's members. */
export const OrganizerAddPlayer: Story = {
  parameters: organizer(
    { club: { id: "club-shibuya" } },
    {
      clubMembers: {
        edges: [
          { node: { id: "membership-ryo", user: { id: "user-ryo", fullName: "Ryo Yamamoto", lineUsername: "Ryo" } } },
          { node: { id: "membership-haruka", user: { id: "user-haruka", fullName: "Haruka Ito", lineUsername: "はるか" } } },
        ],
      },
    },
  ),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByTitle("Add player"));
    // The row fades in.
    const search = await canvas.findByPlaceholderText("Search players...");
    await waitFor(() => expect(search).toBeVisible());
  },
};

/** The organizer's invite strip under the lists: two invites already sent,
    then suggestions (sparkles: ranked by fit, with their DUPR) and players
    whose availability covers the event. */
export const OrganizerWithInvites: Story = {
  parameters: organizer({ rsvps: connection([...rsvps(8), ...invited(12, 2)]) }, INVITE_SOURCES),
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("button", { name: /Swipe invites|Review \d+ potential players/ })).toBeVisible();
    await expect(canvas.getAllByText("sent")).toHaveLength(2);
  },
};

/** Nobody has joined yet. */
export const Empty: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection([]) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("0/12 joined")).toBeVisible();
  },
};
