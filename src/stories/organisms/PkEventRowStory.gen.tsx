/* TypeScript file generated from PkEventRowStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PkEventRowStoryJS from './PkEventRowStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<onEventClick,dimmed> = { readonly onEventClick?: onEventClick; readonly dimmed?: dimmed };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PkEventRowStoryJS.query as any;

export const make: React.ComponentType<{ readonly onEventClick?: (_1:string) => void; readonly dimmed?: boolean }> = PkEventRowStoryJS.make as any;
