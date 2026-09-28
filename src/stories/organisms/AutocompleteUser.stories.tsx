import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { roster } from "./StoryFixturesProfile.gen";
import { make as AutocompleteUserStory, query, variables } from "./AutocompleteUserStory.gen";

// The member search used to add a player to an event's RSVPs. It loads the
// club's members with its own query and filters them by full name or display
// name as you type; picking one reports its user id. With `onClose` (the
// inline "add player" row) there is a close button, and Escape or blur closes.
// The query's variables come from the wrapper so they match what it passes.
const members = roster.slice(0, 16).map((p) => ({
  node: {
    id: `membership-${p.id}`,
    user: {
      id: p.id,
      // One member never filled in a full name: the row shows the display
      // name and a "?" for initials.
      fullName: p.id === "user-mai" ? null : p.fullName,
      lineUsername: p.lineUsername,
      picture: p.picture,
    },
  },
}));

const meta = {
  title: "Organisms/AutocompleteUser",
  component: AutocompleteUserStory,
  parameters: {
    relay: { query, variables, mocks: { Query: { clubMembers: { edges: members } } } },
  },
  args: { onSelected: fn(), onClose: fn() },
} satisfies Meta<typeof AutocompleteUserStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Nothing typed yet: just the focused search field. */
export const Idle: Story = {};

/** Matches on full name and display name alike. */
export const Searching: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(canvas.getByPlaceholderText("Search players..."), "ka");
    await expect(await canvas.findByText("Aki Tanaka")).toBeVisible();
    await expect(canvas.getByText("Haruka Ito")).toBeVisible();
  },
};

/** A one-letter search lists most of the club; the dropdown scrolls. */
export const ManyMatches: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(canvas.getByPlaceholderText("Search players..."), "a");
    await expect(await canvas.findByText("Mai")).toBeVisible();
  },
};

export const NoMatches: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(canvas.getByPlaceholderText("Search players..."), "zz");
    await expect(await canvas.findByText("No players found")).toBeVisible();
  },
};

/** The inline variant with a close button and a custom placeholder; picking a player reports its id. */
export const WithClose: Story = {
  args: { withClose: true, placeholder: "Add a player to this event..." },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.type(canvas.getByPlaceholderText("Add a player to this event..."), "kenji");
    await userEvent.click(await canvas.findByText("Kenji Watanabe"));
    await expect(args.onSelected).toHaveBeenCalledWith("user-kenji");
    await expect(args.onClose).toHaveBeenCalled();
  },
};
