import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, waitFor, within } from "storybook/test";
import { FIXED_DATETIME } from "../../../dev/scenario/engine.mjs";
import { make as SettingsProfileFormStory, query } from "./SettingsProfileFormStory.gen";

// The profile settings page body: the profile form (display name, full name,
// gender, biography, level), then the notifications, receiving emails, DUPR
// and Stripe Connect cards. Stories start from the `new-user` dev scenario
// (dev/scenarios/new-user.mjs) with a filled-in profile; the Stripe card has
// three states (not connected, onboarding pending, active), and a linked DUPR
// account replaces the level picker. The form fades and slides in (Framer
// Motion), so assertions on visibility wait for it.
const SSO_URL = "https://uat.dupr.gg/login-external-app/example";
const STRIPE_ACCOUNT = "acct_1QfT3kPkuruJP7Xy";

const meta = {
  title: "Organisms/SettingsProfileForm",
  component: SettingsProfileFormStory,
  parameters: {
    relay: {
      query,
      scenario: "new-user",
      mocks: {
        Query: { duprSsoUrl: SSO_URL },
        User: {
          lineUsername: "Kenji",
          fullName: "Kenji Watanabe",
          email: "kenji.watanabe@example.jp",
          biography:
            "Weeknight doubles around Shibuya and Meguro, Saturday mornings at Toyosu. Third-shot drop enthusiast, still working on my backhand dink.",
          gender: "male",
          // Internal scale; 30.5 is about DUPR 3.75.
          selfRating: 30.5,
          alternateEmails: [{ address: "kenji@shibuya-pickleball.jp", verified: true }],
          stripeAccountId: null,
          stripeChargesEnabled: false,
        },
      },
    },
  },
} satisfies Meta<typeof SettingsProfileFormStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A complete profile with no Stripe account: paid events are collected at the venue. */
export const StripeNotConnected: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await waitFor(() => expect(canvas.getByLabelText("Display Name")).toHaveValue("Kenji"));
    await waitFor(() => expect(canvas.getByText("Not connected")).toBeVisible());
    await expect(canvas.getByRole("button", { name: "Connect Stripe account" })).toBeEnabled();
  },
};

/** Account created, onboarding unfinished: the button resumes it. */
export const StripePending: Story = {
  parameters: {
    relay: { mocks: { User: { stripeAccountId: STRIPE_ACCOUNT, stripeChargesEnabled: false } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const status = await canvas.findByText("Pending");
    await waitFor(() => expect(status).toBeVisible());
    await expect(canvas.getByRole("button", { name: "Resume onboarding" })).toBeVisible();
    await expect(canvas.getByText(STRIPE_ACCOUNT)).toBeVisible();
  },
};

/** Charges enabled: no country picker or button, just the status. */
export const StripeActive: Story = {
  parameters: {
    relay: { mocks: { User: { stripeAccountId: STRIPE_ACCOUNT, stripeChargesEnabled: true } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const status = await canvas.findByText("Active");
    await waitFor(() => expect(status).toBeVisible());
    await expect(canvas.queryByRole("button", { name: /Connect Stripe account|Resume onboarding/ })).toBeNull();
  },
};

/** A linked DUPR account: the level picker gives way to the DUPR rating. */
export const DuprLinked: Story = {
  parameters: {
    relay: {
      mocks: {
        User: {
          dupr: {
            duprId: "0Y9K2L",
            doubles: 4.12,
            singles: 3.87,
            doublesReliable: true,
            singlesReliable: false,
            doublesReliability: 64,
            syncedAt: FIXED_DATETIME,
          },
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const note = await canvas.findByText(
      "Your rating comes from DUPR. Disconnect DUPR below to set your own level again.",
    );
    await waitFor(() => expect(note).toBeVisible());
  },
};

/** A new account: every field blank, no level, no email on file. */
export const EmptyProfile: Story = {
  parameters: {
    relay: {
      mocks: {
        User: {
          lineUsername: "",
          fullName: null,
          email: null,
          biography: "",
          gender: null,
          selfRating: null,
          alternateEmails: [],
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const hint = await canvas.findByText("Your self-reported skill level");
    await waitFor(() => expect(hint).toBeVisible());
    await expect(canvas.getByLabelText("Display Name")).toHaveValue("");
  },
};
