// The load path the lab actually uses: URL construction, the fetch, and the
// streaming gunzip. The codec is covered in SimLabArchive.test.ts; this covers
// the seam between it and the network, which is the part that only fails in a
// browser and would otherwise be found by a user.
import { describe, expect, it, vi, afterEach } from "vitest";
import { gzipSync, constants } from "node:zlib";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import * as SimLabArchive from "../../src/lib/rating/SimLabArchive.re.mjs";

const assetDir = join(process.cwd(), "public", SimLabArchive.assetDir);
const manifestPath = join(assetDir, SimLabArchive.manifestFile);

// The published artifact must match the current format version: after a
// format bump the old file is refused by design, and these tests should wait
// for regeneration rather than fail against a file the code no longer reads.
const artifactCurrent = (() => {
  try {
    return (
      JSON.parse(readFileSync(manifestPath, "utf8")).version === SimLabArchive.version
    );
  } catch {
    return false;
  }
})();


// Serve the real `public/` tree over a stubbed fetch, so the test exercises
// the same URLs the browser requests rather than a hand-built fixture.
const serveFromDisk = () =>
  vi.stubGlobal("fetch", async (url: string) => {
    const path = join(assetDir, url.split("/").pop()!);
    if (!existsSync(path)) return new Response(null, { status: 404, statusText: "Not Found" });
    return new Response(readFileSync(path));
  });

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("SimLabArchive fetching", () => {
  it("builds asset URLs under the app's base path", () => {
    expect(SimLabArchive.assetUrl("x.json.gz")).toBe("/matchmaking-lab/x.json.gz");
  });

  it("gunzips a .gz asset transparently", async () => {
    const body = JSON.stringify({ hello: "world" });
    vi.stubGlobal("fetch", async () =>
      new Response(gzipSync(Buffer.from(body), { level: constants.Z_BEST_COMPRESSION })));
    // Reached through the `.gz` branch: getting "not a saved run" rather than
    // "not valid JSON" proves the bytes were decompressed and parsed. If the
    // decompressor were skipped, this would be unparseable binary.
    const r = await SimLabArchive.loadRun("anything.json.gz");
    expect(r.TAG).toBe("Error");
    expect(r._0).toBe("Not a saved lab run.");
  });

  it("reads a .gz the server already decompressed", async () => {
    // Some servers and CDNs answer a `.gz` file with `Content-Encoding: gzip`,
    // so the browser hands us plain text under a `.gz` URL. Gunzipping that
    // again would fail, and the saved run would be unloadable on exactly the
    // hosts most likely to be in front of production.
    vi.stubGlobal("fetch", async () => new Response(JSON.stringify({ hello: "world" })));
    const r = await SimLabArchive.loadRun("already-inflated.json.gz");
    expect(r.TAG).toBe("Error");
    expect(r._0).toBe("Not a saved lab run.");
  });

  it("reports a missing asset instead of throwing", async () => {
    vi.stubGlobal("fetch", async () => new Response(null, { status: 404, statusText: "Not Found" }));
    const r = await SimLabArchive.loadRun("gone.json.gz");
    expect(r.TAG).toBe("Error");
    expect(r._0).toContain("404");
  });

  it.runIf(artifactCurrent)("loads every published run end to end", async () => {
    serveFromDisk();
    const m = SimLabArchive.decodeManifest(readFileSync(manifestPath, "utf8"));
    if (m.TAG !== "Ok") throw new Error(m._0);
    expect(m._0.runs.length).toBeGreaterThan(0);

    const fetched = await SimLabArchive.loadManifest();
    if (fetched.TAG !== "Ok") throw new Error(fetched._0);

    for (const entry of fetched._0.runs) {
      const run = await SimLabArchive.loadRun(entry.file);
      if (run.TAG !== "Ok") throw new Error(`${entry.file}: ${run._0}`);
      const loaded = run._0;
      // The manifest is what the picker renders from, so it must not be able
      // to describe a run differently from the run itself.
      expect(loaded.info.numPlayers).toBe(entry.numPlayers);
      expect(loaded.info.courts).toBe(entry.courts);
      expect(loaded.info.numRounds).toBe(entry.numRounds);
      expect(loaded.info.seedCount).toBe(entry.seedCount);
      expect(loaded.info.tournament).toBe(entry.tournament);
      expect(loaded.info.scenario).toBe(entry.scenario);
      // And the run must be the size it claims, on every seed.
      expect(loaded.byField[0].length).toBe(entry.seedCount);
      for (const bySeed of loaded.byField)
        for (const res of bySeed)
          for (const r of res.runs) expect(r.frames.length).toBe(entry.numRounds + 1);
    }
  }, 300_000);
});
