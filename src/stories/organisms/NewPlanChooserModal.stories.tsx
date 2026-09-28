import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import { viewerUser } from "./StoryFixturesDiscovery.gen";
import { make as NewPlanChooserModalStory, query } from "./NewPlanChooserModalStory.gen";

// The "New plan" modal behind the top bar's New event button and the phone
// tab bar's New: "Create Event Manually" hands over to CreateEventModal; below
// it, how to create events by email: forward a court booking confirmation to
// pkuru (or book with your personal pkuru address) and sync the calendar feed
// the new events land in. The addresses come from the viewer, fetched when the
// modal opens (NewPlanChooserModalQuery).
const FORWARDING = "events@in.pkuru.com";
const INBOX = "chris.7k2m@in.pkuru.com";

// The modal fades in; wait until it is shown before asserting on its content.
const openDialog = async (canvasElement: HTMLElement) => {
  const body = within(canvasElement.ownerDocument.body);
  const dialog = await body.findByRole("dialog");
  await waitFor(() => expect(dialog).toBeVisible());
  return body;
};

const meta = {
  title: "Organisms/NewPlanChooserModal",
  component: NewPlanChooserModalStory,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: { viewer: {} },
        Viewer: signedInViewer({
          user: viewerUser,
          profile: viewerUser,
          eventsForwardingAddress: FORWARDING,
          eventsInboxAddress: INBOX,
        }),
      },
    },
  },
  args: { onClose: fn(), onCreateEvent: fn() },
} satisfies Meta<typeof NewPlanChooserModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Both ways in by email: forward from your own address, or book with your
 * personal pkuru address. "Create Event Manually" hands over. */
export const BothAddresses: Story = {
  play: async ({ canvasElement, args }) => {
    const body = await openDialog(canvasElement);
    await expect(await body.findByText(INBOX)).toBeVisible();
    await userEvent.click(body.getByRole("button", { name: /Create Event Manually/ }));
    await expect(args.onCreateEvent).toHaveBeenCalled();
  },
};

/** No personal booking address yet (no email on the account, or inbound
 * email not configured): only the forwarding step. */
export const ForwardingOnly: Story = {
  parameters: { relay: { mocks: { Viewer: { eventsInboxAddress: null } } } },
  play: async ({ canvasElement }) => {
    const body = await openDialog(canvasElement);
    await expect(await body.findByText(FORWARDING)).toBeVisible();
    await expect(body.queryByText(INBOX)).toBeNull();
  },
};

/** "Sync calendar" opens the Apple and Google choices inline. */
export const SyncCalendarMenu: Story = {
  play: async ({ canvasElement }) => {
    const body = await openDialog(canvasElement);
    await userEvent.click(await body.findByRole("button", { name: /Sync calendar/ }));
    await expect(await body.findByRole("link", { name: /Google/ })).toBeVisible();
  },
};

/** Signed out: the email steps need an account, so only the manual button. */
export const SignedOut: Story = {
  parameters: { relay: { query, mocks: { Query: { viewer: null } } } },
  play: async ({ canvasElement }) => {
    const body = await openDialog(canvasElement);
    await expect(await body.findByRole("button", { name: /Create Event Manually/ })).toBeVisible();
    await expect(body.queryByText(FORWARDING)).toBeNull();
  },
};
