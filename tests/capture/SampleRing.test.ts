import { describe, expect, it } from "vitest";
import * as SampleRing from "../../src/lib/capture/SampleRing.re.mjs";

// Labeled args compile positionally: make(keepDurationUs), push(ring, chunk),
// selectRange(ring, fromUs, toUs).

const SEC = 1_000_000;
const KEEP = 24 * SEC;
const FRAME = 21_333; // ~AAC frame at 48kHz

const chunk = (timestampUs: number, byteLength = 400) => ({
  timestampUs,
  durationUs: FRAME,
  byteLength,
  payload: `a@${timestampUs}`,
});

const fill = (seconds: number, startUs = 0) => {
  let ring = SampleRing.make(KEEP);
  const frames = Math.floor((seconds * SEC) / FRAME);
  for (let i = 0; i < frames; i++) {
    ring = SampleRing.push(ring, chunk(startUs + i * FRAME));
  }
  return ring;
};

describe("SampleRing", () => {
  it("keeps only the trailing keep-window of samples", () => {
    const ring = fill(60);
    const newestEnd = Math.floor((60 * SEC) / FRAME - 1) * FRAME + FRAME;
    const oldest = ring.chunks[0];
    expect(oldest.timestampUs + oldest.durationUs).toBeGreaterThan(newestEnd - KEEP);
    // bookkeeping matches retained chunks
    expect(SampleRing.totalBytes(ring)).toBe(SampleRing.chunkCount(ring) * 400);
    expect(SampleRing.chunkCount(ring)).toBeLessThan((25 * SEC) / FRAME);
  });

  it("selectRange returns rebased chunks inside [from, to)", () => {
    const ring = fill(60);
    const from = 45 * SEC;
    const to = 50 * SEC;
    const selected = SampleRing.selectRange(ring, from, to);
    expect(selected.length).toBeGreaterThan(0);
    expect(selected[0].timestampUs).toBeGreaterThanOrEqual(0);
    expect(selected[0].timestampUs).toBeLessThan(FRAME);
    const last = selected[selected.length - 1];
    expect(last.timestampUs).toBeLessThan(to - from);
    for (let i = 1; i < selected.length; i++) {
      expect(selected[i].timestampUs).toBeGreaterThan(selected[i - 1].timestampUs);
    }
    // original absolute position survives in the payload label
    expect(selected[0].payload).toBe(`a@${Math.ceil(from / FRAME) * FRAME}`);
  });

  it("drops out-of-order chunks (encoder flush artifacts)", () => {
    let ring = SampleRing.make(KEEP);
    ring = SampleRing.push(ring, chunk(0));
    ring = SampleRing.push(ring, chunk(2 * FRAME));
    ring = SampleRing.push(ring, chunk(FRAME)); // backward: dropped
    ring = SampleRing.push(ring, chunk(2 * FRAME)); // duplicate: dropped
    expect(SampleRing.chunkCount(ring)).toBe(2);
    expect(SampleRing.totalBytes(ring)).toBe(800);
  });

  it("selectRange is empty for a window with no samples", () => {
    const ring = fill(60);
    expect(SampleRing.selectRange(ring, 100 * SEC, 120 * SEC)).toEqual([]);
    // window fully evicted
    expect(SampleRing.selectRange(ring, 0, 5 * SEC)).toEqual([]);
  });
});
