/* TypeScript file generated from StoryFixturesEvent.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as StoryFixturesEventJS from './StoryFixturesEvent.re.mjs';

export type duprMock = {
  readonly doubles: number; 
  readonly doublesReliable: boolean; 
  readonly doublesReliability: number
};

export type userMock = {
  readonly id: string; 
  readonly lineUsername: (null | string); 
  readonly fullName: (null | string); 
  readonly picture: (null | string); 
  readonly gender: (null | 
    "male"
  | "female"); 
  readonly selfRating: (null | number); 
  readonly dupr: (null | duprMock)
};

export type ratingMock = {
  readonly id: string; 
  readonly mu: number; 
  readonly sigma: number; 
  readonly ordinal: number
};

/** Payment.status: 0 legacy hold, 1 charged, 2 refunded, 3 charge failed
    (card still on file), 4 pending, 5 card on file. */
export type paymentMock = {
  readonly id: string; 
  readonly status: number; 
  readonly chargeable: boolean; 
  readonly currency: string; 
  readonly amount: number
};

/** Rsvp.listType: 0 (or null) the main list, which the event's maxRsvps
    splits into going and waitlist; 1 pending (awaiting the organizer); 2
    invited by the organizer. */
export type rsvpMock = {
  readonly id: string; 
  readonly listType: (null | number); 
  readonly paid: (null | number); 
  readonly message: (null | string); 
  readonly payment: (null | paymentMock); 
  readonly rating: (null | ratingMock); 
  readonly user: userMock
};

export type edgeMock = { readonly node: rsvpMock };

export type connectionMock = { readonly edges: edgeMock[] };

export const avatar: (name:string, seed:number) => string = StoryFixturesEventJS.avatar as any;

/** The number of players in the roster. */
export const rosterSize: number = StoryFixturesEventJS.rosterSize as any;

/** The roster's players as users, strongest first. */
export const users: (count:number) => userMock[] = StoryFixturesEventJS.users as any;

/** The first `count` roster players as main-list RSVPs (going, unpaid, no
    message), strongest first. */
export const rsvps: (count:number) => rsvpMock[] = StoryFixturesEventJS.rsvps as any;

/** RSVPs for the roster players from `start` (0-based), `count` of them. */
export const rsvpsFrom: (start:number, count:number) => rsvpMock[] = StoryFixturesEventJS.rsvpsFrom as any;

/** A yen payment in the given status on the RSVP with this id. */
export const payment: (rsvpId:string, status:number) => paymentMock = StoryFixturesEventJS.payment as any;

/** An Event.rsvps connection. */
export const connection: (nodes:rsvpMock[]) => connectionMock = StoryFixturesEventJS.connection as any;

export const startDate: string = StoryFixturesEventJS.startDate as any;

export const endDate: string = StoryFixturesEventJS.endDate as any;
