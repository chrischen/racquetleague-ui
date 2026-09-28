import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as RouteModalStory } from "./RouteModalStory.gen";

// The modal shell for routes opened over another page (new plan, create
// event): dimmed backdrop, a centred panel (a bottom sheet on phones) with an
// optional eyebrow, the title, an optional back button, close, and a
// scrolling body. The content in these stories stands in for the routes'.
const meta = {
  title: "Organisms/RouteModal",
  component: RouteModalStory,
  parameters: { layout: "fullscreen" },
  argTypes: {
    state: { control: "inline-radio", options: ["planChooser", "flowStep", "longContent", "titleOnly"] },
  },
  args: { state: "planChooser", onClose: fn(), onBack: fn() },
} satisfies Meta<typeof RouteModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Eyebrow, title and two choices, as the "New plan" modal uses it. */
export const PlanChooser: Story = {
  play: async ({ canvasElement, args }) => {
    const body = within(canvasElement.ownerDocument.body);
    const dialog = await body.findByRole("dialog");
    await waitFor(() => expect(dialog).toBeVisible());
    await userEvent.click(body.getByRole("button", { name: "Close" }));
    await expect(args.onClose).toHaveBeenCalled();
  },
};

/** A step inside a flow: the back button appears before the title. */
export const FlowStep: Story = {
  args: { state: "flowStep" },
  play: async ({ canvasElement, args }) => {
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(await body.findByRole("button", { name: "Back" }));
    await expect(args.onBack).toHaveBeenCalled();
  },
};

/** Content taller than the panel scrolls inside it (a title too long for the header truncates). */
export const LongContent: Story = {
  args: { state: "longContent" },
};

/** Title only, no eyebrow: a short confirmation. */
export const TitleOnly: Story = {
  args: { state: "titleOnly" },
  play: async ({ canvasElement }) => {
    const body = within(canvasElement.ownerDocument.body);
    await expect(await body.findByRole("heading", { name: "Leave this club?" })).toBeInTheDocument();
  },
};
