/* TypeScript file generated from ViewerEventsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ViewerEventsRouteJS from './ViewerEventsRoute.re.mjs';

import type {Datetime_t as Util_Datetime_t} from '../../../src/components/shared/Util.gen';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {Types_eventFilters as ViewerEventsPageQuery_graphql_Types_eventFilters} from '../../../src/__generated__/ViewerEventsPageQuery_graphql.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as ViewerEventsPage_props} from '../../../src/components/pages/ViewerEventsPage.gen';

import type {queryRef as ViewerEventsPageQuery_graphql_queryRef} from '../../../src/__generated__/ViewerEventsPageQuery_graphql.gen';

export type params = {
  readonly after?: string; 
  readonly afterDate?: Util_Datetime_t; 
  readonly before?: string; 
  readonly filters?: ViewerEventsPageQuery_graphql_Types_eventFilters; 
  readonly first?: number; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = ViewerEventsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<WaitForMessages_data<ViewerEventsPageQuery_graphql_queryRef>> = ViewerEventsRouteJS.loader as any;

export const HydrateFallbackElement: PervasivesU_Jsx_element = ViewerEventsRouteJS.HydrateFallbackElement as any;
