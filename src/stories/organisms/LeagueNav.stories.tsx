import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, within } from "storybook/test";
import { portrait } from "./StoryFixturesProfile.gen";
import { make as LeagueNavStory, query } from "./LeagueNavStory.gen";

// The league section's tab bar (LeagueLayout): Rankings, Find Games and About
// for the activity in the URL, the language switch, notifications and the
// account menu. Signed out, the account menu is the LINE login button. The
// phone layout (hamburger and panel) only appears below 640px wide. Every
// link gets the locale prefix (/en/...), so the stories sit under /en too.
const meta = {
  title: "Organisms/LeagueNav",
  component: LeagueNavStory,
  parameters: {
    layout: "fullscreen",
    router: { path: ":lang/league/:activitySlug", url: "/en/league/pickleball/" },
    relay: {
      query,
      scenario: "new-user",
      mocks: { User: { lineUsername: "Kenji", picture: portrait(0) } },
    },
  },
} satisfies Meta<typeof LeagueNavStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** On the pickleball league's rankings: that tab is underlined. */
export const SignedIn: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const rankings = await canvas.findByRole("link", { name: "Rankings" });
    await expect(rankings).toHaveAttribute("href", "/en/league/pickleball/");
    await expect(rankings.className).toContain("border-leaguePrimary");
    await expect(canvas.getByRole("link", { name: "Find Games" })).toHaveAttribute("href", "/en/league/pickleball/games");
    await expect(canvas.getByAltText("Profile picture")).toBeVisible();
  },
};

/** The account menu open: the profile and logout links, locale-prefixed. */
export const AccountMenu: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: /Open user menu/ }));
    const profile = await canvas.findByRole("menuitem", { name: "Your Profile" });
    await expect(profile.getAttribute("href")).toMatch(/^\/en\/league\/p\//);
    await expect(canvas.getByRole("menuitem", { name: "Logout" })).toHaveAttribute("href", "/en/signout");
  },
};

/** Signed in without a profile picture: the menu button shows the initial. */
export const SignedInNoPicture: Story = {
  parameters: { relay: { mocks: { User: { picture: null } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const button = await canvas.findByRole("button", { name: "Open user menu" });
    await expect(canvas.queryByAltText("Profile picture")).toBeNull();
    await expect(within(button).getByText("K")).toBeVisible();
  },
};

/** No session, on the site root: tabs point at /en/, /en/games and /en/about. */
export const SignedOut: Story = {
  parameters: {
    router: { path: ":lang", url: "/en" },
    relay: { query, scenario: "signed-out", mocks: {} },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByAltText("login with Line")).toBeVisible();
    await expect(canvas.getByRole("link", { name: "About" })).toHaveAttribute("href", "/en/about");
  },
};
