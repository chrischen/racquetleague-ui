/* TypeScript file generated from FindGames.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as FindGamesJS from './FindGames.re.mjs';

import type {Jsx_element as PervasivesU_Jsx_element} from './PervasivesU.gen';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as FindGamesPage_props} from '../../../src/components/pages/FindGamesPage.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context?: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{}> = FindGamesJS.Component as any;

export const loader: <T1>(param:LoaderArgs_t) => Promise<WaitForMessages_data<(undefined | T1)>> = FindGamesJS.loader as any;

export const HydrateFallbackElement: PervasivesU_Jsx_element = FindGamesJS.HydrateFallbackElement as any;
