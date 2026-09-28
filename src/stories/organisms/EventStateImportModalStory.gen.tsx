/* TypeScript file generated from EventStateImportModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventStateImportModalStoryJS from './EventStateImportModalStory.re.mjs';

export type props<local,disabled,onImport,onClose> = {
  readonly local?: local; 
  readonly disabled?: disabled; 
  readonly onImport?: onImport; 
  readonly onClose?: onClose
};

export const make: React.ComponentType<{
  readonly local?: 
    "fresh"
  | "partial"
  | "upToDate"; 
  readonly disabled?: boolean; 
  readonly onImport?: (_1:string) => void; 
  readonly onClose?: () => void
}> = EventStateImportModalStoryJS.make as any;
