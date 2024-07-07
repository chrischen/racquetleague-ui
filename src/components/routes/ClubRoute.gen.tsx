/* TypeScript file generated from ClubRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ClubRouteJS from './ClubRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as ClubPage_props} from '../../../src/components/pages/ClubPage.gen';

import type {queryRef as ClubPageQuery_graphql_queryRef} from '../../../src/__generated__/ClubPageQuery_graphql.gen';

export type params = { readonly slug: string; readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = ClubRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<ClubPageQuery_graphql_queryRef>)> = ClubRouteJS.loader as any;
