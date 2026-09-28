/* TypeScript file generated from SelectPlayersListStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SelectPlayersListStoryJS from './SelectPlayersListStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,onClick,onRemove,onEnable> = {
  readonly state?: state; 
  readonly onClick?: onClick; 
  readonly onRemove?: onRemove; 
  readonly onEnable?: onEnable
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = SelectPlayersListStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "empty"
  | "typical"
  | "withGuests"; 
  readonly onClick?: (_1:string) => void; 
  readonly onRemove?: (_1:string) => void; 
  readonly onEnable?: (_1:string) => void
}> = SelectPlayersListStoryJS.make as any;
