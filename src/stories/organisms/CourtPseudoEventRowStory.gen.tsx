/* TypeScript file generated from CourtPseudoEventRowStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CourtPseudoEventRowStoryJS from './CourtPseudoEventRowStory.re.mjs';

/** The windows the row saves, in hours (19.5 is 19:30). */
export type window = { readonly start: number; readonly end: number };

export type props<state,onAvailabilityChange> = { readonly state?: state; readonly onAvailabilityChange?: onAvailabilityChange };

export const make: React.ComponentType<{ readonly state?: 
    "nobodyYet"
  | "othersOnly"
  | "unpricedVenue"
  | "viewerAvailable"; readonly onAvailabilityChange?: (_1:window[]) => void }> = CourtPseudoEventRowStoryJS.make as any;
