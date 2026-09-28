import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { make as MediaListStory, query } from "./MediaListStory.gen";

// A venue's videos (Location.media), embedded under the location details on
// the event page, each with its title above a 300x300 player. The embeds
// point at inline placeholder pages rather than YouTube so the stories render
// offline; the app stores YouTube embed URLs here.
const placeholder = (label: string) =>
  "data:text/html;charset=utf-8," +
  encodeURIComponent(
    `<body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;` +
      `background:#0f0f0f;color:#f1f1f1;font:14px system-ui">▶ ${label}</body>`,
  );

const meta = {
  title: "Organisms/MediaList",
  component: MediaListStory,
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { location: {} },
        Location: {
          media: [{ id: "media-1", title: "How to find the 5F arena", url: placeholder("How to find the 5F arena") }],
        },
      },
    },
  },
} satisfies Meta<typeof MediaListStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** One walkthrough video. */
export const OneVideo: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("How to find the 5F arena")).toBeVisible();
    await expect(canvas.getByTitle("YouTube video player")).toBeVisible();
  },
};

/** Several videos, one untitled, and one with no URL (skipped). */
export const SeveralVideos: Story = {
  parameters: {
    relay: {
      mocks: {
        Location: {
          media: [
            { id: "media-1", title: "How to find the 5F arena", url: placeholder("How to find the 5F arena") },
            { id: "media-2", title: "Court 2 from the gallery", url: placeholder("Court 2 from the gallery") },
            { id: "media-3", title: null, url: placeholder("Untitled clip") },
            { id: "media-4", title: "Not uploaded yet", url: null },
          ],
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getAllByTitle("YouTube video player")).toHaveLength(3);
    await expect(canvas.queryByText("Not uploaded yet")).toBeNull();
  },
};

/** Most venues have no media: nothing renders. */
export const Empty: Story = {
  parameters: { relay: { mocks: { Location: { media: null } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByTestId("media-list")).toBeEmptyDOMElement();
  },
};
