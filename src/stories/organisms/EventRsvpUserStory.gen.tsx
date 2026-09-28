/* TypeScript file generated from EventRsvpUserStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventRsvpUserStoryJS from './EventRsvpUserStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<highlight,secondaryText,ratingPercent,sigmaPercent> = {
  readonly highlight?: highlight; 
  readonly secondaryText?: secondaryText; 
  readonly ratingPercent?: ratingPercent; 
  readonly sigmaPercent?: sigmaPercent
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventRsvpUserStoryJS.query as any;

export const make: React.ComponentType<{
  readonly highlight?: boolean; 
  readonly secondaryText?: string; 
  readonly ratingPercent?: number; 
  readonly sigmaPercent?: number
}> = EventRsvpUserStoryJS.make as any;
