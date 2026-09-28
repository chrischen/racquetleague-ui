/* TypeScript file generated from StoryFixturesEventPage.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as StoryFixturesEventPageJS from './StoryFixturesEventPage.re.mjs';

export type messageMock = {
  readonly id: string; 
  readonly createdAt: string; 
  readonly payload: string; 
  readonly topic: string
};

export type messageEdgeMock = { readonly cursor: string; readonly node: messageMock };

export type messageConnectionMock = { readonly edges: messageEdgeMock[] };

export type duprMock = {
  readonly doubles: number; 
  readonly doublesReliable: boolean; 
  readonly doublesReliability: number
};

export type eventRatingMock = {
  readonly id: string; 
  readonly mu: number; 
  readonly sigma: number
};

/** A User as PlayerInviteSwipeDeck_user selects it. */
export type inviteeMock = {
  readonly id: string; 
  readonly lineUsername: string; 
  readonly picture: (null | string); 
  readonly gender: (null | 
    "male"
  | "female"); 
  readonly biography: (null | string); 
  readonly selfRating: (null | number); 
  readonly dupr: (null | duprMock); 
  readonly eventRating: (null | eventRatingMock)
};

export type resolvedRatingMock = { readonly dupr: number; readonly established: boolean };

export type recommendationMock = {
  readonly availability: 
    "unavailable"
  | "available"
  | "unknown"; 
  readonly fit: 
    "unbalanced"
  | "balanced"
  | "unknown"; 
  readonly strong: boolean; 
  readonly rating: resolvedRatingMock; 
  readonly user: inviteeMock
};

export type recommendationsMock = { readonly recommendations: recommendationMock[] };

export type intervalMock = { readonly startHour: number; readonly endHour: number };

export type availabilityDayMock = {
  readonly id: string; 
  readonly localDate: string; 
  readonly user: inviteeMock; 
  readonly intervals: intervalMock[]
};

/** The story event's id, as every batch-B wrapper queries it. */
export const eventId: string = StoryFixturesEventPageJS.eventId as any;

/** The event's activity-feed topic, as the event page subscribes to it. */
export const topic: string = StoryFixturesEventPageJS.topic as any;

/** The instant `minutes` before `anchor` (ms since the epoch), as ISO. */
export const minutesBefore: (anchor:number, minutes:number) => string = StoryFixturesEventPageJS.minutesBefore as any;

/** 19:00 in Tokyo, `days` days after `anchor`'s Tokyo date, in ms. A
    weeknight session a few days out, whatever day the story is opened. */
export const tokyoEvening: (anchor:number, days:number) => number = StoryFixturesEventPageJS.tokyoEvening as any;

/** One feed row. The payload is the JSON the server writes: who acted, what
    happened and, for messages and edits, the text. */
export const message: (id:string, createdAt:string, actor:string, activityType:string, details:(null | string)) => messageMock = StoryFixturesEventPageJS.message as any;

/** A Query.messagesByTopic connection, newest first as the server sends it. */
export const messageConnection: (messages:messageMock[]) => messageConnectionMock = StoryFixturesEventPageJS.messageConnection as any;

/** The event's feed: the first `count` rows (up to 10) of a typical evening,
    `anchor` being the newest moment. Player chat is written with
    `commentType`: "comment_added" on the pickleball event page
    (PkEventMessages), "user_message" on the classic one (EventMessages). */
export const conversation: (anchor:number, count:number, commentType:string) => messageConnectionMock = StoryFixturesEventPageJS.conversation as any;

/** Query.inviteRecommendations: the first `count` invitees (up to 5), ranked. */
export const recommendations: (count:number) => recommendationsMock = StoryFixturesEventPageJS.recommendations as any;

/** Query.availabilityUsersForDay on `localDate`: every invitee who stored
    availability that day. Those past the ranked five cover 18:00-22:00; the
    others overlap with the recommendations or miss the event's hours. */
export const availabilityDays: (localDate:string) => availabilityDayMock[] = StoryFixturesEventPageJS.availabilityDays as any;
