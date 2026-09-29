/* TypeScript file generated from StripePaymentEmbedStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as StripePaymentEmbedStoryJS from './StripePaymentEmbedStory.re.mjs';

export type outcome = 
    "saves"
  | "declines"
  | "failsSilently"
  | "hangs"
  | "blocked"
  | "loadError";

export type props<mode,outcome,amountLabel,onSuccess,onClose,dark> = {
  readonly mode?: mode; 
  readonly outcome?: outcome; 
  readonly amountLabel?: amountLabel; 
  readonly onSuccess?: onSuccess; 
  readonly onClose?: onClose; 
  readonly dark?: dark
};

export const make: React.ComponentType<{
  readonly mode?: 
    "payment"
  | "setup"; 
  readonly outcome?: outcome; 
  readonly amountLabel?: string; 
  readonly onSuccess?: (_1:string) => void; 
  readonly onClose?: () => void; 
  readonly dark?: boolean
}> = StripePaymentEmbedStoryJS.make as any;
