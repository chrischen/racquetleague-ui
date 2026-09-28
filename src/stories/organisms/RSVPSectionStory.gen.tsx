/* TypeScript file generated from RSVPSectionStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RSVPSectionStoryJS from './RSVPSectionStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<onBeforeJoin> = { readonly onBeforeJoin?: onBeforeJoin };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = RSVPSectionStoryJS.query as any;

export const make: React.ComponentType<{ readonly onBeforeJoin?: (_1:(() => void)) => void }> = RSVPSectionStoryJS.make as any;
