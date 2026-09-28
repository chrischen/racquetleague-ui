// Storybook support for KioskCourtCalib.stories.tsx; the app never imports
// this. In the kiosk the calibration overlay sits over the live camera view;
// here it sits the same way (video letterboxed with object-contain, overlay
// absolutely on top) over a synthetic court camera from
// StoryFixturesServices. Confirm goes to a stand-in for the analysis sidecar,
// never to a real one.
open StoryFixturesServices

@genType @react.component
let make = (
  ~anchors: [#none | #wholeCourt | #kitchenOnly]=#none,
  ~sidecar: sidecar=#online,
  ~onDone=() => (),
) => {
  useSidecar(sidecar)
  // The overlay reads its stored anchors on its first render, so they are
  // written before it mounts.
  useInstalled(() => {
    setStored(
      KioskCourtCalib.cornersStorageKey,
      switch anchors {
      | #none => None
      | #wholeCourt => anchoredCourt()
      | #kitchenOnly => kitchenOnly()
      },
    )
    setStored(KioskCourtCalib.loupeStorageKey, None)
    () => ()
  })
  let (stream, _) = React.useState(() =>
    courtStream(~camera=anchors == #kitchenOnly ? closeCamera : baselineCamera)
  )
  React.useEffect0(() => Some(() => stopStream(stream)))
  let videoRef = React.useRef(Nullable.null)
  React.useEffect0(() => {
    videoRef.current->Nullable.forEach(video => video->UserMedia.setSrcObject(Nullable.make(stream)))
    None
  })
  <div className="relative h-dvh w-full overflow-hidden bg-black">
    <video
      ref={ReactDOM.Ref.domRef(videoRef)}
      autoPlay=true
      muted=true
      playsInline=true
      className="absolute inset-0 h-full w-full object-contain"
    />
    <KioskCourtCalib stream=Some(stream) onDone />
  </div>
}
