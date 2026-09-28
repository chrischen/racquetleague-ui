/* TypeScript file generated from RoundRobinDrawsPreviewStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RoundRobinDrawsPreviewStoryJS from './RoundRobinDrawsPreviewStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<activitySlug> = { readonly activitySlug?: activitySlug };

/** The component's own operation, for the story's `parameters.relay.query`. */
export const query: concreteRequest = RoundRobinDrawsPreviewStoryJS.query as any;

export const make: React.ComponentType<{ readonly activitySlug?: "badminton" | "pickleball" }> = RoundRobinDrawsPreviewStoryJS.make as any;
