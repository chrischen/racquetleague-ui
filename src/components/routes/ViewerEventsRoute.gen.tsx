/* TypeScript file generated from ViewerEventsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ViewerEventsRouteJS from './ViewerEventsRoute.re.mjs';

import type {Datetime_t as Util_Datetime_t} from '../../../src/components/shared/Util.gen';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {Types_eventFilters as ViewerEventsRouteQuery_graphql_Types_eventFilters} from '../../../src/__generated__/ViewerEventsRouteQuery_graphql.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {queryRef as ViewerEventsRouteQuery_graphql_queryRef} from '../../../src/__generated__/ViewerEventsRouteQuery_graphql.gen';

export type props = {};

export type params = {
  readonly after?: string; 
  readonly afterDate?: Util_Datetime_t; 
  readonly before?: string; 
  readonly filters?: ViewerEventsRouteQuery_graphql_Types_eventFilters; 
  readonly first?: number; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context?: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const make: React.ComponentType<{}> = ViewerEventsRouteJS.make as any;

export const $$default: React.ComponentType<{}> = ViewerEventsRouteJS.default as any;

export default $$default;

export const Component: React.ComponentType<{}> = ViewerEventsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<WaitForMessages_data<(undefined | ViewerEventsRouteQuery_graphql_queryRef)>> = ViewerEventsRouteJS.loader as any;

export const HydrateFallbackElement: PervasivesU_Jsx_element = ViewerEventsRouteJS.HydrateFallbackElement as any;
