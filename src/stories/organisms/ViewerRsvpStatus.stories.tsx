import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as ViewerRsvpStatusStory, query } from "./ViewerRsvpStatusStory.gen";

// The join / leave link on the legacy event RSVP list (EventRsvps). It reads
// the viewer from GlobalQuery's context: signed out, it asks the visitor to
// log in with LINE.
const meta = {
  title: "Organisms/ViewerRsvpStatus",
  component: ViewerRsvpStatusStory,
  args: { joined: false, onJoin: fn(), onLeave: fn() },
  parameters: {
    relay: { query, scenario: "new-user", mocks: { User: { lineUsername: "Chris" } } },
  },
} satisfies Meta<typeof ViewerRsvpStatusStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Signed in, not on the list yet. */
export const NotJoined: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("link", { name: /join event/ }));
    await expect(args.onJoin).toHaveBeenCalled();
  },
};

/** Signed in and on the list. */
export const Joined: Story = {
  args: { joined: true },
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("link", { name: /leave event/ }));
    await expect(args.onLeave).toHaveBeenCalled();
  },
};

/** Signed out: a login prompt with the LINE button. */
export const SignedOut: Story = {
  parameters: { relay: { scenario: "signed-out" } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("login to join the event")).toBeVisible();
    await expect(canvas.getByRole("link")).toHaveAttribute("href", expect.stringContaining("/oauth-login"));
  },
};
