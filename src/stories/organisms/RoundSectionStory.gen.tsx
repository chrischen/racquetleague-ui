/* TypeScript file generated from RoundSectionStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RoundSectionStoryJS from './RoundSectionStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,debug,onRebalance,onRebalanceMatch,onReset,onFullScreen,onMatchUpdated,onMatchCanceled> = {
  readonly state?: state; 
  readonly debug?: debug; 
  readonly onRebalance?: onRebalance; 
  readonly onRebalanceMatch?: onRebalanceMatch; 
  readonly onReset?: onReset; 
  readonly onFullScreen?: onFullScreen; 
  readonly onMatchUpdated?: onMatchUpdated; 
  readonly onMatchCanceled?: onMatchCanceled
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = RoundSectionStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "current"
  | "manyWaiting"
  | "past"
  | "repeats"
  | "upcoming"; 
  readonly debug?: boolean; 
  readonly onRebalance?: () => void; 
  readonly onRebalanceMatch?: (_1:string) => void; 
  readonly onReset?: (_1:boolean) => void; 
  readonly onFullScreen?: () => void; 
  readonly onMatchUpdated?: (_1:string, _2:(undefined | [number, number])) => void; 
  readonly onMatchCanceled?: (_1:string) => void
}> = RoundSectionStoryJS.make as any;
