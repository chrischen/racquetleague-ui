import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, within } from "storybook/test";
import { FIXED_DATETIME } from "../../../dev/scenario/engine.mjs";
import { make as DuprConnectCardStory, query } from "./DuprConnectCardStory.gen";

// The DUPR card on profile settings. Which body it shows depends on whether
// the profile has a DUPR link and whether the server offers an SSO URL
// (null when DUPR is not configured on the deployment).
const meta = {
  title: "Organisms/DuprConnectCard",
  component: DuprConnectCardStory,
  args: { onChanged: fn() },
} satisfies Meta<typeof DuprConnectCardStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const SSO_URL = "https://uat.dupr.gg/login-external-app/example";

export const NotLinked: Story = {
  parameters: {
    relay: { query, scenario: "new-user", mocks: { Query: { duprSsoUrl: SSO_URL } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Not linked")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Log in with DUPR" })).toBeEnabled();
  },
};

/** Doubles established, singles still provisional. */
export const Linked: Story = {
  parameters: {
    relay: {
      query,
      scenario: "new-user",
      mocks: {
        Query: { duprSsoUrl: SSO_URL },
        User: {
          dupr: {
            duprId: "0Y9K2L",
            doubles: 4.12,
            singles: 3.87,
            doublesReliable: true,
            singlesReliable: false,
            // DUPR's 0-100 reliability score; 20 and up counts as established.
            doublesReliability: 64,
            syncedAt: FIXED_DATETIME,
          },
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Linked")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Disconnect DUPR" })).toBeVisible();
  },
};

/** No SSO URL from the server: the card explains instead of offering a dead button. */
export const Unavailable: Story = {
  parameters: {
    relay: { query, scenario: "new-user", mocks: { Query: { duprSsoUrl: null } } },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("DUPR linking isn't available right now.")).toBeVisible();
    await expect(canvas.queryByRole("button", { name: "Log in with DUPR" })).toBeNull();
  },
};
