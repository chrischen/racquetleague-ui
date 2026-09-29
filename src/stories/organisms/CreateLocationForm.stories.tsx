import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as CreateLocationFormStory } from "./CreateLocationFormStory.gen";

// The "add new location" form from the event form's location picker: name,
// address, a maps link and details shared by every event at the venue. An
// empty name or address shows a translated "... is required" under its field.
const meta = {
  title: "Organisms/CreateLocationForm",
  component: CreateLocationFormStory,
  args: { onCancel: fn(), onClose: fn() },
} satisfies Meta<typeof CreateLocationFormStory>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Empty: Story = {};

/** Saving with nothing filled in: an empty name and address are rejected. */
export const MissingName: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "save" }));
    await expect(await canvas.findByText("name is required")).toBeVisible();
    await expect(await canvas.findByText("address is required")).toBeVisible();
    await expect(args.onClose).not.toHaveBeenCalled();
  },
};

/** A venue typed in, ready to save. */
export const Filled: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(canvas.getByLabelText("name"), "Shibuya Sports Center");
    await userEvent.type(canvas.getByLabelText("address"), "1-40-18 Jinnan, Shibuya-ku, Tokyo 150-0041");
    await userEvent.type(canvas.getByLabelText("maps link"), "https://maps.app.goo.gl/77FBSgrFRFAQrPrM8");
    await userEvent.type(
      canvas.getByLabelText("details"),
      "Enter from the north gate. Courts 3 and 4 are on the 2nd floor; indoor shoes only.",
    );
    await expect(canvas.getByLabelText("name")).toHaveValue("Shibuya Sports Center");
  },
};
