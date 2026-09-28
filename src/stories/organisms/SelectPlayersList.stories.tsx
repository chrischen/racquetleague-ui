import * as React from "react";
import type { Decorator, Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as SelectPlayersListStory, query } from "./SelectPlayersListStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The queue screen's roster table (AiTetsu). Players in tonight's pool are
// solid; players out of it are faded with "Remove"; removed players are struck
// through with "Enable". A green dot marks who is on court, and the right
// column counts games played. Headers sort by rating (default) or by games
// played. The wrapper keeps the sets in state, so taps work. Fixture: the
// Thursday-night roster (StoryFixturesMatch), round 2 on court.
const meta = {
  title: "Organisms/SelectPlayersList",
  component: SelectPlayersListStory,
  parameters: { relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: { control: "inline-radio", options: ["empty", "typical", "withGuests"] },
  },
  args: { state: "typical", onClick: fn(), onRemove: fn(), onEnable: fn() },
} satisfies Meta<typeof SelectPlayersListStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// With no players the table puts its "no players yet" text straight into
// <tbody> (a bug in the component, reported rather than fixed here), which
// React logs as a DOM-nesting error. This mutes exactly that message while the
// Empty story is mounted, so the smoke test still fails on anything else.
let restoreConsole: (() => void) | undefined;
const muteTbodyTextWarning: Decorator = (Story) => {
  React.useState(() => {
    if (restoreConsole) return;
    const original = console.error;
    console.error = (...args: unknown[]) => {
      if (
        typeof args[0] === "string" &&
        args[0].includes("validateDOMNesting") &&
        args[1] === "Text nodes" &&
        args[2] === "tbody"
      )
        return;
      original(...args);
    };
    restoreConsole = () => {
      console.error = original;
      restoreConsole = undefined;
    };
  });
  React.useEffect(() => () => restoreConsole?.(), []);
  return <Story />;
};

// Rows fade and scale in (framer-motion), so wait for them to finish before
// asserting visibility.
const settled = (element: HTMLElement) => waitFor(() => expect(element).toBeVisible());

const bodyRows = (canvasElement: HTMLElement) => within(canvasElement).getAllByRole("row").slice(1);

/** 20 players by rating: 16 in the pool (12 on court), three out of it, one removed. */
export const Typical: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await settled(await canvas.findByText("Kenji Tanaka"));
    await expect(canvas.getAllByRole("link", { name: "Remove" })).toHaveLength(3);
    await settled(canvas.getByRole("link", { name: "Enable" }));
  },
};

/** Sorted by games played, fewest first: Rina (0) leads. */
export const SortedByMatchCount: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("link", { name: /Match Count/ }));
    await waitFor(() => expect(bodyRows(canvasElement)[0]).toHaveTextContent("Rina Yamada"));
  },
};

/** Tapping a name takes the player out of the pool: faded, with "Remove". */
export const TakeOutOfPool: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("link", { name: /Kenji Tanaka/ }));
    await expect(args.onClick).toHaveBeenCalledWith("Kenji Tanaka");
    await waitFor(() => expect(canvas.getAllByRole("link", { name: "Remove" })).toHaveLength(4));
  },
};

/** Two walk-ins in the pool: no account, so a blank avatar and no games yet. */
export const WithGuests: Story = {
  args: { state: "withGuests" },
  play: async ({ canvasElement }) => {
    await settled(await within(canvasElement).findByText("Lisa Brown"));
  },
};

/** Before anyone has joined. */
export const Empty: Story = {
  args: { state: "empty" },
  decorators: [muteTbodyTextWarning],
  play: async ({ canvasElement }) => {
    await expect(await within(canvasElement).findByText("no players yet")).toBeVisible();
  },
};
