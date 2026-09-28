/* TypeScript file generated from StoryFixturesServices.res by genType. */

/* eslint-disable */
/* tslint:disable */

export type cameraAccess = "granted" | "denied" | "absent";

/** How the sidecar answers: `#online` with fixture results; `#offline` as if
 nothing listens on :3003; `#rejectsCourt` refuses a calibration;
 `#noTestClip` has no test_challenge.mov; `#noBounces` finds nothing. */
export type sidecar = 
    "online"
  | "offline"
  | "rejectsCourt"
  | "noTestClip"
  | "noBounces";
