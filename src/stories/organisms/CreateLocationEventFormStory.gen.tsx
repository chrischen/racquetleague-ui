/* TypeScript file generated from CreateLocationEventFormStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CreateLocationEventFormStoryJS from './CreateLocationEventFormStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type prefill = "none" | "draft" | "paidDraft";

export type props<prefill,withVenue,stripeChargesEnabled,onLocationSelected,onClubFormSubmitBlocked> = {
  readonly prefill?: prefill; 
  readonly withVenue?: withVenue; 
  readonly stripeChargesEnabled?: stripeChargesEnabled; 
  readonly onLocationSelected?: onLocationSelected; 
  readonly onClubFormSubmitBlocked?: onClubFormSubmitBlocked
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = CreateLocationEventFormStoryJS.query as any;

export const make: React.ComponentType<{
  readonly prefill?: prefill; 
  readonly withVenue?: boolean; 
  readonly stripeChargesEnabled?: boolean; 
  readonly onLocationSelected?: (_1:string) => void; 
  readonly onClubFormSubmitBlocked?: () => void
}> = CreateLocationEventFormStoryJS.make as any;
