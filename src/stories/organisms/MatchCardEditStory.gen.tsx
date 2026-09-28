/* TypeScript file generated from MatchCardEditStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MatchCardEditStoryJS from './MatchCardEditStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,courtNumber,onSave,onCancel,onDelete> = {
  readonly state?: state; 
  readonly courtNumber?: courtNumber; 
  readonly onSave?: onSave; 
  readonly onCancel?: onCancel; 
  readonly onDelete?: onDelete
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = MatchCardEditStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "longNames"
  | "scored"
  | "unscored"
  | "winnerPicked"; 
  readonly courtNumber?: number; 
  readonly onSave?: (_1:(undefined | [number, number])) => void; 
  readonly onCancel?: () => void; 
  readonly onDelete?: () => void
}> = MatchCardEditStoryJS.make as any;
