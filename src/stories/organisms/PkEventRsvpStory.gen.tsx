/* TypeScript file generated from PkEventRsvpStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PkEventRsvpStoryJS from './PkEventRsvpStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<list,isAdmin,chargesEnabled,showRating,hostId> = {
  readonly list?: list; 
  readonly isAdmin?: isAdmin; 
  readonly chargesEnabled?: chargesEnabled; 
  readonly showRating?: showRating; 
  readonly hostId?: hostId
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PkEventRsvpStoryJS.query as any;

export const make: React.ComponentType<{
  readonly list?: 
    "confirmed"
  | "invited"
  | "pending"
  | "waitlist"; 
  readonly isAdmin?: boolean; 
  readonly chargesEnabled?: boolean; 
  readonly showRating?: boolean; 
  readonly hostId?: string
}> = PkEventRsvpStoryJS.make as any;
