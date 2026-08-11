/* TypeScript file generated from ClubsListRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ClubsListRouteJS from './ClubsListRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as ClubsListPage_props} from '../../../src/components/pages/ClubsListPage.gen';

import type {queryRef as ClubsListPageQuery_graphql_queryRef} from '../../../src/__generated__/ClubsListPageQuery_graphql.gen';

export type params = { readonly lang: (undefined | string); readonly activitySlug: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = ClubsListRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<ClubsListPageQuery_graphql_queryRef>)> = ClubsListRouteJS.loader as any;
