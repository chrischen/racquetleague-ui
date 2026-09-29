import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { make as AvatarRsvpUserStory } from "./AvatarRsvpUserStory.gen";

// The avatar-and-name entry on the classic event page's RSVP lists (drawn by
// EventRsvpUser for EventRsvp). The ring is the player's conservative rating
// (mu - 3 sigma) as a percentage of the event's strongest player's mu, and the
// lighter arc after it is 3 sigma on the same scale, their uncertainty. With
// no rating given the ring is full. The optional text after the name is the
// rating on the DUPR scale or a waitlist position.
const meta = {
  title: "Organisms/AvatarRsvpUser",
  component: AvatarRsvpUserStory,
  args: { name: "Kenji W.", withPicture: true, highlight: false, secondaryText: "3.96", ratingPercent: 70, sigmaPercent: 25 },
  argTypes: {
    ratingPercent: { control: { type: "range", min: 0, max: 100 } },
    sigmaPercent: { control: { type: "range", min: 0, max: 100 } },
  },
} satisfies Meta<typeof AvatarRsvpUserStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** An established player: a long ring, a short uncertainty arc. */
export const Rated: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Kenji W.")).toBeVisible();
    await expect(canvas.getByText("3.96")).toBeVisible();
  },
};

/** A newcomer: little rating, a wide uncertainty arc. */
export const Provisional: Story = {
  args: { name: "あおい", secondaryText: "3.47", ratingPercent: 8, sigmaPercent: 62 },
};

/** The signed-in player's own entry. */
export const Highlighted: Story = {
  args: { highlight: true },
};

/** On the waitlist the position replaces the rating text. */
export const WaitlistPosition: Story = {
  args: { name: "Lucas", secondaryText: "#2", ratingPercent: 40, sigmaPercent: 55 },
};

/** No rating passed (badminton, or no rating yet): a full ring and no text. */
export const NoRating: Story = {
  args: { name: "Yuki", secondaryText: undefined, ratingPercent: undefined, sigmaPercent: undefined },
};

/** No picture: the name's initial, at the avatar's size, inside the ring. */
export const NoPicture: Story = {
  args: { name: "Tom", withPicture: false, secondaryText: "3.27" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("img", { name: "Tom" })).toHaveTextContent("T");
  },
};

/** A long LINE name. */
export const LongName: Story = {
  args: { name: "Alexandra Montgomery-Fujiwara 🏓", secondaryText: "3.85" },
};
