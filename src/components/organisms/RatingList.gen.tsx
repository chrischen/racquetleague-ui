/* TypeScript file generated from RatingList.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RatingListJS from './RatingList.re.mjs';

import type {fragmentRefs as RescriptRelay_fragmentRefs} from 'rescript-relay/src/RescriptRelay.gen';

export type props<ratings> = { readonly ratings: ratings };

export const make: React.ComponentType<{ readonly ratings: RescriptRelay_fragmentRefs<"RatingListFragment"> }> = RatingListJS.make as any;

export const $$default: React.ComponentType<{ readonly ratings: RescriptRelay_fragmentRefs<"RatingListFragment"> }> = RatingListJS.default as any;

export default $$default;
