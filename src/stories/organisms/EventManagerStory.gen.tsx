/* TypeScript file generated from EventManagerStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventManagerStoryJS from './EventManagerStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

import type {managerState as StoryFixturesTools_managerState} from './StoryFixturesTools.gen';

export type concreteRequest = $$concreteRequest;

export type props<state,debug> = { readonly state?: state; readonly debug?: debug };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventManagerStoryJS.query as any;

export const make: React.ComponentType<{ readonly state?: StoryFixturesTools_managerState; readonly debug?: boolean }> = EventManagerStoryJS.make as any;
