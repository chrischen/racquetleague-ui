import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { conversation, message, messageConnection } from "./StoryFixturesEventPage.gen";
import { make as EventMessagesStory, query } from "./EventMessagesStory.gen";

// The classic event page's activity card (EventMessages): the organizer's
// messages, players' status messages and the RSVP history, newest first, each
// with its date and time. A player who has joined also gets a box to post a
// status message. Cancellations are coloured by how close to the start they
// came: red within 24 hours, amber within 48. The event starts on Thursday
// 15 October 2026 at 19:00 in Tokyo.
const START = "2026-10-15T10:00:00.000Z";
const HOUR = 3_600_000;
const before = (hours: number) => new Date(Date.parse(START) - hours * HOUR).toISOString();

const meta = {
  title: "Organisms/EventMessages",
  component: EventMessagesStory,
  args: { eventStartDate: START, viewerHasRsvp: false },
  parameters: {
    relay: {
      query,
      // The feed as of an hour before the start.
      mocks: { Query: { messagesByTopic: conversation(Date.parse(START) - HOUR, 10, "user_message") } },
    },
  },
} satisfies Meta<typeof EventMessagesStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A viewer who hasn't joined: the history, no message box. */
export const Conversation: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/Courts 3 and 4 tonight/)).toBeVisible();
    await expect(canvas.queryByPlaceholderText(/Type a status message/)).toBeNull();
  },
};

/** A joined player can post a status message for everyone. */
export const ViewerJoined: Story = {
  args: { viewerHasRsvp: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByPlaceholderText(/Type a status message/)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Send" })).toBeVisible();
  },
};

/** Nothing has happened yet. */
export const Empty: Story = {
  parameters: { relay: { mocks: { Query: { messagesByTopic: { edges: [] } } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("No activity yet")).toBeVisible();
  },
};

/** Dropouts: red 5 hours before the start, amber 30 hours before, grey
    three days out; an organizer removal in orange. */
export const LateCancellations: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          messagesByTopic: messageConnection([
            message("msg-c1", before(5), "Lucas", "rsvp_deleted", null),
            message("msg-c2", before(8), "Mei", "rsvp_removed", null),
            message("msg-c3", before(30), "Daniel", "rsvp_deleted", null),
            message("msg-c4", before(31), "Olivia", "rsvp_promoted", null),
            message("msg-c5", before(72), "Takeshi", "rsvp_deleted", null),
            message("msg-c6", before(96), "Takeshi", "rsvp_created", null),
          ]),
        },
      },
    },
  },
};
