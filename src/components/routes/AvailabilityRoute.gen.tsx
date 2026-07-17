/* TypeScript file generated from AvailabilityRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as AvailabilityRouteJS from './AvailabilityRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as AvailabilityPage_props} from '../../../src/components/pages/AvailabilityPage.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = AvailabilityRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<void>)> = AvailabilityRouteJS.loader as any;
