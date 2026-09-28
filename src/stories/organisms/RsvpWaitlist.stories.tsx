import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { connection, rsvps } from "./StoryFixturesEvent.gen";
import { make as RsvpWaitlistStory, query } from "./RsvpWaitlistStory.gen";

// The Waitlist on the classic event page's RSVP card: main-list RSVPs past
// the event's capacity, numbered in join order, each an EventRsvp. Renders
// nothing until the event is over capacity.
const meta = {
  title: "Organisms/RsvpWaitlist",
  component: RsvpWaitlistStory,
  args: { activitySlug: "pickleball" },
  argTypes: { activitySlug: { control: "inline-radio", options: ["pickleball", "badminton"] } },
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { event: {} },
        Event: { maxRsvps: 8, price: null, viewerIsAdmin: false, rsvps: connection(rsvps(11)) },
      },
    },
  },
} satisfies Meta<typeof RsvpWaitlistStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Eight places, eleven players: three waiting. */
export const Waitlist: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading")).toHaveTextContent("Waitlist (3)");
    await waitFor(() => expect(canvas.getByText("Tom")).toBeVisible());
  },
};

/** A popular session: ten waiting, the signed-in player among them. */
export const LongWaitlist: Story = {
  args: { viewerId: "user-lucas" },
  parameters: { relay: { mocks: { Event: { maxRsvps: 4 } } } },
};

/** The organizer's view of a priced event: payment badges, and the RSVP menu. */
export const OrganizerPricedEvent: Story = {
  parameters: { relay: { mocks: { Event: { price: 1500, viewerIsAdmin: true } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(canvas.getByText("Tom"));
    await expect(await body.findByRole("menuitem", { name: "Remove from event" })).toBeVisible();
  },
};

/** Under capacity: nothing renders. */
export const NotFull: Story = {
  parameters: { relay: { mocks: { Event: { maxRsvps: 12 } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByRole("heading")).toBeNull();
  },
};
