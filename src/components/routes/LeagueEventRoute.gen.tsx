/* TypeScript file generated from LeagueEventRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as LeagueEventRouteJS from './LeagueEventRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as LeagueEventPage_props} from '../../../src/components/pages/LeagueEventPage.gen';

import type {queryRef as LeagueEventPageQuery_graphql_queryRef} from '../../../src/__generated__/LeagueEventPageQuery_graphql.gen';

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

export const Component: React.ComponentType<{}> = LeagueEventRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<LeagueEventPageQuery_graphql_queryRef>)> = LeagueEventRouteJS.loader as any;
