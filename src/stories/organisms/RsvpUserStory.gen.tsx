/* TypeScript file generated from RsvpUserStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RsvpUserStoryJS from './RsvpUserStory.re.mjs';

export type props<name,withPicture,highlight,linked,secondaryText,ratingPercent,sigmaPercent> = {
  readonly name?: name; 
  readonly withPicture?: withPicture; 
  readonly highlight?: highlight; 
  readonly linked?: linked; 
  readonly secondaryText?: secondaryText; 
  readonly ratingPercent?: ratingPercent; 
  readonly sigmaPercent?: sigmaPercent
};

export const make: React.ComponentType<{
  readonly name?: string; 
  readonly withPicture?: boolean; 
  readonly highlight?: boolean; 
  readonly linked?: boolean; 
  readonly secondaryText?: string; 
  readonly ratingPercent?: number; 
  readonly sigmaPercent?: number
}> = RsvpUserStoryJS.make as any;
