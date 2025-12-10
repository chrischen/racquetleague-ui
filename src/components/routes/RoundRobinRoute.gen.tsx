/* TypeScript file generated from RoundRobinRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RoundRobinRouteJS from './RoundRobinRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as RoundRobinPage_props} from '../../../src/components/pages/RoundRobinPage.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = { readonly params: params; readonly request: Router_RouterRequest_t };

export const Component: React.ComponentType<{}> = RoundRobinRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<void>)> = RoundRobinRouteJS.loader as any;
