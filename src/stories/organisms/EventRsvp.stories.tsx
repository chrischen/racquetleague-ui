import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { connection, payment, rsvps } from "./StoryFixturesEvent.gen";
import { make as EventRsvpStory, query } from "./EventRsvpStory.gen";

// One player on the classic event page's RSVP lists (GoingRsvps, RsvpWaitlist,
// PendingRsvps). The ring around the picture is the player's pkuru rating as a
// share of the event's strongest; on pickleball events the name is followed by
// the rating on the DUPR scale (pkuru, else a linked DUPR, else the player's
// own estimate), on the waitlist by the position. A speech bubble holds the
// player's message; priced events add Paid / Not paid. Clicking a player
// opens RsvpOptions. The wrapper shows every RSVP on the event side by side.
const meta = {
  title: "Organisms/EventRsvp",
  component: EventRsvpStory,
  args: { activitySlug: "pickleball", isAdmin: false, waitlist: false },
  argTypes: { activitySlug: { control: "inline-radio", options: ["pickleball", "badminton"] } },
  parameters: {
    relay: { query, mocks: { Query: { event: {} }, Event: { rsvps: connection(rsvps(6)) } } },
  },
} satisfies Meta<typeof EventRsvpStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Pickleball: each name carries the player's rating. Rin has no games here
    yet, so hers is her linked DUPR rating (and her ring is empty). */
export const Pickleball: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(7)) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    // Entries fade in, so wait for them to settle.
    await waitFor(() => expect(canvas.getByText("Yuki")).toBeVisible());
    await expect(canvas.getByText("4.06")).toBeVisible();
  },
};

/** Badminton shows no rating text, only the ring. */
export const Badminton: Story = {
  args: { activitySlug: "badminton" },
};

/** The signed-in player's own entry is drawn larger. */
export const ViewerHighlighted: Story = {
  args: { viewerId: "user-emily" },
};

/** On a priced event: who has paid. */
export const PricedEvent: Story = {
  args: { eventPrice: 1500 },
  parameters: {
    relay: {
      mocks: {
        Event: {
          rsvps: connection(rsvps(6).map((r, i) => (i % 3 === 2 ? r : { ...r, paid: 1, payment: payment(r.id, 1) }))),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByText("Paid")).toHaveLength(4);
    await expect(canvas.getAllByText("Not paid")).toHaveLength(2);
  },
};

/** Players who left a message get a speech bubble; hovering it shows the message. */
export const WithMessages: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          rsvps: connection(
            rsvps(6).map((r, i) =>
              i === 1
                ? { ...r, message: "Running 15 minutes late, start without me!" }
                : i === 4
                  ? { ...r, message: "Can I borrow a paddle? Mine is being re-gripped." }
                  : r,
            ),
          ),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    // The bubble icon has no accessible name; its wrapper is the tooltip trigger.
    const bubbles = canvasElement.querySelectorAll(".cursor-help");
    await expect(bubbles).toHaveLength(2);
    await userEvent.hover(bubbles[0] as HTMLElement);
    // Radix renders the tooltip text twice (visible and for screen readers).
    const body = within(canvasElement.ownerDocument.body);
    await expect((await body.findAllByText("Running 15 minutes late, start without me!"))[0]).toBeInTheDocument();
  },
};

/** Waitlist numbering replaces the rating text. */
export const Waitlisted: Story = {
  args: { waitlist: true },
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(3)) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await waitFor(() => expect(canvas.getByText("#1")).toBeVisible());
    await expect(canvas.getByText("#3")).toBeVisible();
  },
};

/** An organizer clicking a player gets the RSVP actions. */
export const OrganizerMenu: Story = {
  args: { isAdmin: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(canvas.getByText("Emily"));
    await expect(await body.findByRole("menuitem", { name: "Move to Pending List" })).toBeVisible();
    await expect(body.getByRole("menuitem", { name: "Remove from event" })).toBeVisible();
  },
};

/** Long LINE names and a player with no picture. */
export const LongNames: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          rsvps: connection(
            rsvps(12).map((r, i) =>
              i === 0
                ? { ...r, user: { ...r.user, lineUsername: "Alexandra Montgomery-Fujiwara 🏓" } }
                : i === 3
                  ? { ...r, user: { ...r.user, lineUsername: "たかはし　ゆうじろう（週末のみ）" } }
                  : r,
            ),
          ),
        },
      },
    },
  },
};
