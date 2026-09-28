/* TypeScript file generated from RsvpWaitlistStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RsvpWaitlistStoryJS from './RsvpWaitlistStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<activitySlug,viewerId> = { readonly activitySlug?: activitySlug; readonly viewerId?: viewerId };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = RsvpWaitlistStoryJS.query as any;

export const make: React.ComponentType<{ readonly activitySlug?: "badminton" | "pickleball"; readonly viewerId?: string }> = RsvpWaitlistStoryJS.make as any;
