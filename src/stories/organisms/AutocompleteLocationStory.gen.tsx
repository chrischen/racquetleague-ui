/* TypeScript file generated from AutocompleteLocationStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as AutocompleteLocationStoryJS from './AutocompleteLocationStory.re.mjs';

export type props<places,error,autoSearchAddress,onSelected,onSelectedDetails> = {
  readonly places?: places; 
  readonly error?: error; 
  readonly autoSearchAddress?: autoSearchAddress; 
  readonly onSelected?: onSelected; 
  readonly onSelectedDetails?: onSelectedDetails
};

export const make: React.ComponentType<{
  readonly places?: 
    "answers"
  | "notLoaded"
  | "unavailable"; 
  readonly error?: string; 
  readonly autoSearchAddress?: string; 
  readonly onSelected?: (_1:string) => void; 
  readonly onSelectedDetails?: (_1:[string, string]) => void
}> = AutocompleteLocationStoryJS.make as any;
