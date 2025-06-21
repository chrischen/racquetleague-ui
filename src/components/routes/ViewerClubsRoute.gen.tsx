/* TypeScript file generated from ViewerClubsRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as ViewerClubsRouteJS from './ViewerClubsRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as ViewerClubsPage_props} from '../../../src/components/pages/ViewerClubsPage.gen';

import type {queryRef as ViewerClubsPageQuery_graphql_queryRef} from '../../../src/__generated__/ViewerClubsPageQuery_graphql.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = ViewerClubsRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<ViewerClubsPageQuery_graphql_queryRef>)> = ViewerClubsRouteJS.loader as any;
