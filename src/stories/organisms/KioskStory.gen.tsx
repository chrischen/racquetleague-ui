/* TypeScript file generated from KioskStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as KioskStoryJS from './KioskStory.re.mjs';

import type {cameraAccess as StoryFixturesServices_cameraAccess} from './StoryFixturesServices.gen';

import type {sidecar as StoryFixturesServices_sidecar} from './StoryFixturesServices.gen';

export type props<camera,sidecar,testMode,courtCalibrated> = {
  readonly camera?: camera; 
  readonly sidecar?: sidecar; 
  readonly testMode?: testMode; 
  readonly courtCalibrated?: courtCalibrated
};

export const make: React.ComponentType<{
  readonly camera?: StoryFixturesServices_cameraAccess; 
  readonly sidecar?: StoryFixturesServices_sidecar; 
  readonly testMode?: boolean; 
  readonly courtCalibrated?: boolean
}> = KioskStoryJS.make as any;
