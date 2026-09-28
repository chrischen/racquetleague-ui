/* TypeScript file generated from MatchHistoryListStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MatchHistoryListStoryJS from './MatchHistoryListStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<perspective> = { readonly perspective?: perspective };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = MatchHistoryListStoryJS.query as any;

/** The player whose page the list sits on in the `player` perspective. */
export const playerId: string = MatchHistoryListStoryJS.playerId as any;

export const make: React.ComponentType<{ readonly perspective?: "event" | "player" }> = MatchHistoryListStoryJS.make as any;
