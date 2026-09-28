import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as SeekingPartnerInputStory } from "./SeekingPartnerInputStory.gen";

// The "seeking a doubles partner" switch from the profile form. It is
// controlled; the story wrapper keeps its value so it can be toggled here.
const meta = {
  title: "Organisms/SeekingPartnerInput",
  component: SeekingPartnerInputStory,
  args: { seeking: false, onChange: fn() },
} satisfies Meta<typeof SeekingPartnerInputStory>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Off: Story = {};

export const On: Story = { args: { seeking: true } };

/** Clicking the switch turns it on and reports `true`. */
export const Toggle: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    const toggle = canvas.getByRole("switch");
    await expect(toggle).toHaveAttribute("aria-checked", "false");
    await userEvent.click(toggle);
    await expect(toggle).toHaveAttribute("aria-checked", "true");
    await expect(args.onChange).toHaveBeenCalledWith(true);
  },
};
