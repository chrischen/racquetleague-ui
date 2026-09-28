/* TypeScript file generated from CompMatchStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CompMatchStoryJS from './CompMatchStory.re.mjs';

export type props<state,strategy,onSelectMatch> = {
  readonly state?: state; 
  readonly strategy?: strategy; 
  readonly onSelectMatch?: onSelectMatch
};

export const make: React.ComponentType<{
  readonly state?: 
    "notEnoughPlayers"
  | "queue"
  | "replacePlayer"
  | "somePlaying"
  | "withHistory"; 
  readonly strategy?: 
    "competitive"
  | "mixed"; 
  readonly onSelectMatch?: (_1:string) => void
}> = CompMatchStoryJS.make as any;
