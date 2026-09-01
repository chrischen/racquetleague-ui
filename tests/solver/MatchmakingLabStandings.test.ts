// The summary standings are a rolling window ending at the scrubbed round, so
// the table says how a strategy is doing NOW rather than over its whole
// history. Everything about that is a judgement call about window length, so
// the rule and its one shared consumer are pinned here.
//
// These read the precomputed run rather than solving: 100 rounds x 7 seeds
// already exist on disk, and this is exactly the kind of question that needs
// that much data to answer.
import { describe, expect, it } from "vitest";
import { gunzipSync } from "node:zlib";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import * as SimLabArchive from "../../src/lib/rating/SimLabArchive.re.mjs";
import * as MatchmakingLab from "../../src/components/organisms/MatchmakingLab.re.mjs";

const artifact = join(
  process.cwd(), "public", SimLabArchive.assetDir, "cold-24p-4c-100r-7s.json.gz",
);
const manifestPath = join(process.cwd(), "public", SimLabArchive.assetDir, SimLabArchive.manifestFile);

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


const mean = (xs: number[]) => xs.reduce((a, b) => a + b, 0) / xs.length;

describe("summary window", () => {
  it("is a quarter of the session so far, with a floor", () => {
    // The floor is what keeps a 30-round session discriminating; the quarter
    // is what keeps a 100-round one recent.
    expect(MatchmakingLab.summaryWindow(4)).toBe(10);
    expect(MatchmakingLab.summaryWindow(40)).toBe(10);
    expect(MatchmakingLab.summaryWindow(100)).toBe(25);
    // Frame 0 is the pre-play state and is never a round, so the window is
    // clamped rather than reaching back past the start.
    expect(MatchmakingLab.summaryFrom(0)).toBe(1);
    expect(MatchmakingLab.summaryFrom(5)).toBe(1);
    expect(MatchmakingLab.summaryFrom(100)).toBe(76);
    // The window never extends past the round being shown.
    for (const round of [0, 1, 7, 30, 60, 100])
      expect(MatchmakingLab.summaryFrom(round)).toBeLessThanOrEqual(Math.max(1, round));
  });

  it.runIf(existsSync(artifact) && artifactCurrent)("band standings read only that window", () => {
    const d = SimLabArchive.decode(gunzipSync(readFileSync(artifact)).toString("utf8"));
    if (d.TAG !== "Ok") throw new Error(d._0);
    const seeds = d._0.byField[1]; // typical field

    const round = 100;
    const band = 0;
    const standings = MatchmakingLab.bandStandings(seeds, band, round);
    expect(standings.length).toBeGreaterThan(0);

    // Recompute independently from the frames the window covers.
    for (const [run, value] of standings) {
      const perSeed = seeds.map((res: any) => {
        const r = res.runs.find((x: any) => x.entry.id === run.entry.id);
        return mean(
          r.frames.slice(76, round + 1)
            .map((f: any) => f.qualityByBand[band])
            .filter((v: unknown) => v !== undefined),
        );
      });
      expect(value).toBeCloseTo(mean(perSeed) * 100, 6);
    }

    // And it is genuinely rolling: the last quarter of a 100-round session
    // does not agree with the whole of it. If these matched, the window would
    // not be doing anything.
    const cumulative = seeds[0].runs
      .filter((x: any) => !x.entry.usesTruth)
      .map((r: any) =>
        mean(r.frames.slice(1, round + 1)
          .map((f: any) => f.qualityByBand[band])
          .filter((v: unknown) => v !== undefined)));
    const rolling = seeds[0].runs
      .filter((x: any) => !x.entry.usesTruth)
      .map((r: any) =>
        mean(r.frames.slice(76, round + 1)
          .map((f: any) => f.qualityByBand[band])
          .filter((v: unknown) => v !== undefined)));
    expect(rolling.some((v: number, i: number) => Math.abs(v - cumulative[i]) > 0.01)).toBe(true);
  });

  it.runIf(existsSync(artifact) && artifactCurrent)("ranks the strongest band best-first", () => {
    const d = SimLabArchive.decode(gunzipSync(readFileSync(artifact)).toString("utf8"));
    if (d.TAG !== "Ok") throw new Error(d._0);
    const standings = MatchmakingLab.bandStandings(d._0.byField[1], 0, 100);
    const values = standings.map(([, v]: [unknown, number]) => v);
    expect(values).toEqual([...values].sort((a, b) => b - a));
    // Benchmarks that matchmake from hidden truth are not competitors and must
    // not appear in a standings list.
    expect(standings.every(([run]: [any]) => !run.entry.usesTruth)).toBe(true);
  });
});
