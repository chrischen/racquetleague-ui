/* TypeScript file generated from KioskRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as KioskRouteJS from './KioskRoute.re.mjs';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as KioskPage_props} from '../../../src/components/pages/KioskPage.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = { readonly params: params; readonly request: Router_RouterRequest_t };

export const Component: React.ComponentType<{}> = KioskRouteJS.Component as any;

export const loader: (param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<void>)> = KioskRouteJS.loader as any;
