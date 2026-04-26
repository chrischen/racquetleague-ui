/* TypeScript file generated from EventsMap.resi by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventsMapJS from './EventsMap.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {queryRef as EventsMapQuery_graphql_queryRef} from '../../../src/__generated__/EventsMapQuery_graphql.gen';

export type props = {};

export type params = { readonly activitySlug: (undefined | string); readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const make: React.ComponentType<{}> = EventsMapJS.make as any;

export const Component: React.ComponentType<{}> = EventsMapJS.Component as any;

export const loader: (_1:LoaderArgs_t) => Promise<WaitForMessages_data<EventsMapQuery_graphql_queryRef>> = EventsMapJS.loader as any;
