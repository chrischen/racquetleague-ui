import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as PlayerSettingsModalStory, query } from "./PlayerSettingsModalStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The dialog behind the gear on a check-in tile: rename a player and set the
// gender used for mixed draws. A walk-in (no account) can also be deleted,
// which moves "Delete Guest" to the left of the footer.
const meta = {
  title: "Organisms/PlayerSettingsModal",
  component: PlayerSettingsModalStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: { control: "inline-radio", options: ["registered", "guest", "longName"] },
  },
  args: { state: "registered", onSave: fn(), onClose: fn(), onDelete: fn() },
} satisfies Meta<typeof PlayerSettingsModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A player with an account (Yuki Sato, female): no delete. */
export const RegisteredPlayer: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByDisplayValue("Yuki Sato")).toBeVisible();
    await expect(canvas.getByText("#user-yuki")).toBeVisible();
    await expect(canvas.queryByText("Delete Guest")).toBeNull();
  },
};

/** Rename and switch gender, then save. */
export const EditAndSave: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    const name = await canvas.findByDisplayValue("Yuki Sato");
    await userEvent.clear(name);
    await userEvent.type(name, "Yuki S.");
    await userEvent.click(canvas.getByRole("button", { name: "Male" }));
    await userEvent.click(canvas.getByRole("button", { name: "Save Changes" }));
    await expect(args.onSave).toHaveBeenCalledWith("Yuki S.", "male");
    await expect(args.onClose).toHaveBeenCalled();
  },
};

/** A walk-in added at the desk: "Delete Guest" on the left. */
export const Guest: Story = {
  args: { state: "guest" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByDisplayValue("Kaito Mori")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Delete Guest" })).toBeVisible();
  },
};

/** Deleting the walk-in also closes the dialog. */
export const DeleteGuest: Story = {
  args: { state: "guest" },
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Delete Guest" }));
    await expect(args.onDelete).toHaveBeenCalled();
    await expect(args.onClose).toHaveBeenCalled();
  },
};

/** A long name in the field and the id line. */
export const LongName: Story = { args: { state: "longName" } };
