import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import {
  courtDays,
  discoverEvents,
  eventsConnection,
  playerAvailability,
  resolvedTokyo,
  shiftClock,
  viewerAvailability,
  viewerEvents,
  viewerUser,
} from "./StoryFixturesDiscovery.gen";
import { make as PkEventsListStory, query } from "./PkEventsListStory.gen";

// The events list behind Discover (/e/pickleball), a venue's page and a
// player's own events: the compact calendar, the location and filter bar,
// then one block per day (Today, Tomorrow, weekday, "Next ...") with the
// day's availability row (the viewer's saved time, players, courts) and its
// event rows. Discover also interleaves open courts between the events and
// tucks forwarded venue bookings behind "Show n more". The clock is set to
// Wednesday 14 October 2026, 09:00 in Tokyo (StoryFixturesDiscovery).
const clubs = { edges: [{ node: { id: "club-tpc" } }, { node: { id: "club-spc" } }] };

const VIEWER = signedInViewer({
  user: viewerUser,
  profile: viewerUser,
  clubs,
  availability: viewerAvailability,
  events: eventsConnection(viewerEvents, false),
});

const meta = {
  title: "Organisms/PkEventsList",
  component: PkEventsListStory,
  beforeEach: shiftClock,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: {
          viewer: {},
          events: eventsConnection(discoverEvents, false),
          resolvedLocation: resolvedTokyo,
          availabilityUsersForDateRange: playerAvailability,
          locationsAvailability: courtDays,
        },
        Viewer: VIEWER,
      },
    },
  },
  args: { showInlineCourts: true, showLocationFilter: true, hideOtherClubs: true },
} satisfies Meta<typeof PkEventsListStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Discover for a signed-in club member: six days, open courts between the
 * events, the viewer joined, waitlisted and pending on four of them. */
export const Discover: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Wednesday Night Doubles")).toBeVisible();
    await expect(canvas.getByText("Waitlisted")).toBeVisible();
    await expect(canvas.getAllByText("Joined")).toHaveLength(2);
    await expect(canvas.getByText("Pending")).toBeVisible();
    await expect(canvas.getByText("Show 1 more")).toBeVisible();
  },
};

/** "Show 1 more" brings back the court booking forwarded by email, a
 * venue's own session that can't be joined here. */
export const ForwardedBookingShown: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByText("Show 1 more"));
    await expect(await canvas.findByText("Court booking · PickleOne Ginza, Court 2")).toBeVisible();
  },
};

/** Signed out: every row offers Join (it leads to login) and no statuses. */
export const SignedOut: Story = {
  parameters: { relay: { mocks: { Query: { viewer: null } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Thursday Doubles")).toBeVisible();
    await expect(canvas.queryByText("Waitlisted")).toBeNull();
  },
};

/** A player's own list (PkViewerEventsPage): no courts, no location bar. */
export const MyEvents: Story = {
  args: { showInlineCourts: false, showLocationFilter: false, hideOtherClubs: false },
  parameters: { relay: { mocks: { Query: { events: eventsConnection(viewerEvents, false) } } } },
};

/** The "Open spots" filter on: full events drop out of the loaded page. */
export const OpenSpotsOnly: Story = {
  parameters: { router: { url: "/?openSpots=true" } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Thursday Doubles")).toBeVisible();
    await expect(canvas.queryByText("Friday Rated Session")).toBeNull();
  },
};

/** A page in the middle of the list: "previous" above, "more" below. */
export const MiddlePage: Story = {
  parameters: {
    relay: { mocks: { Query: { events: eventsConnection(discoverEvents.slice(0, 5), true) } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("← previous")).toBeVisible();
    await expect(canvas.getByText("more →")).toBeVisible();
  },
};

/** Nothing scheduled: the header counts zero and no day blocks follow. */
export const NoEvents: Story = {
  parameters: { relay: { mocks: { Query: { events: eventsConnection([], false) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await waitFor(() => expect(canvas.getByText(/0 EVENTS/)).toBeVisible());
  },
};

/** Phone width: rows swap the status badge and bar for a dot and a count.
 * (Use the viewport toolbar, or `storybook-smoke.mjs --mobile`.) */
export const Mobile: Story = {
  globals: { viewport: { value: "mobile2", isRotated: false } },
};
