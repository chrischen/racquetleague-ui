// Pure rolling ring of encoded video chunks, grouped into GOPs so eviction
// and clip extraction always happen on keyframe boundaries. No browser types:
// the payload is opaque ('a), which keeps this testable from plain vitest
// (tests/capture/ClipRing.test.ts) and reusable for a future thin-client mode.
//
// Timestamps are float microseconds — int32 would overflow after ~35 minutes
// and kiosk sessions run for hours.

type chunk<'a> = {
  timestampUs: float,
  durationUs: float,
  isKey: bool,
  byteLength: int,
  payload: 'a,
}

type gop<'a> = {
  startUs: float, // keyframe timestamp
  endUs: float, // last chunk timestamp + duration
  bytes: int,
  chunks: array<chunk<'a>>,
}

type t<'a> = {
  keepDurationUs: float,
  maxBytes: int,
  gops: array<gop<'a>>, // oldest → newest; the last GOP is "open"
  totalBytes: int,
}

let make = (~keepDurationUs: float, ~maxBytes: int): t<'a> => {
  keepDurationUs,
  maxBytes,
  gops: [],
  totalBytes: 0,
}

let lastGop = (ring: t<'a>) => ring.gops->Array.last

// Drop whole GOPs from the front while doing so either keeps coverage at or
// above the keep window, or is forced by the byte cap. Never drops the last
// remaining GOP.
let evict = (ring: t<'a>): t<'a> =>
  switch lastGop(ring) {
  | None => ring
  | Some(newest) => {
      let newestEnd = newest.endUs
      let n = ring.gops->Array.length
      let dropCount = ref(0)
      let bytes = ref(ring.totalBytes)
      let continue = ref(true)
      while continue.contents {
        let i = dropCount.contents
        if n - i >= 2 {
          let second = ring.gops->Array.getUnsafe(i + 1)
          let coverageKept = newestEnd -. second.startUs >= ring.keepDurationUs
          let overBytes = bytes.contents > ring.maxBytes
          if coverageKept || overBytes {
            bytes := bytes.contents - (ring.gops->Array.getUnsafe(i)).bytes
            dropCount := i + 1
          } else {
            continue := false
          }
        } else {
          continue := false
        }
      }
      if dropCount.contents == 0 {
        ring
      } else {
        {
          ...ring,
          gops: ring.gops->Array.sliceToEnd(~start=dropCount.contents),
          totalBytes: bytes.contents,
        }
      }
    }
  }

// Timestamp of the most recently pushed chunk, for the monotonicity guard.
let lastTimestampUs = (ring: t<'a>): option<float> =>
  ring
  ->lastGop
  ->Option.flatMap(gop => gop.chunks->Array.last)
  ->Option.map(chunk => chunk.timestampUs)

let push = (ring: t<'a>, chunk: chunk<'a>): t<'a> =>
  // Encoders can emit an out-of-order chunk around a flush (e.g. a forced
  // keyframe stamped before already-emitted frames). A backward timestamp
  // would corrupt the mux, so drop such chunks — at worst a one-frame gap.
  if ring->lastTimestampUs->Option.mapOr(false, last => chunk.timestampUs <= last) {
    ring
  } else if chunk.isKey {
    evict({
      ...ring,
      gops: ring.gops->Array.concat([
        {
          startUs: chunk.timestampUs,
          endUs: chunk.timestampUs +. chunk.durationUs,
          bytes: chunk.byteLength,
          chunks: [chunk],
        },
      ]),
      totalBytes: ring.totalBytes + chunk.byteLength,
    })
  } else {
    switch lastGop(ring) {
    | None => ring // delta before the first keyframe: undecodable, drop it
    | Some(last) =>
      evict({
        ...ring,
        gops: ring.gops
        ->Array.slice(~start=0, ~end=ring.gops->Array.length - 1)
        ->Array.concat([
          {
            ...last,
            endUs: Math.max(last.endUs, chunk.timestampUs +. chunk.durationUs),
            bytes: last.bytes + chunk.byteLength,
            chunks: last.chunks->Array.concat([chunk]),
          },
        ]),
        totalBytes: ring.totalBytes + chunk.byteLength,
      })
    }
  }

let bufferedDurationUs = (ring: t<'a>): float =>
  switch (ring.gops->Array.get(0), lastGop(ring)) {
  | (Some(oldest), Some(newest)) => newest.endUs -. oldest.startUs
  | _ => 0.
  }

let totalBytes = (ring: t<'a>): int => ring.totalBytes

let chunkCount = (ring: t<'a>): int =>
  ring.gops->Array.reduce(0, (acc, gop) => acc + gop.chunks->Array.length)

type clip<'a> = {
  // Rebased: the first chunk has timestampUs == 0. and isKey == true (when
  // the ring holds at least one keyframe).
  chunks: array<chunk<'a>>,
  durationUs: float,
  // Absolute stream timestamp the clip was rebased against; callers use it to
  // select matching audio from a SampleRing.
  baseUs: float,
}

// Picks the newest GOP that still yields at least targetDurationUs of footage
// (or the oldest GOP when the buffer is shorter than the target) and returns
// every chunk from there to the end, timestamps rebased to 0.
let takeClip = (ring: t<'a>, ~targetDurationUs: float): option<clip<'a>> =>
  switch lastGop(ring) {
  | None => None
  | Some(newest) => {
      let newestEnd = newest.endUs
      let cutoff = newestEnd -. targetDurationUs
      let startIndex = ref(0)
      ring.gops->Array.forEachWithIndex((gop, i) =>
        if gop.startUs <= cutoff {
          startIndex := i
        }
      )
      let chunks = ring.gops->Array.sliceToEnd(~start=startIndex.contents)->Array.flatMap(gop => gop.chunks)
      chunks
      ->Array.get(0)
      ->Option.map(first => {
        chunks: chunks->Array.map(chunk => {...chunk, timestampUs: chunk.timestampUs -. first.timestampUs}),
        durationUs: newestEnd -. first.timestampUs,
        baseUs: first.timestampUs,
      })
    }
  }

// The GOPs pushed after ``afterUs`` (their keyframe strictly later), as one
// rebased clip — the kiosk's live-analysis upload. By default only CLOSED GOPs
// (a newer keyframe exists, so no more frames will join them); ``includeOpen``
// adds the GOP still being filled, for a caller that needs the freshest frames
// now and tolerates re-sending some of them later. None when nothing qualifies.
let segmentAfter = (ring: t<'a>, ~afterUs: float, ~includeOpen: bool=false): option<clip<'a>> => {
  let n = ring.gops->Array.length
  let closed = includeOpen ? n : Math.Int.max(0, n - 1)
  let gops = ring.gops->Array.slice(~start=0, ~end=closed)->Array.filter(gop => gop.startUs > afterUs)
  switch (gops->Array.get(0), gops->Array.last) {
  | (Some(first), Some(last)) => {
      let chunks = gops->Array.flatMap(gop => gop.chunks)
      Some({
        chunks: chunks->Array.map(chunk => {...chunk, timestampUs: chunk.timestampUs -. first.startUs}),
        durationUs: last.endUs -. first.startUs,
        baseUs: first.startUs,
      })
    }
  | _ => None
  }
}
