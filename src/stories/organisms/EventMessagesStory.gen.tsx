/* TypeScript file generated from EventMessagesStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventMessagesStoryJS from './EventMessagesStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<eventStartDate,viewerHasRsvp> = { readonly eventStartDate?: eventStartDate; readonly viewerHasRsvp?: viewerHasRsvp };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventMessagesStoryJS.query as any;

export const make: React.ComponentType<{ readonly eventStartDate?: string; readonly viewerHasRsvp?: boolean }> = EventMessagesStoryJS.make as any;
