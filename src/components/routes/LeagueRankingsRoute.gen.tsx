/* TypeScript file generated from LeagueRankingsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as LeagueRankingsRouteJS from './LeagueRankingsRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {loaderData as LeagueRankingsPage_loaderData} from '../../../src/components/pages/LeagueRankingsPage.gen';

import type {props as LeagueRankingsPage_props} from '../../../src/components/pages/LeagueRankingsPage.gen';

export type params = {
  readonly activitySlug: string; 
  readonly after?: string; 
  readonly before?: string; 
  readonly first?: number; 
  readonly namespace: string; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = LeagueRankingsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<WaitForMessages_data<LeagueRankingsPage_loaderData>> = LeagueRankingsRouteJS.loader as any;

export const HydrateFallbackElement: JSX.Element = LeagueRankingsRouteJS.HydrateFallbackElement as any;
