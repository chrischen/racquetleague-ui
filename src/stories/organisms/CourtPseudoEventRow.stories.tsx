import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { shiftClock } from "./StoryFixturesDiscovery.gen";
import { make as CourtPseudoEventRowStory } from "./CourtPseudoEventRowStory.gen";

// One venue's court opening in an expanded CourtPseudoEventGroup: start and
// length, the venue, courts and other players in the slot, and the viewer's
// own time in it ("You: 6 PM–9 PM"). "Mark available" / "Edit time" opens a
// picker clamped to the slot over the other players' demand; saving replaces
// only the slot's part of the viewer's day. Expanded, the row lists the other
// players (collapsible) and the venue's court card with a reserve link.
// Wednesday 14 October in Tokyo (StoryFixturesDiscovery).
const meta = {
  title: "Organisms/CourtPseudoEventRow",
  component: CourtPseudoEventRowStory,
  beforeEach: shiftClock,
  parameters: { layout: "fullscreen" },
  argTypes: {
    state: { control: "inline-radio", options: ["viewerAvailable", "othersOnly", "nobodyYet", "unpricedVenue"] },
  },
  args: { state: "viewerAvailable", onAvailabilityChange: fn() },
} satisfies Meta<typeof CourtPseudoEventRowStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Minato 6–9 PM: the viewer's saved 6–10 PM covers it; five others overlap. */
export const ViewerAvailable: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/You:/)).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Edit time/ })).toBeVisible();
  },
};

/** Expanded with the player list open, above the venue's court card. */
export const Expanded: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Minato Sports Center/ }));
    await userEvent.click(await canvas.findByRole("button", { name: /other players available in this slot/ }));
    const yuki = await canvas.findByText("Yuki");
    await waitFor(() => expect(yuki).toBeVisible());
  },
};

/** Toyosu 1–5 PM, the viewer not in it yet: "Mark available" opens the
 * slot's picker with the whole slot drafted. */
export const MarkAvailable: Story = {
  args: { state: "othersOnly" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Mark available/ }));
    const editor = await canvas.findByText("Your availability in this slot");
    await waitFor(() => expect(editor).toBeVisible());
    await expect(canvas.getByRole("button", { name: /Save availability/ })).toBeEnabled();
  },
};

/** Ginza 3–6 PM with nobody's windows known: no player count. */
export const NobodyYet: Story = {
  args: { state: "nobodyYet" },
};

/** A venue known only by its booking page (no hourly rollup): the generic
 * "Court" name and no surface or price, expanded to its card. */
export const UnpricedVenue: Story = {
  args: { state: "unpricedVenue" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getAllByRole("button")[0]);
    await expect(await canvas.findAllByText("Court")).not.toHaveLength(0);
  },
};
