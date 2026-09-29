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
  // As in the kiosk, the toolbar portals into a row ABOVE the video.
  let (toolbarHost, setToolbarHost) = React.useState(() => (None: option<Dom.element>))
  let toolbarRef = React.useCallback0(el => setToolbarHost(_ => el->Nullable.toOption))
  <div className="flex h-dvh w-full flex-col overflow-hidden bg-black">
    <div ref={ReactDOM.Ref.callbackDomRef(toolbarRef)} className="shrink-0 p-2" />
    <div className="relative min-h-0 flex-1">
      <video
        ref={ReactDOM.Ref.domRef(videoRef)}
        autoPlay=true
        muted=true
        playsInline=true
        className="absolute inset-0 h-full w-full object-contain"
      />
      <KioskCourtCalib stream=Some(stream) toolbarHost onDone />
    </div>
  </div>
}
