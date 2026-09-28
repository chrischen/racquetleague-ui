/* TypeScript file generated from SortableSubmitMatchStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SortableSubmitMatchStoryJS from './SortableSubmitMatchStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,scoreEntry,onDelete,onUpdated> = {
  readonly state?: state; 
  readonly scoreEntry?: scoreEntry; 
  readonly onDelete?: onDelete; 
  readonly onUpdated?: onUpdated
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = SortableSubmitMatchStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "guests"
  | "longNames"
  | "rated"; 
  readonly scoreEntry?: boolean; 
  readonly onDelete?: () => void; 
  readonly onUpdated?: (_1:(undefined | [number, number])) => void
}> = SortableSubmitMatchStoryJS.make as any;
