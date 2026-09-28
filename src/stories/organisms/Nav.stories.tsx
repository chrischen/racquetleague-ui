import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { make as NavStory, query } from "./NavStory.gen";

// The legacy text header from DefaultLayout: site name, the viewer's display
// name with a logout link (or the LINE login button when signed out), the
// language switch and "Add Event". `new-user` is the dev scenario
// (dev/scenarios/new-user.mjs); stories add only what differs.
const meta = {
  title: "Organisms/Nav",
  component: NavStory,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof NavStory>;

export default meta;
type Story = StoryObj<typeof meta>;

export const SignedIn: Story = {
  parameters: {
    relay: { query, scenario: "new-user", mocks: { User: { lineUsername: "Kenji" } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Kenji")).toBeVisible();
    await expect(canvas.getByRole("link", { name: "(logout)" })).toHaveAttribute("href", "/signout");
    await expect(canvas.getByRole("link", { name: "Add Event" })).toBeVisible();
  },
};

/** No session: the LINE login button takes the display name's place. */
export const SignedOut: Story = {
  parameters: { relay: { query, scenario: "signed-out" } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByAltText("login with Line")).toBeVisible();
    await expect(canvas.queryByText("(logout)")).toBeNull();
  },
};

/**
 * Signed in with no display name yet (the new-user scenario): the name slot
 * is empty and only the logout link shows.
 */
export const NoDisplayName: Story = {
  parameters: { relay: { query, scenario: "new-user" } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("link", { name: "(logout)" })).toBeVisible();
  },
};
