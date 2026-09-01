// Bindings for the WebCodecs surface used by LocalRingCapture: VideoEncoder
// fed from requestVideoFrameCallback, and AudioEncoder fed from a
// MediaStreamTrackProcessor reader (Safari supports MSTP for audio tracks
// only, which is why video goes through rVFC instead).
//
// SSR note: every external here is call-site only, and the feature checks are
// %raw *functions* — nothing touches browser globals at module init.

let hasVideoEncoder: unit => bool = %raw(`() => typeof VideoEncoder === "function"`)
let hasVideoFrame: unit => bool = %raw(`() => typeof VideoFrame === "function"`)
let hasRvfc: unit => bool = %raw(
  `() => typeof HTMLVideoElement !== "undefined" && "requestVideoFrameCallback" in HTMLVideoElement.prototype`
)
let hasAudioEncoder: unit => bool = %raw(`() => typeof AudioEncoder === "function"`)
let hasTrackProcessor: unit => bool = %raw(`() => typeof MediaStreamTrackProcessor === "function"`)

// --- requestVideoFrameCallback ---

type rvfcHandle

type frameMetadata = {
  mediaTime: float, // seconds on the media timeline
  width: int,
  height: int,
}

@send
external requestVideoFrameCallback: (Dom.element, (float, frameMetadata) => unit) => rvfcHandle =
  "requestVideoFrameCallback"
@send
external cancelVideoFrameCallback: (Dom.element, rvfcHandle) => unit = "cancelVideoFrameCallback"

// --- VideoFrame ---

type videoFrame

// Safari does not infer the timestamp from the element — always pass it (µs).
type videoFrameInit = {timestamp: float}

@new external videoFrameFromElement: (Dom.element, videoFrameInit) => videoFrame = "VideoFrame"
@send external closeFrame: videoFrame => unit = "close"

// --- VideoEncoder ---

type encodedVideoChunk

@get external chunkTimestamp: encodedVideoChunk => float = "timestamp" // µs
@get external chunkDuration: encodedVideoChunk => Nullable.t<float> = "duration" // µs
@get external chunkType: encodedVideoChunk => string = "type" // "key" | "delta"
@get external chunkByteLength: encodedVideoChunk => int = "byteLength"
@send external copyTo: (encodedVideoChunk, Uint8Array.t) => unit = "copyTo"

type avcOptions = {format: string} // "avc" → out-of-band avcC description

type encoderConfig = {
  codec: string,
  width: int,
  height: int,
  bitrate: float,
  framerate?: float,
  latencyMode?: string, // "realtime"
  avc?: avcOptions,
  hardwareAcceleration?: string, // "no-preference"
}

type decoderConfig = {codec?: string, description?: Uint8Array.t}
type chunkMetadata = {decoderConfig?: decoderConfig}

type videoEncoder

type encoderInit = {
  output: (encodedVideoChunk, Nullable.t<chunkMetadata>) => unit,
  error: Js.Exn.t => unit,
}

@new external makeEncoder: encoderInit => videoEncoder = "VideoEncoder"

type configSupport = {supported: bool}

@scope("VideoEncoder") @val
external isConfigSupported: encoderConfig => promise<configSupport> = "isConfigSupported"

type encodeOptions = {keyFrame: bool}

@send external configure: (videoEncoder, encoderConfig) => unit = "configure"
@send external encode: (videoEncoder, videoFrame, encodeOptions) => unit = "encode"
@send external flush: videoEncoder => promise<unit> = "flush"
@send external closeEncoder: videoEncoder => unit = "close"
@get external encodeQueueSize: videoEncoder => int = "encodeQueueSize"

// --- AudioData via MediaStreamTrackProcessor ---

type trackProcessor
type trackProcessorInit = {track: UserMedia.track}

@new
external makeTrackProcessor: trackProcessorInit => trackProcessor = "MediaStreamTrackProcessor"

type readable
@get external readable: trackProcessor => readable = "readable"

type reader
@send external getReader: readable => reader = "getReader"
@send external cancelReader: reader => promise<unit> = "cancel"

type audioData

type readResult = {
  @as("done") done_: bool,
  value: Nullable.t<audioData>,
}

@send external read: reader => promise<readResult> = "read"

@get external audioDataTimestamp: audioData => float = "timestamp" // µs
@get external audioDataSampleRate: audioData => float = "sampleRate"
@get external audioDataChannels: audioData => int = "numberOfChannels"
@send external closeAudioData: audioData => unit = "close"

// --- AudioEncoder ---

type encodedAudioChunk

@get external audioChunkTimestamp: encodedAudioChunk => float = "timestamp" // µs
@get external audioChunkDuration: encodedAudioChunk => Nullable.t<float> = "duration" // µs
@get external audioChunkByteLength: encodedAudioChunk => int = "byteLength"
@send external audioCopyTo: (encodedAudioChunk, Uint8Array.t) => unit = "copyTo"

type audioEncoderConfig = {
  codec: string,
  sampleRate: float,
  numberOfChannels: int,
  bitrate?: float,
}

type audioDecoderConfig = {
  codec?: string,
  sampleRate?: float,
  numberOfChannels?: int,
  description?: Uint8Array.t,
}
type audioChunkMetadata = {decoderConfig?: audioDecoderConfig}

type audioEncoder

type audioEncoderInit = {
  output: (encodedAudioChunk, Nullable.t<audioChunkMetadata>) => unit,
  error: Js.Exn.t => unit,
}

@new external makeAudioEncoder: audioEncoderInit => audioEncoder = "AudioEncoder"

@scope("AudioEncoder") @val
external isAudioConfigSupported: audioEncoderConfig => promise<configSupport> = "isConfigSupported"

@send external configureAudio: (audioEncoder, audioEncoderConfig) => unit = "configure"
@send external encodeAudio: (audioEncoder, audioData) => unit = "encode"
@send external flushAudio: audioEncoder => promise<unit> = "flush"
@send external closeAudioEncoder: audioEncoder => unit = "close"
@get external audioEncodeQueueSize: audioEncoder => int = "encodeQueueSize"
