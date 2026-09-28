import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { eventUrl, longUrl, make as SelfCheckinDisplayStory } from "./SelfCheckinDisplayStory.gen";

// The full-screen "scan to check in" QR code an organizer puts up on a tablet
// at the venue (opened from PlayerCheckin). Players scan it with their phone
// camera to open the event page. Without an event URL (the standalone check-in
// tool) the code points at the current page.
const meta = {
  title: "Organisms/SelfCheckinDisplay",
  component: SelfCheckinDisplayStory,
  parameters: { layout: "fullscreen" },
  args: { url: eventUrl, onClose: fn() },
} satisfies Meta<typeof SelfCheckinDisplayStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Opened from an event's check-in list: the code points at the event page. */
export const EventCheckin: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { name: "Scan to check in" })).toBeVisible();
    await userEvent.click(canvas.getByTitle("Close self check-in display"));
    await expect(args.onClose).toHaveBeenCalledTimes(1);
  },
};

/** A long URL makes a denser code; the white card keeps its size. */
export const LongUrl: Story = {
  args: { url: longUrl },
};

/** The standalone tool with no event: the code encodes the current page's URL. */
export const StandaloneTool: Story = {
  args: { url: undefined },
};
