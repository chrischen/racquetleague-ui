// ReScript face of muxLoader.ts. Same error convention as HighsBindings:
// async boundary wrapped in try/catch, surfaced as result.

type muxChunk = {
  bytes: Uint8Array.t,
  timestampUs: float,
  durationUs: float,
  isKey: bool,
}

type muxVideoConfig = {
  codec: string,
  width: int,
  height: int,
  description?: Uint8Array.t,
}

type muxAudioConfig = {
  containerCodec: string, // "aac" | "opus"
  codec: string, // e.g. "mp4a.40.2"
  sampleRate: float,
  numberOfChannels: int,
  description?: Uint8Array.t,
}

@module("./muxLoader")
external muxClipRaw: (
  muxVideoConfig,
  array<muxChunk>,
  option<muxAudioConfig>, // unboxed: reaches TS as MuxAudioConfig | undefined
  array<muxChunk>,
) => promise<CaptureSession.blob> = "muxClip"

let errorToMessage = exn =>
  exn->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")

let muxClip = async (
  ~video: muxVideoConfig,
  ~videoChunks: array<muxChunk>,
  ~audio: option<muxAudioConfig>,
  ~audioChunks: array<muxChunk>,
): result<CaptureSession.blob, string> =>
  try {
    Ok(await muxClipRaw(video, videoChunks, audio, audioChunks))
  } catch {
  | exn => Error(errorToMessage(exn))
  }
