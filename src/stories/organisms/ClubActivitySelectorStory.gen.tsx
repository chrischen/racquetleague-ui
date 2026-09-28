/* TypeScript file generated from ClubActivitySelectorStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ClubActivitySelectorStoryJS from './ClubActivitySelectorStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

/** What the selector reports to its parent on every change. */
export type selection = {
  readonly clubId: (undefined | string); 
  readonly activityId: (undefined | string); 
  readonly isAddingClub: boolean
};

export type props<initialClubId,initialActivitySlug,onChange> = {
  readonly initialClubId?: initialClubId; 
  readonly initialActivitySlug?: initialActivitySlug; 
  readonly onChange?: onChange
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = ClubActivitySelectorStoryJS.query as any;

export const make: React.ComponentType<{
  readonly initialClubId?: string; 
  readonly initialActivitySlug?: string; 
  readonly onChange?: (_1:selection) => void
}> = ClubActivitySelectorStoryJS.make as any;
