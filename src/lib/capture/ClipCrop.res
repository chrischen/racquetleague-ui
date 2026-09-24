// ReScript face of cropClip.ts (same convention as MuxBindings).

type rect = {x: int, y: int, width: int, height: int}

@module("./cropClip") external isAvailable: unit => bool = "isAvailable"

@module("./cropClip")
external cropClipRaw: (CaptureSession.encodedVideo, rect) => promise<CaptureSession.blob> = "cropClip"

let crop = async (source: CaptureSession.encodedVideo, rect: rect): result<
  CaptureSession.blob,
  string,
> =>
  try {
    Ok(await cropClipRaw(source, rect))
  } catch {
  | exn => Error(MuxBindings.errorToMessage(exn))
  }
