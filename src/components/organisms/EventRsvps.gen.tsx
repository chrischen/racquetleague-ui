/* TypeScript file generated from EventRsvps.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventRsvpsJS from './EventRsvps.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type props<event> = { readonly event: event };

export const make: React.ComponentType<{ readonly event: RescriptRelay_fragmentRefs<"EventRsvps_event"> }> = EventRsvpsJS.make as any;

export const $$default: React.ComponentType<{ readonly event: RescriptRelay_fragmentRefs<"EventRsvps_event"> }> = EventRsvpsJS.default as any;

export default $$default;
