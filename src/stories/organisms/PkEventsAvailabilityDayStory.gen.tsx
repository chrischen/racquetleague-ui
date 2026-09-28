/* TypeScript file generated from PkEventsAvailabilityDayStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PkEventsAvailabilityDayStoryJS from './PkEventsAvailabilityDayStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

/** The window "Host event" hands over, in hours (19.5 is 19:30). */
export type window = { readonly start: number; readonly end: number };

export type props<localDate,label,eventCount,host,onCreateEvent,onRefetchNeeded> = {
  readonly localDate?: localDate; 
  readonly label?: label; 
  readonly eventCount?: eventCount; 
  readonly host?: host; 
  readonly onCreateEvent?: onCreateEvent; 
  readonly onRefetchNeeded?: onRefetchNeeded
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PkEventsAvailabilityDayStoryJS.query as any;

export const make: React.ComponentType<{
  readonly localDate?: string; 
  readonly label?: string; 
  readonly eventCount?: number; 
  readonly host?: 
    "club"
  | "discover"
  | "locationClub"; 
  readonly onCreateEvent?: (_1:string, _2:window) => void; 
  readonly onRefetchNeeded?: () => void
}> = PkEventsAvailabilityDayStoryJS.make as any;
