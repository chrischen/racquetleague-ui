/* TypeScript file generated from SelectMatchStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SelectMatchStoryJS from './SelectMatchStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,onMatchQueued> = { readonly state?: state; readonly onMatchQueued?: onMatchQueued };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = SelectMatchStoryJS.query as any;

export const make: React.ComponentType<{ readonly state?: 
    "empty"
  | "longNames"
  | "typical"
  | "withGuests"; readonly onMatchQueued?: (_1:string) => void }> = SelectMatchStoryJS.make as any;
