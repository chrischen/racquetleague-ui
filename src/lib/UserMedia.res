// Minimal bindings for navigator.mediaDevices camera capture, used by the
// kiosk page to show a live court camera feed.
type track

@send external stopTrack: track => unit = "stop"

// A MediaStream returned by getUserMedia.
type t

@send external getTracks: t => array<track> = "getTracks"

type constraints = {video: bool, audio: bool}

type mediaDevices

// Undefined on insecure origins and very old browsers, so keep it nullable.
@val @scope("navigator")
external mediaDevices: Nullable.t<mediaDevices> = "mediaDevices"

@send
external getUserMedia: (mediaDevices, constraints) => promise<t> = "getUserMedia"

// video.srcObject has no ReScript DOM prop; set it imperatively via a ref.
@set external setSrcObject: (Dom.element, Nullable.t<t>) => unit = "srcObject"

let stopAll = (stream: t) => stream->getTracks->Array.forEach(stopTrack)
