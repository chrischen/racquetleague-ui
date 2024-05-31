/* TypeScript file generated from LeagueRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as LeagueRouteJS from './LeagueRoute.re.mjs';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as LeaguePage_props} from '../../../src/components/pages/LeaguePage.gen';

import type {queryRef as LeaguePageQuery_graphql_queryRef} from '../../../src/__generated__/LeaguePageQuery_graphql.gen';

export type params = {
  readonly activitySlug: string; 
  readonly after?: string; 
  readonly before?: string; 
  readonly first?: number; 
  readonly namespace: string; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context?: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = LeagueRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<WaitForMessages_data<(undefined | LeaguePageQuery_graphql_queryRef)>> = LeagueRouteJS.loader as any;

export const HydrateFallbackElement: PervasivesU_Jsx_element = LeagueRouteJS.HydrateFallbackElement as any;
