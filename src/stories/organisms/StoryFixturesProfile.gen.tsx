/* TypeScript file generated from StoryFixturesProfile.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as StoryFixturesProfileJS from './StoryFixturesProfile.re.mjs';

/** A player in the shared roster. `mu` and `sigma` are on the internal
    (openskill) scale: mu 25 is about DUPR 3.54, and each point of mu is about
    0.04 DUPR. The rating list's ordinal is mu - 3 * sigma. */
export type player = {
  readonly id: string; 
  readonly lineUsername: string; 
  readonly fullName: string; 
  readonly gender: 
    "male"
  | "female"; 
  readonly picture: (null | string); 
  readonly mu: number; 
  readonly sigma: number; 
  readonly daysNumberOne: number
};

export const portrait: (seed:number) => string = StoryFixturesProfileJS.portrait as any;

/** Twenty-two players, strongest first by ordinal (mu - 3 * sigma), the order
    the server returns rankings in. Twelve men and ten women, some with a
    picture, some with a Japanese display name. */
export const roster: player[] = StoryFixturesProfileJS.roster as any;
