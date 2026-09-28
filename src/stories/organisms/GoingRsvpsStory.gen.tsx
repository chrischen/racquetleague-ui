/* TypeScript file generated from GoingRsvpsStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as GoingRsvpsStoryJS from './GoingRsvpsStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<activitySlug,maxRating,viewerId> = {
  readonly activitySlug?: activitySlug; 
  readonly maxRating?: maxRating; 
  readonly viewerId?: viewerId
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = GoingRsvpsStoryJS.query as any;

export const make: React.ComponentType<{
  readonly activitySlug?: 
    "badminton"
  | "pickleball"; 
  readonly maxRating?: number; 
  readonly viewerId?: string
}> = GoingRsvpsStoryJS.make as any;
