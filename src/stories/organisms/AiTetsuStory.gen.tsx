/* TypeScript file generated from AiTetsuStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as AiTetsuStoryJS from './AiTetsuStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type queueState = "fresh" | "underway";

export type props<state> = { readonly state?: state };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = AiTetsuStoryJS.query as any;

export const make: React.ComponentType<{ readonly state?: queueState }> = AiTetsuStoryJS.make as any;
