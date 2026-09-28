import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { make as FooterStory } from "./FooterStory.gen";

// The one-line copyright footer under DefaultLayout and LeagueLayout. It has
// no props or data, so there is one state.
const meta = {
  title: "Organisms/Footer",
  component: FooterStory,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof FooterStory>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("copyright the racquet league contributors")).toBeVisible();
  },
};
