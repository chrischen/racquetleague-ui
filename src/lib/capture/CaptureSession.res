// The capture-mode seam for the kiosk. Two interchangeable backends implement
// the session record below:
// - LocalRingCapture: on-device WebCodecs rolling buffer + client-side muxing
// - ThinClientCapture: (future) compressed uplink to a server that owns the
//   buffer and serves clips — currently a stub.
// Kiosk.res programs only against this module plus the Capture factory.

type mode = LocalRing | ThinClient

// Persisted alongside kiosk.cameraDeviceId.
let modeStorageKey = "kiosk.captureMode"

let modeToString = mode =>
  switch mode {
  | LocalRing => "local"
  | ThinClient => "thin-client"
  }

let modeFromString = value =>
  switch value {
  | "local" => Some(LocalRing)
  | "thin-client" => Some(ThinClient)
  | _ => None
  }

// Opaque DOM Blob; the object-URL externals are call-site only (SSR-safe).
type blob

@val @scope("URL") external createObjectURL: blob => string = "createObjectURL"
@val @scope("URL") external revokeObjectURL: string => unit = "revokeObjectURL"

type capabilities = {
  canClip: bool, // static feature detection for this backend
  hasAudio: bool, // whether clips can carry sound on this device
  detail: option<string>, // human-readable reason when canClip == false
}

type status = {
  bufferedSeconds: float, // 0. until the first keyframe lands
  targetSeconds: float,
  totalBytes: int,
  droppedFrames: int, // encoder-backpressure drops, for diagnostics
}

// One encoded H.264 access unit as muxed into the clip. Shared by the muxer
// and the crop transcoder (same runtime shape either way).
type encodedChunk = {
  bytes: Uint8Array.t,
  timestampUs: float,
  durationUs: float,
  isKey: bool,
}

// The clip's video track BEFORE muxing: enough to feed a VideoDecoder
// (chunks rebased so the first is a keyframe at 0, plus the avcC description).
type encodedVideo = {
  codec: string, // e.g. "avc1.4d001f"
  width: int,
  height: int,
  description: option<Uint8Array.t>,
  chunks: array<encodedChunk>,
}

type clip = {
  blob: blob,
  mimeType: string, // "video/mp4"
  durationSeconds: float,
  hasAudio: bool,
  // The raw video track, for backends that re-process the clip (the court
  // crop before analysis upload). None when a backend cannot provide it.
  encoded: option<encodedVideo>,
  // Every muxed frame's timestamp in seconds (frame 0 = 0), in decode order —
  // the clip's real playback timeline, for mapping analysis time (frame/fps)
  // onto it (see FrameTimeline). Empty when a backend cannot provide it.
  frameTimes: array<float>,
}

type startError =
  | Unsupported // capability gate failed
  | NoSupportedCodec // every codec candidate rejected by isConfigSupported
  | VideoPlaybackFailed(string) // hidden <video>.play() rejected, or no frames arrived
  | AlreadyStarted
  | NotImplemented // ThinClientCapture

type clipError =
  | NotStarted
  | BufferEmpty // nothing ringed yet (clip pressed immediately after start)
  | MuxFailed(string) // muxer failed to load or to produce a file
  | ClipUnavailable // backend cannot clip (thin-client stub)

// One session == one camera attachment. A camera switch is stop() plus a
// fresh session — the ring cannot mix chunks from two encoder configs.
type t = {
  capabilities: unit => capabilities, // sync and cheap; safe during render
  // Attaches to the stream and spins up the pipelines. Resolves once the
  // first frame has been encoded. Never takes ownership of the tracks —
  // the caller's stream lifecycle owns those.
  start: UserMedia.t => promise<result<unit, startError>>,
  // Muxes the most recent footage into a standalone MP4. Capture keeps
  // running during and after the call. ``seconds`` trims to a shorter tail
  // than the ring's target (analysis cost scales with FRAME COUNT, so a
  // Challenge asks for a few seconds, not the whole buffer); omitted means
  // the full ring. The cut lands on a GOP boundary, so the result can be
  // slightly longer than asked.
  takeClip: (~seconds: float=?) => promise<result<clip, clipError>>,
  // Idempotent teardown. Does NOT stop the MediaStream tracks.
  stop: unit => unit,
}
