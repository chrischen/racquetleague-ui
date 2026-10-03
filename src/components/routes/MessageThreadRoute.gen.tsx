/* TypeScript file generated from MessageThreadRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MessageThreadRouteJS from './MessageThreadRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as MessageThreadPage_props} from '../../../src/components/pages/MessageThreadPage.gen';

import type {queryRef as MessageThreadPageQuery_graphql_queryRef} from '../../../src/__generated__/MessageThreadPageQuery_graphql.gen';

export type params = { readonly userId: string; readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = MessageThreadRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<MessageThreadPageQuery_graphql_queryRef>)> = MessageThreadRouteJS.loader as any;
