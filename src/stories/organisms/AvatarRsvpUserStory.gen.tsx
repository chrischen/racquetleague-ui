/* TypeScript file generated from AvatarRsvpUserStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as AvatarRsvpUserStoryJS from './AvatarRsvpUserStory.re.mjs';

export type props<name,withPicture,highlight,secondaryText,ratingPercent,sigmaPercent> = {
  readonly name?: name; 
  readonly withPicture?: withPicture; 
  readonly highlight?: highlight; 
  readonly secondaryText?: secondaryText; 
  readonly ratingPercent?: ratingPercent; 
  readonly sigmaPercent?: sigmaPercent
};

export const make: React.ComponentType<{
  readonly name?: string; 
  readonly withPicture?: boolean; 
  readonly highlight?: boolean; 
  readonly secondaryText?: string; 
  readonly ratingPercent?: number; 
  readonly sigmaPercent?: number
}> = AvatarRsvpUserStoryJS.make as any;
