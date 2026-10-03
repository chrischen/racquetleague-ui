/* TypeScript file generated from PlayerInviteSwipeDeckStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PlayerInviteSwipeDeckStoryJS from './PlayerInviteSwipeDeckStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<mode,startAt,reviewed,onAccept,onClose> = {
  readonly mode?: mode; 
  readonly startAt?: startAt; 
  readonly reviewed?: reviewed; 
  readonly onAccept?: onAccept; 
  readonly onClose?: onClose
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PlayerInviteSwipeDeckStoryJS.query as any;

export const make: React.ComponentType<{
  readonly mode?: 
    "approve"
  | "invite"; 
  readonly startAt?: number; 
  readonly reviewed?: boolean; 
  readonly onAccept?: (_1:string, _2:(undefined | string)) => void; 
  readonly onClose?: () => void
}> = PlayerInviteSwipeDeckStoryJS.make as any;
