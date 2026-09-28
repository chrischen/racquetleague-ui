import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { shiftClock } from "./StoryFixturesDiscovery.gen";
import { make as CourtPseudoEventGroupStory } from "./CourtPseudoEventGroupStory.gen";

// The cyan row the Discover feed shows for a continuous run of open courts:
// the span, "n courts available" (the most open at once), how many venues,
// the indoor/outdoor mix and the price range per court-hour. "View slots"
// expands it into one CourtPseudoEventRow per venue opening, where the viewer
// can mark themselves available for that slot. Built from the stories'
// fortnight in Tokyo (StoryFixturesDiscovery), as PkEventsDayFeed builds it.
const meta = {
  title: "Organisms/CourtPseudoEventGroup",
  component: CourtPseudoEventGroupStory,
  beforeEach: shiftClock,
  parameters: { layout: "fullscreen" },
  argTypes: { state: { control: "inline-radio", options: ["afternoonRun", "singleVenue", "morning", "noPlayers"] } },
  args: { state: "afternoonRun", onAvailabilityChange: fn() },
} satisfies Meta<typeof CourtPseudoEventGroupStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** 1–10 PM on Wednesday: four openings at three venues that overlap. */
export const AfternoonRun: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("3 courts available")).toBeVisible();
    await expect(canvas.getByText("3 locations")).toBeVisible();
  },
};

/** Expanded: each venue's opening as its own row, with the viewer's saved
 * 6–10 PM on the ones it overlaps and the other players in each slot. */
export const Expanded: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /3 courts available/ }));
    await expect(await canvas.findByText("Hide slots")).toBeInTheDocument();
    const minato = await canvas.findByText("Minato Sports Center");
    await waitFor(() => expect(minato).toBeVisible());
  },
};

/** One venue, one opening (next Monday evening). */
export const SingleVenue: Story = {
  args: { state: "singleVenue" },
};

/** Early courts, before the day's first event. */
export const Morning: Story = {
  args: { state: "morning" },
};

/** Saturday morning at two venues with nobody's windows known, expanded:
 * the slot rows carry no player counts. */
export const NoPlayers: Story = {
  args: { state: "noPlayers" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /courts available/ }));
    const toyosu = await canvas.findByText("Toyosu Riverside Courts");
    await waitFor(() => expect(toyosu).toBeVisible());
  },
};
