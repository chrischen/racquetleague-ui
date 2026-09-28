import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as ProfileModalStory, query } from "./ProfileModalStory.gen";

// The profile modal as UseProfileGate raises it. `new-user` is the dev
// scenario (dev/scenarios/new-user.mjs), so these stories and
// /__dev/scenario/new-user show the same person. Stories only add the fields
// that differ.
const meta = {
  title: "Organisms/ProfileModal",
  component: ProfileModalStory,
  parameters: {
    layout: "fullscreen",
    relay: { query, scenario: "new-user" },
  },
  argTypes: {
    context: { control: "inline-radio", options: ["Join", "Availability", "Profile"] },
  },
  args: {
    isOpen: true,
    context: "Join",
    onClose: fn(),
    onProfileComplete: fn(),
  },
} satisfies Meta<typeof ProfileModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A first-time player joining an event: nothing filled in yet. */
export const Join: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement.ownerDocument.body);
    // The modal fades in, so wait for it rather than asserting on first paint.
    const title = await canvas.findByText("Complete your player profile");
    await waitFor(() => expect(title).toBeVisible());
    const name = canvas.getByPlaceholderText("How other players will see you");
    await userEvent.type(name, "Chris");
    await expect(name).toHaveValue("Chris");
  },
};

/** Sharing availability also asks for a biography, and the subtitle says why. */
export const Availability: Story = {
  args: { context: "Availability" },
};

/** An email already on file hides the email field. */
export const EmailOnFile: Story = {
  parameters: {
    relay: { query, scenario: "new-user", mocks: { User: { email: "player@example.com" } } },
  },
};

/** Opened from profile settings with everything already filled in. */
export const Complete: Story = {
  args: { context: "Profile" },
  parameters: {
    relay: {
      query,
      scenario: "new-user",
      mocks: {
        User: {
          lineUsername: "Chris",
          email: "player@example.com",
          fullName: "Chris Chen",
          biography: "Weeknight doubles, mostly in Shibuya.",
          gender: "male",
          // Stored on the internal scale; 17.4 is about DUPR 3.25 (Intermediate).
          selfRating: 17.4,
        },
      },
    },
  },
};
