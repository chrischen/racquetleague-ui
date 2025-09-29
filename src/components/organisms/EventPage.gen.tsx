/* TypeScript file generated from EventPage.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as EventPageJS from './EventPage.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {queryRef as EventQuery_graphql_queryRef} from '../../../src/__generated__/EventQuery_graphql.gen';

export type props = {};

export type params = {
  readonly after?: string; 
  readonly before?: string; 
  readonly eventId: string; 
  readonly first?: number; 
  readonly topic: string; 
  readonly lang: (undefined | string)
};

export type LoaderArgs_t = {
  readonly context: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const $$default: React.ComponentType<{}> = EventPageJS.default as any;

export default $$default;

export const Component: React.ComponentType<{}> = EventPageJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<EventQuery_graphql_queryRef>)> = EventPageJS.loader as any;
