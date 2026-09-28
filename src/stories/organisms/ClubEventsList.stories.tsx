import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import {
  clubEvents,
  courtDays,
  eventsConnection,
  picklrClub,
  picklrEvents,
  playerAvailability,
  shiftClock,
  tokyoClub,
  viewerAvailability,
  viewerEvents,
  viewerUser,
} from "./StoryFixturesDiscovery.gen";
import { make as ClubEventsListStory, query } from "./ClubEventsListStory.gen";

// A club's schedule (ClubEventsListPage): the compact calendar, the open
// spots / level filter bar, then a block per day with the day's availability
// row, scoped to the club's members, and the club's events. On a club page
// the day trigger reads "Add to <day>", and the editor's "Host event" opens
// the create form for that window. A location club (Picklr) hosts open play
// on the spot instead, so its editor also picks the level. The clock is
// Wednesday 14 October 2026, 09:00 in Tokyo.
const PICKLEBALL = "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61";

const VIEWER = signedInViewer({
  user: viewerUser,
  profile: viewerUser,
  clubs: { edges: [{ node: { id: tokyoClub.id } }] },
  availability: viewerAvailability,
  events: eventsConnection(viewerEvents, false),
});

const meta = {
  title: "Organisms/ClubEventsList",
  component: ClubEventsListStory,
  beforeEach: shiftClock,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: {
          viewer: {},
          club: { ...tokyoClub, defaultActivity: { id: PICKLEBALL }, events: eventsConnection(clubEvents, false) },
          availabilityUsersForDateRange: playerAvailability,
          locationsAvailability: courtDays,
        },
        Viewer: VIEWER,
      },
    },
  },
} satisfies Meta<typeof ClubEventsListStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A member's view of Tokyo Pickleball Club's fortnight. */
export const MemberView: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Club Ladder Night")).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Add to today/ })).toBeVisible();
  },
};

/** Signed out: the same schedule, with Join on every row. */
export const SignedOut: Story = {
  parameters: { relay: { mocks: { Query: { viewer: null } } } },
};

/** A location club: open play at its home court, six players a session. The
 * day editor picks the level of the session "Host event" creates. */
export const LocationClub: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          club: { ...picklrClub, defaultActivity: { id: PICKLEBALL }, events: eventsConnection(picklrEvents, false) },
          locationsAvailability: [],
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: /Add to saturday/ }));
    const legend = await canvas.findByText("Skill level");
    await waitFor(() => expect(legend).toBeVisible());
  },
};

/** Nothing on the schedule yet. */
export const NoEvents: Story = {
  parameters: {
    relay: { mocks: { Query: { club: { ...tokyoClub, events: eventsConnection([], false) } } } },
  },
};

/** One venue picked on the map: the others' events dim. */
export const VenuePicked: Story = {
  args: { selectedLocationId: "loc-minato" },
};
