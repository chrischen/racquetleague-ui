/* TypeScript file generated from PkViewerEventsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PkViewerEventsRouteJS from './PkViewerEventsRoute.re.mjs';

import type {Datetime_t as Util_Datetime_t} from '../../../src/components/shared/Util.gen';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {Types_eventFilters as PkViewerEventsPageQuery_graphql_Types_eventFilters} from '../../../src/__generated__/PkViewerEventsPageQuery_graphql.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as PkViewerEventsPage_props} from '../../../src/components/pages/PkViewerEventsPage.gen';

import type {queryRef as PkViewerEventsPageQuery_graphql_queryRef} from '../../../src/__generated__/PkViewerEventsPageQuery_graphql.gen';

export type params = {
  readonly after?: string; 
  readonly afterDate?: Util_Datetime_t; 
  readonly before?: string; 
  readonly filters?: PkViewerEventsPageQuery_graphql_Types_eventFilters; 
  readonly first?: number; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = PkViewerEventsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<WaitForMessages_data<PkViewerEventsPageQuery_graphql_queryRef>> = PkViewerEventsRouteJS.loader as any;

export const HydrateFallbackElement: JSX.Element = PkViewerEventsRouteJS.HydrateFallbackElement as any;
