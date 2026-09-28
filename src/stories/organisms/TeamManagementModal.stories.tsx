import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as TeamManagementModalStory, query } from "./TeamManagementModalStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The event manager's team dialog. "Teams" are partners the draw keeps
// together; "Anti-Teams" are players it keeps apart. Each list has an empty
// state; edit and create open a player picker (the 20-player roster plus two
// walk-ins) with a required name. "Save & Close" hands both lists back.
const meta = {
  title: "Organisms/TeamManagementModal",
  component: TeamManagementModalStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: { control: "inline-radio", options: ["empty", "teamsOnly", "typical"] },
  },
  args: { state: "typical", onSave: fn(), onClose: fn() },
} satisfies Meta<typeof TeamManagementModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Three fixed partnerships. Delete one and save: both lists go back to the manager. */
export const Teams: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Team Management")).toBeVisible();
    await expect(canvas.getByText("Team 3")).toBeVisible();
    await userEvent.click(canvas.getAllByTitle("Delete team")[2]);
    await waitFor(() => expect(canvas.queryByText("Team 3")).toBeNull());
    await userEvent.click(canvas.getByText("Save & Close"));
    await expect(args.onSave).toHaveBeenCalledWith(
      ["Team 1: Kenji Tanaka, Yuki Sato", "Team 2: Chris Chen, Emily Parker"],
      ["Anti-Team 1: Aiko Suzuki, Hiroshi Watanabe", "Anti-Team 2: Daniel Kim, Sarah Johnson, Tom Wilson"],
    );
    await expect(args.onClose).toHaveBeenCalled();
  },
};

/** The Anti-Teams tab: a couple who won't partner, and three newcomers kept apart. */
export const AntiTeams: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Anti-Teams" }));
    await expect(await canvas.findByText("Anti-Team 2")).toBeVisible();
    await expect(canvas.getByText("3 players")).toBeVisible();
  },
};

/** Nothing set up yet. */
export const Empty: Story = {
  args: { state: "empty" },
  play: async ({ canvasElement }) => {
    await expect(await within(canvasElement).findByText("No teams yet")).toBeVisible();
  },
};

/** Teams but no anti-teams: the Anti-Teams tab's empty state. */
export const NoAntiTeams: Story = {
  args: { state: "teamsOnly" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Anti-Teams" }));
    await expect(await canvas.findByText("No anti-teams yet")).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Create Anti-Team/ })).toBeVisible();
  },
};

/** Editing Team 1: its two members are ticked in the roster grid. */
export const EditTeam: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click((await canvas.findAllByTitle("Edit team"))[0]);
    await expect(await canvas.findByText("Edit Team")).toBeVisible();
    await expect(canvas.getByDisplayValue("Team 1")).toBeVisible();
    await expect(canvas.getByText("Team Members (2)")).toBeVisible();
  },
};

/** A new team picks up members as they are tapped; an empty name disables saving. */
export const CreateTeam: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: /Create Team/ }));
    await expect(await canvas.findByDisplayValue("New Team")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: /Haruka Nakamura/ }));
    await userEvent.click(canvas.getByRole("button", { name: /Kaito Mori/ }));
    await expect(canvas.getByText("Team Members (2)")).toBeVisible();
    await userEvent.clear(canvas.getByDisplayValue("New Team"));
    await expect(canvas.getByRole("button", { name: "Save Team" })).toBeDisabled();
  },
};
