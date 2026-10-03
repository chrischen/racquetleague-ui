import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { recommendations } from "./StoryFixturesEventPage.gen";
import { make as PlayerInviteSwipeDeckStory, query } from "./PlayerInviteSwipeDeckStory.gen";

// The full-screen card deck an organizer swipes through, one player at a
// time. Invite mode (from EventInvites) reviews suggested players: a right
// swipe opens a note to send with the invite. Approve mode (from
// PkRSVPSection) reviews pending join requests: a right swipe approves. A left
// swipe changes nothing. Each card shows the rating the player would be
// seeded at (and where it comes from), the computed rating, the biography and
// either their availability for the event or the note left with the request.
const meta = {
  title: "Organisms/PlayerInviteSwipeDeck",
  component: PlayerInviteSwipeDeckStory,
  argTypes: { mode: { control: "inline-radio", options: ["invite", "approve"] } },
  args: { mode: "invite", startAt: 0, reviewed: false, onAccept: fn(), onClose: fn() },
  parameters: {
    layout: "fullscreen",
    relay: { query, mocks: { Query: { inviteRecommendations: recommendations(5) } } },
  },
} satisfies Meta<typeof PlayerInviteSwipeDeckStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// The deck and its cards fade in, so wait for them to show.
const visible = (el: HTMLElement) => waitFor(() => expect(el).toBeVisible());

const deck = (canvasElement: HTMLElement) => within(canvasElement.ownerDocument.body);

/** A suggested player whose availability covers the event: established DUPR,
    league rating and biography. */
export const Invite: Story = {
  play: async ({ canvasElement }) => {
    const body = deck(canvasElement);
    await visible(await body.findByRole("heading", { name: "Ryo" }));
    await visible(body.getByText("Available for the full event"));
  },
};

/** A visitor with a provisional DUPR who stored no availability that day. */
export const InviteAvailabilityUnknown: Story = {
  args: { startAt: 2 },
  play: async ({ canvasElement }) => {
    const body = deck(canvasElement);
    await visible(await body.findByText("Availability not shared for this day"));
  },
};

/** Free that day, but not at the event's hours. */
export const InviteOtherHours: Story = {
  args: { startAt: 3 },
  play: async ({ canvasElement }) => {
    const body = deck(canvasElement);
    await visible(await body.findByText("Available at other hours that day"));
  },
};

/** A new player with no picture and only their own estimate. */
export const InviteSelfRatedOnly: Story = {
  args: { startAt: 4 },
  play: async ({ canvasElement }) => {
    const body = deck(canvasElement);
    await visible(await body.findByText("Not yet rated"));
  },
};

/** Inviting asks for a note first; the card waits until it is sent. */
export const InviteComposer: Story = {
  play: async ({ canvasElement }) => {
    const body = deck(canvasElement);
    await userEvent.click(await body.findByRole("button", { name: "Invite Ryo" }));
    const composer = await body.findByRole("dialog", { name: "Invite Ryo" });
    await waitFor(() => expect(composer).toBeVisible());
  },
};

/** Reviewing a pending request: their rating, biography and note. */
export const Approve: Story = {
  args: { mode: "approve" },
  play: async ({ canvasElement }) => {
    const body = deck(canvasElement);
    await visible(await body.findByRole("dialog", { name: "Review requests" }));
    await visible(body.getByText("初心者ですが、よろしくお願いします！"));
  },
};

/** A request with nothing to go on: no picture, no games, no note. */
export const ApproveNoSignals: Story = {
  args: { mode: "approve", startAt: 1 },
  play: async ({ canvasElement }) => {
    const body = deck(canvasElement);
    await visible(await body.findByText("No message left with the request"));
    await visible(body.getByText("Not yet rated"));
  },
};

/** Approving every request ends on the summary card. */
export const EveryoneReviewed: Story = {
  args: { mode: "approve" },
  play: async ({ canvasElement, args }) => {
    const body = deck(canvasElement);
    for (const name of ["あおい", "Tom", "Rin"]) {
      await userEvent.click(await body.findByRole("button", { name: `Approve ${name}` }));
    }
    await visible(await body.findByText("Everyone reviewed"));
    await expect(args.onAccept).toHaveBeenCalledTimes(3);
  },
};
