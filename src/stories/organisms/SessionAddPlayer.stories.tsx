import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as SessionAddPlayerStory } from "./SessionAddPlayerStory.gen";

// AiTetsu's "Add Player" pane: a QR code to the event page (players with an
// account join there) beside a name field that adds a walk-in by hand. The
// field clears after each add; an empty name is refused.
const meta = {
  title: "Organisms/SessionAddPlayer",
  component: SessionAddPlayerStory,
  parameters: { layout: "padded" },
  args: { eventId: "evt-story-match", onPlayerAdd: fn() },
} satisfies Meta<typeof SessionAddPlayerStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The QR code and an empty name field. */
export const Default: Story = {};

/** Add a walk-in: the name goes to the session and the field clears for the next one. */
export const AddWalkIn: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    const name = await canvas.findByRole("textbox");
    await userEvent.type(name, "Kaito Mori");
    await userEvent.click(canvas.getByRole("button", { name: "Add Guest Player" }));
    await waitFor(() => expect(args.onPlayerAdd).toHaveBeenCalledWith("Kaito Mori"));
    await waitFor(() => expect(name).toHaveValue(""));
  },
};

/** An empty name is not added. */
export const EmptyNameRefused: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Add Guest Player" }));
    // Validation is async; give it a moment before asserting nothing happened.
    await new Promise((resolve) => setTimeout(resolve, 200));
    await expect(args.onPlayerAdd).not.toHaveBeenCalled();
  },
};
