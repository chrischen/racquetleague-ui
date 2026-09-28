import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { connection, rsvps } from "./StoryFixturesEvent.gen";
import { eventId } from "./StoryFixturesEventPage.gen";
import { make as RoundRobinDrawsPreviewStory, query } from "./RoundRobinDrawsPreviewStory.gen";

// The Round Robin preview card on pickleball and badminton event pages: the
// first two rounds of doubles the draws tool would generate from the going
// players (strongest first, waitlist excluded), on a suggested number of
// courts the viewer can change, faded out under a link to the full draws.
// Draws are generated in the browser, so pairings vary between loads. Hidden
// with fewer than four players. Phone widths show only the first round's
// first two courts.
const meta = {
  title: "Organisms/RoundRobinDrawsPreview",
  component: RoundRobinDrawsPreviewStory,
  args: { activitySlug: "pickleball" },
  argTypes: { activitySlug: { control: "inline-radio", options: ["pickleball", "badminton"] } },
  parameters: {
    relay: {
      query,
      variables: { eventId },
      mocks: {
        Query: { event: {} },
        Event: {
          tags: [],
          maxRsvps: 12,
          startDate: "2026-10-15T10:00:00.000Z",
          activity: { id: "act-pickleball", slug: "pickleball" },
          rsvps: connection(rsvps(8)),
        },
      },
    },
  },
} satisfies Meta<typeof RoundRobinDrawsPreviewStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Eight going: two courts per round. */
export const EightPlayers: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Round Robin Draws")).toBeVisible();
    await expect(canvas.getByRole("link", { name: /View Full Draws/ })).toHaveAttribute(
      "href",
      expect.stringContaining(`/league/events/${eventId}/pickleball/manager`),
    );
  },
};

/** A full session of 12 (two more on the waitlist are left out): three courts. */
export const FullSession: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(14)) } } } },
};

/** Down to one court: the minus button redraws the rounds for a single court. */
export const OneCourt: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await canvas.findByText("Round Robin Draws");
    // The two icon buttons beside "Courts:" are minus, then plus.
    const [minus] = canvas.getAllByRole("button");
    await userEvent.click(minus);
    await waitFor(() => expect(minus).toBeDisabled());
  },
};

/** A badminton event links to the badminton draws tool. */
export const Badminton: Story = {
  args: { activitySlug: "badminton" },
  parameters: {
    relay: { mocks: { Event: { activity: { id: "act-badminton", slug: "badminton" }, rsvps: connection(rsvps(6)) } } },
  },
};
