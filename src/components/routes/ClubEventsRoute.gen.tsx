/* TypeScript file generated from ClubEventsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ClubEventsRouteJS from './ClubEventsRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as ClubEventsPage_props} from '../../../src/components/pages/ClubEventsPage.gen';

import type {queryRef as ClubEventsPageQuery_graphql_queryRef} from '../../../src/__generated__/ClubEventsPageQuery_graphql.gen';

export type params = { readonly slug: string; readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = ClubEventsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<ClubEventsPageQuery_graphql_queryRef>)> = ClubEventsRouteJS.loader as any;
