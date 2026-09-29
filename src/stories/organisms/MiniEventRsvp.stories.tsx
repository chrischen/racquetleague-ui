import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { connection, rsvps } from "./StoryFixturesEvent.gen";
import { make as MiniEventRsvpStory, query } from "./MiniEventRsvpStory.gen";

// A player as a small 36px avatar whose ring is their pkuru rating (mu) as a
// share of the event's strongest. RSVPSection's collapsed mobile bar stacks
// the first three and counts the rest; a player without a rating is drawn at
// the default mu of 25.
const meta = {
  title: "Organisms/MiniEventRsvp",
  component: MiniEventRsvpStory,
  args: { layout: "row" },
  argTypes: { layout: { control: "inline-radio", options: ["row", "mobileBar"] } },
  parameters: {
    relay: { query, mocks: { Query: { event: {} }, Event: { rsvps: connection(rsvps(8)) } } },
  },
} satisfies Meta<typeof MiniEventRsvpStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Eight players side by side, strongest first. */
export const Row: Story = {};

/** The collapsed mobile RSVP bar: three avatars overlapped, then "+5". */
export const MobileBar: Story = {
  args: { layout: "mobileBar" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("+5")).toBeVisible();
  },
};

/** Players with no pkuru rating yet (Rin, Tom) sit at the default mu. */
export const UnratedPlayers: Story = {
  parameters: {
    relay: { mocks: { Event: { rsvps: connection(rsvps(12).filter((_, i) => i === 0 || i === 6 || i === 10 || i === 11)) } } },
  },
};

/** A player with no picture: the initial of their name, not an empty image. */
export const NoPicture: Story = {
  parameters: {
    relay: { mocks: { Event: { rsvps: connection(rsvps(11).filter((_, i) => i >= 8)) } } },
  },
  play: async ({ canvasElement }) => {
    await expect(canvasElement.querySelector('img[src=""], img:not([src])')).toBeNull();
  },
};
