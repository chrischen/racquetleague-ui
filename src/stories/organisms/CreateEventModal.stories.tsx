import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import { shiftClock, viewerUser } from "./StoryFixturesDiscovery.gen";
import { make as CreateEventModalStory, query } from "./CreateEventModalStory.gen";

// The create-event form as a modal over the current page. It is a thin shell:
// the `create` search param opens a RouteModal around CreateEventPage.Body
// (the AI assistant band, the club and activity selector, the event form) and
// the rest of the query string is the form's prefill, so these stories set
// the URL with `parameters.router`. The venue field searches Google Places,
// which isn't loaded in Storybook, so a venue appears only when the URL
// carries its id. The clock is Wednesday 14 October 2026 in Tokyo.
const ACTIVITIES = [
  { id: "act-badminton", name: "badminton", slug: "badminton" },
  { id: "act-pickleball", name: "pickleball", slug: "pickleball" },
];
const club = (id: string, name: string) => ({ node: { id, name, defaultActivity: { id: "act-pickleball" } } });

const meta = {
  title: "Organisms/CreateEventModal",
  component: CreateEventModalStory,
  beforeEach: shiftClock,
  parameters: {
    layout: "fullscreen",
    router: { url: "/?create=1" },
    relay: {
      query,
      variables: { locationId: "" },
      mocks: {
        Query: { viewer: {}, activities: ACTIVITIES },
        Viewer: signedInViewer({
          user: { ...viewerUser, stripeChargesEnabled: true },
          profile: { ...viewerUser, stripeChargesEnabled: true },
          adminClubs: {
            edges: [club("club-tpc", "Tokyo Pickleball Club"), club("club-spc", "Shibuya Pickleball Club")],
          },
        }),
      },
    },
  },
} satisfies Meta<typeof CreateEventModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const formReady = async (canvasElement: HTMLElement) => {
  const body = within(canvasElement.ownerDocument.body);
  const dialog = await body.findByRole("dialog");
  await waitFor(() => expect(dialog).toBeVisible());
  // The body waits for its message catalog, then for its page query.
  await body.findByRole("region", { name: "AI-assisted event form" }, { timeout: 5000 });
  return body;
};

/** Opened from "Create Event Manually": an empty form. */
export const Blank: Story = {
  play: async ({ canvasElement }) => {
    await formReady(canvasElement);
  },
};

/** Opened from a day's "Host event" on a club schedule: the club, the day and
 * the drafted 7–9 PM window, and the venue, carried in the URL. */
export const FromAvailabilityWindow: Story = {
  parameters: {
    router: {
      url: "/?create=1&clubId=club-tpc&activitySlug=pickleball&date=2026-10-15&startHour=19&endHour=21&locationId=loc-minato",
    },
    relay: {
      variables: { locationId: "loc-minato" },
      mocks: {
        Query: {
          location: { name: "Minato Sports Center", details: "4 indoor courts on B1. Bring indoor shoes." },
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const body = await formReady(canvasElement);
    const summary = await body.findByText(/Minato Sports Center · Thu, Oct 15/);
    await waitFor(() => expect(summary).toBeVisible());
  },
};

/** A copy of an existing event ("Copy event" on its page): every field
 * carried over, private, with its price and cancel deadline. */
export const CopiedEvent: Story = {
  parameters: {
    router: {
      url:
        "/?create=1&clubId=club-spc&activitySlug=pickleball&title=Wednesday%20Night%20Doubles" +
        "&details=Rated%20doubles%2C%20rotating%20partners.&maxRsvps=8&tags=3.5%2B%2Ccomp&listed=false" +
        "&price=1500&cancelDeadline=86400000&timezone=Asia%2FTokyo" +
        "&startDateTime=2026-10-21T19%3A00&endTime=21%3A00",
    },
  },
  play: async ({ canvasElement }) => {
    const body = await formReady(canvasElement);
    const title = await body.findByText("Wednesday Night Doubles");
    await waitFor(() => expect(title).toBeVisible());
    await expect(body.getByDisplayValue("1500")).toBeInTheDocument();
  },
};
