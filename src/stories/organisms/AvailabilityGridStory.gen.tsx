/* TypeScript file generated from AvailabilityGridStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as AvailabilityGridStoryJS from './AvailabilityGridStory.re.mjs';

/** One edited day as the grid saves it. */
export type interval = { readonly startHour: number; readonly endHour: number };

export type dayUpdate = { readonly isoDate: string; readonly intervals: interval[] };

export type props<state,isSaving,onSave> = {
  readonly state?: state; 
  readonly isSaving?: isSaving; 
  readonly onSave?: onSave
};

export const make: React.ComponentType<{
  readonly state?: 
    "blank"
  | "planned"; 
  readonly isSaving?: boolean; 
  readonly onSave?: (_1:dayUpdate[]) => void
}> = AvailabilityGridStoryJS.make as any;
