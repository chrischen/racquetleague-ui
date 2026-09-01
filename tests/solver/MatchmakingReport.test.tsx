// The report page: an article wrapped around the lab's chart series, fed by
// the precomputed run. Rendered here against the real artifact served through
// a stubbed fetch, so the whole path the browser takes — manifest, gunzip,
// decode, chart-data build, Recharts mount — runs end to end.
import { describe, expect, it, vi, afterEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import * as React from "react";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import * as SimLabArchive from "../../src/lib/rating/SimLabArchive.re.mjs";
import * as MatchmakingReport from "../../src/components/organisms/MatchmakingReport.re.mjs";

const assetDir = join(process.cwd(), "public", SimLabArchive.assetDir);
const manifestPath = join(assetDir, SimLabArchive.manifestFile);
const published = (() => {
  // Requires an artifact in the CURRENT format: after a bump the old file is
  // refused by design, and the article render should wait for regeneration
  // rather than fail against it. The load-failure test below still runs.
  try {
    return (
      JSON.parse(readFileSync(manifestPath, "utf8")).version === SimLabArchive.version
    );
  } catch {
    return false;
  }
})();

const serveFromDisk = () =>
  vi.stubGlobal("fetch", async (url: string) => {
    const path = join(assetDir, url.split("/").pop()!);
    if (!existsSync(path)) return new Response(null, { status: 404, statusText: "Not Found" });
    return new Response(readFileSync(path));
  });

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("MatchmakingReport", () => {
  it.runIf(published)("renders the article from the precomputed run", async () => {
    serveFromDisk();
    render(React.createElement(MatchmakingReport.make));

    // The shell paints immediately…
    expect(screen.getByText(/measured/i)).toBeTruthy();
    // …and the article arrives once the run decodes.
    await waitFor(() => expect(screen.getByText(/Why the Oracle never converges/)).toBeTruthy(), {
      timeout: 30_000,
    });

    // Every section landed.
    for (const heading of [
      /Tight skill spread/,
      /Varied skill levels/,
      /Typical 3\.0–4\.0 spread/,
      /Conclusion/,
      /Future improvements/,
    ])
      expect(screen.getAllByText(heading).length).toBeGreaterThan(0);

    // The charts mounted with their interactive legends: the adaptive
    // strategy appears as a clickable chip on several charts.
    const chips = screen.getAllByRole("button", { name: /Competitive\+ \(adaptive\)/ });
    expect(chips.length).toBeGreaterThanOrEqual(5);
    // Isolating a strategy and switching the blowout room must not throw.
    fireEvent.click(chips[0]);
    fireEvent.click(screen.getAllByRole("button", { name: /Tight club/ })[0]);
  }, 60_000);

  it("reports a load failure in place of the article", async () => {
    vi.stubGlobal("fetch", async () => new Response(null, { status: 404, statusText: "Not Found" }));
    render(React.createElement(MatchmakingReport.make));
    await waitFor(() => expect(screen.getByText(/Could not load the data/)).toBeTruthy(), {
      timeout: 10_000,
    });
  }, 30_000);
});
