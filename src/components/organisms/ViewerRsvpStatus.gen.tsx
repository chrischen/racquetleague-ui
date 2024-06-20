/* TypeScript file generated from ViewerRsvpStatus.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ViewerRsvpStatusJS from './ViewerRsvpStatus.re.mjs';

export type props<onJoin,onLeave,joined> = {
  readonly onJoin: onJoin; 
  readonly onLeave: onLeave; 
  readonly joined: joined
};

export const make: React.ComponentType<{
  readonly onJoin: () => void; 
  readonly onLeave: () => void; 
  readonly joined: boolean
}> = ViewerRsvpStatusJS.make as any;

export const $$default: React.ComponentType<{
  readonly onJoin: () => void; 
  readonly onLeave: () => void; 
  readonly joined: boolean
}> = ViewerRsvpStatusJS.default as any;

export default $$default;
