/* @generated */
@@warning("-30")

@live @unboxed
type enum_Gender = 
  | @as("female") Female
  | @as("male") Male
  | FutureAddedValue(string)


@live @unboxed
type enum_Gender_input = 
  | @as("female") Female
  | @as("male") Male


@live @unboxed
type enum_MessageType = 
  | Agent
  | Function
  | User
  | FutureAddedValue(string)


@live @unboxed
type enum_MessageType_input = 
  | Agent
  | Function
  | User


@live @unboxed
type enum_T = 
  | Active
  | Pending
  | Rejected
  | FutureAddedValue(string)


@live @unboxed
type enum_T_input = 
  | Active
  | Pending
  | Rejected


@live @unboxed
type enum_RequiredFieldAction = 
  | NONE
  | LOG
  | THROW
  | FutureAddedValue(string)


@live @unboxed
type enum_RequiredFieldAction_input = 
  | NONE
  | LOG
  | THROW


@live
type rec input_AddUserToClubInput = {
  clubId: string,
  isAdmin?: bool,
  userId: string,
}

@live
and input_AddUserToClubInput_nullable = {
  clubId: string,
  isAdmin?: Js.Null.t<bool>,
  userId: string,
}

@live
and input_AutocompleteLocationInput = {
  formattedAddress: string,
  lat: float,
  lng: float,
  mapsId: string,
  name: string,
  plusCode?: string,
}

@live
and input_AutocompleteLocationInput_nullable = {
  formattedAddress: string,
  lat: float,
  lng: float,
  mapsId: string,
  name: string,
  plusCode?: Js.Null.t<string>,
}

@live
and input_ChatInput = {
  message: string,
}

@live
and input_ChatInput_nullable = {
  message: string,
}

@live
and input_ClubMembersInput = {
  clubId: string,
}

@live
and input_ClubMembersInput_nullable = {
  clubId: string,
}

@live
and input_CreateActivitySubscriptionInput = {
  activityId: string,
}

@live
and input_CreateActivitySubscriptionInput_nullable = {
  activityId: string,
}

@live
and input_CreateClubInput = {
  activity: string,
  description?: string,
  name: string,
  slug: string,
}

@live
and input_CreateClubInput_nullable = {
  activity: string,
  description?: Js.Null.t<string>,
  name: string,
  slug: string,
}

@live
and input_CreateEventInput = {
  activity: string,
  clubId: string,
  details?: string,
  endDate: Util.Datetime.t,
  listed?: bool,
  locationId: string,
  maxRsvps?: int,
  minRating?: float,
  startDate: Util.Datetime.t,
  tags?: array<string>,
  timezone?: string,
  title: string,
}

@live
and input_CreateEventInput_nullable = {
  activity: string,
  clubId: string,
  details?: Js.Null.t<string>,
  endDate: Util.Datetime.t,
  listed?: Js.Null.t<bool>,
  locationId: string,
  maxRsvps?: Js.Null.t<int>,
  minRating?: Js.Null.t<float>,
  startDate: Util.Datetime.t,
  tags?: Js.Null.t<array<string>>,
  timezone?: Js.Null.t<string>,
  title: string,
}

@live
and input_CreateEventsInput = {
  activityId?: string,
  activitySlug?: string,
  clubId?: string,
  input: string,
  listed: bool,
  timezone?: string,
}

@live
and input_CreateEventsInput_nullable = {
  activityId?: Js.Null.t<string>,
  activitySlug?: Js.Null.t<string>,
  clubId?: Js.Null.t<string>,
  input: string,
  listed: bool,
  timezone?: Js.Null.t<string>,
}

@live
and input_CreateLocationInput = {
  address: string,
  details?: string,
  links?: array<string>,
  listed?: bool,
  name: string,
}

@live
and input_CreateLocationInput_nullable = {
  address: string,
  details?: Js.Null.t<string>,
  links?: Js.Null.t<array<string>>,
  listed?: Js.Null.t<bool>,
  name: string,
}

@live
and input_DeleteActivitySubscriptionInput = {
  subscriptionId: string,
}

@live
and input_DeleteActivitySubscriptionInput_nullable = {
  subscriptionId: string,
}

@live
and input_DoublesMatchInput = {
  createdAt: Util.Datetime.t,
  losers: array<string>,
  score?: array<float>,
  winners: array<string>,
}

@live
and input_DoublesMatchInput_nullable = {
  createdAt: Util.Datetime.t,
  losers: array<string>,
  score?: Js.Null.t<array<float>>,
  winners: array<string>,
}

@live
and input_EventFilters = {
  activitySlug?: string,
  clubSlug?: string,
  locationId?: string,
  shadow?: bool,
  userId?: string,
  viewer?: bool,
}

@live
and input_EventFilters_nullable = {
  activitySlug?: Js.Null.t<string>,
  clubSlug?: Js.Null.t<string>,
  locationId?: Js.Null.t<string>,
  shadow?: Js.Null.t<bool>,
  userId?: Js.Null.t<string>,
  viewer?: Js.Null.t<bool>,
}

@live
and input_GetUserClubMembershipInput = {
  clubId: string,
  userId: string,
}

@live
and input_GetUserClubMembershipInput_nullable = {
  clubId: string,
  userId: string,
}

@live
and input_JoinClubInput = {
  clubId: string,
}

@live
and input_JoinClubInput_nullable = {
  clubId: string,
}

@live
and input_LeagueMatchInput = {
  activitySlug: string,
  doublesMatch: input_DoublesMatchInput,
  namespace: string,
}

@live
and input_LeagueMatchInput_nullable = {
  activitySlug: string,
  doublesMatch: input_DoublesMatchInput_nullable,
  namespace: string,
}

@live
and input_LeagueRatingInput = {
  activitySlug: string,
  namespace: string,
  userId?: string,
}

@live
and input_LeagueRatingInput_nullable = {
  activitySlug: string,
  namespace: string,
  userId?: Js.Null.t<string>,
}

@live
and input_PredictMatchInput = {
  team1RatingIds: array<string>,
  team2RatingIds: array<string>,
}

@live
and input_PredictMatchInput_nullable = {
  team1RatingIds: array<string>,
  team2RatingIds: array<string>,
}

@live
and input_RemoveUserFromClubInput = {
  clubId: string,
  userId: string,
}

@live
and input_RemoveUserFromClubInput_nullable = {
  clubId: string,
  userId: string,
}

@live
and input_UpdateMembershipStatusInput = {
  membershipId: string,
  status: enum_T_input,
}

@live
and input_UpdateMembershipStatusInput_nullable = {
  membershipId: string,
  status: enum_T_input,
}

@live
and input_UpdateProfileInput = {
  biography: string,
  fullName: string,
  username: string,
}

@live
and input_UpdateProfileInput_nullable = {
  biography: string,
  fullName: string,
  username: string,
}

@live
and input_UpdateRsvpListTypeInput = {
  listType: int,
  rsvpId: string,
}

@live
and input_UpdateRsvpListTypeInput_nullable = {
  listType: int,
  rsvpId: string,
}

@live
and input_UpdateViewerRsvpMessageInput = {
  eventId: string,
  message: string,
}

@live
and input_UpdateViewerRsvpMessageInput_nullable = {
  eventId: string,
  message: string,
}
