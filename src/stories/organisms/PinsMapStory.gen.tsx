/* TypeScript file generated from PinsMapStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PinsMapStoryJS from './PinsMapStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<mapsApiKey,selected,onLocationClick> = {
  readonly mapsApiKey: mapsApiKey; 
  readonly selected?: selected; 
  readonly onLocationClick?: onLocationClick
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PinsMapStoryJS.query as any;

export const make: React.ComponentType<{
  readonly mapsApiKey: string; 
  readonly selected?: string; 
  readonly onLocationClick?: (_1:string) => void
}> = PinsMapStoryJS.make as any;
