/* TypeScript file generated from RsvpOptionsStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RsvpOptionsStoryJS from './RsvpOptionsStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<isAdmin,chargesEnabled> = { readonly isAdmin?: isAdmin; readonly chargesEnabled?: chargesEnabled };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = RsvpOptionsStoryJS.query as any;

export const make: React.ComponentType<{ readonly isAdmin?: boolean; readonly chargesEnabled?: boolean }> = RsvpOptionsStoryJS.make as any;
