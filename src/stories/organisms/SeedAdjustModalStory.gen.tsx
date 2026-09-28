/* TypeScript file generated from SeedAdjustModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SeedAdjustModalStoryJS from './SeedAdjustModalStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,onSave,onClose,onUseClubRatings> = {
  readonly state?: state; 
  readonly onSave?: onSave; 
  readonly onClose?: onClose; 
  readonly onUseClubRatings?: onUseClubRatings
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = SeedAdjustModalStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "checkedIn"
  | "clubEvent"
  | "clubRatings"
  | "loadingClubRatings"
  | "walkInsOnly"
  | "withGuests"; 
  readonly onSave?: (_1:Array<[string, number]>) => void; 
  readonly onClose?: () => void; 
  readonly onUseClubRatings?: (_1:boolean) => void
}> = SeedAdjustModalStoryJS.make as any;
