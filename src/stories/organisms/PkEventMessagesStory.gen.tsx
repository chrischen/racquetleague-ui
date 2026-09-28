/* TypeScript file generated from PkEventMessagesStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PkEventMessagesStoryJS from './PkEventMessagesStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<variant,isJoined> = { readonly variant?: variant; readonly isJoined?: isJoined };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PkEventMessagesStoryJS.query as any;

export const make: React.ComponentType<{ readonly variant?: "card" | "footer"; readonly isJoined?: boolean }> = PkEventMessagesStoryJS.make as any;
