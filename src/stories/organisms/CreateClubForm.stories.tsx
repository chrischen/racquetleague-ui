import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as CreateClubFormStory, query } from "./CreateClubFormStory.gen";

// The inline "new club" form (from the event form's club picker and the club
// selector): name, description, default activity and the club URL, which
// follows the name until edited by hand. Create stays disabled until there
// is a name and a URL.
const ACTIVITIES = [
  { id: "act-badminton", name: "badminton", slug: "badminton" },
  { id: "act-pickleball", name: "pickleball", slug: "pickleball" },
  { id: "act-table-tennis", name: "table tennis", slug: "table-tennis" },
  { id: "act-futsal", name: "futsal", slug: "futsal" },
];

const meta = {
  title: "Organisms/CreateClubForm",
  component: CreateClubFormStory,
  parameters: { relay: { query, mocks: { Query: { activities: ACTIVITIES } } } },
  args: { onCancel: fn(), onCreated: fn() },
} satisfies Meta<typeof CreateClubFormStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Blank, with pickleball preselected as the default activity. */
export const Empty: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByLabelText("Default club activity")).toHaveValue("act-pickleball");
    await expect(canvas.getByRole("button", { name: "Create Club" })).toBeDisabled();
  },
};

/** Typing a name fills in the URL slug and enables Create. */
export const Filled: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(canvas.getByLabelText("Club Name"), "Meguro Morning Dinkers!");
    await userEvent.type(
      canvas.getByLabelText("Description"),
      "Casual doubles every Saturday 8:00–10:00 at Meguro Pickleball Park. All levels welcome.",
    );
    await expect(canvas.getByLabelText("Club URL")).toHaveValue("meguro-morning-dinkers");
    await expect(canvas.getByRole("button", { name: "Create Club" })).toBeEnabled();
  },
};

/** Without pickleball in the list, the first activity is the default. */
export const NoPickleball: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: { activities: ACTIVITIES.filter((a) => a.slug !== "pickleball") },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByLabelText("Default club activity")).toHaveValue("act-badminton");
  },
};
