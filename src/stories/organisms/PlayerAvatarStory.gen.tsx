/* TypeScript file generated from PlayerAvatarStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PlayerAvatarStoryJS from './PlayerAvatarStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,name> = { readonly state?: state; readonly name?: name };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PlayerAvatarStoryJS.query as any;

export const make: React.ComponentType<{ readonly state?: "initials" | "sizes" | "skillBands"; readonly name?: string }> = PlayerAvatarStoryJS.make as any;
