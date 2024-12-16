/* TypeScript file generated from EventRsvps.resi by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventRsvpsJS from './EventRsvps.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type props<event,user> = { readonly event: event; readonly user: user };

export const make: React.ComponentType<{ readonly event: RescriptRelay_fragmentRefs<"EventRsvps_event">; readonly user: (undefined | RescriptRelay_fragmentRefs<"EventRsvps_user">) }> = EventRsvpsJS.make as any;
