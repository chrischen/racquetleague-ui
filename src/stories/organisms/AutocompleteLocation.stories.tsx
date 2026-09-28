import * as React from "react";
import type { Decorator, Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as AutocompleteLocationStory } from "./AutocompleteLocationStory.gen";
import { pending } from "../support";

// The venue search on the event and location forms: type, pick a suggestion
// (arrow keys and Enter work too), and the venue is saved as a Location whose
// id the form keeps. Suggestions come from Google Places in the app; here a
// stand-in for the Places SDK answers from a fixed list of Tokyo venues (no
// network, no API key), and the save goes through the mocked
// autocompleteLocation mutation.
const meta = {
  title: "Organisms/AutocompleteLocation",
  component: AutocompleteLocationStory,
  argTypes: {
    places: { control: "inline-radio", options: ["answers", "unavailable", "notLoaded"] },
  },
  args: { places: "answers", onSelected: fn(), onSelectedDetails: fn() },
  parameters: {
    relay: {
      mocks: {
        // The saved Location echoes the picked place, as the backend's upsert does.
        Mutation: {
          autocompleteLocation: (_: unknown, args: { input: { mapsId: string; name: string } }) => ({
            location: { id: `loc-${args.input.mapsId}`, name: args.input.name },
          }),
        },
      },
    },
  },
} satisfies Meta<typeof AutocompleteLocationStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const search = (canvasElement: HTMLElement) => within(canvasElement).getByRole("combobox");

// The component logs the Places failure before showing its message; expected
// in that story, so exactly that message is muted there.
const mutePlacesFailure: Decorator = (Story) => {
  const [restore] = React.useState(() => {
    const original = console.error;
    console.error = (...args: unknown[]) => {
      if (args[0] === "Places autocomplete failed") return;
      original(...args);
    };
    return () => {
      console.error = original;
    };
  });
  React.useEffect(() => restore, [restore]);
  return <Story />;
};

/** Nothing typed yet. */
export const Idle: Story = {
  play: async ({ canvasElement }) => {
    await expect(search(canvasElement)).toHaveAttribute("placeholder", "Search for a venue or address");
  },
};

/** Suggestions for what was typed: venue name over its address, and Google's
 * attribution at the foot of the list. */
export const Suggestions: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(search(canvasElement), "pickleball");
    await expect(await canvas.findByText("Toyosu Pickleball Courts")).toBeVisible();
    await expect(canvas.getByText("Powered by Google")).toBeVisible();
  },
};

/** Arrow keys move the highlight; Enter would pick it. */
export const KeyboardHighlight: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const input = search(canvasElement);
    await userEvent.type(input, "gym");
    await canvas.findByText("Tokyo Metropolitan Gymnasium");
    await userEvent.keyboard("{ArrowDown}{ArrowDown}");
    await expect(canvas.getAllByRole("option")[1]).toHaveAttribute("aria-selected", "true");
  },
};

/** A pick is saved as a Location and reported with its id and name. */
export const Picked: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.type(search(canvasElement), "toyosu");
    await userEvent.click(await canvas.findByText("Toyosu Pickleball Courts"));
    await waitFor(() => expect(args.onSelected).toHaveBeenCalledWith("loc-ChIJ-story-toyosu"));
    await expect(args.onSelectedDetails).toHaveBeenCalledWith(["loc-ChIJ-story-toyosu", "Toyosu Pickleball Courts"]);
    await expect(search(canvasElement)).toHaveValue("Toyosu Pickleball Courts, 6-1-23 Toyosu, Koto City, Tokyo");
  },
};

/** While the pick is being saved: a spinner and a locked field. */
export const Saving: Story = {
  parameters: { relay: { mocks: { Mutation: { autocompleteLocation: () => pending() } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(search(canvasElement), "minato");
    await userEvent.click(await canvas.findByText("Minato Sports Center"));
    await waitFor(() => expect(search(canvasElement)).toBeDisabled());
  },
};

/** The backend could not save the place. */
export const SaveFailed: Story = {
  parameters: { relay: { mocks: { Mutation: { autocompleteLocation: { location: null } } } } },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.type(search(canvasElement), "ariake");
    await userEvent.click(await canvas.findByText("Ariake Tennis Forest Park"));
    await expect(await canvas.findByText("Could not save that location")).toBeVisible();
    await expect(args.onSelected).not.toHaveBeenCalled();
  },
};

/** Places answered with an error (e.g. the API not enabled for the key). */
export const SearchUnavailable: Story = {
  args: { places: "unavailable" },
  decorators: [mutePlacesFailure],
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(search(canvasElement), "shibuya");
    await expect(await canvas.findByText("Location search is unavailable right now")).toBeVisible();
  },
};

/** The form's own validation message, with the field outlined in red. */
export const WithError: Story = {
  args: { error: "Choose where the event is played" },
};

/** An address handed over by the AI event parser is resolved without typing:
 * the top text-search hit is saved and reported. */
export const ResolvesAddress: Story = {
  args: { autoSearchAddress: "Minato Sports Center Shibaura" },
  play: async ({ args }) => {
    await waitFor(() =>
      expect(args.onSelectedDetails).toHaveBeenCalledWith(["loc-ChIJ-story-minato", "Minato Sports Center"]),
    );
  },
};

/** The Maps script has not loaded (or failed to): the field accepts text but
 * never suggests anything. */
export const PlacesNotLoaded: Story = {
  args: { places: "notLoaded" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(search(canvasElement), "toyosu");
    await new Promise((resolve) => setTimeout(resolve, 400));
    await expect(canvas.queryByRole("listbox")).toBeNull();
  },
};
