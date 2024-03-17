/* TypeScript file generated from DefaultLayout.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as DefaultLayoutJS from './DefaultLayout.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {Types_variables as DefaultLayoutQuery_graphql_Types_variables} from '../../../src/__generated__/DefaultLayoutQuery_graphql.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {queryRef as DefaultLayoutQuery_graphql_queryRef} from '../../../src/__generated__/DefaultLayoutQuery_graphql.gen';

export type props = {};

export type LoaderArgs_t = {
  readonly context?: RelayEnv_context; 
  readonly params: DefaultLayoutQuery_graphql_Types_variables; 
  readonly request: Router_RouterRequest_t
};

export const make: React.ComponentType<{}> = DefaultLayoutJS.make as any;

export const $$default: React.ComponentType<{}> = DefaultLayoutJS.default as any;

export default $$default;

export const Component: React.ComponentType<{}> = DefaultLayoutJS.Component as any;

export const loader: (param:LoaderArgs_t) => (undefined | DefaultLayoutQuery_graphql_queryRef) = DefaultLayoutJS.loader as any;
