/* TypeScript file generated from SeedAdjustmentTimelineStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SeedAdjustmentTimelineStoryJS from './SeedAdjustmentTimelineStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,onDelete> = { readonly state?: state; readonly onDelete?: onDelete };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = SeedAdjustmentTimelineStoryJS.query as any;

export const make: React.ComponentType<{ readonly state?: 
    "everyone"
  | "seeds"
  | "severalRounds"
  | "singlePlayer"; readonly onDelete?: (_1:string) => void }> = SeedAdjustmentTimelineStoryJS.make as any;
