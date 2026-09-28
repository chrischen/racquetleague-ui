import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import { conversation } from "./StoryFixturesEventPage.gen";
import { make as EventStickyFooterStory, query } from "./EventStickyFooterStory.gen";

// The bar pinned to the bottom of the pickleball event page: the viewer's
// RSVP state and the one action it allows (claim a spot, join the waitlist,
// save a card, leave), the cancellation-deadline notice and, once joined, the
// event chat. The page derives the flags from the event's RSVPs; each story's
// `state` is one such set (see EventStickyFooterStory.res). The event is a
// 19:00 Tokyo session three days after the day the story is opened, because
// the countdown and the 30-minute grace period are measured against the clock.
const meta = {
  title: "Organisms/EventStickyFooter",
  component: EventStickyFooterStory,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: {
          viewer: {},
          event: {},
          // Built when the story loads, so "12m ago" stays "12m ago".
          messagesByTopic: () => conversation(Date.now(), 10, "comment_added"),
        },
        Viewer: signedInViewer(),
        // A complete profile, so joining goes straight through the gate.
        User: {
          lineUsername: "Chris",
          email: "chris@example.com",
          biography: "Weeknight doubles, mostly in Minato.",
          selfRating: 22.5,
          locale: "en",
        },
      },
    },
  },
  argTypes: {
    state: { control: "select" },
  },
  args: {
    state: "notJoined",
    fullWidth: true,
    onPayClick: fn(),
    onUseSavedCard: fn(),
    onJoinedNeedsCard: fn(),
  },
} satisfies Meta<typeof EventStickyFooterStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A free session with room: the date, 9/12 going and "Claim spot", under
    the cancellation-deadline notice. */
export const NotJoined: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: "Claim spot" })).toBeEnabled();
    await expect(canvas.getByText(/Cancellation deadline/)).toBeVisible();
  },
};

/** A ¥1,500 session: the price is on the button. With no card on file, the
    card form opens as soon as the join lands. */
export const NotJoinedPriced: Story = {
  args: { state: "notJoinedPriced" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: "Claim spot · ¥1500" })).toBeVisible();
  },
};

/** Invited by the organizer: the invite is accepted by joining, so the bar
    offers the same call to action. */
export const Invited: Story = {
  args: { state: "invited" },
};

/** Signed out: "Claim spot" is a link to the login page, which returns here. */
export const SignedOut: Story = {
  args: { state: "signedOut" },
  parameters: { relay: { mocks: { Query: { viewer: null } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("link", { name: "Claim spot" })).toHaveAttribute(
      "href",
      expect.stringContaining("/oauth-login?return="),
    );
  },
};

/** 12 of 12 going and two waiting: joining puts the viewer third in line. */
export const Full: Story = {
  args: { state: "full" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: "Join waitlist (#3)" })).toBeVisible();
  },
};

/** Going, with the countdown to the cancellation deadline. */
export const Joined: Story = {
  args: { state: "joined" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("You're in")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Leave event" })).toBeEnabled();
  },
};

/** Leaving a full event hands the spot to the waitlist, so it asks first. */
export const LeaveWithWaitlist: Story = {
  args: { state: "leaveWithWaitlist" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Leave event" }));
    const body = within(canvasElement.ownerDocument.body);
    const warning = await body.findByText(/There are players on the waitlist/);
    await waitFor(() => expect(warning).toBeVisible());
  },
};

/** On the waitlist of a full event: no deadline notice, "Leave waitlist". */
export const Waitlisted: Story = {
  args: { state: "waitlisted" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("On waitlist")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Leave waitlist" })).toBeEnabled();
  },
};

/** The join is held for the organizer (a level restriction or Smart RSVP). */
export const PendingApproval: Story = {
  args: { state: "pending" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Pending approval")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Withdraw RSVP" })).toBeVisible();
  },
};

/** Joined a priced event without a card: the spot is held until a card is
    saved (nothing is charged until the organizer charges after the event). */
export const UnpaidNoCard: Story = {
  args: { state: "unpaidNoCard" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Card required to confirm your spot")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Save card" }));
    await expect(args.onPayClick).toHaveBeenCalled();
  },
};

/** A card already on file: one click confirms the spot, or switch cards. */
export const UnpaidSavedCard: Story = {
  args: { state: "unpaidSavedCard" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/VISA •••• 4242/)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Use a different card" })).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Join with saved card" }));
    await expect(args.onUseSavedCard).toHaveBeenCalled();
  },
};

/** The saved card was declined: the error sits under the buttons. */
export const SavedCardError: Story = {
  args: { state: "savedCardError" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/Your card was declined/)).toBeVisible();
  },
};

/** Past the cancellation deadline: leaving is disabled and the notice sends
    the player to the organizer. */
export const DeadlinePassed: Story = {
  args: { state: "deadlinePassed" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/Cancellation deadline passed/)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Leave event" })).toBeDisabled();
  },
};

/** Past the deadline, but joined 12 minutes ago: within the 30-minute grace
    period the player can still back out. */
export const GracePeriod: Story = {
  args: { state: "gracePeriod" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/Cancellation deadline passed/)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Leave event" })).toBeEnabled();
  },
};

/** A cancelled event has no footer at all (the page shows CANCELED in the
    title card instead). */
export const CancelledEvent: Story = {
  args: { state: "cancelled" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByRole("button")).toBeNull();
  },
};

/** A session the venue runs, imported from a booking email: joined on the
    venue's site, so the bar links there. */
export const ExternalEvent: Story = {
  args: { state: "externalEvent" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("link", { name: "Open Labola" })).toHaveAttribute(
      "href",
      "https://labola.jp/r/event/4821/",
    );
  },
};

/** Joined players get the chat on top of the bar: the newest message. */
export const ChatInFooter: Story = {
  args: { state: "chat" },
};

/** The chat row opens the whole feed above the bar, with a message box. */
export const ChatExpanded: Story = {
  args: { state: "chat" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { expanded: false, name: /Kenji W\./ }));
    await expect(await canvas.findByRole("heading", { name: "Event chat" })).toBeVisible();
    await expect(canvas.getByRole("textbox", { name: "Message everyone in this event" })).toBeVisible();
  },
};

/** Inside the events drawer rather than on the event's own page: the bar
    has a rounded top. */
export const InDrawer: Story = {
  args: { state: "joined", fullWidth: false },
};
