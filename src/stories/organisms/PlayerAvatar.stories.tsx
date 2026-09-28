import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { portrait } from "./StoryFixturesProfile.gen";
import { make as PlayerAvatarStory, query } from "./PlayerAvatarStory.gen";

// A player's avatar in the round and check-in views, ringed by a progress arc
// for their skill (0-100, relative to the group) coloured red, amber, blue or
// green by band. Without a user (guests) it shows the name's first letter.
const meta = {
  title: "Organisms/PlayerAvatar",
  component: PlayerAvatarStory,
  // Nullable root fields default to null in the mock engine, so the user(id:)
  // the wrapper asks for has to be given (it takes the id from the argument).
  parameters: { relay: { query, mocks: { Query: { user: {} }, User: { picture: portrait(0) } } } },
  argTypes: { state: { control: "inline-radio", options: ["sizes", "initials", "skillBands"] } },
  args: { state: "sizes", name: "Kenji Watanabe" },
} satisfies Meta<typeof PlayerAvatarStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** small, medium, large, and a custom size given as a className. */
export const WithPicture: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByAltText("Kenji Watanabe")).toHaveLength(4);
  },
};

/** No user record (a guest): the first letter of the name. */
export const Initials: Story = {
  args: { state: "initials", name: "Haruka Ito" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByText("H")).toHaveLength(4);
  },
};

/** The four ring colours: under 25, 25-50, 50-75, 75 and over. */
export const SkillBands: Story = {
  args: { state: "skillBands" },
};
