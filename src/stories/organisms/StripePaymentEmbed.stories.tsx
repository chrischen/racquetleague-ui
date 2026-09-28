import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as StripePaymentEmbedStory } from "./StripePaymentEmbedStory.gen";

// The card sheet a player sees when joining a priced event: Stripe's Payment
// Element inside the app's own sheet. "setup" saves the card for the organizer
// to charge after the event (the flow in use); "payment" charges it now.
// Stripe itself is replaced by a stand-in (see StripePaymentEmbedStory.res):
// no Stripe.js, no network, a labelled skeleton where the card fields go, and
// `outcome` decides how confirming the card turns out.
const meta = {
  title: "Organisms/StripePaymentEmbed",
  component: StripePaymentEmbedStory,
  parameters: { layout: "fullscreen" },
  argTypes: {
    mode: { control: "inline-radio", options: ["setup", "payment"] },
    outcome: { control: "select", options: ["saves", "declines", "failsSilently", "hangs", "blocked"] },
  },
  args: { mode: "setup", outcome: "saves", amountLabel: "¥1,500", onSuccess: fn(), onClose: fn() },
} satisfies Meta<typeof StripePaymentEmbedStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const confirmButton = (canvasElement: HTMLElement, name: string) =>
  within(canvasElement).findByRole("button", { name });

/** Saving a card for a ¥1,500 event: the notice says nothing is charged yet,
 * and a saved card reports its SetupIntent. */
export const SaveCard: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/The organizer will charge ¥1,500 later/)).toBeVisible();
    const save = await confirmButton(canvasElement, "Save card");
    await waitFor(() => expect(save).toBeEnabled());
    await userEvent.click(save);
    await waitFor(() => expect(args.onSuccess).toHaveBeenCalledWith("seti_1StoryFixture0000000000"));
  },
};

/** No fee on the event yet: the notice speaks of "the participation fee".
 * Cancel (or a tap outside the sheet) closes it. */
export const SaveCardNoAmount: Story = {
  args: { amountLabel: undefined },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/the participation fee later/)).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Cancel" }));
    await expect(args.onClose).toHaveBeenCalledTimes(1);
  },
};

/** While Stripe confirms: both buttons locked, "Processing…". */
export const Processing: Story = {
  args: { outcome: "hangs" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const save = await confirmButton(canvasElement, "Save card");
    await waitFor(() => expect(save).toBeEnabled());
    await userEvent.click(save);
    await expect(await canvas.findByRole("button", { name: "Processing…" })).toBeDisabled();
    await expect(canvas.getByRole("button", { name: "Cancel" })).toBeDisabled();
  },
};

/** Stripe's own message for a declined card, under the form. */
export const CardDeclined: Story = {
  args: { outcome: "declines" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const save = await confirmButton(canvasElement, "Save card");
    await waitFor(() => expect(save).toBeEnabled());
    await userEvent.click(save);
    await expect(await canvas.findByText("Your card was declined.")).toBeVisible();
    await expect(args.onSuccess).not.toHaveBeenCalled();
  },
};

/** Paying now, on the organizer's connected account: no notice. */
export const PayNow: Story = {
  args: { mode: "payment" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { name: "Complete payment" })).toBeVisible();
    await expect(await confirmButton(canvasElement, "Pay now")).toBeVisible();
  },
};

/** A payment error without a message falls back to "Payment failed". */
export const PaymentFailed: Story = {
  args: { mode: "payment", outcome: "failsSilently" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const pay = await confirmButton(canvasElement, "Pay now");
    await waitFor(() => expect(pay).toBeEnabled());
    await userEvent.click(pay);
    await expect(await canvas.findByText("Payment failed")).toBeVisible();
  },
};

/** Stripe.js never loaded (blocked by the network or an extension): no card
 * fields, and Save stays disabled with nothing telling the player why. */
export const StripeBlocked: Story = {
  args: { outcome: "blocked" },
  play: async ({ canvasElement }) => {
    await expect(await confirmButton(canvasElement, "Save card")).toBeDisabled();
  },
};
