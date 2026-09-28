import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as SessionEvenPlayModeStory } from "./SessionEvenPlayModeStory.gen";

// AiTetsu's "even play" setting: how many players rest each round so match
// counts level out across the night. 0 turns it off in favour of match
// quality. The label reports how many are resting right now.
const meta = {
  title: "Organisms/SessionEvenPlayMode",
  component: SessionEvenPlayModeStory,
  parameters: { layout: "padded" },
  args: { breakCount: 4, breakPlayersCount: 4, onChangeBreakCount: fn() },
} satisfies Meta<typeof SessionEvenPlayModeStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** 16 checked in on three courts: four rest each round, and the setting matches. */
export const FourResting: Story = {};

/** Off: optimise match quality instead of evening out play counts. */
export const Off: Story = { args: { breakCount: 0, breakPlayersCount: 2 } };

/** Change it to 2 and save. */
export const ChangeRestCount: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    const input = await canvas.findByRole("textbox");
    await userEvent.clear(input);
    await userEvent.type(input, "2");
    await userEvent.click(canvas.getByRole("button", { name: "save" }));
    await waitFor(() => expect(args.onChangeBreakCount).toHaveBeenCalledWith(2));
  },
};
