/* TypeScript file generated from SelectedLocationStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SelectedLocationStoryJS from './SelectedLocationStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<onNewLocation> = { readonly onNewLocation?: onNewLocation };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = SelectedLocationStoryJS.query as any;

export const make: React.ComponentType<{ readonly onNewLocation?: (_1:string) => void }> = SelectedLocationStoryJS.make as any;
