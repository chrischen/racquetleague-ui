/* TypeScript file generated from EventManagerRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventManagerRouteJS from './EventManagerRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as EventManagerPage_props} from '../../../src/components/pages/EventManagerPage.gen';

import type {queryRef as EventManagerPageQuery_graphql_queryRef} from '../../../src/__generated__/EventManagerPageQuery_graphql.gen';

export type params = {
  readonly after?: string; 
  readonly before?: string; 
  readonly eventId: string; 
  readonly first?: number; 
  readonly topic: string; 
  readonly activitySlug: string; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = EventManagerRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<EventManagerPageQuery_graphql_queryRef>)> = EventManagerRouteJS.loader as any;
