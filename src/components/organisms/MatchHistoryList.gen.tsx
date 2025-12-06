/* TypeScript file generated from MatchHistoryList.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as MatchHistoryListJS from './MatchHistoryList.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type props<matches,user> = { readonly matches: matches; readonly user?: user };

export const make: React.ComponentType<{ readonly matches: RescriptRelay_fragmentRefs<"MatchHistoryListFragment">; readonly user?: RescriptRelay_fragmentRefs<"MatchHistoryListUser_user"> }> = MatchHistoryListJS.make as any;

export const $$default: React.ComponentType<{ readonly matches: RescriptRelay_fragmentRefs<"MatchHistoryListFragment">; readonly user?: RescriptRelay_fragmentRefs<"MatchHistoryListUser_user"> }> = MatchHistoryListJS.default as any;

export default $$default;
