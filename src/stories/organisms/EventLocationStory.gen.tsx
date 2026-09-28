/* TypeScript file generated from EventLocationStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventLocationStoryJS from './EventLocationStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<hideAddress> = { readonly hideAddress?: hideAddress };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventLocationStoryJS.query as any;

export const make: React.ComponentType<{ readonly hideAddress?: boolean }> = EventLocationStoryJS.make as any;
