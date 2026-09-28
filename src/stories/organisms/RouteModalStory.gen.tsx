/* TypeScript file generated from RouteModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RouteModalStoryJS from './RouteModalStory.re.mjs';

export type props<state,onClose,onBack> = {
  readonly state?: state; 
  readonly onClose?: onClose; 
  readonly onBack?: onBack
};

export const make: React.ComponentType<{
  readonly state?: 
    "flowStep"
  | "longContent"
  | "planChooser"
  | "titleOnly"; 
  readonly onClose?: () => void; 
  readonly onBack?: () => void
}> = RouteModalStoryJS.make as any;
