import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import { endDate, startDate } from "./StoryFixturesEvent.gen";
import { make as UpdateLocationEventFormStory, query } from "./UpdateLocationEventFormStory.gen";

// The event form on /events/update/:eventId/:locationId and
// /events/copy/:eventId/:locationId: the club and activity picker, then
// CreateLocationEventForm prefilled from the event, at its venue. Editing
// keeps the event's date and saves over it; copying keeps the time of day on
// today's date and creates a new event, with the viewer's own Stripe account
// deciding whether fees can be charged. The organizer administers two clubs.
const ACTIVITIES = [
  { id: "act-badminton", name: "badminton", slug: "badminton" },
  { id: "act-pickleball", name: "pickleball", slug: "pickleball" },
];
const ADMIN_CLUBS = {
  edges: [
    { node: { id: "club-shibuya", name: "Shibuya Pickleball Club", defaultActivity: { id: "act-pickleball" } } },
    { node: { id: "club-meguro", name: "Meguro Shuttle Society", defaultActivity: { id: "act-badminton" } } },
  ],
};

// A club's weekly paid session at Ariake, Thursday 15 October 2026, 19:00-21:00.
const EVENT = {
  title: "Thursday Night Doubles",
  details: "Courts 3 and 4 on the second floor. Indoor shoes only.\nBalls provided (Franklin X-40).",
  maxRsvps: 12,
  minRating: null,
  activity: { id: "act-pickleball", name: "pickleball", slug: "pickleball" },
  club: { id: "club-shibuya" },
  startDate,
  endDate,
  listed: true,
  timezone: "Asia/Tokyo",
  tags: [],
  price: 1500,
  cancelDeadline: 86_400_000,
  smartRsvpThreshold: null,
  chargesEnabled: false,
};

const meta = {
  title: "Organisms/UpdateLocationEventForm",
  component: UpdateLocationEventFormStory,
  args: { isCopy: false, viewerStripeChargesEnabled: false },
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: { location: {}, event: {}, viewer: {}, activities: ACTIVITIES },
        Viewer: signedInViewer({ userId: "user-kenji", adminClubs: ADMIN_CLUBS }),
        User: { lineUsername: "Kenji W.", locale: "en" },
        Location: {
          name: "Ariake Tennis Forest Park",
          details: "Indoor courts on the second floor; the entrance is by the east car park.",
        },
        Event: EVENT,
      },
    },
  },
} satisfies Meta<typeof UpdateLocationEventFormStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Editing a club's ¥1,500 session; the club collects no fees through
    Stripe, so attendees only save a card. */
export const EditClubEvent: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const update = await canvas.findByRole("button", { name: "Update event" });
    await waitFor(() => expect(update).toBeVisible());
    // The collapsed "Event details" header summarises the title.
    await expect(canvas.getByRole("button", { name: /^Event details.*Thursday Night Doubles/ })).toBeVisible();
  },
};

// Opens one of the form's collapsed sections by its title.
const openSection = async (canvasElement: HTMLElement, title: string) => {
  const canvas = within(canvasElement);
  await userEvent.click(await canvas.findByRole("button", { name: new RegExp(`^${title}`) }));
  return canvas;
};

/** The "Event details" section opened: title and notes as saved. */
export const EditDetailsOpen: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await openSection(canvasElement, "Event details");
    const title = await canvas.findByDisplayValue("Thursday Night Doubles");
    await waitFor(() => expect(title).toBeVisible());
  },
};

/** The club's Stripe account can charge, so the organizer can collect fees. */
export const EditWithStripe: Story = {
  parameters: { relay: { mocks: { Event: { chargesEnabled: true } } } },
};

/** A competitive event with a level floor and Smart RSVP admitting players. */
export const EditCompetitiveSmartRsvp: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: { title: "DUPR 3.5+ Ladder Night", tags: ["comp"], minRating: 26.5, smartRsvpThreshold: 0.05, maxRsvps: 16 },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = await openSection(canvasElement, "Players");
    await waitFor(() => expect(canvas.getByText("Hold RSVPs")).toBeVisible());
  },
};

/** An independent, free, unlisted event with no cancellation deadline. */
export const EditIndependentFreeEvent: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          title: "Friends hit at Shibaura",
          details: null,
          club: null,
          price: null,
          cancelDeadline: null,
          listed: false,
          maxRsvps: 8,
        },
      },
    },
  },
};

/** Copying: the same settings, on today's date, as a new event. */
export const CopyEvent: Story = {
  args: { isCopy: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const create = await canvas.findByRole("button", { name: "Create event" });
    await waitFor(() => expect(create).toBeVisible());
  },
};

/** Copying, with "Location & time" open: today's date at the source time. */
export const CopyScheduleOpen: Story = {
  args: { isCopy: true },
  play: async ({ canvasElement }) => {
    const canvas = await openSection(canvasElement, "Location & time");
    await waitFor(() => expect(canvas.getByDisplayValue("19:00")).toBeVisible());
  },
};

/** Copying as an organizer whose own Stripe account can charge. */
export const CopyWithStripe: Story = {
  args: { isCopy: true, viewerStripeChargesEnabled: true },
};
