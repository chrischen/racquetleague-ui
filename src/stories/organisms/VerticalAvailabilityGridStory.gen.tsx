/* TypeScript file generated from VerticalAvailabilityGridStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as VerticalAvailabilityGridStoryJS from './VerticalAvailabilityGridStory.re.mjs';

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
  | "firstVisit"
  | "planned"; 
  readonly isSaving?: boolean; 
  readonly onSave?: (_1:dayUpdate[]) => void
}> = VerticalAvailabilityGridStoryJS.make as any;
