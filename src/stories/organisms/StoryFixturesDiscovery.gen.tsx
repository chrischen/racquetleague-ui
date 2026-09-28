/* TypeScript file generated from StoryFixturesDiscovery.res by genType. */

/* eslint-disable */
/* tslint:disable */

import * as StoryFixturesDiscoveryJS from './StoryFixturesDiscovery.re.mjs';

import type {connectionMock as StoryFixturesEvent_connectionMock} from './StoryFixturesEvent.gen';

import type {userMock as StoryFixturesEvent_userMock} from './StoryFixturesEvent.gen';

export type placeMock = { readonly id: string; readonly name: string };

export type clubMock = {
  readonly id: string; 
  readonly name: string; 
  readonly slug: string
};

export type coordsMock = { readonly lat: number; readonly lng: number };

export type resolvedLocationMock = { readonly coords: coordsMock; readonly region: (null | string) };

/** The signed-in player, with a complete profile so joining and sharing
    availability are not gated. Give it as both viewer.user and
    viewer.profile (one User record). */
export type viewerUserMock = {
  readonly id: string; 
  readonly lineUsername: string; 
  readonly fullName: string; 
  readonly email: string; 
  readonly biography: string; 
  readonly selfRating: number; 
  readonly picture: string; 
  readonly gender: string; 
  readonly locale: string
};

export type eventMock = {
  readonly id: string; 
  readonly title: string; 
  readonly startDate: string; 
  readonly endDate: string; 
  readonly timezone: string; 
  readonly location: placeMock; 
  readonly club: (null | clubMock); 
  readonly maxRsvps: (null | number); 
  readonly rsvps: StoryFixturesEvent_connectionMock; 
  readonly shadow: boolean; 
  readonly listed: boolean; 
  readonly deleted: (null | string); 
  readonly tags: string[]; 
  readonly cancelDeadline: (null | number)
};

export type eventEdgeMock = { readonly node: eventMock };

export type pageInfoMock = {
  readonly hasNextPage: boolean; 
  readonly hasPreviousPage: boolean; 
  readonly startCursor: (null | string); 
  readonly endCursor: (null | string)
};

export type eventConnectionMock = { readonly edges: eventEdgeMock[]; readonly pageInfo: pageInfoMock };

export type intervalMock = { readonly startHour: number; readonly endHour: number };

/** An AvailabilityDay: a player's windows for one day. */
export type availabilityDayMock = {
  readonly id: string; 
  readonly localDate: string; 
  readonly user: (null | StoryFixturesEvent_userMock); 
  readonly intervals: intervalMock[]
};

export type hourlyMock = {
  readonly hour: number; 
  readonly indoorCount: number; 
  readonly outdoorCount: number; 
  readonly priceMin: (null | number); 
  readonly priceMax: (null | number)
};

/** A LocationAvailabilityDay: one venue's open courts for a day. */
export type courtDayMock = {
  readonly id: string; 
  readonly localDate: string; 
  readonly link: (null | string); 
  readonly location: (null | placeMock); 
  readonly intervals: intervalMock[]; 
  readonly hourly: hourlyMock[]
};

export type hourCountMock = { readonly hour: number; readonly count: number };

/** The stories' "now": Wednesday 14 October 2026, 09:00 in Tokyo. */
export const now: string = StoryFixturesDiscoveryJS.now as any;

/** The availability window the event pages ask for (EventsListUtils: two weeks). */
export const fromDate: string = StoryFixturesDiscoveryJS.fromDate as any;

export const toDate: string = StoryFixturesDiscoveryJS.toDate as any;

/** A story `beforeEach`: runs the clock from `now` (still ticking, so timers
    and debounces behave), and restores the real clock afterwards. The lists
    bucket events into Today / Tomorrow / weekday by the current date and the
    rows grey out a passed cancel deadline, so without this the same fixtures
    would read differently every day. */
export const shiftClock: () => () => void = StoryFixturesDiscoveryJS.shiftClock as any;

/** The viewer's club. */
export const tokyoClub: clubMock = StoryFixturesDiscoveryJS.tokyoClub as any;

/** A location club (LocationClub): every event is open play at its home court. */
export const picklrClub: clubMock = StoryFixturesDiscoveryJS.picklrClub as any;

/** Query.resolvedLocation for a list scoped to the Tokyo default. */
export const resolvedTokyo: resolvedLocationMock = StoryFixturesDiscoveryJS.resolvedTokyo as any;

export const viewerUser: viewerUserMock = StoryFixturesDiscoveryJS.viewerUser as any;

/** The Discover feed, in start order: six days, twelve events. */
export const discoverEvents: eventMock[] = StoryFixturesDiscoveryJS.discoverEvents as any;

/** The events the viewer is on (joined, waitlisted or pending). */
export const viewerEvents: eventMock[] = StoryFixturesDiscoveryJS.viewerEvents as any;

/** Tokyo Pickleball Club's schedule. */
export const clubEvents: eventMock[] = StoryFixturesDiscoveryJS.clubEvents as any;

/** A location club's week: open play at its home court, six players each. */
export const picklrEvents: eventMock[] = StoryFixturesDiscoveryJS.picklrEvents as any;

/** Events by id, for picking single rows. */
export const eventById: (id:string) => (null | eventMock) = StoryFixturesDiscoveryJS.eventById as any;

/** An EventConnection over `events`; `more` says there are pages on both sides. */
export const eventsConnection: (events:eventMock[], more:boolean) => eventConnectionMock = StoryFixturesDiscoveryJS.eventsConnection as any;

/** viewer.availability. */
export const viewerAvailability: availabilityDayMock[] = StoryFixturesDiscoveryJS.viewerAvailability as any;

/** Query.availabilityUsersForDateRange: everyone else's windows. */
export const playerAvailability: availabilityDayMock[] = StoryFixturesDiscoveryJS.playerAvailability as any;

/** Query.locationsAvailability: every venue's open courts over the fortnight. */
export const courtDays: courtDayMock[] = StoryFixturesDiscoveryJS.courtDays as any;

/** Query.availabilityHourlyCounts for one day: the picker's demand heatmap. */
export const hourlyCounts: hourCountMock[] = StoryFixturesDiscoveryJS.hourlyCounts as any;
