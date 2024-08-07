/* TypeScript file generated from LeagueAboutRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as LeagueAboutRouteJS from './LeagueAboutRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as LeagueAboutPage_props} from '../../../src/components/pages/LeagueAboutPage.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context?: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = LeagueAboutRouteJS.Component as any;

export const loader: <T1>(param:LoaderArgs_t) => Promise<WaitForMessages_data<(undefined | T1)>> = LeagueAboutRouteJS.loader as any;

export const HydrateFallbackElement: JSX.Element = LeagueAboutRouteJS.HydrateFallbackElement as any;
