/* TypeScript file generated from AutocompleteUserStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as AutocompleteUserStoryJS from './AutocompleteUserStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

export type concreteRequest = $$concreteRequest;

export type props<withClose,placeholder,onSelected,onClose> = {
  readonly withClose?: withClose; 
  readonly placeholder?: placeholder; 
  readonly onSelected?: onSelected; 
  readonly onClose?: onClose
};

/** The component's own operation, for the story's `parameters.relay.query`. */
export const query: concreteRequest = AutocompleteUserStoryJS.query as any;

/** The club whose members the story searches. */
export const clubId: string = AutocompleteUserStoryJS.clubId as any;

/** The variables the component passes; `parameters.relay.variables` must match. */
export const variables: { readonly clubId: string; readonly first: number } = AutocompleteUserStoryJS.variables as any;

export const make: React.ComponentType<{
  readonly withClose?: boolean; 
  readonly placeholder?: string; 
  readonly onSelected?: (_1:string) => void; 
  readonly onClose?: () => void
}> = AutocompleteUserStoryJS.make as any;
