/* TypeScript file generated from KioskCourtCalibStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as KioskCourtCalibStoryJS from './KioskCourtCalibStory.re.mjs';

import type {sidecar as StoryFixturesServices_sidecar} from './StoryFixturesServices.gen';

export type props<anchors,sidecar,onDone> = {
  readonly anchors?: anchors; 
  readonly sidecar?: sidecar; 
  readonly onDone?: onDone
};

export const make: React.ComponentType<{
  readonly anchors?: 
    "kitchenOnly"
  | "none"
  | "wholeCourt"; 
  readonly sidecar?: StoryFixturesServices_sidecar; 
  readonly onDone?: () => void
}> = KioskCourtCalibStoryJS.make as any;
