/* TypeScript file generated from FullScreenRoundViewStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as FullScreenRoundViewStoryJS from './FullScreenRoundViewStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,onClose> = { readonly state?: state; readonly onClose?: onClose };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = FullScreenRoundViewStoryJS.query as any;

export const make: React.ComponentType<{ readonly state?: 
    "fourCourts"
  | "longNames"
  | "notStarted"
  | "partlyScored"
  | "twoCourts"; readonly onClose?: () => void }> = FullScreenRoundViewStoryJS.make as any;
