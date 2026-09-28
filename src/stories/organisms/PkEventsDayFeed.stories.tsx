import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import {
  courtDays,
  discoverEvents,
  eventsConnection,
  playerAvailability,
  shiftClock,
  viewerAvailability,
  viewerEvents,
  viewerUser,
} from "./StoryFixturesDiscovery.gen";
import { make as PkEventsDayFeedStory, query } from "./PkEventsDayFeedStory.gen";

// One day of Discover with inline courts: the day's event rows with the open
// courts interleaved by start time. Courts that touch or overlap collapse into
// one cyan group ("3 courts available · 3 locations · ¥1800–¥5500") that
// expands into one row per venue opening. The feed never shows the day header
// or availability row; PkEventsList draws those above it. Forwarded bookings
// start hidden in the list, so they are left out here.
const VIEWER = signedInViewer({
  user: viewerUser,
  profile: viewerUser,
  availability: viewerAvailability,
  events: eventsConnection(viewerEvents, false),
});

const meta = {
  title: "Organisms/PkEventsDayFeed",
  component: PkEventsDayFeedStory,
  beforeEach: shiftClock,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: {
          viewer: {},
          events: eventsConnection(
            discoverEvents.filter((e) => !e.shadow),
            false,
          ),
          availabilityUsersForDateRange: playerAvailability,
          locationsAvailability: courtDays,
        },
        Viewer: VIEWER,
      },
    },
  },
  argTypes: { localDate: { control: "select", options: ["2026-10-14", "2026-10-16", "2026-10-17", "2026-10-19"] } },
  args: { localDate: "2026-10-14", onRefetchNeeded: fn() },
} satisfies Meta<typeof PkEventsDayFeedStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Wednesday: early courts at 7, an event at 10, courts from 1 to 10 PM at
 * three venues, and the evening doubles. */
export const Today: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Morning Open Play")).toBeVisible();
    await expect(canvas.getByText("3 courts available")).toBeVisible();
  },
};

/** The afternoon group opened: one row per venue opening, the viewer's own
 * 6–10 PM shown on the ones it overlaps. */
export const CourtsExpanded: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByText("3 courts available"));
    const minato = await canvas.findByText("Minato Sports Center");
    await waitFor(() => expect(minato).toBeVisible());
  },
};

/** Saturday: a morning group at two venues, two events, and afternoon courts
 * that start with the clinic (the event sorts first). */
export const Weekend: Story = {
  args: { localDate: "2026-10-17" },
};

/** Friday: no courts open, so only events (one of them canceled). */
export const EventsOnly: Story = {
  args: { localDate: "2026-10-16" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Friday Rated Session")).toBeVisible();
    await expect(canvas.queryByText(/courts? available/)).toBeNull();
  },
};

/** Next Monday: no events yet, one venue open in the evening. */
export const CourtsOnly: Story = {
  args: { localDate: "2026-10-19" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("2 courts available")).toBeVisible();
  },
};
