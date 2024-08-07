/* TypeScript file generated from EventRsvpUser.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventRsvpUserJS from './EventRsvpUser.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

import type {props as RsvpUser_props} from './RsvpUser.gen';

export const $$default: React.ComponentType<{
  readonly user: RescriptRelay_fragmentRefs<
    "EventRsvpUser_user">; 
  readonly highlight?: boolean; 
  readonly link?: string; 
  readonly rating?: number; 
  readonly ratingPercent?: number
}> = EventRsvpUserJS.default as any;

export default $$default;
