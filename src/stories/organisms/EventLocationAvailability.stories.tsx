import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { endDate, startDate } from "./StoryFixturesEvent.gen";
import { make as EventLocationAvailabilityStory, query } from "./EventLocationAvailabilityStory.gen";

// Court availability at the event's venue, for its organizer, inside the
// expanded location card: whether a court covers the event's whole window
// (Thursday 15 October 2026, 19:00-21:00 in Tokyo) and, when one doesn't,
// other same-day times at the venue and nearby venues free at the event's
// hours. Picking one moves the event, after a second tap to confirm, since it
// reschedules everyone who RSVP'd. Availability is scraped from the venues'
// booking sites, mostly as day-level opening hours; some venues name their
// courts, with a surface and price each.

// One venue-day from the scraper (Event.courtAvailability entry).
type Interval = [number, number];
const day = (
  location: { id: string; name: string },
  intervals: Interval[],
  opts: { courts?: unknown[]; indoor?: number; outdoor?: number; price?: number } = {},
) => ({
  id: `avail-${location.id}-2026-10-15`,
  localDate: "2026-10-15",
  link: `https://yoyaku.sports.metro.tokyo.lg.jp/${location.id}`,
  location,
  intervals: intervals.map(([startHour, endHour]) => ({ startHour, endHour })),
  // Per-hour rollup: courts free in each open hour.
  hourly: intervals.flatMap(([from, to]) =>
    Array.from({ length: to - from }, (_, i) => ({
      hour: from + i,
      indoorCount: opts.indoor ?? 0,
      outdoorCount: opts.outdoor ?? 2,
      priceMin: opts.price ?? 1300,
      priceMax: opts.price ?? 1300,
    })),
  ),
  courts: opts.courts ?? [],
});

const ARIAKE = { id: "loc-ariake", name: "Ariake Tennis Forest Park" };
const SHINONOME = { id: "loc-shinonome", name: "Shinonome Sports Center" };
const TATSUMI = { id: "loc-tatsumi", name: "Tatsumi Forest Seaside Park" };

// Everything the move needs (updateEvent replaces the whole event).
const EVENT = {
  title: "Thursday Night Doubles",
  details: "Courts 3 and 4. Indoor shoes only.",
  startDate,
  endDate,
  timezone: "Asia/Tokyo",
  listed: true,
  tags: [],
  maxRsvps: 12,
  minRating: null,
  cancelDeadline: 86_400_000,
  price: 1500,
  smartRsvpThreshold: null,
  activity: { id: "act-pickleball" },
  club: null,
  location: { id: ARIAKE.id },
};

const meta = {
  title: "Organisms/EventLocationAvailability",
  component: EventLocationAvailabilityStory,
  args: { genericCourtName: "Courts" },
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { event: {} },
        Event: {
          ...EVENT,
          courtAvailability: [day(ARIAKE, [[9, 12], [17, 22]])],
        },
      },
    },
  },
} satisfies Meta<typeof EventLocationAvailabilityStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const expand = async (canvasElement: HTMLElement) => {
  const canvas = within(canvasElement);
  await userEvent.click(canvas.getByRole("button", { expanded: false }));
  return canvas;
};

/** A court covers the event: a green "Available" row, collapsed. */
export const Available: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Available")).toBeVisible();
  },
};

/** Opened: the venue's courts over the event's hours. */
export const AvailableExpanded: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await expand(canvasElement);
    await waitFor(() => expect(canvas.getByText("At Ariake Tennis Forest Park now")).toBeVisible());
  },
};

/** A venue that names its courts, each with a surface and an hourly price. */
export const NamedCourts: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          courtAvailability: [
            day(ARIAKE, [[9, 13], [18, 22]], {
              courts: [
                { name: "Court 1", courtType: "indoor", price: 2200, intervals: [{ startHour: 18, endHour: 22 }] },
                { name: "Court 2", courtType: "indoor", price: 2200, intervals: [{ startHour: 19, endHour: 21 }] },
                { name: "Court 7 (omni)", courtType: "outdoor", price: 1300, intervals: [{ startHour: 9, endHour: 13 }] },
              ],
            }),
          ],
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = await expand(canvasElement);
    await waitFor(() => expect(canvas.getAllByText(/Court 1/)[0]).toBeVisible());
  },
};

/** No court at the venue covers 19:00-21:00: other times that day, and two
    nearby venues free at the event's hours. */
export const NotAvailableWithAlternatives: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          courtAvailability: [
            day(ARIAKE, [[9, 12], [13, 17]]),
            day(SHINONOME, [[18, 22]], { indoor: 3, outdoor: 0, price: 2640 }),
            day(TATSUMI, [[19, 21]], { outdoor: 4, price: 1100 }),
          ],
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Not available")).toBeVisible();
    await expand(canvasElement);
    await waitFor(() => expect(canvas.getByText("Other times at Ariake Tennis Forest Park")).toBeVisible());
    await expect(canvas.getByText("Other locations at this time")).toBeVisible();
  },
};

/** Moving asks for a second tap: the chosen option says "Confirm move". */
export const ConfirmMove: Story = {
  parameters: NotAvailableWithAlternatives.parameters,
  play: async ({ canvasElement }) => {
    const canvas = await expand(canvasElement);
    const [useLocation] = await canvas.findAllByRole("button", { name: /Use location/ });
    await userEvent.click(useLocation);
    await waitFor(() =>
      expect(canvas.getByText(/This moves the event to another venue and reschedules everyone/)).toBeVisible(),
    );
    await expect(canvas.getByRole("button", { name: /Confirm move/ })).toBeVisible();
  },
};

/** Nothing works that day: no court at the event's hours, no other two-hour
    slot at the venue, and no nearby venue. */
export const NoAlternatives: Story = {
  parameters: { relay: { mocks: { Event: { courtAvailability: [day(ARIAKE, [[9, 10], [15, 16]])] } } } },
  play: async ({ canvasElement }) => {
    const canvas = await expand(canvasElement);
    await waitFor(() =>
      expect(canvas.getByText(/No other same-day time at Ariake Tennis Forest Park/)).toBeVisible(),
    );
    await expect(canvas.getByText(/No other nearby venue has a court free/)).toBeVisible();
  },
};
