/* TypeScript file generated from LeagueNav.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as LeagueNavJS from './LeagueNav.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type Viewer_props<viewer> = { readonly viewer: viewer };

export type props<query> = { readonly query: query };

export const Viewer_make: React.ComponentType<{ readonly viewer: RescriptRelay_fragmentRefs<"LeagueNav_viewer"> }> = LeagueNavJS.Viewer.make as any;

export const make: React.ComponentType<{ readonly query: RescriptRelay_fragmentRefs<"LeagueNav_query"> }> = LeagueNavJS.make as any;

export const $$default: React.ComponentType<{ readonly query: RescriptRelay_fragmentRefs<"LeagueNav_query"> }> = LeagueNavJS.default as any;

export default $$default;

export const Viewer: { make: React.ComponentType<{ readonly viewer: RescriptRelay_fragmentRefs<"LeagueNav_viewer"> }> } = LeagueNavJS.Viewer as any;
