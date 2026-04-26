/* TypeScript file generated from EventsMapRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventsMapRouteJS from './EventsMapRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as EventsMapPage_props} from '../../../src/components/pages/EventsMapPage.gen';

import type {queryRef as EventsMapPageQuery_graphql_queryRef} from '../../../src/__generated__/EventsMapPageQuery_graphql.gen';

export type params = { readonly activitySlug: (undefined | string); readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = EventsMapRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<WaitForMessages_data<EventsMapPageQuery_graphql_queryRef>> = EventsMapRouteJS.loader as any;
