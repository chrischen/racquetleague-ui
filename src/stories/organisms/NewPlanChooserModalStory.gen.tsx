/* TypeScript file generated from NewPlanChooserModalStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as NewPlanChooserModalStoryJS from './NewPlanChooserModalStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<onClose,onCreateEvent> = { readonly onClose?: onClose; readonly onCreateEvent?: onCreateEvent };

/** The modal's own operation, for the story's `parameters.relay.query`. */
export const query: concreteRequest = NewPlanChooserModalStoryJS.query as any;

export const make: React.ComponentType<{ readonly onClose?: () => void; readonly onCreateEvent?: () => void }> = NewPlanChooserModalStoryJS.make as any;
