/* TypeScript file generated from ClubEventsListStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ClubEventsListStoryJS from './ClubEventsListStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<selectedLocationId,onHoverLocation> = { readonly selectedLocationId?: selectedLocationId; readonly onHoverLocation?: onHoverLocation };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = ClubEventsListStoryJS.query as any;

export const make: React.ComponentType<{ readonly selectedLocationId?: string; readonly onHoverLocation?: (_1:(undefined | string)) => void }> = ClubEventsListStoryJS.make as any;
