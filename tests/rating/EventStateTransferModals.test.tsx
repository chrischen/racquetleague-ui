// The two debug modals that carry history between devices. Rendered for real,
// because the parts that can only fail at runtime are here: the preview has to
// refuse a bad paste without throwing, and the Import button has to stay shut
// until there is genuinely something to import.
import { describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import * as React from "react";
import * as Transfer from "../../src/lib/rating/EventStateTransfer.re.mjs";
import * as ExportModal from "../../src/components/organisms/EventStateExportModal.re.mjs";
import * as ImportModal from "../../src/components/organisms/EventStateImportModal.re.mjs";
import { makePlayer, type Player } from "../solver/fixtures";

const P: Player[] = Array.from({ length: 4 }, (_, i) => makePlayer(i, { id: `p${i}` }));

const history = [
  [
    {
      id: "m1",
      match: [
        [P[0], P[1]],
        [P[2], P[3]],
      ],
      score: [11, 5],
      createdAt: new Date(1000),
      synced: false,
    },
  ],
];

const exported = () => Transfer.encode("evt", 1_700_000_000_000, history, []);

// The manager's own preview closure: decode, plan against an empty event, and
// hand back just the counts.
const preview = (text: string) => {
  const decoded = Transfer.decode(text);
  if (decoded.TAG !== "Ok") return decoded;
  return { TAG: "Ok", _0: Transfer.plan([], [], {}, 0, P, decoded._0).counts };
};

const typeInto = (value: string) => {
  const box = screen.getByRole("textbox") as HTMLTextAreaElement;
  fireEvent.change(box, { target: { value } });
};

describe("EventStateExportModal", () => {
  it("shows the export and copies it to the clipboard", async () => {
    const writeText = vi.fn().mockResolvedValue(undefined);
    vi.stubGlobal("navigator", { clipboard: { writeText } });

    const text = exported();
    render(React.createElement(ExportModal.make, { text, onClose: () => {} }));

    expect((screen.getByRole("textbox") as HTMLTextAreaElement).value).toBe(text);

    fireEvent.click(screen.getByText("Copy"));
    await screen.findByText("Copied");
    expect(writeText).toHaveBeenCalledWith(text);

    vi.unstubAllGlobals();
  });

  it("survives a clipboard that refuses, as on a plain-http address", async () => {
    const writeText = vi.fn().mockRejectedValue(new Error("not allowed"));
    vi.stubGlobal("navigator", { clipboard: { writeText } });

    render(React.createElement(ExportModal.make, { text: exported(), onClose: () => {} }));
    fireEvent.click(screen.getByText("Copy"));

    // No "Copied", no crash — the text is selected for a manual copy instead.
    await Promise.resolve();
    expect(screen.queryByText("Copied")).toBeNull();

    vi.unstubAllGlobals();
  });
});

describe("EventStateImportModal", () => {
  const mount = (onImport = () => {}, disabled = false) =>
    render(
      React.createElement(ImportModal.make, {
        preview,
        onImport,
        disabled,
        onClose: () => {},
      }),
    );

  it("keeps Import shut until a paste yields matches", () => {
    mount();
    const button = screen.getByText("Import").closest("button")!;
    expect(button.disabled).toBe(true);

    typeInto(exported());
    expect(screen.getByText("Import").closest("button")!.disabled).toBe(false);
  });

  it("explains a bad paste instead of throwing", () => {
    mount();
    typeInto("this is not an export");

    expect(screen.getByText(/not valid JSON/i)).toBeTruthy();
    expect(screen.getByText("Import").closest("button")!.disabled).toBe(true);
  });

  it("hands the pasted text back on confirm", () => {
    const onImport = vi.fn();
    mount(onImport);

    const text = exported();
    typeInto(text);
    fireEvent.click(screen.getByText("Import"));

    expect(onImport).toHaveBeenCalledWith(text);
  });

  it("stays shut while a draw is being generated", () => {
    mount(() => {}, true);
    typeInto(exported());

    expect(screen.getByText("Import").closest("button")!.disabled).toBe(true);
  });
});
