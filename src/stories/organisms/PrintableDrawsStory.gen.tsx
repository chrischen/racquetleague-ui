/* TypeScript file generated from PrintableDrawsStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PrintableDrawsStoryJS from './PrintableDrawsStory.re.mjs';

export type props<state,onClose> = { readonly state?: state; readonly onClose?: onClose };

export const make: React.ComponentType<{ readonly state?: 
    "empty"
  | "longNames"
  | "manyRounds"
  | "singleMatch"
  | "threeRounds"; readonly onClose?: () => void }> = PrintableDrawsStoryJS.make as any;
