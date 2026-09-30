import { describe, expect, it } from "vitest";
import * as ClipRing from "../../src/lib/capture/ClipRing.re.mjs";

// ReScript records are plain objects; labeled args compile positionally:
// make(keepDurationUs, maxBytes), push(ring, chunk), takeClip(ring, targetUs).

type Chunk = {
  timestampUs: number;
  durationUs: number;
  isKey: boolean;
  byteLength: number;
  payload: string;
};

const SEC = 1_000_000;
const KEEP = 24 * SEC;
const TARGET = 20 * SEC;
const MAX_BYTES = 64 * 1024 * 1024;

const chunk = (
  timestampUs: number,
  isKey: boolean,
  { durationUs = SEC / 30, byteLength = 1000, payload = `c@${timestampUs}` } = {},
): Chunk => ({ timestampUs, durationUs, isKey, byteLength, payload });

// Pushes `seconds` of synthetic 30 fps footage with a keyframe every
// `gopSeconds`, starting at `startUs`. Returns the final ring.
const fill = (
  ring: any,
  { startUs = 0, seconds = 60, gopSeconds = 2, onPush = (_r: any) => {} } = {},
) => {
  const frameUs = SEC / 30;
  const frames = seconds * 30;
  for (let i = 0; i < frames; i++) {
    const ts = startUs + i * frameUs;
    const isKey = i % (gopSeconds * 30) === 0;
    ring = ClipRing.push(ring, chunk(ts, isKey));
    onPush(ring);
  }
  return ring;
};

describe("ClipRing.push", () => {
  it("drops delta chunks that arrive before any keyframe", () => {
    let ring = ClipRing.make(KEEP, MAX_BYTES);
    ring = ClipRing.push(ring, chunk(0, false));
    ring = ClipRing.push(ring, chunk(SEC / 30, false));
    expect(ClipRing.chunkCount(ring)).toBe(0);
    expect(ClipRing.bufferedDurationUs(ring)).toBe(0);
  });

  it("drops out-of-order chunks (encoder flush artifacts)", () => {
    let ring = ClipRing.make(KEEP, MAX_BYTES);
    ring = ClipRing.push(ring, chunk(0, true));
    ring = ClipRing.push(ring, chunk(2 * (SEC / 30), false));
    // a forced keyframe stamped BEFORE the last chunk must be dropped
    ring = ClipRing.push(ring, chunk(SEC / 30, true));
    // and an exact duplicate timestamp too
    ring = ClipRing.push(ring, chunk(2 * (SEC / 30), false));
    expect(ClipRing.chunkCount(ring)).toBe(2);
    const clip = ClipRing.takeClip(ring, TARGET);
    for (let i = 1; i < clip.chunks.length; i++) {
      expect(clip.chunks[i].timestampUs).toBeGreaterThan(clip.chunks[i - 1].timestampUs);
    }
  });

  it("opens a GOP on a keyframe and appends deltas to it", () => {
    let ring = ClipRing.make(KEEP, MAX_BYTES);
    ring = ClipRing.push(ring, chunk(0, true));
    ring = ClipRing.push(ring, chunk(SEC / 30, false));
    ring = ClipRing.push(ring, chunk((2 * SEC) / 30, false));
    expect(ClipRing.chunkCount(ring)).toBe(3);
    expect(ClipRing.totalBytes(ring)).toBe(3000);
    expect(ClipRing.bufferedDurationUs(ring)).toBeCloseTo((3 * SEC) / 30, -2);
  });
});

describe("ClipRing eviction", () => {
  it("keeps coverage at or above the keep window once full (property over 60s)", () => {
    let sawFull = false;
    fill(ClipRing.make(KEEP, MAX_BYTES), {
      seconds: 60,
      onPush: (ring) => {
        const buffered = ClipRing.bufferedDurationUs(ring);
        if (buffered >= KEEP) sawFull = true;
        if (sawFull) {
          expect(buffered).toBeGreaterThanOrEqual(KEEP);
          // never retains more than keep window + one extra whole GOP + slack
          expect(buffered).toBeLessThanOrEqual(KEEP + 2 * SEC + SEC);
        }
      },
    });
    expect(sawFull).toBe(true);
  });

  it("only evicts whole GOPs (a clip always starts on a keyframe)", () => {
    const ring = fill(ClipRing.make(KEEP, MAX_BYTES), { seconds: 60 });
    const clip = ClipRing.takeClip(ring, TARGET);
    expect(clip.chunks[0].isKey).toBe(true);
  });

  it("evicts below the keep window when the byte cap demands it", () => {
    // 2s GOPs at 60 frames * 1000B = 60kB per GOP; cap at ~3 GOPs.
    const cap = 3 * 60 * 1000;
    const ring = fill(ClipRing.make(KEEP, cap), { seconds: 30 });
    expect(ClipRing.totalBytes(ring)).toBeLessThanOrEqual(cap + 60 * 1000);
    expect(ClipRing.bufferedDurationUs(ring)).toBeLessThan(KEEP);
    // ...but never drops the newest GOP
    expect(ClipRing.chunkCount(ring)).toBeGreaterThan(0);
  });
});

