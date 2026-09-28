import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { signedInViewer } from "../../../dev/scenarios/_shared.mjs";
import { make as CreateLocationEventFormStory, query } from "./CreateLocationEventFormStory.gen";
import { shiftClock } from "./StoryFixturesDiscovery.gen";

// The create-event form, drawn as /events/create draws it: the "Club &
// Activity" selector, then the form in accordion sections (Location & time,
// Event details, a Paid event toggle, Format, Players) and Create event. A new
// event opens on Location & time with today's date and a two-hour window from
// the current hour (the clock is fixed at 14 October 2026 here). Values the
// event assistant filled in collapse their sections behind a green border and
// a check. With a fee, two panels say what happens without and with a Stripe
// account; which one is Active follows the organiser's own Stripe account.
// Without a venue the Location field is the Google Places search, which does
// not load in Storybook: its input shows, but it never suggests anything.
const ACTIVITIES = [
  { id: "act-pickleball", name: "pickleball", slug: "pickleball" },
  { id: "act-badminton", name: "badminton", slug: "badminton" },
];
const ADMIN_CLUBS = {
  edges: [
    { node: { id: "club-shibuya", name: "Shibuya Pickleball Club", defaultActivity: { id: "act-pickleball" } } },
    { node: { id: "club-meguro", name: "Meguro Shuttle Society", defaultActivity: { id: "act-badminton" } } },
  ],
};

const meta = {
  title: "Organisms/CreateLocationEventForm",
  component: CreateLocationEventFormStory,
  beforeEach: shiftClock,
  parameters: {
    layout: "fullscreen",
    relay: {
      query,
      mocks: {
        Query: { location: {}, viewer: {}, activities: ACTIVITIES },
        Viewer: signedInViewer({ userId: "user-kenji", adminClubs: ADMIN_CLUBS }),
        User: { lineUsername: "Kenji W.", locale: "en" },
        Location: {
          name: "Ariake Tennis Forest Park",
          details:
            "Indoor courts on the second floor; the entrance is by the east car park. Four pickleball courts are taped over the tennis lines on weekday evenings.",
        },
      },
    },
  },
  argTypes: {
    prefill: { control: "inline-radio", options: ["none", "draft", "paidDraft"] },
  },
  args: {
    prefill: "none",
    withVenue: true,
    stripeChargesEnabled: false,
    onLocationSelected: fn(),
    onClubFormSubmitBlocked: fn(),
  },
} satisfies Meta<typeof CreateLocationEventFormStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const ready = async (canvasElement: HTMLElement) => {
  const canvas = within(canvasElement);
  const create = await canvas.findByRole("button", { name: "Create event" });
  // The form slides in.
  await waitFor(() => expect(create).toBeVisible());
  return canvas;
};

// Opens one of the form's collapsed sections by its title.
const openSection = async (canvasElement: HTMLElement, title: string) => {
  const canvas = within(canvasElement);
  await userEvent.click(canvas.getByRole("button", { name: new RegExp(`^${title}`) }));
};

/** A new event at a venue, for the organiser's club: the schedule open on today's date. */
export const NewClubEvent: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await expect(canvas.getByText("Ariake Tennis Forest Park")).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Shibuya Pickleball Club/ })).toBeVisible();
  },
};

/** An organiser with no clubs: an independent event, with just the activity above the form. */
export const IndependentEvent: Story = {
  parameters: { relay: { mocks: { Viewer: { adminClubs: { edges: [] } } } } },
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await expect(canvas.getByText("No club")).toBeVisible();
  },
};

/** No venue yet: the Location field is the venue search (Google Places, which does not load here). */
export const ChoosingVenue: Story = {
  args: { withVenue: false },
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await expect(canvas.getByRole("combobox")).toBeVisible();
  },
};

/** Submitted empty: the first section with an error opens and says what is missing. */
export const ValidationErrors: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Create event" }));
    await expect(await canvas.findByText("title is required")).toBeVisible();
  },
};

/** Everything valid but no venue chosen: the schedule opens with "Choose a location". */
export const MissingVenue: Story = {
  args: { withVenue: false, prefill: "draft" },
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Create event" }));
    await expect(await canvas.findByText("Choose a location for this event")).toBeVisible();
  },
};

/** The event assistant's draft: sections collapsed behind green borders, each summarising what it filled in. */
export const AssistantDraft: Story = {
  args: { prefill: "draft" },
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await expect(canvas.getByText("Draft filled in. Review the details before creating the event.")).toBeVisible();
    await expect(canvas.getByRole("button", { name: /^Players.*Public · Up to 16 players/ })).toBeVisible();
  },
};

/** The draft's Players section opened: public, 3.5+ with its minimum rating, RSVPs held, 16 players, 12-hour cancel deadline. */
export const DraftPlayersSection: Story = {
  args: { prefill: "draft" },
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await openSection(canvasElement, "Players");
    await expect(await canvas.findByText("This event is public")).toBeVisible();
    await expect(canvas.getByLabelText(/Hold RSVPs/)).toBeChecked();
  },
};

/** The draft's Format section opened: competitive and DUPR rated. */
export const DraftFormatSection: Story = {
  args: { prefill: "draft" },
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await openSection(canvasElement, "Format");
    await expect(await canvas.findByRole("button", { name: "DUPR rated" })).toHaveAttribute("aria-pressed", "true");
  },
};

/** A ¥1,500 fee without a Stripe account: cards are saved at RSVP but can't be charged; a link to connect one. */
export const PaidWithoutStripe: Story = {
  args: { prefill: "paidDraft" },
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await expect(canvas.getByLabelText(/Participation fee/)).toHaveValue(1500);
    await expect(canvas.getByRole("link", { name: "Connect a Stripe account to enable this" })).toBeVisible();
  },
};

/** The same fee with the organiser's Stripe account connected: the charge-later panel is the active one. */
export const PaidWithStripe: Story = {
  args: { prefill: "paidDraft", stripeChargesEnabled: true },
  play: async ({ canvasElement }) => {
    const canvas = await ready(canvasElement);
    await expect(canvas.queryByRole("link", { name: "Connect a Stripe account to enable this" })).toBeNull();
  },
};

/** "+ Add new club..." left open: Create event is refused and the club field shakes until the club is saved. */
export const ClubFormBlocksSubmit: Story = {
  args: { prefill: "draft" },
  play: async ({ args, canvasElement }) => {
    const canvas = await ready(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Shibuya Pickleball Club/ }));
    await userEvent.selectOptions(await canvas.findByLabelText("Club"), "__add_new__");
    await expect(await canvas.findByLabelText("Club Name")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Create event" }));
    await waitFor(() => expect(args.onClubFormSubmitBlocked).toHaveBeenCalled());
  },
};
