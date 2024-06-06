/* TypeScript file generated from CreateLocationEventRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CreateLocationEventRouteJS from './CreateLocationEventRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as CreateLocationEventPage_props} from '../../../src/components/pages/CreateLocationEventPage.gen';

import type {queryRef as CreateLocationEventPageQuery_graphql_queryRef} from '../../../src/__generated__/CreateLocationEventPageQuery_graphql.gen';

export type params = { readonly locationId: string; readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = CreateLocationEventRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<CreateLocationEventPageQuery_graphql_queryRef>)> = CreateLocationEventRouteJS.loader as any;
