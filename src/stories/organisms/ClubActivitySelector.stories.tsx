import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as ClubActivitySelectorStory, query } from "./ClubActivitySelectorStory.gen";

// The "Club & Activity" field on the create/edit event forms. Collapsed, it
// is a summary button ("Club • activity"); opened, two selects for the clubs
// the viewer administers (or none) and the activity, plus "+ Add new club..."
// which swaps in the inline CreateClubForm. Starts from the `new-user` dev
// scenario, whose viewer administers no clubs.
const ACTIVITIES = [
  { id: "act-badminton", name: "badminton", slug: "badminton" },
  { id: "act-pickleball", name: "pickleball", slug: "pickleball" },
  { id: "act-table-tennis", name: "table tennis", slug: "table-tennis" },
];

const club = (id: string, name: string, activityId: string) => ({
  node: { id, name, defaultActivity: { id: activityId } },
});

const ADMIN_CLUBS = {
  edges: [
    club("club-shibuya", "Shibuya Pickleball Club", "act-pickleball"),
    club("club-meguro-shuttle", "Meguro Shuttle Society", "act-badminton"),
    club("club-yokohama", "Yokohama Bay Dinkers", "act-pickleball"),
  ],
};

const meta = {
  title: "Organisms/ClubActivitySelector",
  component: ClubActivitySelectorStory,
  parameters: {
    relay: {
      query,
      scenario: "new-user",
      mocks: { Query: { activities: ACTIVITIES }, Viewer: { adminClubs: ADMIN_CLUBS } },
    },
  },
  args: { onChange: fn() },
} satisfies Meta<typeof ClubActivitySelectorStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Collapsed on the viewer's first club and pickleball. */
export const WithClubs: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Shibuya Pickleball Club")).toBeVisible();
    await expect(args.onChange).toHaveBeenCalledWith({
      clubId: "club-shibuya",
      activityId: "act-pickleball",
      isAddingClub: false,
    });
  },
};

/** An organiser with no clubs: an independent event. */
export const NoClubs: Story = {
  parameters: { relay: { mocks: { Viewer: { adminClubs: { edges: [] } } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("No club")).toBeVisible();
  },
};

/** Opened, editing a badminton club's event. */
export const Expanded: Story = {
  args: { initialClubId: "club-meguro-shuttle", initialActivitySlug: "badminton" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Meguro Shuttle Society/ }));
    await expect(await canvas.findByLabelText("Club")).toHaveValue("club-meguro-shuttle");
    await expect(canvas.getByLabelText("Activity")).toHaveValue("act-badminton");
  },
};

/** "+ Add new club..." swaps the selects for the create-club form. */
export const AddingClub: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Shibuya Pickleball Club/ }));
    await userEvent.selectOptions(await canvas.findByLabelText("Club"), "__add_new__");
    await expect(await canvas.findByLabelText("Club Name")).toBeVisible();
    await waitFor(() =>
      expect(args.onChange).toHaveBeenLastCalledWith({
        clubId: undefined,
        activityId: "act-pickleball",
        isAddingClub: true,
      }),
    );
  },
};
