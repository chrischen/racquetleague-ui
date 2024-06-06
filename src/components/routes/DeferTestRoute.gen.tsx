/* TypeScript file generated from DeferTestRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as DeferTestRouteJS from './DeferTestRoute.re.mjs';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {queryRef as DeferTestRouteQuery_graphql_queryRef} from '../../../src/__generated__/DeferTestRouteQuery_graphql.gen';

export type DeferTest_props = {};

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: (_1:DeferTest_props) => PervasivesU_Jsx_element = DeferTestRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<DeferTestRouteQuery_graphql_queryRef>)> = DeferTestRouteJS.loader as any;
