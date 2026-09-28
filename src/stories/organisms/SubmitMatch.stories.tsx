import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as SubmitMatchStory, query } from "./SubmitMatchStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// AiTetsu's match card: the two teams (compact player rows with rating bars)
// and a Cancel button; tapping it opens score entry with a points box per
// team, Submit Rated, and the predicted-winner bar. With a walk-in (no
// account) the match can't be rated, so each team gets a Winner button
// instead. Players come from the shared match roster (StoryFixturesMatch).
const meta = {
  title: "Organisms/SubmitMatch",
  component: SubmitMatchStory,
  parameters: { relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: { state: { control: "inline-radio", options: ["rated", "guests", "longNames"] } },
  args: { state: "rated", scoreEntry: false, withScore: false, onDelete: fn(), onComplete: fn() },
} satisfies Meta<typeof SubmitMatchStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The card as queued: both teams and Cancel. */
export const Card: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Kenji Tanaka")).toBeVisible();
    await expect(canvas.getByText("Cancel")).toBeVisible();
  },
};

/** Tapping the card opens score entry. */
export const TapToEnterScore: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("Kenji Tanaka"));
    await expect(await canvas.findByRole("button", { name: "Submit Rated" })).toBeVisible();
  },
};

/** Score entry: points per team, Go Back / Submit Rated, and the prediction bar. */
export const ScoreEntry: Story = { args: { scoreEntry: true } };

/** A finished match re-opened: the recorded 11–7 is filled in. */
export const ScoreEntryPrefilled: Story = {
  args: { scoreEntry: true, withScore: true },
  play: async ({ canvasElement }) => {
    const [left, right] = within(canvasElement).getAllByPlaceholderText("Points");
    await waitFor(() => expect(left).toHaveValue(11));
    await expect(right).toHaveValue(7);
  },
};

/** Entering 11–9 and submitting reports the rated result. */
export const SubmitScore: Story = {
  args: { scoreEntry: true },
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    const [left, right] = canvas.getAllByPlaceholderText("Points");
    await userEvent.type(left, "11");
    await userEvent.type(right, "9");
    await userEvent.click(canvas.getByRole("button", { name: "Submit Rated" }));
    await waitFor(() =>
      expect(args.onComplete).toHaveBeenCalledWith("Kenji Tanaka & Mai Yamamoto vs Yuki Sato & Takumi Ito", [11, 9]),
    );
  },
};

/** With walk-ins the match is unrated: Winner buttons instead of points. */
export const GuestPlayers: Story = {
  args: { state: "guests", scoreEntry: true },
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getAllByText("Winner")[1]);
    // The winning team is reported first, with no score.
    await waitFor(() =>
      expect(args.onComplete).toHaveBeenCalledWith("Yuki Sato & Walk-in Sam vs Kenji Tanaka & Taro (guest)", undefined),
    );
  },
};

export const LongNames: Story = { args: { state: "longNames" } };

export const LongNamesScoreEntry: Story = { args: { state: "longNames", scoreEntry: true } };
