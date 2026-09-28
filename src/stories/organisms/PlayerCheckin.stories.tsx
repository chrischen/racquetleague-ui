import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as PlayerCheckinStory, query } from "./PlayerCheckinStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The check-in panel at the top of the event manager. Tiles run strongest
// first: green when checked in, a play count, a trend badge for how far the
// rating has moved tonight, and a "$" that turns green when the court fee is
// paid. The header opens team management and the seeding modal; the last
// tiles add walk-ins or show a join QR code. The panel starts open while
// fewer than four are checked in, otherwise collapsed. The wrapper keeps
// check-ins and payments in state, so taps work.
const meta = {
  title: "Organisms/PlayerCheckin",
  component: PlayerCheckinStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: { control: "inline-radio", options: ["empty", "arriving", "underway", "withGuests"] },
  },
  args: {
    state: "underway",
    clubEvent: false,
    onToggleCheckin: fn(),
    onTogglePaid: fn(),
    onAdjustSeeds: fn(),
    onOpenTeamManagement: fn(),
    onOpenPlayerSettings: fn(),
    onOpenAddGuests: fn(),
    onUseClubRatings: fn(),
  },
} satisfies Meta<typeof PlayerCheckinStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// Tiles fade and scale in (framer-motion), so wait for them to finish before
// asserting visibility.
const settled = (element: HTMLElement) => waitFor(() => expect(element).toBeVisible());

const openPanel = async (canvasElement: HTMLElement) => {
  const canvas = within(canvasElement);
  await userEvent.click(await canvas.findByRole("button", { name: /Player Check-in/ }));
  await canvas.findByText("Kenji Tanaka");
  return canvas;
};

/** Two rounds in with 16 of 20 checked in: the panel starts collapsed. */
export const Collapsed: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("16 of 20 checked in")).toBeVisible();
    await expect(canvas.queryByText("Kenji Tanaka")).toBeNull();
  },
};

/** Opened: checked-in and absent tiles, play counts, rating trends, and five players yet to pay. */
export const Underway: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await openPanel(canvasElement);
    await expect(canvas.getAllByTitle("Not paid")).toHaveLength(5);
    await settled(canvas.getByText("3.2"));
  },
};

/** Doors just opened: three here, nobody has played or paid, so the panel starts open. */
export const Arriving: Story = {
  args: { state: "arriving" },
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("3 of 20 checked in")).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: /Yuki Sato/ }));
    await expect(args.onToggleCheckin).toHaveBeenCalledWith("user-yuki");
    await expect(await canvas.findByText("4 of 20 checked in")).toBeVisible();
  },
};

/** Two walk-ins added at the desk: checked in, unpaid, initials instead of a picture. */
export const WithGuests: Story = {
  args: { state: "withGuests" },
  play: async ({ canvasElement }) => {
    const canvas = await openPanel(canvasElement);
    await expect(canvas.getByText("18 of 22 checked in")).toBeVisible();
    await settled(canvas.getByText("#9001"));
  },
};

/** Marking a fee paid turns the "$" green. */
export const MarkPaid: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = await openPanel(canvasElement);
    await userEvent.click(canvas.getAllByTitle("Not paid")[0]);
    await expect(args.onTogglePaid).toHaveBeenCalled();
    await waitFor(() => expect(canvas.getAllByTitle("Not paid")).toHaveLength(4));
  },
};

/** No RSVPs and no walk-ins yet: just the add-guest and invite tiles. */
export const Empty: Story = {
  args: { state: "empty" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("0 of 0 checked in")).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Add guest/ })).toBeVisible();
  },
};

/** The seeding button opens the seed modal; at a club event it offers the club's ratings. */
export const SeedModalAtClubEvent: Story = {
  args: { clubEvent: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByTitle("Adjust player seeds"));
    await expect(await canvas.findByText("Adjust Player Seeds")).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Shibuya Pickleball Club ratings/ })).toBeVisible();
  },
};

/** "Invite player" shows a full-screen QR code to the event page. */
export const InviteQrCode: Story = {
  args: { state: "arriving" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: /Invite player/ }));
    await expect(await canvas.findByText("Scan to check in")).toBeVisible();
  },
};
