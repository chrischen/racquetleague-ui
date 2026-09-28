/* TypeScript file generated from ViewerRsvpStatusStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ViewerRsvpStatusStoryJS from './ViewerRsvpStatusStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<joined,onJoin,onLeave> = {
  readonly joined?: joined; 
  readonly onJoin?: onJoin; 
  readonly onLeave?: onLeave
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = ViewerRsvpStatusStoryJS.query as any;

export const make: React.ComponentType<{
  readonly joined?: boolean; 
  readonly onJoin?: () => void; 
  readonly onLeave?: () => void
}> = ViewerRsvpStatusStoryJS.make as any;
