// TODO(kiosk): thin-client capture mode — compress the camera stream and send
// it to a server (WebRTC/WHIP uplink), with the rolling buffer and clip
// extraction living server-side; takeClip becomes an API call. This stub is
// interface-complete so the settings toggle and the Capture factory already
// have a second mode to point at.

let make = (~onStatus as _: CaptureSession.status => unit): CaptureSession.t => {
  capabilities: () => {
    CaptureSession.canClip: false,
    hasAudio: false,
    detail: Some("Thin-client mode is not implemented yet"),
  },
  start: _stream => Promise.resolve(Error(CaptureSession.NotImplemented)),
  takeClip: (~seconds as _=?) => Promise.resolve(Error(CaptureSession.ClipUnavailable)),
  stop: () => (),
}
