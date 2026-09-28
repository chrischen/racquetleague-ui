import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, within } from "storybook/test";
import { connection, rsvps, rsvpsFrom } from "./StoryFixturesEvent.gen";
import { make as PendingRsvpsStory, query } from "./PendingRsvpsStory.gen";

// The Pending list on the classic event page's RSVP card: join requests the
// organizer has not admitted (listType other than 0), each an EventRsvp. On a
// Smart RSVP event the organizer can preview which requests the next run would
// admit; those are ringed in green. Renders nothing when nobody is pending.
const pending = rsvpsFrom(7, 5).map((r) => ({ ...r, listType: 1 }));

const meta = {
  title: "Organisms/PendingRsvps",
  component: PendingRsvpsStory,
  args: { activitySlug: "pickleball" },
  argTypes: { activitySlug: { control: "inline-radio", options: ["pickleball", "badminton"] } },
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { event: {} },
        Event: { price: null, viewerIsAdmin: false, rsvps: connection([...rsvps(6), ...pending]) },
      },
    },
  },
} satisfies Meta<typeof PendingRsvpsStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Five requests waiting (the six going players are not listed here). */
export const Pending: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading")).toHaveTextContent("Pending (5)");
    await expect(canvas.queryByText("Yuki")).toBeNull();
  },
};

/** A Smart RSVP preview: two requests the next run would admit. */
export const WouldBeAdmitted: Story = {
  args: { previewAdmittedIds: [pending[0].id, pending[2].id] },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByText("Would be admitted")).toHaveLength(2);
  },
};

/** The organizer's menu on a pending request offers to approve it. */
export const OrganizerApproves: Story = {
  parameters: { relay: { mocks: { Event: { viewerIsAdmin: true } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(canvas.getByText("Lucas"));
    await expect(await body.findByRole("menuitem", { name: "Approve RSVP" })).toBeVisible();
  },
};

/** Nobody pending: nothing renders. */
export const NoneWaiting: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection(rsvps(6)) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByRole("heading")).toBeNull();
  },
};
