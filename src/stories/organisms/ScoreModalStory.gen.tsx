/* TypeScript file generated from ScoreModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ScoreModalStoryJS from './ScoreModalStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<winningTeam,state,onSubmit,onClose> = {
  readonly winningTeam?: winningTeam; 
  readonly state?: state; 
  readonly onSubmit?: onSubmit; 
  readonly onClose?: onClose
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = ScoreModalStoryJS.query as any;

export const make: React.ComponentType<{
  readonly winningTeam?: 
    "team1"
  | "team2"; 
  readonly state?: 
    "longNames"
  | "typical"; 
  readonly onSubmit?: (_1:number, _2:number) => void; 
  readonly onClose?: () => void
}> = ScoreModalStoryJS.make as any;
