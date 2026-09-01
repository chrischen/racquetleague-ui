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

type clip = {
  blob: blob,
  mimeType: string, // "video/mp4"
  durationSeconds: float,
  hasAudio: bool,
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
  // Muxes the most recent <= target-duration footage into a standalone MP4.
  // Capture keeps running during and after the call.
  takeClip: unit => promise<result<clip, clipError>>,
  // Idempotent teardown. Does NOT stop the MediaStream tracks.
  stop: unit => unit,
}
