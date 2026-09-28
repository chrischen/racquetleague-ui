import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { hourlyCounts, shiftClock } from "./StoryFixturesDiscovery.gen";
import { make as NewPlanModalStory } from "./NewPlanModalStory.gen";
import { must } from "../support";

// The Magic Patterns "New plan" dialog: 1 · Day (today and the next three),
// 2 · Time (presets, and a picker over the demand heatmap that
// TimePickerWithHeatmap fetches from Query.availabilityHourlyCounts),
// 3 · What kind? (Mark available, or Host an event, which needs exactly one
// window). Nothing in the app opens it now (NewPlanChooserModal replaced it).
// The clock is Wednesday 14 October 2026, 09:00 in Tokyo.
const meta = {
  title: "Organisms/NewPlanModal",
  component: NewPlanModalStory,
  beforeEach: shiftClock,
  parameters: {
    layout: "fullscreen",
    relay: { mocks: { Query: { availabilityHourlyCounts: hourlyCounts } } },
  },
  args: { isOpen: true, onClose: fn(), onMarkAvailable: fn(), onCreateEvent: fn() },
} satisfies Meta<typeof NewPlanModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Opened: today, the default 7–10 PM evening over the day's demand. */
export const Open: Story = {
  play: async ({ canvasElement }) => {
    const body = within(canvasElement.ownerDocument.body);
    const dialog = await body.findByRole("dialog");
    await waitFor(() => expect(dialog).toBeVisible());
    await expect(await body.findByRole("img", { name: "Player availability heatmap" })).toBeInTheDocument();
  },
};

/** Saturday morning picked, then hosted: the chosen day and window go to
 * the create form. */
export const SaturdayMorning: Story = {
  play: async ({ canvasElement, args }) => {
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(await body.findByRole("button", { name: /Sat/ }));
    await userEvent.click(body.getByRole("button", { name: /Morning/ }));
    await userEvent.click(body.getByRole("button", { name: /Host an event/ }));
    await expect(args.onCreateEvent).toHaveBeenCalledWith("2026-10-17", { start: 9, end: 12 });
  },
};

/** Two windows drawn: Mark available still works, hosting asks for one. */
export const TwoWindows: Story = {
  play: async ({ canvasElement }) => {
    const body = within(canvasElement.ownerDocument.body);
    const heatmap = await body.findByRole("img", { name: "Player availability heatmap" });
    // A tap on the track (here its left edge, 6 AM) adds a window there.
    await userEvent.click(must(heatmap.parentElement, "heatmap cell"));
    // The warning fades in, so wait for it to become visible.
    const warning = await body.findByText("Hosting an event needs exactly one time window — pick one.");
    await waitFor(() => expect(warning).toBeVisible());
    await expect(body.getByRole("button", { name: /Host an event/ })).toBeDisabled();
  },
};
