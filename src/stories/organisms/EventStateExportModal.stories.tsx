import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, spyOn, userEvent, waitFor, within } from "storybook/test";
import { make as EventStateExportModalStory } from "./EventStateExportModalStory.gen";
import { must } from "../support";

// The event manager's "Export History" dialog: scored matches and rating
// adjustments as one JSON string (the real encoder's output for the shared
// Thursday-night fixtures), read-only, with Copy. Copy turns green for two
// seconds; where the clipboard is refused (plain-http LAN addresses) the text
// is selected for a manual copy instead.
const meta = {
  title: "Organisms/EventStateExportModal",
  component: EventStateExportModalStory,
  parameters: { layout: "fullscreen" },
  argTypes: { state: { control: "inline-radio", options: ["typical", "longSession"] } },
  args: { state: "typical", onClose: fn() },
} satisfies Meta<typeof EventStateExportModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const clipboardOf = (canvasElement: HTMLElement) => must(canvasElement.ownerDocument.defaultView, "window").navigator.clipboard;

/** Rounds 1 and 2 (seven scored matches) and ten rating adjustments. */
export const Typical: Story = {
  play: async ({ canvasElement }) => {
    const box = await within(canvasElement).findByRole("textbox");
    await expect((box as HTMLTextAreaElement).value).toMatch(/^\{"format":"pkuru-event-history","version":2/);
  },
};

/** Twelve rounds: the text fills the box and scrolls. */
export const LongSession: Story = { args: { state: "longSession" } };

/** Copied: the button turns green. */
export const Copied: Story = {
  play: async ({ canvasElement }) => {
    const writeText = spyOn(clipboardOf(canvasElement), "writeText").mockResolvedValue(undefined);
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Copy" }));
    await expect(await canvas.findByRole("button", { name: "Copied" })).toBeVisible();
    await expect(writeText).toHaveBeenCalledWith(expect.stringContaining('"eventId":"evt-story-match"'));
  },
};

/** The clipboard refused: no "Copied", the whole text is selected instead. */
export const ClipboardRefused: Story = {
  play: async ({ canvasElement }) => {
    spyOn(clipboardOf(canvasElement), "writeText").mockRejectedValue(new Error("Write permission denied."));
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Copy" }));
    const box = canvas.getByRole("textbox") as HTMLTextAreaElement;
    await waitFor(() => expect(box.selectionEnd - box.selectionStart).toBe(box.value.length));
    await expect(canvas.queryByRole("button", { name: "Copied" })).toBeNull();
  },
};
