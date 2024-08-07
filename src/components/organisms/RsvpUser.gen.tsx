/* TypeScript file generated from RsvpUser.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RsvpUserJS from './RsvpUser.re.mjs';

export type user = { readonly name: string; readonly picture: (undefined | string) };

export type props<user,highlight,link,rating,ratingPercent> = {
  readonly user: user; 
  readonly highlight?: highlight; 
  readonly link?: link; 
  readonly rating?: rating; 
  readonly ratingPercent?: ratingPercent
};

export const make: React.ComponentType<{
  readonly user: user; 
  readonly highlight?: boolean; 
  readonly link?: string; 
  readonly rating?: number; 
  readonly ratingPercent?: number
}> = RsvpUserJS.make as any;

export const $$default: React.ComponentType<{
  readonly user: user; 
  readonly highlight?: boolean; 
  readonly link?: string; 
  readonly rating?: number; 
  readonly ratingPercent?: number
}> = RsvpUserJS.default as any;

export default $$default;
