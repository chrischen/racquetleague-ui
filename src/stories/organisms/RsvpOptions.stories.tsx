import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { connection, payment, rsvps } from "./StoryFixturesEvent.gen";
import { make as RsvpOptionsStory, query } from "./RsvpOptionsStory.gen";

// The menu behind every RSVP chip (EventRsvp, PkEventRsvp). Anyone can open a
// player's profile; an organizer can also move them between the going and
// pending lists, remove them, and act on their payment: charge a saved card
// (or retry a declined one, or capture a legacy hold) when the club collects
// payments, and refund a charge. Each story opens the menu.
const [kenji] = rsvps(2).slice(1);
const withPayment = (status: number) => ({ Event: { rsvps: connection([{ ...kenji, payment: payment(kenji.id, status) }]) } });

const meta = {
  title: "Organisms/RsvpOptions",
  component: RsvpOptionsStory,
  args: { isAdmin: false, chargesEnabled: false },
  parameters: {
    relay: { query, mocks: { Query: { event: {} }, Event: { rsvps: connection([kenji]) } } },
  },
} satisfies Meta<typeof RsvpOptionsStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const openMenu = async (canvasElement: HTMLElement) => {
  await userEvent.click(within(canvasElement).getByText("Kenji W."));
  const body = within(canvasElement.ownerDocument.body);
  await body.findByRole("menu");
  return body;
};

const items = async (canvasElement: HTMLElement) => {
  const body = await openMenu(canvasElement);
  return body.getAllByRole("menuitem").map((item) => item.textContent);
};

/** Another player sees only "View Profile". */
export const PlayerView: Story = {
  play: async ({ canvasElement }) => {
    await expect(await items(canvasElement)).toEqual(["View Profile"]);
  },
};

/** An organizer on a going player. */
export const OrganizerGoing: Story = {
  args: { isAdmin: true },
  play: async ({ canvasElement }) => {
    await expect(await items(canvasElement)).toEqual(["View Profile", "Move to Pending List", "Remove from event"]);
  },
};

/** An organizer on a pending request: approve it. */
export const OrganizerPending: Story = {
  args: { isAdmin: true },
  parameters: { relay: { mocks: { Event: { rsvps: connection([{ ...kenji, listType: 1 }]) } } } },
  play: async ({ canvasElement }) => {
    await expect(await items(canvasElement)).toEqual(["View Profile", "Approve RSVP", "Remove from event"]);
  },
};

/** A saved card on a club that collects payments: charge it. */
export const CardOnFile: Story = {
  args: { isAdmin: true, chargesEnabled: true },
  parameters: { relay: { mocks: withPayment(5) } },
  play: async ({ canvasElement }) => {
    await expect(await items(canvasElement)).toContain("Charge payment");
  },
};

/** The same card on a club without payouts set up: nothing to charge to. */
export const CardOnFileChargesDisabled: Story = {
  args: { isAdmin: true, chargesEnabled: false },
  parameters: { relay: { mocks: withPayment(5) } },
  play: async ({ canvasElement }) => {
    await expect(await items(canvasElement)).not.toContain("Charge payment");
  },
};

/** The last charge was declined; the card is still on file. */
export const ChargeFailed: Story = {
  args: { isAdmin: true, chargesEnabled: true },
  parameters: { relay: { mocks: withPayment(3) } },
  play: async ({ canvasElement }) => {
    await expect(await items(canvasElement)).toContain("Retry charge");
  },
};

/** A hold from the old flow, ready to capture. */
export const LegacyHold: Story = {
  args: { isAdmin: true, chargesEnabled: true },
  parameters: { relay: { mocks: withPayment(0) } },
  play: async ({ canvasElement }) => {
    await expect(await items(canvasElement)).toContain("Capture payment");
  },
};

/** Charged: the organizer can refund. */
export const Charged: Story = {
  args: { isAdmin: true, chargesEnabled: true },
  parameters: { relay: { mocks: withPayment(1) } },
  play: async ({ canvasElement }) => {
    await expect(await items(canvasElement)).toContain("Refund payment");
  },
};

/** Charging a card that is declined: the error shows under the chip. */
export const ChargeDeclined: Story = {
  args: { isAdmin: true, chargesEnabled: true },
  parameters: {
    relay: {
      mocks: {
        ...withPayment(5),
        CapturePaymentResult: { errors: [{ message: "Your card was declined." }] },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const body = await openMenu(canvasElement);
    await userEvent.click(body.getByRole("menuitem", { name: "Charge payment" }));
    const canvas = within(canvasElement);
    await waitFor(() => expect(canvas.getByText("Your card was declined.")).toBeVisible());
  },
};

/** "Remove from event" asks for confirmation. */
export const ConfirmRemove: Story = {
  args: { isAdmin: true },
  play: async ({ canvasElement }) => {
    const body = await openMenu(canvasElement);
    await userEvent.click(body.getByRole("menuitem", { name: "Remove from event" }));
    // The dialog fades in.
    const title = await body.findByText("Remove this RSVP");
    await waitFor(() => expect(title).toBeVisible());
  },
};
