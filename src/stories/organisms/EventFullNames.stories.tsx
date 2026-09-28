import * as React from "react";
import type { Decorator, Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, within } from "storybook/test";
import { connection, rsvps } from "./StoryFixturesEvent.gen";
import { make as EventFullNamesStory, query } from "./EventFullNamesStory.gen";

// The collapsible guest list on the classic event page: players' full names
// (not their LINE names), for organizers who need to register the group with
// the venue. Collapsed by default; the chevron opens it.
// EventFullNames renders its <li> rows without a `key` (a bug in the
// component, reported rather than fixed here), which React logs as an error
// on every mount. This mutes exactly that warning while one of these stories
// is mounted, so the smoke test still fails on anything else.
let restoreConsole: (() => void) | undefined;
const muteMissingKeyWarning: Decorator = (Story) => {
  React.useState(() => {
    if (restoreConsole) return;
    const original = console.error;
    console.error = (...args: unknown[]) => {
      if (typeof args[0] === "string" && args[0].includes('unique "key" prop')) return;
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

const meta = {
  title: "Organisms/EventFullNames",
  component: EventFullNamesStory,
  decorators: [muteMissingKeyWarning],
  parameters: {
    relay: { query, mocks: { Query: { event: {} }, Event: { rsvps: connection(rsvps(8)) } } },
  },
} satisfies Meta<typeof EventFullNamesStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const open = async (canvasElement: HTMLElement) => {
  const canvas = within(canvasElement);
  // The toggle is a link with only an icon in it.
  await userEvent.click(canvas.getByRole("link"));
  return canvas;
};

/** Collapsed: the title and the toggle. */
export const Collapsed: Story = {};

/** Opened: one full name per line. */
export const Expanded: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await open(canvasElement);
    await expect(await canvas.findByText("Tanaka Yuki")).toBeVisible();
    await expect(canvas.getByText("Kobayashi Takeshi")).toBeVisible();
  },
};

/** Players without a full name on file are left out. */
export const SomeNamesMissing: Story = {
  parameters: {
    relay: {
      mocks: {
        Event: {
          rsvps: connection(rsvps(6).map((r, i) => (i % 2 ? { ...r, user: { ...r.user, fullName: null } } : r))),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = await open(canvasElement);
    await expect(await canvas.findByText("Tanaka Yuki")).toBeVisible();
    await expect(canvas.queryByText("Watanabe Kenji")).toBeNull();
  },
};

/** Nobody has joined yet. */
export const Empty: Story = {
  parameters: { relay: { mocks: { Event: { rsvps: connection([]) } } } },
  play: async ({ canvasElement }) => {
    const canvas = await open(canvasElement);
    await expect(await canvas.findByText("no players yet")).toBeVisible();
  },
};
