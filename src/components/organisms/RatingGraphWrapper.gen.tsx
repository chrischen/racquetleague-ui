/* TypeScript file generated from RatingGraphWrapper.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RatingGraphWrapperJS from './RatingGraphWrapper.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type props<matches,userId> = { readonly matches: matches; readonly userId: userId };

export const make: React.ComponentType<{ readonly matches: RescriptRelay_fragmentRefs<"RatingGraphWrapperFragment">; readonly userId: string }> = RatingGraphWrapperJS.make as any;

export const $$default: React.ComponentType<{ readonly matches: RescriptRelay_fragmentRefs<"RatingGraphWrapperFragment">; readonly userId: string }> = RatingGraphWrapperJS.default as any;

export default $$default;
