import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { make as RsvpUserStory } from "./RsvpUserStory.gen";

// A player row on the check-in list (SelectPlayersList): picture, name and a
// bar for the player's conservative rating as a share of the strongest
// player's, with a softer segment for its uncertainty when that is known.
// Guests added by name have no picture; registered players come through
// EventRsvpUserBar.
const meta = {
  title: "Organisms/RsvpUser",
  component: RsvpUserStory,
  args: { name: "Emily", withPicture: true, highlight: false, linked: false, ratingPercent: 62, sigmaPercent: 20 },
  argTypes: {
    ratingPercent: { control: { type: "range", min: 0, max: 100 } },
    sigmaPercent: { control: { type: "range", min: 0, max: 100 } },
  },
} satisfies Meta<typeof RsvpUserStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Rating bar with its uncertainty. */
export const WithUncertainty: Story = {};

/** Only the rating: a single bar. */
export const RatingOnly: Story = {
  args: { sigmaPercent: undefined, ratingPercent: 45 },
};

/** A guest added by name: no picture, no rating. */
export const Guest: Story = {
  args: { name: "Guest: Hiroshi", withPicture: false, ratingPercent: undefined, sigmaPercent: undefined },
};

/** Highlighted, with a note after the name. */
export const Highlighted: Story = {
  args: { highlight: true, secondaryText: "checked in" },
};

/** The name links to the player's profile. */
export const Linked: Story = {
  args: { linked: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("link")).toHaveAttribute("href", expect.stringContaining("/league/pickleball/p/user-emily"));
  },
};

/** A long name. */
export const LongName: Story = {
  args: { name: "Alexandra Montgomery-Fujiwara 🏓", secondaryText: "late" },
};
