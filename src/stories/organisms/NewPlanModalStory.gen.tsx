/* TypeScript file generated from NewPlanModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as NewPlanModalStoryJS from './NewPlanModalStory.re.mjs';

/** A drawn window, in hours (19.5 is 19:30). */
export type window = { readonly start: number; readonly end: number };

export type props<isOpen,onClose,onMarkAvailable,onCreateEvent> = {
  readonly isOpen?: isOpen; 
  readonly onClose?: onClose; 
  readonly onMarkAvailable?: onMarkAvailable; 
  readonly onCreateEvent?: onCreateEvent
};

export const make: React.ComponentType<{
  readonly isOpen?: boolean; 
  readonly onClose?: () => void; 
  readonly onMarkAvailable?: (_1:string, _2:window[]) => void; 
  readonly onCreateEvent?: (_1:string, _2:window) => void
}> = NewPlanModalStoryJS.make as any;
