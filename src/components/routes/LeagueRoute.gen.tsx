/* TypeScript file generated from LeagueRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as LeagueRouteJS from './LeagueRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {params as LeaguePage_params} from '../../../src/components/pages/LeaguePage.gen';

import type {props as LeaguePage_props} from '../../../src/components/pages/LeaguePage.gen';

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: LeaguePage_params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = LeagueRouteJS.Component as any;

export const loader: <T1>(param:LoaderArgs_t) => Promise<WaitForMessages_data<(undefined | T1)>> = LeagueRouteJS.loader as any;

export const HydrateFallbackElement: JSX.Element = LeagueRouteJS.HydrateFallbackElement as any;
