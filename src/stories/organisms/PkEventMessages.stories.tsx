import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { conversation, message, messageConnection, minutesBefore } from "./StoryFixturesEventPage.gen";
import { make as PkEventMessagesStory, query } from "./PkEventMessagesStory.gen";

// The pickleball event page's activity feed: the organizer's messages and
// players' chat, mixed with system rows (joined, left, promoted from the
// waitlist, invited, event edited), newest first, five at a time. Viewers who
// haven't joined see it as a read-only card in the page; joined viewers can
// post, and get it in the sticky footer as a one-line row that opens the
// whole feed. Times are relative ("12m ago"), so the feed is built from the
// moment the story loads.
const feed = (count: number) => () => conversation(Date.now(), count, "comment_added");

const meta = {
  title: "Organisms/PkEventMessages",
  component: PkEventMessagesStory,
  argTypes: { variant: { control: "inline-radio", options: ["card", "footer"] } },
  args: { variant: "card", isJoined: false },
  parameters: {
    relay: { query, mocks: { Query: { messagesByTopic: feed(4) } } },
  },
} satisfies Meta<typeof PkEventMessagesStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A viewer who hasn't joined: the feed, read-only, with a nudge to join. */
export const Conversation: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Join this event to take part in the chat")).toBeVisible();
    await expect(canvas.queryByRole("textbox")).toBeNull();
  },
};

/** A joined player: message and update counts, and a box to post in. */
export const Joined: Story = {
  args: { isJoined: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const send = canvas.getByRole("button", { name: "Send message" });
    await expect(send).toBeDisabled();
    await userEvent.type(canvas.getByRole("textbox", { name: "Message everyone in this event" }), "On my way!");
    await expect(send).toBeEnabled();
  },
};

/** Nothing has happened yet. */
export const Empty: Story = {
  parameters: { relay: { mocks: { Query: { messagesByTopic: { edges: [] } } } } },
};

/** A joined player on a quiet event: zero counts and the message box. */
export const EmptyJoined: Story = {
  args: { isJoined: true },
  parameters: { relay: { mocks: { Query: { messagesByTopic: { edges: [] } } } } },
};

/** A busy evening: five rows, then "View all 10 updates" opens the rest. */
export const LongFeed: Story = {
  args: { isJoined: true },
  parameters: { relay: { mocks: { Query: { messagesByTopic: feed(10) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "View all 10 updates" }));
    await waitFor(() => expect(canvas.getByText("Yuki")).toBeVisible());
    await expect(canvas.getByRole("button", { name: "Show less" })).toBeVisible();
  },
};

/** Long messages and names wrap inside the card. */
export const LongMessages: Story = {
  args: { isJoined: true },
  parameters: {
    relay: {
      mocks: {
        Query: {
          messagesByTopic: () => {
            const now = Date.now();
            return messageConnection([
              message(
                "msg-long-1",
                minutesBefore(now, 3),
                "Kenji W.",
                "host_message",
                "Reminder for tonight: we have courts 3, 4 and 5 until 21:00. Please arrive 10 minutes early to help set up the nets, and bring a water bottle — the vending machines in the lobby are out of order this week. Beginners will rotate on court 5 for the first hour.",
              ),
              message(
                "msg-long-2",
                minutesBefore(now, 30),
                "Alexandra Montgomery-Fujiwara",
                "comment_added",
                "Is there parking nearby? I'll be driving from Yokohama and have never been to this gym before.",
              ),
              message("msg-long-3", minutesBefore(now, 55), "たかはし　ゆうじろう（週末のみ）", "rsvp_created", null),
            ]);
          },
        },
      },
    },
  },
};

/** In the sticky footer (joined players): the newest chat message. */
export const FooterRow: Story = {
  args: { variant: "footer" },
  parameters: { layout: "fullscreen" },
};

/** The footer row before anyone has written anything. */
export const FooterRowNoMessages: Story = {
  args: { variant: "footer" },
  parameters: {
    layout: "fullscreen",
    relay: {
      mocks: {
        Query: {
          messagesByTopic: () => messageConnection([message("msg-sys-1", minutesBefore(Date.now(), 5), "Tom", "rsvp_created", null)]),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("No messages yet")).toBeVisible();
  },
};

/** The footer row opened: the whole feed above it, titled "Event chat". */
export const FooterExpanded: Story = {
  args: { variant: "footer" },
  parameters: { layout: "fullscreen", relay: { mocks: { Query: { messagesByTopic: feed(10) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { expanded: false }));
    await expect(await canvas.findByRole("heading", { name: "Event chat" })).toBeVisible();
  },
};
