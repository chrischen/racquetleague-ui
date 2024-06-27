/* TypeScript file generated from CreateClubEventsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CreateClubEventsRouteJS from './CreateClubEventsRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as CreateClubEventsPage_props} from '../../../src/components/pages/CreateClubEventsPage.gen';

import type {queryRef as CreateClubEventsPageQuery_graphql_queryRef} from '../../../src/__generated__/CreateClubEventsPageQuery_graphql.gen';

export type params = { readonly clubId: string; readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = CreateClubEventsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<CreateClubEventsPageQuery_graphql_queryRef>)> = CreateClubEventsRouteJS.loader as any;
