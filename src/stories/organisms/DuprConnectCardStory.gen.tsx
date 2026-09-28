/* TypeScript file generated from DuprConnectCardStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as DuprConnectCardStoryJS from './DuprConnectCardStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<onChanged> = { readonly onChanged?: onChanged };

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = DuprConnectCardStoryJS.query as any;

export const make: React.ComponentType<{ readonly onChanged?: () => void }> = DuprConnectCardStoryJS.make as any;
