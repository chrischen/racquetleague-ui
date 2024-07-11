/* TypeScript file generated from CreateEventsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CreateEventsRouteJS from './CreateEventsRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as CreateEventsPage_props} from '../../../src/components/pages/CreateEventsPage.gen';

import type {queryRef as CreateEventsPageQuery_graphql_queryRef} from '../../../src/__generated__/CreateEventsPageQuery_graphql.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = CreateEventsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<CreateEventsPageQuery_graphql_queryRef>)> = CreateEventsRouteJS.loader as any;