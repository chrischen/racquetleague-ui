import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as MatchesViewStory, query } from "./MatchesViewStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// AiTetsu's full-screen session mode (black). The Queue tab shows every
// player as queued, playing, on a break or free, with the courts stepper and
// Queue All / CHOOSE MATCH; the Matches tab shows the court cards (drag
// players between them) and SUBMIT RESULTS; check-in ends in START SESSION.
// The check-in list and the team-actions drawer are AiTetsu's own components,
// shown here as labelled stand-ins. "CHOOSE MATCH" opens a real CompMatch.
// Players come from the shared match roster (StoryFixturesMatch).
const meta = {
  title: "Organisms/MatchesView",
  component: MatchesViewStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    view: { control: "inline-radio", options: ["queue", "matches", "checkin"] },
    state: { control: "inline-radio", options: ["typical", "noMatches", "readyToChoose"] },
  },
  args: {
    view: "queue",
    state: "typical",
    onClose: fn(),
    onSubmitResults: fn(),
    onMatchUpdated: fn(),
    onMatchCanceled: fn(),
  },
} satisfies Meta<typeof MatchesViewStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Two courts playing, two players on a break, two queued. */
export const Queue: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Add/Remove Players")).toBeVisible();
    await expect(canvas.getByText("2 players selected")).toBeVisible();
  },
};

/** Four queued: the main action becomes CHOOSE MATCH. */
export const ReadyToChoose: Story = { args: { state: "readyToChoose" } };

/** CHOOSE MATCH opens the match chooser in a drawer. */
export const ChooseMatchDrawer: Story = {
  args: { state: "readyToChoose" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("CHOOSE MATCH"));
    const body = within(canvasElement.ownerDocument.body);
    const recommended = await body.findByText("Recommended Match");
    await waitFor(() => expect(recommended).toBeVisible());
  },
};

/** The Matches tab: two courts and SUBMIT RESULTS. */
export const Matches: Story = {
  args: { view: "matches" },
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByText("Enter Score")).toHaveLength(2);
    await userEvent.click(canvas.getByText("SUBMIT RESULTS"));
    await waitFor(() => expect(args.onSubmitResults).toHaveBeenCalled());
  },
};

/** No matches yet: the Matches tab offers Queue All instead. */
export const NoMatches: Story = {
  args: { view: "matches", state: "noMatches" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByText("Queue All")).toBeVisible();
  },
};

/** The check-in slot and START SESSION. */
export const Checkin: Story = {
  args: { view: "checkin" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("START SESSION"));
    await expect(await canvas.findByText("Add/Remove Players")).toBeVisible();
  },
};
