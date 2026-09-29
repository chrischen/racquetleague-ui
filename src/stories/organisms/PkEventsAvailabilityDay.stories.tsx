import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import {
  courtDays,
  eventsConnection,
  hourlyCounts,
  playerAvailability,
  shiftClock,
  viewerAvailability,
  viewerEvents,
  viewerUser,
} from "./StoryFixturesDiscovery.gen";
import { make as PkEventsAvailabilityDayStory, query } from "./PkEventsAvailabilityDayStory.gen";

// The availability row under each day's header in the events lists. The
// header's trigger ("Play today"; "Add to <day>" on a club's schedule) and the
// summary line below it open the editor: presets, a time picker over the
// players' demand heatmap with the viewer's events and open courts, the
// courts that cover the drafted window, who else is free, then Host event /
// Mark available. The summary shows the viewer's saved windows (or "Set your
// time") and counts the day's events, players and courts. Signed out, both
// lead to login.
const VIEWER = signedInViewer({
  user: viewerUser,
  profile: viewerUser,
  availability: viewerAvailability,
  events: eventsConnection(viewerEvents, false),
});

const meta = {
  title: "Organisms/PkEventsAvailabilityDay",
  component: PkEventsAvailabilityDayStory,
  beforeEach: shiftClock,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: {
          viewer: {},
          availabilityUsersForDateRange: playerAvailability,
          locationsAvailability: courtDays,
          // The editor's heatmap, fetched when it opens.
          availabilityHourlyCounts: hourlyCounts,
        },
        Viewer: VIEWER,
      },
    },
  },
  argTypes: { host: { control: "inline-radio", options: ["discover", "club", "locationClub"] } },
  args: { localDate: "2026-10-14", label: "Today", eventCount: 3, host: "discover", onCreateEvent: fn(), onRefetchNeeded: fn() },
} satisfies Meta<typeof PkEventsAvailabilityDayStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The viewer saved 6–10 PM today: their window, their one event, and the
 * five players whose windows overlap it. */
export const SavedWindow: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("5 players")).toBeVisible();
  },
};

/** Nothing saved for tomorrow: "Set your time" with the day's event, players
 * and courts. */
export const NotSetYet: Story = {
  args: { localDate: "2026-10-15", label: "Tomorrow", eventCount: 2 },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Set your time")).toBeVisible();
    await expect(canvas.getByText("2 courts")).toBeVisible();
  },
};

/** The editor, opened from the header: presets, the picker over the heatmap,
 * the courts covering the drafted evening, and who else is free. */
export const Editing: Story = {
  args: { localDate: "2026-10-15", label: "Tomorrow", eventCount: 2 },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: /Play today/ }));
    const title = await canvas.findByText("When can you play tomorrow?");
    await waitFor(() => expect(title).toBeVisible());
    await expect(await canvas.findByRole("img", { name: "Player availability heatmap" })).toBeInTheDocument();
    await expect(canvas.getByRole("button", { name: /Mark available/ })).toBeEnabled();
  },
};

/** A day with nothing on it: just the header and its trigger. */
export const QuietDay: Story = {
  args: { localDate: "2026-10-27", label: "Next Tuesday", eventCount: 0 },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("button", { name: /Play today/ })).toBeVisible();
    await expect(canvas.queryByText("Set your time")).toBeNull();
  },
};

/** Signed out: everyone's counts, and every button leads to login. */
export const SignedOut: Story = {
  parameters: { relay: { mocks: { Query: { viewer: null } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("6 players")).toBeVisible();
  },
};

/** A club's schedule, editor open: the trigger adds to the named day, the
 * players are the club's members, and "Host event" opens the create form for
 * the window. */
export const ClubSchedule: Story = {
  args: { localDate: "2026-10-17", label: "Saturday", eventCount: 2, host: "club" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: /Add to Saturday/ }));
    // The saved 9 AM–1 PM is drafted: one window, so it can be hosted.
    const host = await canvas.findByRole("button", { name: /Host event/ });
    await waitFor(() => expect(host).toBeEnabled());
  },
};

/** A location club hosts on the spot, so its editor also picks the level. */
export const LocationClubLevels: Story = {
  args: { localDate: "2026-10-17", label: "Saturday", eventCount: 1, host: "locationClub" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: /Add to Saturday/ }));
    const legend = await canvas.findByText("Skill level");
    await waitFor(() => expect(legend).toBeVisible());
  },
};
