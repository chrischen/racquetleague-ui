/* TypeScript file generated from TeamManagementModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as TeamManagementModalStoryJS from './TeamManagementModalStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,onSave,onClose> = {
  readonly state?: state; 
  readonly onSave?: onSave; 
  readonly onClose?: onClose
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = TeamManagementModalStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "empty"
  | "teamsOnly"
  | "typical"; 
  readonly onSave?: (_1:string[], _2:string[]) => void; 
  readonly onClose?: () => void
}> = TeamManagementModalStoryJS.make as any;
