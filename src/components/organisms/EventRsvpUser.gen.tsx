/* TypeScript file generated from EventRsvpUser.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventRsvpUserJS from './EventRsvpUser.re.mjs';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {Types_fragment as EventRsvpUser_user_graphql_Types_fragment} from '../../../src/__generated__/EventRsvpUser_user_graphql.gen';

export type userData = 
    "Guest"
  | { TAG: "Registered"; _0: EventRsvpUser_user_graphql_Types_fragment };

export type user = {
  readonly name: string; 
  readonly picture: (undefined | string); 
  readonly data: userData
};

export type props<user,highlight,link,rating,ratingPercent> = {
  readonly user: user; 
  readonly highlight?: highlight; 
  readonly link?: link; 
  readonly rating?: rating; 
  readonly ratingPercent?: ratingPercent
};

export const make: (_1:props<user,boolean,string,number,number>) => PervasivesU_Jsx_element = EventRsvpUserJS.make as any;

export const $$default: (_1:props<user,boolean,string,number,number>) => PervasivesU_Jsx_element = EventRsvpUserJS.default as any;

export default $$default;
