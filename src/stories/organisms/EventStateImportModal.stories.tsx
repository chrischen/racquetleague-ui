import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as EventStateImportModalStory } from "./EventStateImportModalStory.gen";
import { sampleExport } from "./StoryFixturesSession.gen";
import { must } from "../support";

// The event manager's "Import History" dialog. Paste an export and it previews
// the merge before anything is written: rounds and matches to import (green),
// and what is skipped and why (amber); a bad paste gets a red explanation.
// Import stays disabled until there is at least one match to import, and
// while a draw is being generated. The preview is the real decode + plan
// (EventStateTransfer) against three local situations; the pasted text is a
// second device's rounds 1 and 2 (StoryFixturesSession.sampleExport).
const meta = {
  title: "Organisms/EventStateImportModal",
  component: EventStateImportModalStory,
  parameters: { layout: "fullscreen" },
  argTypes: { local: { control: "inline-radio", options: ["fresh", "partial", "upToDate"] } },
  args: { local: "fresh", disabled: false, onImport: fn(), onClose: fn() },
} satisfies Meta<typeof EventStateImportModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const paste = async (canvasElement: HTMLElement, text: string) => {
  const canvas = within(canvasElement);
  await userEvent.click(await canvas.findByRole("textbox"));
  await userEvent.paste(text);
  return canvas;
};

// A preview row: its label and its count.
const row = async (canvasElement: HTMLElement, label: string) =>
  must((await within(canvasElement).findByText(label)).parentElement, label);

const importButton = (canvasElement: HTMLElement) => within(canvasElement).getByRole("button", { name: "Import" });

/** Nothing pasted: no preview, Import disabled. */
export const Empty: Story = {
  play: async ({ canvasElement }) => {
    await within(canvasElement).findByText("Import History");
    await expect(importButton(canvasElement)).toBeDisabled();
  },
};

/** Into a fresh device with the whole roster: 2 rounds, 7 matches, nothing skipped. */
export const ValidPaste: Story = {
  play: async ({ args, canvasElement }) => {
    await paste(canvasElement, sampleExport);
    await expect(await row(canvasElement, "Rounds to import")).toHaveTextContent(/2$/);
    await expect(await row(canvasElement, "Matches to import")).toHaveTextContent(/7$/);
    await expect(importButton(canvasElement)).toBeEnabled();
    await userEvent.click(importButton(canvasElement));
    await expect(args.onImport).toHaveBeenCalledWith(sampleExport);
  },
};

/** This device already ran round 1 and never added the walk-ins: duplicates and missing players are skipped. */
export const PartialOverlap: Story = {
  args: { local: "partial" },
  play: async ({ canvasElement }) => {
    await paste(canvasElement, sampleExport);
    await expect(await row(canvasElement, "Matches to import")).toHaveTextContent(/3$/);
    await expect(await row(canvasElement, "Skipped, players not in this event")).toHaveTextContent(/1$/);
    await expect(await row(canvasElement, "Skipped, already here")).toHaveTextContent(/3$/);
    await expect(await row(canvasElement, "Skipped rating adjustments")).toHaveTextContent(/7$/);
    await expect(importButton(canvasElement)).toBeEnabled();
  },
};

/** Everything is already here: all skipped, Import stays disabled. */
export const NothingNew: Story = {
  args: { local: "upToDate" },
  play: async ({ canvasElement }) => {
    await paste(canvasElement, sampleExport);
    await expect(await row(canvasElement, "Matches to import")).toHaveTextContent(/0$/);
    await expect(await row(canvasElement, "Skipped, already here")).toHaveTextContent(/7$/);
    await expect(importButton(canvasElement)).toBeDisabled();
  },
};

/** Not JSON at all. */
export const InvalidPaste: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await paste(canvasElement, "Round 1: Kenji & Mai beat Yuki & Takumi 11-8");
    await expect(await canvas.findByText("That is not valid JSON.")).toBeVisible();
    await expect(importButton(canvasElement)).toBeDisabled();
  },
};

/** An export from a newer build of the app. */
export const NewerVersion: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await paste(canvasElement, sampleExport.replace('"version":2', '"version":3'));
    await expect(await canvas.findByText(/format v3, but this version of the app reads v2/)).toBeVisible();
  },
};

/** A valid paste while a draw is being generated: Import waits. */
export const WhileGenerating: Story = {
  args: { disabled: true },
  play: async ({ canvasElement }) => {
    const canvas = await paste(canvasElement, sampleExport);
    await expect(await canvas.findByText(/Wait for the draw currently being generated/)).toBeVisible();
    await expect(importButton(canvasElement)).toBeDisabled();
  },
};
