import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { shiftClock } from "./StoryFixturesDiscovery.gen";
import { make as VerticalAvailabilityGridStory } from "./VerticalAvailabilityGridStory.gen";

// The availability page's planner (AvailabilityPage): fifteen day columns
// from today with time running down from 6 AM. The viewer's windows are lime
// chips (tap empty time to add, drag to move, even to another day, grab the
// edges to resize); behind them, other players' demand as violet heat, the
// viewer's events in amber and open courts as cyan silhouettes whose width
// follows the court count. Below, each saved day lists the courts whose
// opening covers the whole window, then a Save bar. Two weeks from Wednesday
// 14 October 2026 in Tokyo (StoryFixturesDiscovery).
const meta = {
  title: "Organisms/VerticalAvailabilityGrid",
  component: VerticalAvailabilityGridStory,
  beforeEach: shiftClock,
  parameters: { layout: "fullscreen" },
  argTypes: { state: { control: "inline-radio", options: ["planned", "firstVisit", "blank"] } },
  args: { state: "planned", isSaving: false, onSave: fn() },
} satisfies Meta<typeof VerticalAvailabilityGridStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Four saved windows; next Monday's and Thursday's also list the
 * courts that cover them end to end. */
export const Planned: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("14h / 2 weeks")).toBeVisible();
    await expect(canvas.getAllByText("Courts and openings covering your full window").length).toBeGreaterThan(0);
    await userEvent.click(canvas.getByRole("button", { name: "Save" }));
    await expect(args.onSave).toHaveBeenCalled();
  },
};

/** A first visit: the fortnight's players, events and courts, nothing saved. */
export const FirstVisit: Story = {
  args: { state: "firstVisit" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Add time windows above")).toBeVisible();
  },
};

/** "Weekend morns" adds 9 AM–noon to both weekends. */
export const WeekendMornings: Story = {
  args: { state: "firstVisit" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Weekend morns/ }));
    await waitFor(() => expect(canvas.getByText("12h / 2 weeks")).toBeVisible());
  },
};

/** An area with nobody sharing and no courts known. */
export const Blank: Story = {
  args: { state: "blank" },
};

/** While saving, the button says so and is disabled. */
export const Saving: Story = {
  args: { isSaving: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: /Saving/ })).toBeDisabled();
  },
};
