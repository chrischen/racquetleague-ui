/* TypeScript file generated from RatingGraph.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as RatingGraphJS from './RatingGraph.re.mjs';

export type ratingDataPoint = {
  readonly date: string; 
  readonly rating: number; 
  readonly uncertainty: number; 
  readonly upperBound: number; 
  readonly lowerBound: number
};

export type props<data> = { readonly data: data };

export const $$default: React.ComponentType<{ readonly data: ratingDataPoint[] }> = RatingGraphJS.default as any;

export default $$default;
