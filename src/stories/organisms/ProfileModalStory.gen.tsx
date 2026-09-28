/* TypeScript file generated from ProfileModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ProfileModalStoryJS from './ProfileModalStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<isOpen,context,onClose,onProfileComplete> = {
  readonly isOpen?: isOpen; 
  readonly context?: context; 
  readonly onClose?: onClose; 
  readonly onProfileComplete?: onProfileComplete
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = ProfileModalStoryJS.query as any;

export const make: React.ComponentType<{
  readonly isOpen?: boolean; 
  readonly context?: 
    "Availability"
  | "Join"
  | "Profile"; 
  readonly onClose?: () => void; 
  readonly onProfileComplete?: () => void
}> = ProfileModalStoryJS.make as any;
