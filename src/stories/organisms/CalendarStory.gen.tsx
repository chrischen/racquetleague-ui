/* TypeScript file generated from CalendarStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CalendarStoryJS from './CalendarStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<onDateSelected> = { readonly onDateSelected?: onDateSelected };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = CalendarStoryJS.query as any;

export const make: React.ComponentType<{ readonly onDateSelected?: (_1:Date) => void }> = CalendarStoryJS.make as any;
