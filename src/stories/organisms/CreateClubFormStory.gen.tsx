/* TypeScript file generated from CreateClubFormStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CreateClubFormStoryJS from './CreateClubFormStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<onCancel,onCreated> = { readonly onCancel?: onCancel; readonly onCreated?: onCreated };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = CreateClubFormStoryJS.query as any;

export const make: React.ComponentType<{ readonly onCancel?: () => void; readonly onCreated?: (_1:string) => void }> = CreateClubFormStoryJS.make as any;
