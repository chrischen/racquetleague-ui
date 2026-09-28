import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { avatar } from "./StoryFixturesEvent.gen";
import { make as EventRsvpUserStory, query } from "./EventRsvpUserStory.gen";

// A registered player on the classic event page's RSVP lists: reads the LINE
// name and picture and draws them with AvatarRsvpUser. EventRsvp passes the
// rating ring (percentages of the event's strongest player) and the text after
// the name (the DUPR-scale rating on pickleball events, or a waitlist
// position).
const meta = {
  title: "Organisms/EventRsvpUser",
  component: EventRsvpUserStory,
  args: { highlight: false, secondaryText: "3.96", ratingPercent: 70, sigmaPercent: 25 },
  argTypes: {
    ratingPercent: { control: { type: "range", min: 0, max: 100 } },
    sigmaPercent: { control: { type: "range", min: 0, max: 100 } },
  },
  parameters: {
    relay: { query, mocks: { Query: { user: {} }, User: { lineUsername: "Kenji W.", picture: avatar("Kenji W.", 1) } } },
  },
} satisfies Meta<typeof EventRsvpUserStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** On a pickleball event's going list. */
export const Default: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Kenji W.")).toBeVisible();
  },
};

/** The signed-in player's own entry. */
export const Highlighted: Story = {
  args: { highlight: true },
};

/** On the waitlist. */
export const Waitlisted: Story = {
  args: { secondaryText: "#3" },
};

/** A player without a LINE name on file. */
export const MissingName: Story = {
  args: { secondaryText: undefined },
  parameters: { relay: { mocks: { User: { lineUsername: null } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("[Line username missing]")).toBeVisible();
  },
};

/** A player without a picture. */
export const NoPicture: Story = {
  parameters: { relay: { mocks: { User: { lineUsername: "Tom", picture: null } } } },
  args: { secondaryText: "3.27", ratingPercent: 0, sigmaPercent: 70 },
};
