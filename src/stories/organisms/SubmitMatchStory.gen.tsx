/* TypeScript file generated from SubmitMatchStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SubmitMatchStoryJS from './SubmitMatchStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,scoreEntry,withScore,onDelete,onComplete> = {
  readonly state?: state; 
  readonly scoreEntry?: scoreEntry; 
  readonly withScore?: withScore; 
  readonly onDelete?: onDelete; 
  readonly onComplete?: onComplete
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = SubmitMatchStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "guests"
  | "longNames"
  | "rated"; 
  readonly scoreEntry?: boolean; 
  readonly withScore?: boolean; 
  readonly onDelete?: () => void; 
  readonly onComplete?: (_1:string, _2:(undefined | [number, number])) => void
}> = SubmitMatchStoryJS.make as any;
