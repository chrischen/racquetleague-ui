import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { discoverEvents, eventsConnection, shiftClock } from "./StoryFixturesDiscovery.gen";
import { make as CalendarStory, query } from "./CalendarStory.gen";

// The month calendar (react-calendar) on the older events pages: it opens on
// the current month, highlights today, puts a dot under each day with an
// event, and reports the day clicked. The clock is Wednesday 14 October 2026
// in Tokyo.
const meta = {
  title: "Organisms/Calendar",
  component: CalendarStory,
  beforeEach: shiftClock,
  parameters: {
    relay: { query, mocks: { Query: { events: eventsConnection(discoverEvents, false) } } },
  },
  args: { onDateSelected: fn() },
} satisfies Meta<typeof CalendarStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** October with events on the 14th to the 18th and the 20th. Clicking a
 * day reports it. */
export const WithEvents: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("October 2026")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: /October 17, 2026/ }));
    await waitFor(() => expect(args.onDateSelected).toHaveBeenCalled());
  },
};

/** No events: only today is marked. */
export const NoEvents: Story = {
  parameters: { relay: { query, mocks: { Query: { events: eventsConnection([], false) } } } },
};
