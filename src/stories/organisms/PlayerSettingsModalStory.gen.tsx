/* TypeScript file generated from PlayerSettingsModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PlayerSettingsModalStoryJS from './PlayerSettingsModalStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<state,onSave,onClose,onDelete> = {
  readonly state?: state; 
  readonly onSave?: onSave; 
  readonly onClose?: onClose; 
  readonly onDelete?: onDelete
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = PlayerSettingsModalStoryJS.query as any;

export const make: React.ComponentType<{
  readonly state?: 
    "guest"
  | "longName"
  | "registered"; 
  readonly onSave?: (_1:string, _2:string) => void; 
  readonly onClose?: () => void; 
  readonly onDelete?: () => void
}> = PlayerSettingsModalStoryJS.make as any;
