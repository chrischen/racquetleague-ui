/* TypeScript file generated from CourtPseudoEventGroupStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CourtPseudoEventGroupStoryJS from './CourtPseudoEventGroupStory.re.mjs';

/** The windows the row saves, in hours (19.5 is 19:30). */
export type window = { readonly start: number; readonly end: number };

export type props<state,onAvailabilityChange> = { readonly state?: state; readonly onAvailabilityChange?: onAvailabilityChange };

export const make: React.ComponentType<{ readonly state?: 
    "afternoonRun"
  | "morning"
  | "noPlayers"
  | "singleVenue"; readonly onAvailabilityChange?: (_1:window[]) => void }> = CourtPseudoEventGroupStoryJS.make as any;
