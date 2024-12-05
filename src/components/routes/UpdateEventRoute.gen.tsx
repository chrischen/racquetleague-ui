/* TypeScript file generated from UpdateEventRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as UpdateEventRouteJS from './UpdateEventRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as UpdateEventPage_props} from '../../../src/components/pages/UpdateEventPage.gen';

import type {queryRef as UpdateEventPageQuery_graphql_queryRef} from '../../../src/__generated__/UpdateEventPageQuery_graphql.gen';

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

export const Component: React.ComponentType<{}> = UpdateEventRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<UpdateEventPageQuery_graphql_queryRef>)> = UpdateEventRouteJS.loader as any;
