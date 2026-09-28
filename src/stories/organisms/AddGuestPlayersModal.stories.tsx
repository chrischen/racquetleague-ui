import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as AddGuestPlayersModalStory } from "./AddGuestPlayersModalStory.gen";

// The event manager's walk-in dialog: names one per line (blank lines and
// stray spaces are dropped), a numbered preview, and a button that counts
// them. Adding is disabled until there is at least one name.
const meta = {
  title: "Organisms/AddGuestPlayersModal",
  component: AddGuestPlayersModalStory,
  parameters: { layout: "fullscreen" },
  args: { onAdd: fn(), onClose: fn() },
} satisfies Meta<typeof AddGuestPlayersModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const typeNames = async (canvasElement: HTMLElement, names: string) => {
  const canvas = within(canvasElement);
  const box = await canvas.findByRole("textbox");
  await userEvent.click(box);
  await userEvent.paste(names);
  return canvas;
};

/** Nothing typed: placeholder names, and Add is disabled. */
export const Empty: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("button", { name: /Add .*Guest/ })).toBeDisabled();
  },
};

/** One walk-in: singular preview and button. */
export const OneGuest: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await typeNames(canvasElement, "Kaito Mori");
    await expect(await canvas.findByText("Preview (1 guest)")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Add 1 Guest" })).toBeEnabled();
  },
};

/** Three names with a blank line and stray spaces: the preview shows the three, trimmed. */
export const SeveralGuests: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = await typeNames(canvasElement, "Kaito Mori\n  Lisa Brown  \n\n林 亮太\n");
    await expect(await canvas.findByText("Preview (3 guests)")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Add 3 Guests" }));
    await expect(args.onAdd).toHaveBeenCalledWith(["Kaito Mori", "Lisa Brown", "林 亮太"]);
    await expect(args.onClose).toHaveBeenCalled();
  },
};

/** A whole beginners' group at once: the preview scrolls. */
export const ManyGuests: Story = {
  play: async ({ canvasElement }) => {
    const names = [
      "Ryo Hayashi",
      "Megumi Ono",
      "Ben Clarke",
      "Saki Fujita",
      "Daisuke Matsumoto",
      "Olivia Turner",
      "Kenta Shimizu",
      "Yui Morita",
      "James O'Connor",
      "Natsuki Aoyama",
      "Priya Raman",
      "Taro Yamaguchi",
    ];
    const canvas = await typeNames(canvasElement, names.join("\n"));
    await expect(await canvas.findByText("Preview (12 guests)")).toBeVisible();
  },
};
