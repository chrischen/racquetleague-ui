/* TypeScript file generated from PickleLeagueLayoutRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PickleLeagueLayoutRouteJS from './PickleLeagueLayoutRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as LeagueLayout_props} from '../../../src/components/pages/LeagueLayout.gen';

import type {queryRef as DefaultLayoutQuery_graphql_queryRef} from '../../../src/__generated__/DefaultLayoutQuery_graphql.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = PickleLeagueLayoutRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<DefaultLayoutQuery_graphql_queryRef>)> = PickleLeagueLayoutRouteJS.loader as any;

export const HydrateFallbackElement: JSX.Element = PickleLeagueLayoutRouteJS.HydrateFallbackElement as any;
