/* TypeScript file generated from CopyEventRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CopyEventRouteJS from './CopyEventRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as CopyEventPage_props} from '../../../src/components/pages/CopyEventPage.gen';

import type {queryRef as CopyEventPageQuery_graphql_queryRef} from '../../../src/__generated__/CopyEventPageQuery_graphql.gen';

export type params = {
  readonly eventId: string; 
  readonly locationId: string; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = CopyEventRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<CopyEventPageQuery_graphql_queryRef>)> = CopyEventRouteJS.loader as any;
