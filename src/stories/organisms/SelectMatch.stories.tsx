import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as SelectMatchStory, query } from "./SelectMatchStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// AiTetsu's "manual team" picker: the queue listed twice, strongest first,
// with rating bars. Pick two players on the left and two on the right (a
// left pick is greyed out on the right); with four picked, "Queue Match"
// appears above a SubmitMatch card for the pairing. Players come from the
// shared match roster (StoryFixturesMatch).
const meta = {
  title: "Organisms/SelectMatch",
  component: SelectMatchStory,
  parameters: { relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: { state: { control: "inline-radio", options: ["empty", "typical", "withGuests", "longNames"] } },
  args: { state: "typical", onMatchQueued: fn() },
} satisfies Meta<typeof SelectMatchStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Twelve queued players, nothing picked yet. */
export const Typical: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("left team players")).toBeVisible();
    await expect(canvas.getAllByText("Kenji Tanaka")).toHaveLength(2);
  },
};

/** Nobody queued: each list says "no players yet". */
export const Empty: Story = {
  args: { state: "empty" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("left team players")).toBeVisible();
    const empty = canvas.getAllByText("no players yet");
    await expect(empty).toHaveLength(2);
    for (const text of empty) await expect(text).toBeVisible();
    await expect(canvas.queryAllByRole("listitem")).toHaveLength(0);
  },
};

/** Two walk-ins without accounts in the queue. */
export const WithGuests: Story = { args: { state: "withGuests" } };

export const LongNames: Story = { args: { state: "longNames" } };

/** Kenji & Aiko against Yuki & Chris: the pairing appears, ready to queue. */
export const MatchPicked: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    const left = (name: string) => canvas.getAllByText(name)[0];
    const right = (name: string) => canvas.getAllByText(name)[1];
    await userEvent.click(left("Kenji Tanaka"));
    await userEvent.click(left("Aiko Suzuki"));
    await userEvent.click(right("Yuki Sato"));
    await userEvent.click(right("Chris Chen"));
    const queue = await canvas.findByText("Queue Match");
    await userEvent.click(queue);
    await waitFor(() =>
      expect(args.onMatchQueued).toHaveBeenCalledWith("Kenji Tanaka & Aiko Suzuki vs Yuki Sato & Chris Chen"),
    );
  },
};
