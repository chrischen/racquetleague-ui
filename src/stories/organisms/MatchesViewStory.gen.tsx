/* TypeScript file generated from MatchesViewStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MatchesViewStoryJS from './MatchesViewStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<view,state,onClose,onSubmitResults,onMatchUpdated,onMatchCanceled> = {
  readonly view?: view; 
  readonly state?: state; 
  readonly onClose?: onClose; 
  readonly onSubmitResults?: onSubmitResults; 
  readonly onMatchUpdated?: onMatchUpdated; 
  readonly onMatchCanceled?: onMatchCanceled
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = MatchesViewStoryJS.query as any;

export const make: React.ComponentType<{
  readonly view?: 
    "checkin"
  | "matches"
  | "queue"; 
  readonly state?: 
    "noMatches"
  | "readyToChoose"
  | "typical"; 
  readonly onClose?: () => void; 
  readonly onSubmitResults?: () => void; 
  readonly onMatchUpdated?: (_1:string, _2:(undefined | [number, number])) => void; 
  readonly onMatchCanceled?: (_1:string) => void
}> = MatchesViewStoryJS.make as any;
