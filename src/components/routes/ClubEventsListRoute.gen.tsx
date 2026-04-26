/* TypeScript file generated from ClubEventsListRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ClubEventsListRouteJS from './ClubEventsListRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as ClubEventsListPage_props} from '../../../src/components/pages/ClubEventsListPage.gen';

import type {queryRef as ClubEventsListPageQuery_graphql_queryRef} from '../../../src/__generated__/ClubEventsListPageQuery_graphql.gen';

export type params = { readonly slug: string; readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = ClubEventsListRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<ClubEventsListPageQuery_graphql_queryRef>)> = ClubEventsListRouteJS.loader as any;
