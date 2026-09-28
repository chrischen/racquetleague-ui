/* TypeScript file generated from StoryFixturesMatch.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as StoryFixturesMatchJS from './StoryFixturesMatch.re.mjs';

export type mockUser = {
  readonly id: string; 
  readonly lineUsername: string; 
  readonly gender: string; 
  readonly picture: (null | string)
};

export type mockRating = {
  readonly id: string; 
  readonly mu: number; 
  readonly sigma: number; 
  readonly ordinal: number
};

export type mockRsvp = {
  readonly id: string; 
  readonly user: mockUser; 
  readonly rating: mockRating
};

export type mockEdge = { readonly cursor: string; readonly node: mockRsvp };

export type mockRsvps = { readonly edges: mockEdge[] };

export type mockEvent = { readonly rsvps: mockRsvps };

/** The story event, one RSVP per roster player: `parameters.relay.mocks: { Query: { event: eventMock } }`. */
export const eventMock: mockEvent = StoryFixturesMatchJS.eventMock as any;