describe("ClipRing.takeClip", () => {
  it("returns undefined on an empty ring", () => {
    expect(ClipRing.takeClip(ClipRing.make(KEEP, MAX_BYTES), TARGET)).toBeUndefined();
  });

  it("returns at least the target duration when the buffer is full", () => {
    const ring = fill(ClipRing.make(KEEP, MAX_BYTES), { seconds: 60 });
    const clip = ClipRing.takeClip(ring, TARGET);
    expect(clip.durationUs).toBeGreaterThanOrEqual(TARGET);
    // picks the *latest* eligible GOP: no more than one extra GOP of footage
    expect(clip.durationUs).toBeLessThanOrEqual(TARGET + 2 * SEC + SEC);
  });

  it("returns the whole (shorter) buffer while still filling", () => {
    const ring = fill(ClipRing.make(KEEP, MAX_BYTES), { seconds: 5 });
    const clip = ClipRing.takeClip(ring, TARGET);
    expect(clip.durationUs).toBeLessThan(TARGET);
    expect(clip.durationUs).toBeCloseTo(5 * SEC, -6);
    expect(clip.chunks[0].isKey).toBe(true);
  });

  it("rebases timestamps to 0, keeps them monotonic, and includes the newest chunk", () => {
    const ring = fill(ClipRing.make(KEEP, MAX_BYTES), { seconds: 60 });
    const clip = ClipRing.takeClip(ring, TARGET);
    expect(clip.chunks[0].timestampUs).toBe(0);
    for (let i = 1; i < clip.chunks.length; i++) {
      expect(clip.chunks[i].timestampUs).toBeGreaterThan(clip.chunks[i - 1].timestampUs);
    }
    const last = clip.chunks[clip.chunks.length - 1];
    // newest source frame is at 60s - 1 frame; rebased end must match durationUs
    expect(last.timestampUs + last.durationUs).toBeCloseTo(clip.durationUs, -2);
    // payload rides along untouched (label was stamped from the source timestamp)
    expect(last.payload).toBe(`c@${1799 * (SEC / 30)}`);
    // baseUs restores absolute time for audio range selection
    expect(clip.baseUs + last.timestampUs).toBeCloseTo(60 * SEC - SEC / 30, -2);
  });

  it("is safe at hour-scale float microsecond timestamps", () => {
    const hour = 3600 * SEC;
    const ring = fill(ClipRing.make(KEEP, MAX_BYTES), { startUs: hour, seconds: 60 });
    const clip = ClipRing.takeClip(ring, TARGET);
    expect(clip.chunks[0].timestampUs).toBe(0);
    expect(clip.baseUs).toBeGreaterThanOrEqual(hour);
    expect(clip.durationUs).toBeGreaterThanOrEqual(TARGET);
    expect(clip.durationUs).toBeLessThanOrEqual(TARGET + 3 * SEC);
  });
});

describe("segmentAfter (live-analysis uploads)", () => {
  // Labeled args compile positionally: segmentAfter(ring, afterUs, includeOpen).
  it("returns only closed GOPs after the cursor, rebased, and advances cleanly", () => {
    const ring = fill(ClipRing.make(KEEP, MAX_BYTES), { seconds: 7, gopSeconds: 2 });
    // GOPs start at 0, 2, 4, 6 s; the 6 s GOP is still open.
    const first = ClipRing.segmentAfter(ring, -1, false);
    expect(first.baseUs).toBe(0);
    expect(first.chunks[0].timestampUs).toBe(0);
    expect(first.chunks[0].isKey).toBe(true);
    expect(first.chunks.length).toBe(3 * 60); // 0-6 s at 30 fps, open GOP excluded
    // The cursor is a GOP's own start (what the kiosk loop carries), not a
    // round number: at 30 fps frame 120 is 4,000,000.0000000005 µs.
    const lastStart = ring.gops[2].startUs;
    expect(ClipRing.segmentAfter(ring, lastStart, false)).toBeUndefined();
    const withOpen = ClipRing.segmentAfter(ring, lastStart, true);
    expect(withOpen.baseUs).toBe(ring.gops[3].startUs);
    expect(withOpen.chunks.length).toBe(30);
  });

  it("is empty on an empty ring", () => {
    expect(ClipRing.segmentAfter(ClipRing.make(KEEP, MAX_BYTES), -1, true)).toBeUndefined();
  });
});

describe("takeRange (auto-clip spans in stream time)", () => {
  // 60 s of 30 fps footage, keyframes every 2 s, starting at t = 100 s.
  const ring = () => fill(ClipRing.make(KEEP, MAX_BYTES), { startUs: 100 * SEC, seconds: 60 });

  it("cuts [from, to] starting on the keyframe at or before `from`", () => {
    // the ring keeps the last ~24 s: 136..160 s
    const clip = ClipRing.takeRange(ring(), 141.3 * SEC, 152.5 * SEC);
    expect(clip.chunks[0].isKey).toBe(true);
    expect(clip.baseUs).toBeCloseTo(140 * SEC, -3); // keyframe at 140 s <= 141.3 s
    const lastAbs = clip.baseUs + clip.chunks[clip.chunks.length - 1].timestampUs;
    expect(lastAbs).toBeLessThanOrEqual(152.5 * SEC);
    expect(lastAbs).toBeGreaterThan(152.5 * SEC - SEC / 30 - 1);
    expect(clip.chunks[0].timestampUs).toBe(0);
  });

  it("does not run on to the newest frame the way a tail clip would", () => {
    const clip = ClipRing.takeRange(ring(), 141.3 * SEC, 150 * SEC);
    expect(clip.durationUs).toBeLessThan(11 * SEC); // not 141..160
  });

  it("starts at the oldest ringed keyframe when `from` was already evicted", () => {
    const r = ring();
    const oldestKey = r.gops[0].startUs;
    const clip = ClipRing.takeRange(r, 110 * SEC, 150 * SEC);
    expect(clip.baseUs).toBe(oldestKey);
    expect(clip.baseUs).toBeGreaterThan(110 * SEC); // the caller can see the start was lost
  });

  it("is undefined when the window lies entirely before the ring", () => {
    expect(ClipRing.takeRange(ring(), 100 * SEC, 120 * SEC)).toBeUndefined();
  });
});
