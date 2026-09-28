/* TypeScript file generated from MiniEventRsvpStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MiniEventRsvpStoryJS from './MiniEventRsvpStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<layout> = { readonly layout?: layout };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = MiniEventRsvpStoryJS.query as any;

export const make: React.ComponentType<{ readonly layout?: "mobileBar" | "row" }> = MiniEventRsvpStoryJS.make as any;
