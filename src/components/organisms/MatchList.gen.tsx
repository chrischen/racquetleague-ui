/* TypeScript file generated from MatchList.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MatchListJS from './MatchList.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type props<matches,user> = { readonly matches: matches; readonly user?: user };

export const make: React.ComponentType<{ readonly matches: RescriptRelay_fragmentRefs<"MatchListFragment">; readonly user?: RescriptRelay_fragmentRefs<"MatchListUser_user"> }> = MatchListJS.make as any;

export const $$default: React.ComponentType<{ readonly matches: RescriptRelay_fragmentRefs<"MatchListFragment">; readonly user?: RescriptRelay_fragmentRefs<"MatchListUser_user"> }> = MatchListJS.default as any;

export default $$default;
