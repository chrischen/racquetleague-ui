/* TypeScript file generated from SessionEvenPlayModeStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SessionEvenPlayModeStoryJS from './SessionEvenPlayModeStory.re.mjs';

export type props<breakCount,breakPlayersCount,onChangeBreakCount> = {
  readonly breakCount?: breakCount; 
  readonly breakPlayersCount?: breakPlayersCount; 
  readonly onChangeBreakCount?: onChangeBreakCount
};

export const make: React.ComponentType<{
  readonly breakCount?: number; 
  readonly breakPlayersCount?: number; 
  readonly onChangeBreakCount?: (_1:number) => void
}> = SessionEvenPlayModeStoryJS.make as any;
