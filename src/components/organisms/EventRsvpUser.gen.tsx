/* TypeScript file generated from EventRsvpUser.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventRsvpUserJS from './EventRsvpUser.re.mjs';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type props<user,highlight,link,rating,ratingPercent> = {
  readonly user: user; 
  readonly highlight?: highlight; 
  readonly link?: link; 
  readonly rating?: rating; 
  readonly ratingPercent?: ratingPercent
};

export const make: (_1:props<RescriptRelay_fragmentRefs<"EventRsvpUser_user">,boolean,boolean,number,number>) => PervasivesU_Jsx_element = EventRsvpUserJS.make as any;

export const $$default: (_1:props<RescriptRelay_fragmentRefs<"EventRsvpUser_user">,boolean,boolean,number,number>) => PervasivesU_Jsx_element = EventRsvpUserJS.default as any;

export default $$default;
