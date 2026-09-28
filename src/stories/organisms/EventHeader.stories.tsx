import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, within } from "storybook/test";
import { endDate, startDate } from "./StoryFixturesEvent.gen";
import { make as EventHeaderStory, query } from "./EventHeaderStory.gen";

// The top of the event page: activity / title, club, tags (a level tag, or
// "all level" when none; "Private" when unlisted), then the date, time range
// and duration, and the venue. The relative time ("in N days") counts from
// now, so it changes from day to day. A signed-in viewer also gets the
// add-to-calendar menu.
const EVENT = {
  title: "Thursday Night Rated Doubles",
  startDate,
  endDate,
  timezone: "Asia/Tokyo",
  tags: ["comp", "3.5+"],
  listed: true,
  deleted: null,
  shadow: false,
  activity: { name: "Pickleball", slug: "pickleball" },
  club: { name: "Tokyo Pickleball Club", slug: "tokyo-pickleball" },
  location: { id: "loc-minato", name: "Minato Sports Center" },
};

const meta = {
  title: "Organisms/EventHeader",
  component: EventHeaderStory,
  parameters: {
    layout: "fullscreen",
    relay: { query, mocks: { Query: { event: {} }, Event: EVENT } },
  },
} satisfies Meta<typeof EventHeaderStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A rated 3.5+ session: two hours on a Thursday evening. */
export const Rated: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/Thursday Night Rated Doubles/)).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Minato Sports Center" })).toHaveAttribute(
      "href",
      expect.stringContaining("/locations/loc-minato"),
    );
  },
};

/** Recreational, no level tag (so "all level" is added), 90 minutes. */
export const Recreational: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          title: "Sunday Morning Open Play",
          tags: ["rec"],
          startDate: "2026-10-18T00:00:00.000Z",
          endDate: "2026-10-18T01:30:00.000Z",
          location: { id: "loc-shibuya", name: "Shibuya Ward Gym, Sub Arena" },
        },
      },
    },
  },
};

/** Unlisted: the "Private" tag warns players not to share it. */
export const Private: Story = {
  parameters: { relay: { mocks: { Event: { title: "Club members' ladder night", listed: false, tags: ["comp", "4.0+"] } } } },
};

/** Canceled: struck through, with a CANCELED prefix. */
export const Canceled: Story = {
  parameters: { relay: { mocks: { Event: { deleted: "2026-10-12T03:00:00.000Z" } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("CANCELED")).toBeVisible();
  },
};

/** A shadow event (mirrored from elsewhere): the venue is not a link. */
export const ShadowEvent: Story = {
  parameters: { relay: { mocks: { Event: { shadow: true } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Minato Sports Center")).toBeVisible();
    await expect(canvas.queryByRole("link", { name: "Minato Sports Center" })).toBeNull();
  },
};

/** Nothing set yet: every fallback (Event, Date TBD, Time TBD, Unknown club and location). */
export const Unscheduled: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          title: null,
          startDate: null,
          endDate: null,
          tags: null,
          activity: null,
          club: null,
          location: null,
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Date TBD")).toBeVisible();
    await expect(canvas.getByText("Unknown location")).toBeVisible();
  },
};

/** A long title, club and venue with many tags, on a phone (Storybook's
    viewport toolbar; the header's breakpoints follow the window). */
export const LongTitleMobile: Story = {
  globals: { viewport: { value: "mobile1", isRotated: false } },
  parameters: {
    relay: {
      mocks: {
        Event: {
          title: "Tokyo Pickleball Club × Yokohama Dinkers Inter-club Mixed Doubles Round Robin (Beginners Welcome!)",
          tags: ["comp", "dupr", "3.0+", "drill"],
          club: { name: "Yokohama Minato Mirai Pickleball Association", slug: "yokohama-dinkers" },
          location: { id: "loc-yokohama", name: "Yokohama Cultural Gymnasium, Main Arena (横浜文化体育館)" },
        },
      },
    },
  },
};

/** Signed in: the calendar icon opens the feed menu. */
export const SignedIn: Story = {
  parameters: { relay: { scenario: "new-user", mocks: { User: { lineUsername: "Chris" } } } },
  play: async ({ canvasElement }) => {
    const body = within(canvasElement.ownerDocument.body);
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button"));
    await expect(await body.findByText("Google Calendar")).toBeVisible();
  },
};
