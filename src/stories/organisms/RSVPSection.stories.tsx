import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import { connection, rosterSize, rsvps, rsvpsFrom, users } from "./StoryFixturesEvent.gen";
import { make as RSVPSectionStory, query } from "./RSVPSectionStory.gen";

// The RSVP card on the classic event page (EventPage): the join button in the
// viewer's state, their status message once they have joined, then the Going
// list, the waitlist and pending requests (GoingRsvps, RsvpWaitlist,
// PendingRsvps). Players see a warning when they are rated below the event's
// minimum, or a notice when it admits by Smart RSVP. The organizer gets the
// Smart RSVP controls and, on club events, "Add Member". On a desktop window
// it is a sidebar card; below the md breakpoint it becomes a bar fixed to the
// bottom of the window that expands into the lists (see MobileBar).

const ME = "user-1";
// A signed-in viewer; `eventRating` is theirs for this event (ordinal = mu - 3 sigma).
// A viewer on the roster is the same User record as their RSVP's, so they
// carry the roster's fields.
const viewer = (userId = ME, eventRating: { mu: number; sigma: number } | null = null) =>
  signedInViewer({
    userId,
    user: {
      ...(users(rosterSize).find((u) => u.id === userId) ?? { lineUsername: "Chris" }),
      id: userId,
      eventRating: eventRating && {
        id: `rating-evt-${userId}`,
        ordinal: eventRating.mu - 3 * eventRating.sigma,
        ...eventRating,
      },
    },
  });

// The card renders a mobile and a desktop layout and CSS hides one, so text
// appears twice: take the copy that is showing.
const shown = (canvasElement: HTMLElement, text: string | RegExp) => {
  const el = within(canvasElement)
    .getAllByText(text)
    .find((e) => e.offsetParent !== null);
  if (!el) throw new Error(`No visible element with text ${String(text)}`);
  return el;
};

const pending = (start: number, count: number) => rsvpsFrom(start, count).map((r) => ({ ...r, listType: 1 }));

const meta = {
  title: "Organisms/RSVPSection",
  component: RSVPSectionStory,
  args: { onBeforeJoin: fn() },
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { event: {}, viewer: {} },
        Viewer: viewer(),
        Event: {
          maxRsvps: 12,
          minRating: null,
          price: null,
          smartRsvpThreshold: null,
          viewerIsAdmin: false,
          activity: { slug: "pickleball" },
          club: null,
          rsvps: connection(rsvps(9)),
        },
      },
    },
  },
} satisfies Meta<typeof RSVPSectionStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A signed-in player who hasn't joined: "Join Event" over the Going list. */
export const NotJoined: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getAllByRole("button", { name: /Join Event/ })[0]);
    // The page's profile gate runs first; the story only records the call.
    await expect(args.onBeforeJoin).toHaveBeenCalled();
  },
};

/** Signed out: the button sends the visitor to log in. */
export const SignedOut: Story = {
  parameters: { relay: { mocks: { Query: { viewer: null } } } },
  play: async ({ canvasElement }) => {
    await expect(shown(canvasElement, "Login to Join")).toBeVisible();
  },
};

/** Going, with the status message the player left for everyone (click it to
    edit). */
export const Going: Story = {
  parameters: {
    relay: {
      mocks: {
        Viewer: viewer("user-emily"),
        Event: {
          rsvps: connection(
            rsvps(9).map((r) => (r.id === "rsvp-emily" ? { ...r, message: "Running 10 minutes late, start without me!" } : r)),
          ),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    await expect(shown(canvasElement, "You're Going")).toBeVisible();
    // The collapsed phone bar has no room for it.
    if (window.innerWidth >= 768) {
      await expect(shown(canvasElement, "Running 10 minutes late, start without me!")).toBeVisible();
    }
  },
};

/** Full: 12 going and two waiting; the viewer can join the waitlist. */
export const Full: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(14)) } } } },
  play: async ({ canvasElement }) => {
    await expect(shown(canvasElement, "Join Waitlist")).toBeVisible();
  },
};

/** The viewer is second on the waitlist of a full event. */
export const Waitlisted: Story = {
  parameters: {
    relay: { mocks: { Viewer: viewer("user-olivia"), Event: { rsvps: connection(rsvps(14)) } } },
  },
  play: async ({ canvasElement }) => {
    await expect(shown(canvasElement, "You're Waitlisted")).toBeVisible();
  },
};

/** The viewer's request is waiting for the organizer. */
export const PendingRequest: Story = {
  parameters: {
    relay: { mocks: { Viewer: viewer("user-tom"), Event: { rsvps: connection([...rsvps(9), ...pending(10, 2)]) } } },
  },
  play: async ({ canvasElement }) => {
    await expect(shown(canvasElement, "RSVP Pending...")).toBeVisible();
  },
};

/** Rated below the event's minimum: the warning with the player's rating
    range, before they join. */
export const BelowMinimumRating: Story = {
  parameters: {
    relay: { mocks: { Viewer: viewer(ME, { mu: 24.5, sigma: 4.2 }), Event: { minRating: 20 } } },
  },
  play: async ({ canvasElement }) => {
    await expect(shown(canvasElement, /Required rating: 20.00/)).toBeVisible();
  },
};

/** A Smart RSVP event: players are told their request will be reviewed. */
export const SmartRsvpNotice: Story = {
  parameters: {
    relay: { mocks: { Event: { smartRsvpThreshold: 0.05, rsvps: connection([...rsvps(8), ...pending(9, 4)]) } } },
  },
  play: async ({ canvasElement }) => {
    await expect(shown(canvasElement, /This event admits players automatically/)).toBeVisible();
  },
};

/** The organizer of a club's Smart RSVP event: the pending requests, the
    preview/run button and the member search to add someone directly. */
export const OrganizerSmartRsvp: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          previewSmartRsvps: { errors: null, rsvps: [{ id: "rsvp-aoi" }, { id: "rsvp-mei" }] },
          clubMembers: { edges: [] },
        },
        Viewer: viewer("user-kenji"),
        Event: {
          viewerIsAdmin: true,
          club: { id: "club-shibuya" },
          smartRsvpThreshold: 0.05,
          rsvps: connection([...rsvps(8), ...pending(9, 4)]),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const [preview] = canvas.getAllByRole("button", { name: "Preview Smart RSVP" });
    await userEvent.click(preview);
    await waitFor(() => expect(shown(canvasElement, /Smart RSVP would admit 2 of 4/)).toBeVisible());
  },
};

/** Phone width: a bar fixed to the bottom with the join button and the first
    three faces; tapping it expands the lists. Open the viewport toolbar (or
    run the smoke test with --mobile) to see it; wider windows show the card. */
export const MobileBar: Story = {
  globals: { viewport: { value: "mobile1", isRotated: false } },
  parameters: { layout: "fullscreen" },
};
