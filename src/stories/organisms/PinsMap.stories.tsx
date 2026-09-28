import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, waitFor } from "storybook/test";
import wrapperSource from "../../wrapper.tsx?raw";
import { make as PinsMapStory, query } from "./PinsMapStory.gen";

// The events map: a pin per event at its venue (events at the same venue
// stack), the selected venue's pin enlarged in green, cooperative gestures
// (Ctrl/Cmd + scroll to zoom). It is a real Google map, loaded the way the app
// loads it: the story reads the app's browser key from src/wrapper.tsx, which
// has no export for it. Map tiles need the network.
const mapsApiKey = /GOOGLE_MAPS_API_KEY = "([^"]+)"/.exec(wrapperSource)?.[1] ?? "";

const venues = {
  minato: { id: "loc-minato", address: "1-16-13 Shibaura, Minato City, Tokyo", coords: { lat: 35.6453, lng: 139.7527 } },
  tokyoGym: { id: "loc-tokyo-gym", address: "1-17-1 Sendagaya, Shibuya City, Tokyo", coords: { lat: 35.6812, lng: 139.7125 } },
  shibuya: { id: "loc-shibuya", address: "1-40-18 Nishihara, Shibuya City, Tokyo", coords: { lat: 35.6784, lng: 139.6832 } },
  ariake: { id: "loc-ariake", address: "2-2-22 Ariake, Koto City, Tokyo", coords: { lat: 35.638, lng: 139.789 } },
  toyosu: { id: "loc-toyosu", address: "6-1-23 Toyosu, Koto City, Tokyo", coords: { lat: 35.6456, lng: 139.7843 } },
  komazawa: { id: "loc-komazawa", address: "1-1 Komazawakoen, Setagaya City, Tokyo", coords: { lat: 35.6254, lng: 139.6617 } },
  shinagawa: { id: "loc-shinagawa", address: "2-18-1 Konan, Minato City, Tokyo", coords: { lat: 35.6284, lng: 139.7387 } },
};

const event = (id: string, startDate: string, location: object | null) => ({ node: { id, startDate, location } });
const events = [
  event("evt-1", "2026-10-15T10:00:00.000Z", venues.minato),
  event("evt-2", "2026-10-17T01:00:00.000Z", venues.minato),
  event("evt-3", "2026-10-22T10:00:00.000Z", venues.minato),
  event("evt-4", "2026-10-16T09:30:00.000Z", venues.tokyoGym),
  event("evt-5", "2026-10-18T00:00:00.000Z", venues.tokyoGym),
  event("evt-6", "2026-10-16T11:00:00.000Z", venues.shibuya),
  event("evt-7", "2026-10-18T02:00:00.000Z", venues.ariake),
  event("evt-8", "2026-10-19T10:00:00.000Z", venues.toyosu),
  event("evt-9", "2026-10-21T10:00:00.000Z", venues.toyosu),
  event("evt-10", "2026-10-24T01:00:00.000Z", venues.komazawa),
  event("evt-11", "2026-10-20T10:30:00.000Z", venues.shinagawa),
  // An online meetup: no venue, so no pin.
  event("evt-12", "2026-10-23T11:00:00.000Z", null),
];

const meta = {
  title: "Organisms/PinsMap",
  component: PinsMapStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { events: { edges: events } } } } },
  argTypes: { mapsApiKey: { table: { disable: true } } },
  args: { mapsApiKey, onLocationClick: fn() },
} satisfies Meta<typeof PinsMapStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const pinsAppear = (canvasElement: HTMLElement, count: number) =>
  waitFor(() => expect(canvasElement.querySelectorAll("gmp-advanced-marker").length).toBe(count), { timeout: 20000 });

/** A week of events across Tokyo; venues with several events stack pins. */
export const TokyoVenues: Story = {
  play: async ({ canvasElement }) => pinsAppear(canvasElement, 11),
};

/** The venue hovered or picked in the list: its pins enlarged in green. */
export const SelectedVenue: Story = {
  args: { selected: "loc-toyosu" },
  play: async ({ canvasElement }) => pinsAppear(canvasElement, 11),
};

/** No events in range: just the map. */
export const NoEvents: Story = {
  parameters: { relay: { mocks: { Query: { events: { edges: [] } } } } },
};
