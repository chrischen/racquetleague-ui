// Minimal bindings for navigator.mediaDevices camera capture, used by the
// kiosk page to show a live court camera feed.
type track

@send external stopTrack: track => unit = "stop"

// A MediaStream returned by getUserMedia.
type t

@send external getTracks: t => array<track> = "getTracks"
@send external getAudioTracks: t => array<track> = "getAudioTracks"
@send external getVideoTracks: t => array<track> = "getVideoTracks"

// MediaTrackSettings — only the fields the kiosk needs (native frame size,
// for mapping calibration drags into video-pixel space; the delivered frame
// rate, for sizing the ring encoder).
type trackSettings = {width?: int, height?: int, frameRate?: float}
@send external getSettings: track => trackSettings = "getSettings"

let videoSettings = (stream: t): option<trackSettings> =>
  stream->getVideoTracks->Array.get(0)->Option.map(getSettings)

let videoSize = (stream: t): option<(int, int)> =>
  stream
  ->videoSettings
  ->Option.flatMap(settings =>
    switch (settings.width, settings.height) {
    | (Some(w), Some(h)) => Some((w, h))
    | _ => None
    }
  )

let videoFrameRate = (stream: t): option<float> =>
  stream->videoSettings->Option.flatMap(settings => settings.frameRate)

type exactDevice = {exact: string}
type ideal<'a> = {ideal: 'a}
type videoTrackConstraints = {deviceId?: exactDevice, width?: ideal<int>, height?: ideal<int>}
type constraints = {video: videoTrackConstraints, audio: bool}

// The frame size the kiosk asks the camera for.  Without a size constraint
// browsers open a small default mode (Chrome: 640x480) — measured: every
// spooled Challenge clip was 640x480 from a camera that runs 1080p in the
// Python app.  `ideal` is a preference, so a camera without this mode still
// opens at its nearest one.  1080p, not more: it is the kiosk camera's clean
// sensor mode (main.py probes it first), the ball detector resizes its input
// to 512x288 regardless, and anything above 1080p only multiplies the
// analysis decode cost while buying the display nothing.
let nativeVideo = (1920, 1080)

// `Native` is the kiosk's capture mode; `BrowserDefault` is for throwaway
// streams (device-label priming) that should not spin the camera up.
type videoMode = Native | BrowserDefault

let constraintsFor = (~deviceId: option<string>, ~audio: bool=false, ~mode: videoMode=Native) => {
  let deviceId = deviceId->Option.map(id => {exact: id})
  let (w, h) = nativeVideo
  switch mode {
  | Native => {video: {deviceId: ?deviceId, width: {ideal: w}, height: {ideal: h}}, audio}
  | BrowserDefault => {video: {deviceId: ?deviceId}, audio}
  }
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
