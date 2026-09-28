import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { make as ReceivingEmailsCardStory, query } from "./ReceivingEmailsCardStory.gen";

// The "Receiving emails" card on profile settings: the account email and the
// alternates a player receives booking confirmations at, each confirmed or
// awaiting confirmation, with forms to add one or change the account email.
// Changing the account email goes through better-auth, which these stories
// don't reach; adding, resending and removing are answered by the mocks.
const meta = {
  title: "Organisms/ReceivingEmailsCard",
  component: ReceivingEmailsCardStory,
  parameters: {
    relay: {
      query,
      scenario: "new-user",
      mocks: {
        User: {
          email: "kenji.watanabe@example.jp",
          alternateEmails: [
            { address: "kenji@shibuya-pickleball.jp", verified: true },
            { address: "k.watanabe@rakuten-mail.jp", verified: false },
          ],
        },
      },
    },
  },
} satisfies Meta<typeof ReceivingEmailsCardStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The account email plus one confirmed and one unconfirmed alternate. */
export const ConfirmedAndPending: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Account email")).toBeVisible();
    await expect(canvas.getByText("Confirmed")).toBeVisible();
    await expect(canvas.getByText("Awaiting confirmation")).toBeVisible();
    // Only the unconfirmed address offers Resend.
    await expect(canvas.getAllByRole("button", { name: "Resend" })).toHaveLength(1);
  },
};

/** Just the account email, nothing added yet. */
export const AccountEmailOnly: Story = {
  parameters: { relay: { mocks: { User: { alternateEmails: [] } } } },
};

/** No account email: the explainer says the first confirmed address becomes it. */
export const NoAccountEmail: Story = {
  parameters: {
    relay: {
      mocks: {
        User: { email: null, alternateEmails: [{ address: "kenji.w@docomo.ne.jp", verified: false }] },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(
      await canvas.findByText(
        "Your account has no email yet. The first address you confirm here becomes your account email.",
      ),
    ).toBeVisible();
    await expect(canvas.queryByRole("button", { name: "Change" })).toBeNull();
  },
};

/** The five-alternate maximum, with long addresses (they truncate on narrow screens). */
export const ManyAddresses: Story = {
  parameters: {
    relay: {
      mocks: {
        User: {
          email: "kenji.watanabe.shibuya.pickleball.organiser@example-company.co.jp",
          alternateEmails: [
            { address: "kenji@shibuya-pickleball.jp", verified: true },
            { address: "reservations+court-bookings-2026@setagaya-sports-center.tokyo.jp", verified: true },
            { address: "k.watanabe@rakuten-mail.jp", verified: false },
            { address: "watanabe.kenji@icloud.com", verified: true },
            { address: "kenji.w@docomo.ne.jp", verified: false },
          ],
        },
      },
    },
  },
};

/** "Change" on the account email opens the new-address form. */
export const ChangeAccountEmail: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Change" }));
    const input = await canvas.findByLabelText("New account email");
    await userEvent.type(input, "kenji.new@example.jp");
    await expect(canvas.getByRole("button", { name: "Send link" })).toBeEnabled();
  },
};

/** After adding an address: the notice asks the player to open the link. */
export const ConfirmationSent: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(await canvas.findByLabelText("Add a receiving email"), "Kenji.Bookings@example.jp");
    await userEvent.click(canvas.getByRole("button", { name: "Add" }));
    await expect(await canvas.findByText(/We sent a confirmation link to kenji.bookings@example.jp/)).toBeVisible();
  },
};

/** "Remove" asks for confirmation first. */
export const RemoveConfirmation: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click((await canvas.findAllByRole("button", { name: "Remove" }))[0]);
    const body = within(canvasElement.ownerDocument.body);
    // The dialog fades in.
    const title = await body.findByText("Remove this receiving email?");
    await waitFor(() => expect(title).toBeVisible());
  },
};
