import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, within } from "storybook/test";
import { portrait } from "./StoryFixturesProfile.gen";
import { make as NavViewerStory, query } from "./NavViewerStory.gen";

// The account menu at the right of the top bar (PkuruLayout, LeagueLayout):
// display name and avatar, opening a menu with Clubs and logout. Without a
// viewer the bar shows the LINE login button instead, as PkuruLayout does.
const meta = {
  title: "Organisms/NavViewer",
  component: NavViewerStory,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      scenario: "new-user",
      mocks: { User: { lineUsername: "Aki", picture: portrait(1) } },
    },
  },
} satisfies Meta<typeof NavViewerStory>;

export default meta;
type Story = StoryObj<typeof meta>;

export const SignedIn: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Aki")).toBeVisible();
  },
};

/** The dropdown opened: Clubs, a divider, and the logout link. */
export const MenuOpen: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByText("Aki"));
    const body = within(canvasElement.ownerDocument.body);
    await expect(await body.findByRole("menuitem", { name: "Clubs" })).toBeVisible();
    await expect(body.getByText("(logout)")).toBeVisible();
  },
};

/** No picture on the profile: the avatar falls back to its placeholder. */
export const NoPicture: Story = {
  parameters: { relay: { mocks: { User: { lineUsername: "Takumi Suzuki", picture: null } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Takumi Suzuki")).toBeVisible();
  },
};

/** No session: the LINE login button. */
export const SignedOut: Story = {
  parameters: { relay: { query, scenario: "signed-out", mocks: {} } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByAltText("login with Line")).toBeVisible();
  },
};
