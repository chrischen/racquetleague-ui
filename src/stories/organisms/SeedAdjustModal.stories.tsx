import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as SeedAdjustModalStory, query } from "./SeedAdjustModalStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The seeding modal the check-in panel opens: players strongest first, each
// with a drag handle, avatar, skill bar (relative to tonight's range) and mu.
// Dropping a player between two others sets their mu halfway between. At a
// club event a switch chooses the rating pool players start from; the wrapper
// swaps ratings when it flips, as EventManager does.
const meta = {
  title: "Organisms/SeedAdjustModal",
  component: SeedAdjustModalStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: {
      control: "select",
      options: ["checkedIn", "withGuests", "walkInsOnly", "clubEvent", "clubRatings", "loadingClubRatings"],
    },
  },
  args: { state: "checkedIn", onSave: fn(), onClose: fn(), onUseClubRatings: fn() },
} satisfies Meta<typeof SeedAdjustModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Tonight's 16 checked-in players. Saving hands back every id with its mu, in order. */
export const CheckedIn: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Adjust Player Seeds")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Save Seed Adjustments" }));
    await expect(args.onSave).toHaveBeenCalledWith(
      expect.arrayContaining([
        ["user-kenji", 32.4],
        ["user-rina", 18.7],
      ]),
    );
  },
};

/** The whole RSVP list plus two walk-ins at the default 25.0: long names and initials. */
export const WithGuests: Story = { args: { state: "withGuests" } };

/** Only walk-ins, all at the default rating: every skill bar sits at the midpoint. */
export const WalkInsOnly: Story = { args: { state: "walkInsOnly" } };

/** A club event on global ratings: the switch offers the club's own ratings. */
export const ClubEvent: Story = {
  args: { state: "clubEvent" },
  play: async ({ canvasElement }) => {
    await expect(
      await within(canvasElement).findByText("Players start on their global rating across all clubs."),
    ).toBeVisible();
  },
};

/** On club ratings: the order shifts, and players with no club rating start at 25.0. */
export const ClubRatings: Story = {
  args: { state: "clubRatings" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText(/rating they earned inside this club/)).toBeVisible();
    // Yuki leads on club ratings.
    await expect(canvas.getAllByText(/^\d+\.\d$/)[0]).toHaveTextContent("31.5");
  },
};

/** Switching back to global ratings re-seeds the list. */
export const SwitchToGlobal: Story = {
  args: { state: "clubRatings" },
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Global ratings" }));
    await expect(args.onUseClubRatings).toHaveBeenCalledWith(false);
    await waitFor(() => expect(canvas.getAllByText(/^\d+\.\d$/)[0]).toHaveTextContent("32.4"));
  },
};

/** Club ratings still loading: a spinner on the club button, both buttons disabled. */
export const LoadingClubRatings: Story = {
  args: { state: "loadingClubRatings" },
  play: async ({ canvasElement }) => {
    await expect(await within(canvasElement).findByRole("button", { name: "Global ratings" })).toBeDisabled();
  },
};
