import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { connection, rsvps } from "./StoryFixturesEvent.gen";
import { make as EventMatchRsvpUserStory, query } from "./EventMatchRsvpUserStory.gen";

// A player's card in the in-person match tools (MatchesView's queue,
// SubmitMatch): picture with the player's session number, a large name (pink
// for women), and a tint for their state: white available, green queued for
// the next match, yellow with a clock on a break, faded while playing. The
// compact size is SubmitMatch's. The wrapper lays out every player on the
// event as MatchesView's grid does.
const meta = {
  title: "Organisms/EventMatchRsvpUser",
  component: EventMatchRsvpUserStory,
  args: { status: "available", compact: false, showPlayCount: false },
  argTypes: { status: { control: "inline-radio", options: ["available", "queued", "break", "playing", "mixed"] } },
  parameters: {
    layout: "padded",
    relay: { query, mocks: { Query: { event: {} }, Event: { rsvps: connection(rsvps(6)) } } },
  },
} satisfies Meta<typeof EventMatchRsvpUserStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Everyone available. */
export const Available: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Yuki")).toBeVisible();
  },
};

/** Queued for the next match. */
export const Queued: Story = { args: { status: "queued" } };

/** Sitting out a round. */
export const OnBreak: Story = { args: { status: "break" } };

/** On court. */
export const Playing: Story = { args: { status: "playing" } };

/** Mid-session: a mix of states with games-played counts, twelve players. */
export const SessionQueue: Story = {
  args: { status: "mixed", showPlayCount: true },
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(12)) } } } },
};

/** SubmitMatch's compact cards. */
export const Compact: Story = {
  args: { compact: true },
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(4)) } } } },
};
