// Pure rolling time-window ring for independently decodable chunks (audio:
// every AAC/Opus frame stands alone, so there is no GOP structure — just a
// window of recent samples). Payload is opaque like ClipRing's.

type chunk<'a> = {
  timestampUs: float,
  durationUs: float,
  byteLength: int,
  payload: 'a,
}

type t<'a> = {
  keepDurationUs: float,
  chunks: array<chunk<'a>>, // oldest → newest
  totalBytes: int,
}

let make = (~keepDurationUs: float): t<'a> => {keepDurationUs, chunks: [], totalBytes: 0}

// Timestamp of the most recently pushed chunk, for the monotonicity guard.
let lastTimestampUs = (ring: t<'a>): option<float> =>
  ring.chunks->Array.last->Option.map(chunk => chunk.timestampUs)

let push = (ring: t<'a>, chunk: chunk<'a>): t<'a> =>
  // Same guard as ClipRing: drop out-of-order chunks (flush artifacts) so
  // the muxer always sees monotonic timestamps.
  if ring->lastTimestampUs->Option.mapOr(false, last => chunk.timestampUs <= last) {
    ring
  } else {
    let appended = ring.chunks->Array.concat([chunk])
  let newestEnd = chunk.timestampUs +. chunk.durationUs
  let horizon = newestEnd -. ring.keepDurationUs
  let dropCount = ref(0)
  let dropped = ref(0)
  let continue = ref(true)
  while continue.contents {
    switch appended->Array.get(dropCount.contents) {
    | Some(oldest) if oldest.timestampUs +. oldest.durationUs <= horizon => {
        dropped := dropped.contents + oldest.byteLength
        dropCount := dropCount.contents + 1
      }
    | _ => continue := false
    }
  }
    {
      ...ring,
      chunks: dropCount.contents == 0
        ? appended
        : appended->Array.sliceToEnd(~start=dropCount.contents),
      totalBytes: ring.totalBytes + chunk.byteLength - dropped.contents,
    }
  }

let totalBytes = (ring: t<'a>): int => ring.totalBytes

let chunkCount = (ring: t<'a>): int => ring.chunks->Array.length

// Chunks whose start lies in [fromUs, toUs), rebased so the window start is 0.
// Used to pull the audio matching a video clip's absolute time range.
let selectRange = (ring: t<'a>, ~fromUs: float, ~toUs: float): array<chunk<'a>> =>
  ring.chunks
  ->Array.filter(chunk => chunk.timestampUs >= fromUs && chunk.timestampUs < toUs)
  ->Array.map(chunk => {...chunk, timestampUs: chunk.timestampUs -. fromUs})
