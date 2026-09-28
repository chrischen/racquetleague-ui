import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { shiftClock } from "./StoryFixturesDiscovery.gen";
import { make as AvailabilityGridStory } from "./AvailabilityGridStory.gen";

// The horizontal weekly planner: a row per day with a time track from 6 AM to
// midnight, the viewer's windows as draggable lime chips over the other
// players' demand (violet), the viewer's events (amber) and open courts
// (cyan). Weekly / one-off modes, presets, a summary of the saved windows and
// a Save bar. The availability page now uses VerticalAvailabilityGrid; this
// one isn't rendered anywhere but still builds. The week is 12–18 October
// 2026, today Wednesday (StoryFixturesDiscovery).
const meta = {
  title: "Organisms/AvailabilityGrid",
  component: AvailabilityGridStory,
  beforeEach: shiftClock,
  parameters: { layout: "fullscreen" },
  argTypes: { state: { control: "inline-radio", options: ["planned", "blank"] } },
  args: { state: "planned", isSaving: false, onSave: fn() },
} satisfies Meta<typeof AvailabilityGridStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Wednesday evening and Saturday morning saved, over the week's demand,
 * events and courts. Save reports every day of the week. */
export const Planned: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("8h / 2 weeks")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Save" }));
    await expect(args.onSave).toHaveBeenCalled();
  },
};

/** Nothing saved and nothing around it. */
export const Blank: Story = {
  args: { state: "blank" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Add time windows above")).toBeVisible();
  },
};

/** "Weekday eves" adds 6–10 PM to Monday to Friday. */
export const WeekdayEvenings: Story = {
  args: { state: "blank" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Weekday eves/ }));
    await waitFor(() => expect(canvas.getByText("20h / 2 weeks")).toBeVisible());
  },
};

/** Weekly mode drops the dates: the rows read as a repeating week. */
export const WeeklyMode: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Weekly/ }));
    await waitFor(() => expect(canvas.queryByText("Oct 14")).toBeNull());
  },
};

/** While saving, the button says so and is disabled. */
export const Saving: Story = {
  args: { isSaving: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: /Saving/ })).toBeDisabled();
  },
};
