/* TypeScript file generated from PkEventsListStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PkEventsListStoryJS from './PkEventsListStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<showInlineCourts,showLocationFilter,hideOtherClubs,selectedLocationId,onHoverLocation> = {
  readonly showInlineCourts?: showInlineCourts; 
  readonly showLocationFilter?: showLocationFilter; 
  readonly hideOtherClubs?: hideOtherClubs; 
  readonly selectedLocationId?: selectedLocationId; 
  readonly onHoverLocation?: onHoverLocation
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PkEventsListStoryJS.query as any;

export const make: React.ComponentType<{
  readonly showInlineCourts?: boolean; 
  readonly showLocationFilter?: boolean; 
  readonly hideOtherClubs?: boolean; 
  readonly selectedLocationId?: string; 
  readonly onHoverLocation?: (_1:(undefined | string)) => void
}> = PkEventsListStoryJS.make as any;
