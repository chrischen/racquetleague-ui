// Storybook support for Kiosk.stories.tsx; the app never imports this. The
// kiosk takes no props: what a story controls is the world around it, set up
// before it mounts (StoryFixturesServices):
// - camera access: granted (a synthetic court camera and two named USB
//   cameras), denied, or no camera at all;
// - the analysis sidecar on localhost:3003: a stand-in answering with
//   fixture results, or behaving as offline. No story reaches a real one;
// - the kiosk's saved settings in localStorage: test mode, and whether a
//   court calibration is already on file.
open StoryFixturesServices

@genType @react.component
let make = (
  ~camera: cameraAccess=#granted,
  ~sidecar: sidecar=#online,
  ~testMode=false,
  ~courtCalibrated=true,
) => {
  useCameraAccess(camera)
  useSidecar(sidecar)
  useInstalled(() => {
    setStored(Kiosk.testModeStorageKey, testMode ? Some("1") : None)
    setStored(Kiosk.cameraStorageKey, None)
    setStored(CaptureSession.modeStorageKey, None)
    setStored(KioskCourtCalib.cornersStorageKey, courtCalibrated ? anchoredCourt() : None)
    () => ()
  })
  <Kiosk />
}
