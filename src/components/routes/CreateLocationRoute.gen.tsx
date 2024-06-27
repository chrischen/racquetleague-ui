/* TypeScript file generated from CreateLocationRoute.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as CreateLocationRouteJS from './CreateLocationRoute.re.mjs';

import type {Mouse_t as JsxEventU_Mouse_t} from './JsxEventU.gen';

import type {RouterRequest_t as Router_RouterRequest_t} from '../../../src/components/shared/Router.gen';

import type {context as RelayEnv_context} from '../../../src/entry/RelayEnv.gen';

import type {data as WaitForMessages_data} from '../../../src/components/shared/i18n/WaitForMessages.gen';

import type {props as CreateLocationForm_props} from '../../../src/components/organisms/CreateLocationForm.gen';

export type params = { readonly lang: (undefined | string) };

export type LoaderArgs_t = {
  readonly context?: RelayEnv_context; 
  readonly params: params; 
  readonly request: Router_RouterRequest_t
};

export const Component: React.ComponentType<{ readonly onCancel: (_1:JsxEventU_Mouse_t) => void; readonly onClose: () => void }> = CreateLocationRouteJS.Component as any;

export const loader: <T1>(param:LoaderArgs_t) => Promise<(null | WaitForMessages_data<(undefined | T1)>)> = CreateLocationRouteJS.loader as any;
