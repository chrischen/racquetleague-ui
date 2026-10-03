import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { connection, rsvps, rsvpsFrom } from "./StoryFixturesEvent.gen";
import { availabilityDays, recommendations } from "./StoryFixturesEventPage.gen";
import { make as EventInvitesStory, query } from "./EventInvitesStory.gen";

// The Invites strip at the bottom of the event's Participants card
// (PkRSVPSection): invites the organizer already sent ("sent" chips), then,
// for the organizer only, players worth inviting. Suggestions from the ranking
// pass lead, marked with sparkles and their DUPR ("~" when provisional);
// players whose stored availability covers the event follow ("invite").
// Clicking a suggestion offers the profile or an invite with a note; "Swipe
// invites" reviews them one card at a time. Nobody already on the event, and
// not the organizer, is suggested. Thursday 15 October 2026, 19:00-21:00.
const SENT = rsvpsFrom(12, 2).map((r) => ({ ...r, listType: 2 }));
const SOURCES = {
  inviteRecommendations: recommendations(5),
  availabilityUsersForDay: availabilityDays("2026-10-15"),
};

const meta = {
  title: "Organisms/EventInvites",
  component: EventInvitesStory,
  args: { canInvite: true, viewerId: "user-kenji" },
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { event: {}, ...SOURCES },
        Event: { rsvps: connection([...rsvps(8), ...SENT]) },
      },
    },
  },
} satisfies Meta<typeof EventInvitesStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// The deck and its cards fade in, so wait for them to show.
const visible = (el: HTMLElement) => waitFor(() => expect(el).toBeVisible());

/** Two sent, five ranked suggestions and three more available players. */
export const Suggestions: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Invites · 10")).toBeVisible();
    await expect(canvas.getAllByText("sent")).toHaveLength(2);
    await expect(canvas.getByText("~4.12")).toBeVisible();
  },
};

/** No ranking available: only players whose availability covers the event. */
export const AvailabilityOnly: Story = {
  parameters: { relay: { mocks: { Query: { inviteRecommendations: { recommendations: [] } } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Invites · 8")).toBeVisible();
  },
};

/** Nobody stored availability for the day: suggestions only. */
export const RecommendationsOnly: Story = {
  parameters: { relay: { mocks: { Query: { availabilityUsersForDay: [] } } } },
};

/** A player's view: only the invites already sent, no suggestions. */
export const PlayerView: Story = {
  args: { canInvite: false, viewerId: "user-1" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Invites · 2")).toBeVisible();
    await expect(canvas.queryByRole("button", { name: /potential players/ })).toBeNull();
  },
};

/** A suggestion's menu: view the profile or send an invite. */
export const SuggestionMenu: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: "Open invite actions for Ryo" }));
    await expect(await canvas.findByRole("menuitem", { name: "Send invite" })).toBeVisible();
    await expect(canvas.getByRole("menuitem", { name: "View Profile" })).toBeVisible();
  },
};

/** "Send invite" asks for the note the invite email carries. */
export const ComposeInvite: Story = {
  parameters: { layout: "fullscreen" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(await canvas.findByRole("button", { name: "Open invite actions for はるか" }));
    await userEvent.click(await canvas.findByRole("menuitem", { name: "Send invite" }));
    const dialog = await body.findByRole("dialog", { name: "Invite はるか" });
    await waitFor(() => expect(dialog).toBeVisible());
  },
};

/** "Swipe invites" reviews the suggestions as cards. */
export const SwipeDeck: Story = {
  parameters: { layout: "fullscreen" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const body = within(canvasElement.ownerDocument.body);
    await userEvent.click(await canvas.findByRole("button", { name: "Review 8 potential players with swipe cards" }));
    await visible(await body.findByRole("dialog", { name: "Invite players" }));
  },
};
