/* TypeScript file generated from MatchCardStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MatchCardStoryJS from './MatchCardStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,editing,debug,courtNumber,onDelete,onRebalance,onUpdated> = {
  readonly state?: state; 
  readonly editing?: editing; 
  readonly debug?: debug; 
  readonly courtNumber?: courtNumber; 
  readonly onDelete?: onDelete; 
  readonly onRebalance?: onRebalance; 
  readonly onUpdated?: onUpdated
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = MatchCardStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "draw"
  | "lastRound"
  | "longNames"
  | "mismatch"
  | "repeat"
  | "scored"
  | "unscored"
  | "winnerPicked"; 
  readonly editing?: boolean; 
  readonly debug?: boolean; 
  readonly courtNumber?: number; 
  readonly onDelete?: () => void; 
  readonly onRebalance?: () => void; 
  readonly onUpdated?: (_1:(undefined | [number, number])) => void
}> = MatchCardStoryJS.make as any;
