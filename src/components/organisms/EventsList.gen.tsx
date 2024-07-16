/* TypeScript file generated from EventsList.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventsListJS from './EventsList.re.mjs';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type TextEventsList_props<events> = { readonly events: events };

export type props<events> = { readonly events: events };

export const TextEventsList_make: (_1:TextEventsList_props<RescriptRelay_fragmentRefs<"EventsListFragment">>) => PervasivesU_Jsx_element = EventsListJS.TextEventsList.make as any;

export const make: React.ComponentType<{ readonly events: RescriptRelay_fragmentRefs<
    "CalendarEventsFragment"
  | "EventsListFragment"> }> = EventsListJS.make as any;

export const $$default: React.ComponentType<{ readonly events: RescriptRelay_fragmentRefs<
    "CalendarEventsFragment"
  | "EventsListFragment"> }> = EventsListJS.default as any;

export default $$default;

export const TextEventsList: { make: (_1:TextEventsList_props<RescriptRelay_fragmentRefs<"EventsListFragment">>) => PervasivesU_Jsx_element } = EventsListJS.TextEventsList as any;
