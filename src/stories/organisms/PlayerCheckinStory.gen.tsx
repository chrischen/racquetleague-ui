/* TypeScript file generated from PlayerCheckinStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PlayerCheckinStoryJS from './PlayerCheckinStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,clubEvent,onToggleCheckin,onTogglePaid,onAdjustSeeds,onOpenTeamManagement,onOpenPlayerSettings,onOpenAddGuests,onUseClubRatings> = {
  readonly state?: state; 
  readonly clubEvent?: clubEvent; 
  readonly onToggleCheckin?: onToggleCheckin; 
  readonly onTogglePaid?: onTogglePaid; 
  readonly onAdjustSeeds?: onAdjustSeeds; 
  readonly onOpenTeamManagement?: onOpenTeamManagement; 
  readonly onOpenPlayerSettings?: onOpenPlayerSettings; 
  readonly onOpenAddGuests?: onOpenAddGuests; 
  readonly onUseClubRatings?: onUseClubRatings
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PlayerCheckinStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "arriving"
  | "empty"
  | "underway"
  | "withGuests"; 
  readonly clubEvent?: boolean; 
  readonly onToggleCheckin?: (_1:string) => void; 
  readonly onTogglePaid?: (_1:string) => void; 
  readonly onAdjustSeeds?: (_1:Array<[string, number]>) => void; 
  readonly onOpenTeamManagement?: () => void; 
  readonly onOpenPlayerSettings?: (_1:string) => void; 
  readonly onOpenAddGuests?: () => void; 
  readonly onUseClubRatings?: (_1:boolean) => void
}> = PlayerCheckinStoryJS.make as any;
