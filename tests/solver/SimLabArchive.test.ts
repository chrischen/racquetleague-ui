// The saved-run format has no schema and no migrations: it is the runtime
// shape of `SimLab.labResult` written straight out, guarded by a version
// number. That is only safe if the guard actually fires and if the trimming
// takes exactly what nothing reads — so both are pinned here.
import { describe, expect, it } from "vitest";
import * as SimLab from "../../src/lib/rating/SimLab.re.mjs";
import * as SimLabArchive from "../../src/lib/rating/SimLabArchive.re.mjs";

const ROUNDS = 2;
const SEEDS = 2;

// [field][seed], the shape the lab holds and the file stores.
const buildRun = async () => {
  const byField: any[][] = SimLab.fields.map(() => []);
  for (let seedIndex = 0; seedIndex < SEEDS; seedIndex++)
    for (let f = 0; f < SimLab.fields.length; f++)
      byField[f].push(
        await SimLab.run("ColdStart", 1 + seedIndex, 8, 2, ROUNDS, SimLab.fields[f], false, undefined),
      );
  return byField;
};

const encode = (byField: any[][]) =>
  SimLabArchive.encode(byField, "test", "ColdStart", 8, 2, ROUNDS, 1, SEEDS, false, "now");

const unwrap = (r: any) => {
  if (r.TAG !== "Ok") throw new Error(r._0);
  return r._0;
};

describe("SimLabArchive", () => {
  it("round-trips a run without changing what the charts read", async () => {
    const byField = await buildRun();
    const loaded = unwrap(SimLabArchive.decode(encode(byField)));

    expect(loaded.byField.length).toBe(SimLab.fields.length);
    expect(loaded.byField[0].length).toBe(SEEDS);

    for (let f = 0; f < SimLab.fields.length; f++)
      for (let s = 0; s < SEEDS; s++) {
        const before = byField[f][s];
        const after = loaded.byField[f][s];
        expect(after.numPlayers).toBe(before.numPlayers);
        expect(after.seed).toBe(before.seed);
        expect(after.names).toEqual(before.names);
        expect(after.driftRoles).toEqual(before.driftRoles);
        // The session model: who drops in, who attends which session, and the
        // per-session form offsets (rounded to write precision).
        expect(after.dropIns).toEqual(before.dropIns);
        expect(after.attendance).toEqual(before.attendance);
        expect(after.form.length).toBe(before.form.length);
        after.form.forEach((sess: number[], si: number) =>
          sess.forEach((v: number, i: number) => expect(v).toBeCloseTo(before.form[si][i], 3)),
        );
        expect(after.runs.length).toBe(before.runs.length);

        for (let i = 0; i < before.runs.length; i++) {
          expect(after.runs[i].entry.id).toBe(before.runs[i].entry.id);
          expect(after.runs[i].frames.length).toBe(before.runs[i].frames.length);
          for (let k = 0; k < before.runs[i].frames.length; k++) {
            const a = before.runs[i].frames[k];
            const b = after.runs[i].frames[k];
            // Every metric the charts and the summary table plot. Four
            // decimals is the write precision, so 3 is the honest tolerance.
            expect(b.round).toBe(a.round);
            expect(b.spearman).toBeCloseTo(a.spearman, 3);
            expect(b.rankError).toBeCloseTo(a.rankError, 3);
            expect(b.muError).toBeCloseTo(a.muError, 3);
            for (const key of ["blowoutRate", "trueDrawProb", "medianDrawProb", "forecastError"] as const) {
              if (a[key] === undefined) expect(b[key]).toBeUndefined();
              else expect(b[key]).toBeCloseTo(a[key], 3);
            }
            // `None` must survive as `None` and not become 0 — the pre-play
            // frame has no games, and a 0 there would read as a perfect round.
            expect(b.qualityByBand.length).toBe(a.qualityByBand.length);
            a.qualityByBand.forEach((v: number | undefined, band: number) => {
              if (v === undefined) expect(b.qualityByBand[band]).toBeUndefined();
              else expect(b.qualityByBand[band]).toBeCloseTo(v, 3);
            });
          }
        }
      }
  }, 900_000);

  it("keeps detail on the seed the ladder shows and drops it everywhere else", async () => {
    const byField = await buildRun();
    const loaded = unwrap(SimLabArchive.decode(encode(byField)));
    expect(loaded.info.detailSeeds).toBe(1);

    for (let f = 0; f < SimLab.fields.length; f++) {
      // Seed 0 is `primary` in MatchmakingLab: the ladder and round views read
      // its mu, sigma and games, so all three must survive.
      const last = loaded.byField[f][0].runs[0].frames.at(-1);
      expect(last.mu.length).toBe(8);
      expect(last.sigma.length).toBe(8);
      expect(last.games.length).toBe(2);
      expect(last.games[0].team1.length).toBe(2);

      // Later seeds feed the seed-averaged charts and the error bars, which
      // never look at a game. Dropping their detail is most of the file.
      for (let s = 1; s < SEEDS; s++) {
        const other = loaded.byField[f][s].runs[0].frames.at(-1);
        expect(other.mu).toEqual([]);
        expect(other.games).toEqual([]);
        // ...but their metrics are intact, which is the point.
        expect(other.rankError).toBeCloseTo(byField[f][s].runs[0].frames.at(-1).rankError, 3);
      }
    }
  }, 900_000);

  it("strategies are rehydrated from code, never from the file", async () => {
    const byField = await buildRun();
    const json = encode(byField);
    // Nothing but the id is written, so a saved run cannot carry a stale copy
    // of a strategy's weights or colours back into the UI.
    expect(json).not.toContain("partnerVariety");
    expect(json).toContain('"entryId":"cpa"');
    const loaded = unwrap(SimLabArchive.decode(json));
    expect(loaded.byField[0][0].runs[0].entry).toBe(SimLab.strategies[0]);
  }, 900_000);

  it("refuses a file it cannot vouch for", async () => {
    const byField = await buildRun();
    const json = encode(byField);
    const fails = (text: string, needle: string) => {
      const r = SimLabArchive.decode(text);
      expect(r.TAG).toBe("Error");
      expect(r._0).toContain(needle);
    };

    fails("{oops", "valid JSON");
    // Well-formed JSON that is not a run at all — a truncated download, or a
    // dev server answering a missing asset with index.html. This used to crash
    // reading `.length` of nothing instead of failing the load.
    fails("{}", "Not a saved lab run");
    fails(`{"version":${SimLabArchive.version},"byField":[1,2,3]}`, "incomplete or corrupt");
    // A format bump must invalidate every file rather than half-reading one.
    fails(json.replace(`"version":${SimLabArchive.version}`, '"version":9999'), "Regenerate");
    // A strategy that no longer exists would otherwise render as a gap.
    fails(json.replace('"entryId":"cpa"', '"entryId":"ghost"'), "no longer exists");
    // Field count is part of the shape: two fields in a three-field build
    // would silently mislabel every chart.
    const parsed = JSON.parse(json);
    parsed.byField.pop();
    fails(JSON.stringify(parsed), "fields");
  }, 900_000);
});
