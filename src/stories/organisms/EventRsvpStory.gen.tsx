/* TypeScript file generated from EventRsvpStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventRsvpStoryJS from './EventRsvpStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<activitySlug,isAdmin,eventPrice,waitlist,viewerId> = {
  readonly activitySlug?: activitySlug; 
  readonly isAdmin?: isAdmin; 
  readonly eventPrice?: eventPrice; 
  readonly waitlist?: waitlist; 
  readonly viewerId?: viewerId
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventRsvpStoryJS.query as any;

export const make: React.ComponentType<{
  readonly activitySlug?: 
    "badminton"
  | "pickleball"; 
  readonly isAdmin?: boolean; 
  readonly eventPrice?: number; 
  readonly waitlist?: boolean; 
  readonly viewerId?: string
}> = EventRsvpStoryJS.make as any;
