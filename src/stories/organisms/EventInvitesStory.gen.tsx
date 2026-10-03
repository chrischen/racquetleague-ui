/* TypeScript file generated from EventInvitesStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventInvitesStoryJS from './EventInvitesStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<canInvite,viewerId> = { readonly canInvite?: canInvite; readonly viewerId?: viewerId };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventInvitesStoryJS.query as any;

export const make: React.ComponentType<{ readonly canInvite?: boolean; readonly viewerId?: string }> = EventInvitesStoryJS.make as any;
