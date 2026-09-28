/* TypeScript file generated from PendingRsvpsStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PendingRsvpsStoryJS from './PendingRsvpsStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<activitySlug,maxRating,previewAdmittedIds> = {
  readonly activitySlug?: activitySlug; 
  readonly maxRating?: maxRating; 
  readonly previewAdmittedIds?: previewAdmittedIds
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PendingRsvpsStoryJS.query as any;

export const make: React.ComponentType<{
  readonly activitySlug?: 
    "badminton"
  | "pickleball"; 
  readonly maxRating?: number; 
  readonly previewAdmittedIds?: string[]
}> = PendingRsvpsStoryJS.make as any;
