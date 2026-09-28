import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as SortableSubmitMatchStory, query } from "./SortableSubmitMatchStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The court card on MatchesView's Matches tab: the two team slots (filled by
// the drag-and-drop containers in the app), a "..." menu with Cancel, and
// Enter Score. Score entry takes points per team, or (with a walk-in, who
// can't be rated) a Winner button per team; tapping a team marks it the
// winner with a green border. Players come from the shared match roster
// (StoryFixturesMatch).
const meta = {
  title: "Organisms/SortableSubmitMatch",
  component: SortableSubmitMatchStory,
  parameters: { relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: { state: { control: "inline-radio", options: ["rated", "guests", "longNames"] } },
  args: { state: "rated", scoreEntry: false, onDelete: fn(), onUpdated: fn() },
} satisfies Meta<typeof SortableSubmitMatchStory>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Kenji Tanaka")).toBeVisible();
    await expect(canvas.getByText("Enter Score")).toBeVisible();
  },
};

/** Score entry: a points box per team, Save, and the prediction bar. */
export const EnterScore: Story = { args: { scoreEntry: true } };

/** Tapping a team in score entry marks it the winner (1 to −1) and closes. */
export const WinnerPicked: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("Enter Score"));
    await userEvent.click(await canvas.findByText("Yuki Sato"));
    await waitFor(() => expect(args.onUpdated).toHaveBeenCalledWith([-1, 1]));
    await expect(await canvas.findByText("Enter Score")).toBeVisible();
  },
};

/** With walk-ins: Winner buttons instead of points. */
export const GuestPlayers: Story = { args: { state: "guests", scoreEntry: true } };

/** The "..." menu holds Cancel. */
export const CancelMenu: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "..." }));
    const body = within(canvasElement.ownerDocument.body);
    await expect(await body.findByRole("menuitem", { name: "Cancel" })).toBeVisible();
  },
};

export const LongNames: Story = { args: { state: "longNames" } };
