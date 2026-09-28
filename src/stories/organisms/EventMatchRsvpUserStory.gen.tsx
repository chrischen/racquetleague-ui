/* TypeScript file generated from EventMatchRsvpUserStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventMatchRsvpUserStoryJS from './EventMatchRsvpUserStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<status,compact,showPlayCount> = {
  readonly status?: status; 
  readonly compact?: compact; 
  readonly showPlayCount?: showPlayCount
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventMatchRsvpUserStoryJS.query as any;

export const make: React.ComponentType<{
  readonly status?: 
    "available"
  | "break"
  | "mixed"
  | "playing"
  | "queued"; 
  readonly compact?: boolean; 
  readonly showPlayCount?: boolean
}> = EventMatchRsvpUserStoryJS.make as any;
