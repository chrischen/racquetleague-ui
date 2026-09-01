// Factory over the capture-mode seam. Kiosk.res calls this and otherwise
// only touches CaptureSession types.

let makeSession = (
  ~mode: CaptureSession.mode,
  ~onStatus: CaptureSession.status => unit,
): CaptureSession.t =>
  switch mode {
  | LocalRing => LocalRingCapture.make(~onStatus)
  | ThinClient => ThinClientCapture.make(~onStatus)
  }
