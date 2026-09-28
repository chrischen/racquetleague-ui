import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { connection, payment, rsvps, rsvpsFrom } from "./StoryFixturesEvent.gen";
import { make as PkEventRsvpStory, query } from "./PkEventRsvpStory.gen";

// A player on the pickleball event page's RSVP section (PkRSVPSection): a chip
// on the confirmed, pending (dashed, faded) and invited (violet, "sent")
// lists, a numbered row on the waitlist. Each shows the avatar with its rating
// ring, the LINE name, a gender mark, the rating on the DUPR scale (competitive
// events only; pkuru, else a linked DUPR, else the player's own estimate), the
// payment mark and, for the organizer, a star. The currency sign is grey for a
// card on file or a hold, green once charged, red when the charge failed; a
// legacy paid flag without a payment is a green check. Clicking opens
// RsvpOptions. The wrapper lays out every RSVP on the event as that list does.
const going = rsvps(11).map((r, i) => {
  switch (i) {
    case 0:
      return { ...r, payment: payment(r.id, 1) }; // charged
    case 2:
      return { ...r, payment: payment(r.id, 5) }; // card on file
    case 3:
      return { ...r, paid: 1 }; // paid before payments were tracked
    case 4:
      return { ...r, payment: payment(r.id, 3) }; // the charge was declined
    case 5:
      return { ...r, payment: payment(r.id, 0) }; // legacy hold
    default:
      return r;
  }
});

const meta = {
  title: "Organisms/PkEventRsvp",
  component: PkEventRsvpStory,
  args: { list: "confirmed", showRating: true, isAdmin: false, chargesEnabled: false, hostId: "user-kenji" },
  argTypes: { list: { control: "inline-radio", options: ["confirmed", "waitlist", "pending", "invited"] } },
  parameters: {
    relay: { query, mocks: { Query: { event: {} }, Event: { rsvps: connection(going) } } },
  },
} satisfies Meta<typeof PkEventRsvpStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A rated event's confirmed list: ratings, payment marks and the host star. */
export const Confirmed: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("★")).toBeVisible();
    await expect(canvas.getByTitle("Charge failed")).toBeVisible();
  },
};

/** A casual event hides the ratings. */
export const CasualEvent: Story = {
  args: { showRating: false },
};

/** The waitlist: numbered rows in join order. */
export const Waitlist: Story = {
  args: { list: "waitlist", hostId: undefined },
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvpsFrom(6, 6)) } } } },
};

/** Join requests awaiting the organizer: dashed and faded. */
export const Pending: Story = {
  args: { list: "pending", hostId: undefined },
  parameters: {
    relay: { mocks: { Event: { rsvps: connection(rsvpsFrom(7, 5).map((r) => ({ ...r, listType: 1 }))) } } },
  },
};

/** Players the organizer invited, not yet answered. */
export const Invited: Story = {
  args: { list: "invited", hostId: undefined },
  parameters: {
    relay: { mocks: { Event: { rsvps: connection(rsvpsFrom(2, 4).map((r) => ({ ...r, listType: 2 }))) } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByText("sent")).toHaveLength(4);
  },
};

/** The organizer opens a card-on-file player's menu on a club that collects
    payments: "Charge payment" is offered. */
export const OrganizerCharges: Story = {
  args: { isAdmin: true, chargesEnabled: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(canvas.getByText("Emily"));
    const charge = await body.findByRole("menuitem", { name: "Charge payment" });
    await waitFor(() => expect(charge).toBeVisible());
  },
};

/** Long names wrap the row of chips. */
export const LongNames: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          rsvps: connection(
            going.map((r, i) =>
              i === 1
                ? { ...r, user: { ...r.user, lineUsername: "Alexandra Montgomery-Fujiwara 🏓" } }
                : i === 7
                  ? { ...r, user: { ...r.user, lineUsername: "たかはし　ゆうじろう（週末のみ）" } }
                  : r,
            ),
          ),
        },
      },
    },
  },
};
