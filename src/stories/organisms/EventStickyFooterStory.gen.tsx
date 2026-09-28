/* TypeScript file generated from EventStickyFooterStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventStickyFooterStoryJS from './EventStickyFooterStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type state = 
    "signedOut"
  | "notJoined"
  | "notJoinedPriced"
  | "invited"
  | "full"
  | "joined"
  | "leaveWithWaitlist"
  | "waitlisted"
  | "pending"
  | "unpaidNoCard"
  | "unpaidSavedCard"
  | "savedCardError"
  | "deadlinePassed"
  | "gracePeriod"
  | "cancelled"
  | "externalEvent"
  | "chat";

export type props<state,fullWidth,onPayClick,onUseSavedCard,onJoinedNeedsCard> = {
  readonly state?: state; 
  readonly fullWidth?: fullWidth; 
  readonly onPayClick?: onPayClick; 
  readonly onUseSavedCard?: onUseSavedCard; 
  readonly onJoinedNeedsCard?: onJoinedNeedsCard
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = EventStickyFooterStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: state; 
  readonly fullWidth?: boolean; 
  readonly onPayClick?: () => void; 
  readonly onUseSavedCard?: () => void; 
  readonly onJoinedNeedsCard?: (_1:string) => void
}> = EventStickyFooterStoryJS.make as any;
