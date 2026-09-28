import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { avatar } from "./StoryFixturesEvent.gen";
import { make as EventRsvpUserBarStory, query } from "./EventRsvpUserBarStory.gen";

// A registered player's row on the check-in list (SelectPlayersList): reads the
// LINE name and picture and draws them with RsvpUser, a row with a rating bar.
const meta = {
  title: "Organisms/EventRsvpUserBar",
  component: EventRsvpUserBarStory,
  args: { highlight: false, ratingPercent: 62, sigmaPercent: 20 },
  argTypes: {
    ratingPercent: { control: { type: "range", min: 0, max: 100 } },
    sigmaPercent: { control: { type: "range", min: 0, max: 100 } },
  },
  parameters: {
    relay: { query, mocks: { Query: { user: {} }, User: { lineUsername: "Emily", picture: avatar("Emily", 2) } } },
  },
} satisfies Meta<typeof EventRsvpUserBarStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** With a rating bar and its uncertainty. */
export const Rated: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Emily")).toBeVisible();
  },
};

/** As SelectPlayersList renders it: name and picture only. */
export const NameOnly: Story = {
  args: { ratingPercent: undefined, sigmaPercent: undefined },
};

/** Highlighted, with a note after the name. */
export const Highlighted: Story = {
  args: { highlight: true, secondaryText: "3.85" },
};

/** A player without a picture or LINE name on file. */
export const MissingNameAndPicture: Story = {
  parameters: { relay: { mocks: { User: { lineUsername: null, picture: null } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("[Line username missing]")).toBeVisible();
  },
};
