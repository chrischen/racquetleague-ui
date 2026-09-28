/* TypeScript file generated from SelfCheckinDisplayStory.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as SelfCheckinDisplayStoryJS from './SelfCheckinDisplayStory.re.mjs';

export type props<url,onClose> = { readonly url?: url; readonly onClose?: onClose };

/** An event page, as PlayerCheckin passes it. */
export const eventUrl: string = SelfCheckinDisplayStoryJS.eventUrl as any;

/** A long URL (tracking parameters, a Japanese club slug): a denser code. */
export const longUrl: string = SelfCheckinDisplayStoryJS.longUrl as any;

export const make: React.ComponentType<{ readonly url?: string; readonly onClose?: () => void }> = SelfCheckinDisplayStoryJS.make as any;
