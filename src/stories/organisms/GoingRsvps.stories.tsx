import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { connection, payment, rsvps } from "./StoryFixturesEvent.gen";
import { make as GoingRsvpsStory, query } from "./GoingRsvpsStory.gen";

// The Going list on the classic event page's RSVP card (RSVPSection): the
// main-list RSVPs up to the event's capacity, strongest first, three at a time
// until expanded. Each player is an EventRsvp. Pending requests (listType 1)
// and anyone past capacity are left to PendingRsvps and RsvpWaitlist.
const meta = {
  title: "Organisms/GoingRsvps",
  component: GoingRsvpsStory,
  args: { activitySlug: "pickleball" },
  argTypes: { activitySlug: { control: "inline-radio", options: ["pickleball", "badminton"] } },
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { event: {} },
        Event: { maxRsvps: 12, price: null, viewerIsAdmin: false, rsvps: connection(rsvps(8)) },
      },
    },
  },
} satisfies Meta<typeof GoingRsvpsStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Eight going: the top three, then "+5 more". */
export const Collapsed: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("+5 more")).toBeVisible();
  },
};

/** Expanded: everyone, with "Show less". */
export const Expanded: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("+5 more"));
    await waitFor(() => expect(canvas.getByText("Takeshi")).toBeVisible());
    await expect(canvas.getByText("Show less")).toBeVisible();
  },
};

/** Two players: both shown, and nothing to expand. */
export const FewPlayers: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(2)) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    // The entries fade in.
    const yuki = await canvas.findByText("Yuki");
    await waitFor(() => expect(yuki).toBeVisible());
    await expect(canvas.queryByText("See all")).toBeNull();
    await expect(canvas.queryByText(/more$/)).toBeNull();
  },
};

/** A full event: 12 of 12 going; the rest are on the waitlist, and pending
    requests are not counted. */
export const Full: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          maxRsvps: 12,
          rsvps: connection(rsvps(14).map((r, i) => (i === 3 ? { ...r, listType: 1 } : r))),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading")).toHaveTextContent("Going (12/12)");
  },
};

/** Nobody going yet. */
export const Empty: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection([]) } } } },
};

/** The organizer's view of a priced event, expanded: payment badges and the
    signed-in organizer's own entry drawn larger. */
export const OrganizerPricedEvent: Story = {
  args: { viewerId: "user-kenji" },
  parameters: {
    relay: {
      mocks: {
        Event: {
          price: 1500,
          viewerIsAdmin: true,
          rsvps: connection(rsvps(8).map((r, i) => (i % 3 === 1 ? r : { ...r, paid: 1, payment: payment(r.id, 1) }))),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("+5 more"));
    await waitFor(() => expect(canvas.getAllByText("Not paid")).toHaveLength(3));
  },
};

/** Badminton: no rating text next to the names. */
export const Badminton: Story = {
  args: { activitySlug: "badminton" },
};
