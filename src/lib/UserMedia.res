// Minimal bindings for navigator.mediaDevices camera capture, used by the
// kiosk page to show a live court camera feed.
type track

@send external stopTrack: track => unit = "stop"

// A MediaStream returned by getUserMedia.
type t

@send external getTracks: t => array<track> = "getTracks"
@send external getAudioTracks: t => array<track> = "getAudioTracks"

type exactDevice = {exact: string}
type videoTrackConstraints = {deviceId?: exactDevice}
type constraints = {video: videoTrackConstraints, audio: bool}

// An empty video constraint set means "any camera", same as `video: true`.
let constraintsFor = (~deviceId: option<string>, ~audio: bool=false) => {
  let deviceId = deviceId->Option.map(id => {exact: id})
  {video: {deviceId: ?deviceId}, audio}
}

type deviceInfo = {deviceId: string, kind: string, label: string}

type mediaDevices

// Undefined on insecure origins and very old browsers, so keep it nullable.
@val @scope("navigator")
external mediaDevices: Nullable.t<mediaDevices> = "mediaDevices"

@send
external getUserMedia: (mediaDevices, constraints) => promise<t> = "getUserMedia"

@send
external enumerateDevices: mediaDevices => promise<array<deviceInfo>> = "enumerateDevices"

// Fires when a camera is plugged in or removed.
@send
external addDeviceChangeListener: (mediaDevices, @as("devicechange") _, unit => unit) => unit =
  "addEventListener"
@send
external removeDeviceChangeListener: (mediaDevices, @as("devicechange") _, unit => unit) => unit =
  "removeEventListener"

// video.srcObject has no ReScript DOM prop; set it imperatively via a ref.
@set external setSrcObject: (Dom.element, Nullable.t<t>) => unit = "srcObject"

let stopAll = (stream: t) => stream->getTracks->Array.forEach(stopTrack)
