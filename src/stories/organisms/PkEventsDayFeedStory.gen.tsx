/* TypeScript file generated from PkEventsDayFeedStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PkEventsDayFeedStoryJS from './PkEventsDayFeedStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<localDate,onRefetchNeeded> = { readonly localDate?: localDate; readonly onRefetchNeeded?: onRefetchNeeded };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PkEventsDayFeedStoryJS.query as any;

export const make: React.ComponentType<{ readonly localDate?: string; readonly onRefetchNeeded?: () => void }> = PkEventsDayFeedStoryJS.make as any;
