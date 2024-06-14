/* TypeScript file generated from PickleLeagueRankingsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PickleLeagueRankingsRouteJS from './PickleLeagueRankingsRoute.re.mjs';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

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

export const Component: React.ComponentType<{}> = PickleLeagueRankingsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<WaitForMessages_data<LeagueRankingsPage_loaderData>> = PickleLeagueRankingsRouteJS.loader as any;

export const HydrateFallbackElement: PervasivesU_Jsx_element = PickleLeagueRankingsRouteJS.HydrateFallbackElement as any;
