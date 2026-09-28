/* TypeScript file generated from EventLocationAvailabilityStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventLocationAvailabilityStoryJS from './EventLocationAvailabilityStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<genericCourtName> = { readonly genericCourtName?: genericCourtName };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventLocationAvailabilityStoryJS.query as any;

export const make: React.ComponentType<{ readonly genericCourtName?: string }> = EventLocationAvailabilityStoryJS.make as any;
