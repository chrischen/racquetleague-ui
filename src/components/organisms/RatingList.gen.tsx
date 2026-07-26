/* TypeScript file generated from RatingList.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RatingListJS from './RatingList.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type genderFilter = "all" | "male" | "female";

export type props<ratings,genderFilter,search,showDraftUi,viewerUserId,viewerOrdinal,viewerMu,viewerDays,viewerName,viewerPicture> = {
  readonly ratings: ratings; 
  readonly genderFilter?: genderFilter; 
  readonly search?: search; 
  readonly showDraftUi?: showDraftUi; 
  readonly viewerUserId?: viewerUserId; 
  readonly viewerOrdinal?: viewerOrdinal; 
  readonly viewerMu?: viewerMu; 
  readonly viewerDays?: viewerDays; 
  readonly viewerName?: viewerName; 
  readonly viewerPicture?: viewerPicture
};

export const make: React.ComponentType<{
  readonly ratings: RescriptRelay_fragmentRefs<
    "RatingListFragment">; 
  readonly genderFilter?: genderFilter; 
  readonly search?: string; 
  readonly showDraftUi?: boolean; 
  readonly viewerUserId?: string; 
  readonly viewerOrdinal?: number; 
  readonly viewerMu?: number; 
  readonly viewerDays?: number; 
  readonly viewerName?: string; 
  readonly viewerPicture?: string
}> = RatingListJS.make as any;

export const $$default: React.ComponentType<{
  readonly ratings: RescriptRelay_fragmentRefs<
    "RatingListFragment">; 
  readonly genderFilter?: genderFilter; 
  readonly search?: string; 
  readonly showDraftUi?: boolean; 
  readonly viewerUserId?: string; 
  readonly viewerOrdinal?: number; 
  readonly viewerMu?: number; 
  readonly viewerDays?: number; 
  readonly viewerName?: string; 
  readonly viewerPicture?: string
}> = RatingListJS.default as any;

export default $$default;
