/* TypeScript file generated from LeaguePlayerRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as LeaguePlayerRouteJS from './LeaguePlayerRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as LeaguePlayerPage_props} from '../../../src/components/pages/LeaguePlayerPage.gen';

import type {queryRef as LeaguePlayerPageQuery_graphql_queryRef} from '../../../src/__generated__/LeaguePlayerPageQuery_graphql.gen';

export type params = {
  readonly activitySlug: string; 
  readonly after?: string; 
  readonly before?: string; 
  readonly first?: number; 
  readonly namespace: string; 
  readonly userId: string; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: (_1:LeaguePlayerPage_props) => (undefined | JSX.Element) = LeaguePlayerRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<WaitForMessages_data<LeaguePlayerPageQuery_graphql_queryRef>> = LeaguePlayerRouteJS.loader as any;

export const HydrateFallbackElement: JSX.Element = LeaguePlayerRouteJS.HydrateFallbackElement as any;
