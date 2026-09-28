import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import { eventById, eventsConnection, shiftClock, viewerUser, type eventMock } from "./StoryFixturesDiscovery.gen";
import { make as PkEventRowStory, query } from "./PkEventRowStory.gen";

// One event in the events lists: start time and length, title, club and
// venue, level and privacy tags, then the viewer's status (Joined /
// Waitlisted / Pending), the average DUPR of the top six players and a
// capacity bar that turns orange two spots from full and red when full. On a
// desktop, hovering slides in Join / Waitlist / Leave (greyed once the cancel
// deadline has passed); on a phone the row swipes. A canceled event collapses
// to a struck-through line that expands. The clock is Wednesday 14 October
// 2026, 09:00 in Tokyo. Each story lists the events it names on Query.events.
const events = (...ids: string[]) =>
  eventsConnection(
    ids.map((id) => eventById(id) as eventMock),
    false,
  );

const meta = {
  title: "Organisms/PkEventRow",
  component: PkEventRowStory,
  beforeEach: shiftClock,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: { viewer: {}, events: events("evt-morning-open") },
        Viewer: signedInViewer({ user: viewerUser, profile: viewerUser }),
      },
    },
  },
  args: { onEventClick: fn(), dimmed: false },
} satisfies Meta<typeof PkEventRowStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Room to spare (7 of 12): hovering slides in Join. */
export const Open: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.hover(await canvas.findByText("Morning Open Play"));
    await expect(await canvas.findByRole("button", { name: "Join" })).toBeVisible();
  },
};

/** The viewer is in, two spots left (orange). Leave slides in on hover. */
export const Joined: Story = {
  parameters: { relay: { mocks: { Query: { events: events("evt-thu-doubles") } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Joined")).toBeVisible();
    await userEvent.hover(canvas.getByText("Thursday Doubles"));
    await expect(await canvas.findByRole("button", { name: "Leave" })).toBeVisible();
  },
};

/** Full (red), the viewer ninth of eight: waitlisted, and past the 24-hour
 * cancel deadline, so Leave is greyed. */
export const WaitlistedPastDeadline: Story = {
  parameters: { relay: { mocks: { Query: { events: events("evt-wed-doubles") } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Waitlisted")).toBeVisible();
    // The count is drawn twice (phone and desktop layouts); one is shown.
    await expect(canvas.getAllByText("10/8").filter((el) => el.offsetParent !== null)).toHaveLength(1);
    await userEvent.hover(canvas.getByText("Wednesday Night Doubles"));
    await expect(await canvas.findByRole("button", { name: "Leave" })).toHaveClass("text-gray-400");
  },
};

/** Full with a waitlist: the action becomes Waitlist. Strong players push the
 * DUPR badge up (amber at 4.0, orange at 4.5). */
export const FullAndStrong: Story = {
  parameters: { relay: { mocks: { Query: { events: events("evt-fri-rated", "evt-advanced") } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.hover(await canvas.findByText("Friday Rated Session"));
    await expect(await canvas.findByRole("button", { name: "Waitlist" })).toBeVisible();
  },
};

/** The viewer asked to join; the organizer hasn't answered. */
export const Pending: Story = {
  parameters: { relay: { mocks: { Query: { events: events("evt-sunday-social") } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Pending")).toBeVisible();
  },
};

/** A private (unlisted) event with a long title, and an uncapped one that
 * counts players instead of showing a bar. */
export const PrivateAndUncapped: Story = {
  parameters: { relay: { mocks: { Query: { events: events("evt-weekend-rr", "evt-beginners") } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const counts = await canvas.findAllByText("6 players");
    await expect(counts.filter((el) => el.offsetParent !== null)).toHaveLength(1);
  },
};

/** A venue booking forwarded by email: grey bar, external mark, no action. */
export const ForwardedBooking: Story = {
  parameters: { relay: { mocks: { Query: { events: events("evt-ginza-booking") } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.hover(await canvas.findByText("Court booking · PickleOne Ginza, Court 2"));
    await expect(canvas.queryByRole("button", { name: "Join" })).toBeNull();
  },
};

/** Canceled: struck through; clicking shows its details. */
export const Canceled: Story = {
  parameters: { relay: { mocks: { Query: { events: events("evt-lunch-rally") } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByText("Friday Lunch Rally"));
    const venue = await canvas.findByText("Toyosu Riverside Courts");
    await waitFor(() => expect(venue).toBeVisible());
  },
};

/** Signed out: no status, and Join leads to login. */
export const SignedOut: Story = {
  parameters: {
    relay: { mocks: { Query: { viewer: null, events: events("evt-morning-open", "evt-thu-doubles") } } },
  },
};

/** Dimmed, as the lists show events at other venues while one is picked. */
export const Dimmed: Story = {
  args: { dimmed: true },
  parameters: { relay: { mocks: { Query: { events: events("evt-morning-open", "evt-thu-doubles") } } } },
};
