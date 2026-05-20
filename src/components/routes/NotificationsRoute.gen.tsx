/* TypeScript file generated from NotificationsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as NotificationsRouteJS from './NotificationsRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as NotificationsPage_props} from '../../../src/components/pages/NotificationsPage.gen';

import type {queryRef as NotificationsPageQuery_graphql_queryRef} from '../../../src/__generated__/NotificationsPageQuery_graphql.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = NotificationsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<NotificationsPageQuery_graphql_queryRef>)> = NotificationsRouteJS.loader as any;
