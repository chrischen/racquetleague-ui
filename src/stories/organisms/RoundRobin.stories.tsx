import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { make as RoundRobinStory } from "./RoundRobinStory.gen";

// The standalone round-robin tool (/round-robin): EventManager's layout with
// no event behind it. Every player is a walk-in typed in by name (default
// rating, so no seeds or avatars), nothing is saved, and draws come from the
// synchronous greedy engine, so Generate works in Storybook. It always starts
// empty; each story's play function adds a Saturday social's players and, where
// its name says so, draws the rounds. The draw is randomised, so the pairings
// differ from run to run.
const meta = {
  title: "Organisms/RoundRobin",
  component: RoundRobinStory,
  parameters: { layout: "fullscreen" },
  args: { debug: false },
} satisfies Meta<typeof RoundRobinStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const PLAYERS = [
  "Kenji Tanaka",
  "Yuki Sato",
  "Chris Chen",
  "Aiko Suzuki",
  "Hiroshi Watanabe",
  "Emily Parker",
  "Takumi Ito",
  "Mai Yamamoto",
  "Daniel Kim",
  "Haruka Nakamura",
  "Sota Kobayashi",
  "Sarah Johnson",
  "Ren Kato",
  "Naomi Yoshida",
];

const body = (canvasElement: HTMLElement) => within(canvasElement.ownerDocument.body);

// Opens "Add guest" and pastes the names, one per line.
const typeNames = async (canvasElement: HTMLElement, names: string[]) => {
  const canvas = within(canvasElement);
  await userEvent.click(await canvas.findByRole("button", { name: /Add guest/ }));
  const box = await body(canvasElement).findByRole("textbox");
  await userEvent.click(box);
  await userEvent.paste(names.join("\n"));
};

const addPlayers = async (canvasElement: HTMLElement) => {
  await typeNames(canvasElement, PLAYERS);
  await userEvent.click(await body(canvasElement).findByRole("button", { name: `Add ${PLAYERS.length} Guests` }));
  await within(canvasElement).findByText(`${PLAYERS.length} of ${PLAYERS.length} checked in`);
};

const generate = async (canvasElement: HTMLElement) => {
  const canvas = within(canvasElement);
  await userEvent.click(canvas.getByRole("button", { name: "Generate" }));
  await expect(await canvas.findByText("ACTIVE ROUND")).toBeVisible();
};

/** Nobody yet: the empty check-in panel and a generator waiting for players. */
export const Empty: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("0 of 0 checked in")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Generate" })).toBeDisabled();
  },
};

/** "Add guest" with fourteen names pasted in, before adding them. */
export const AddingPlayers: Story = {
  play: async ({ canvasElement }) => {
    await typeNames(canvasElement, PLAYERS);
    await expect(await body(canvasElement).findByText(`Preview (${PLAYERS.length} guests)`)).toBeVisible();
  },
};

/** Fourteen players added and checked in: three courts, ready to generate. */
export const PlayersCheckedIn: Story = {
  play: async ({ canvasElement }) => {
    await addPlayers(canvasElement);
    await waitFor(() => expect(within(canvasElement).getByRole("button", { name: "Generate" })).toBeEnabled());
  },
};

/** Round 1 drawn and active, ten rounds ahead, two players sitting out each round. */
export const RoundOne: Story = {
  play: async ({ canvasElement }) => {
    await addPlayers(canvasElement);
    await generate(canvasElement);
    await expect(within(canvasElement).getByRole("button", { name: /Advance to Round 2/ })).toBeVisible();
  },
};

/** Debug on after drawing: overall match quality, per-court quality and μ/σ under every name. */
export const DebugRounds: Story = {
  args: { debug: true },
  play: async ({ canvasElement }) => {
    await addPlayers(canvasElement);
    await generate(canvasElement);
    await expect(within(canvasElement).getByText("Overall Match Quality Across All Rounds")).toBeVisible();
  },
};
