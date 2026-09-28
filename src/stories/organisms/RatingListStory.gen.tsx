/* TypeScript file generated from RatingListStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RatingListStoryJS from './RatingListStory.re.mjs';

import type {ConcreteRequest as $$concreteRequest} from 'relay-runtime';

import type {genderFilter as RatingList_genderFilter} from '../../../src/components/organisms/RatingList.gen';

export type concreteRequest = $$concreteRequest;

export type props<genderFilter,search,showDraftUi,viewerId> = {
  readonly genderFilter?: genderFilter; 
  readonly search?: search; 
  readonly showDraftUi?: showDraftUi; 
  readonly viewerId?: viewerId
};

/** The operation for the story's `parameters.relay.query`. */
export const query: concreteRequest = RatingListStoryJS.query as any;

export const make: React.ComponentType<{
  readonly genderFilter?: RatingList_genderFilter; 
  readonly search?: string; 
  readonly showDraftUi?: boolean; 
  readonly viewerId?: string
}> = RatingListStoryJS.make as any;
