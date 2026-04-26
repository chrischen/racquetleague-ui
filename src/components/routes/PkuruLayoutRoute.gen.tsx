/* TypeScript file generated from PkuruLayoutRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as PkuruLayoutRouteJS from './PkuruLayoutRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as PkuruLayout_props} from '../../../src/components/pages/PkuruLayout.gen';

import type {queryRef as PkuruLayoutQuery_graphql_queryRef} from '../../../src/__generated__/PkuruLayoutQuery_graphql.gen';

export type params = { readonly activitySlug: string; readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = PkuruLayoutRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<PkuruLayoutQuery_graphql_queryRef>)> = PkuruLayoutRouteJS.loader as any;

export const HydrateFallbackElement: JSX.Element = PkuruLayoutRouteJS.HydrateFallbackElement as any;
