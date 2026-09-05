/* @generated */
@@warning("-30")

@live @unboxed
type enum_CourtType = 
  | @as("indoor") Indoor
  | @as("outdoor") Outdoor
  | FutureAddedValue(string)


@live @unboxed
type enum_CourtType_input = 
  | @as("indoor") Indoor
  | @as("outdoor") Outdoor


@live @unboxed
type enum_SmartRsvpAlgorithm = 
  | Ilp
  | BestFit
  | FutureAddedValue(string)


@live @unboxed
type enum_SmartRsvpAlgorithm_input = 
  | Ilp
  | BestFit


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
type enum_Region = 
  | @as("tokyo") Tokyo
  | FutureAddedValue(string)


@live
type enum_Region_input = 
  | @as("tokyo") Tokyo


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
type rec input_ActionResultInput = {
  operationName: string,
  proposalId: string,
  resultJson: string,
}

@live
and input_ActionResultInput_nullable = {
  operationName: string,
  proposalId: string,
  resultJson: string,
}

@live
and input_AddUserToClubInput = {
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
and input_AvailabilityDayInput = {
  intervals: array<input_IntervalInput>,
  localDate: string,
}

@live
and input_AvailabilityDayInput_nullable = {
  intervals: array<input_IntervalInput_nullable>,
  localDate: string,
}

@live
and input_BanUserFromClubInput = {
  clubId: string,
  reason?: string,
  userId: string,
}

@live
and input_BanUserFromClubInput_nullable = {
  clubId: string,
  reason?: Js.Null.t<string>,
  userId: string,
}

@live
and input_ChatInput = {
  actionResult?: input_ActionResultInput,
  message?: string,
}

@live
and input_ChatInput_nullable = {
  actionResult?: Js.Null.t<input_ActionResultInput_nullable>,
  message?: Js.Null.t<string>,
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
and input_CoordsInput = {
  lat: float,
  lng: float,
}

@live
and input_CoordsInput_nullable = {
  lat: float,
  lng: float,
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
  cancelDeadline?: int,
  clubId?: string,
  details?: string,
  endDate: Util.Datetime.t,
  listed?: bool,
  locationId: string,
  maxRsvps?: int,
  minRating?: float,
  price?: int,
  smartRsvpThreshold?: float,
  startDate: Util.Datetime.t,
  tags?: array<string>,
  timezone?: string,
  title: string,
}

@live
and input_CreateEventInput_nullable = {
  activity: string,
  cancelDeadline?: Js.Null.t<int>,
  clubId?: Js.Null.t<string>,
  details?: Js.Null.t<string>,
  endDate: Util.Datetime.t,
  listed?: Js.Null.t<bool>,
  locationId: string,
  maxRsvps?: Js.Null.t<int>,
  minRating?: Js.Null.t<float>,
  price?: Js.Null.t<int>,
  smartRsvpThreshold?: Js.Null.t<float>,
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
and input_DeleteAvailabilityForTimeWindowInput = {
  activityId: string,
  endHour: int,
  localDate: string,
  startHour: int,
}

@live
and input_DeleteAvailabilityForTimeWindowInput_nullable = {
  activityId: string,
  endHour: int,
  localDate: string,
  startHour: int,
}

@live
and input_DeleteClubInput = {
  clubId: string,
}

@live
and input_DeleteClubInput_nullable = {
  clubId: string,
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
  level?: float,
  locationId?: string,
  rating?: float,
  shadow?: bool,
  userId?: string,
  viewer?: bool,
}

@live
and input_EventFilters_nullable = {
  activitySlug?: Js.Null.t<string>,
  clubSlug?: Js.Null.t<string>,
  level?: Js.Null.t<float>,
  locationId?: Js.Null.t<string>,
  rating?: Js.Null.t<float>,
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
and input_IntervalInput = {
  endHour: int,
  startHour: int,
}

@live
and input_IntervalInput_nullable = {
  endHour: int,
  startHour: int,
}

@live
and input_IsUserBannedInput = {
  clubId: string,
  userId: string,
}

@live
and input_IsUserBannedInput_nullable = {
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
  eventId?: string,
  namespace: string,
  syncId?: string,
}

@live
and input_LeagueMatchInput_nullable = {
  activitySlug: string,
  doublesMatch: input_DoublesMatchInput_nullable,
  eventId?: Js.Null.t<string>,
  namespace: string,
  syncId?: Js.Null.t<string>,
}

@live
and input_LeagueRatingInput = {
  activitySlug: string,
  clubId?: string,
  namespace: string,
  userId?: string,
}

@live
and input_LeagueRatingInput_nullable = {
  activitySlug: string,
  clubId?: Js.Null.t<string>,
  namespace: string,
  userId?: Js.Null.t<string>,
}

@live
and input_LocationInput = {
  coords?: input_CoordsInput,
  region?: enum_Region_input,
}

@live
and input_LocationInput_nullable = {
  coords?: Js.Null.t<input_CoordsInput_nullable>,
  region?: Js.Null.t<enum_Region_input>,
}

@live
and input_OverlapScopeInput = {
  activityId: string,
  clubId?: string,
  userIds?: array<string>,
}

@live
and input_OverlapScopeInput_nullable = {
  activityId: string,
  clubId?: Js.Null.t<string>,
  userIds?: Js.Null.t<array<string>>,
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
and input_RegisterPushSubscriptionInput = {
  auth: string,
  endpoint: string,
  expirationTime?: float,
  p256dh: string,
}

@live
and input_RegisterPushSubscriptionInput_nullable = {
  auth: string,
  endpoint: string,
  expirationTime?: Js.Null.t<float>,
  p256dh: string,
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
and input_SetAvailabilityDayInput = {
  activityId: string,
  intervals: array<input_IntervalInput>,
  localDate: string,
  location?: input_LocationInput,
}

@live
and input_SetAvailabilityDayInput_nullable = {
  activityId: string,
  intervals: array<input_IntervalInput_nullable>,
  localDate: string,
  location?: Js.Null.t<input_LocationInput_nullable>,
}

@live
and input_SetAvailabilityDaysInput = {
  activityId: string,
  days: array<input_AvailabilityDayInput>,
  location?: input_LocationInput,
}

@live
and input_SetAvailabilityDaysInput_nullable = {
  activityId: string,
  days: array<input_AvailabilityDayInput_nullable>,
  location?: Js.Null.t<input_LocationInput_nullable>,
}

@live
and input_SetMembershipAdminInput = {
  isAdmin: bool,
  membershipId: string,
}

@live
and input_SetMembershipAdminInput_nullable = {
  isAdmin: bool,
  membershipId: string,
}

@live
and input_UnbanUserFromClubInput = {
  clubId: string,
  userId: string,
}

@live
and input_UnbanUserFromClubInput_nullable = {
  clubId: string,
  userId: string,
}

@live
and input_UpdateClubInput = {
  activity?: string,
  clubId: string,
  description?: string,
  listed?: bool,
  name?: string,
  slug?: string,
}

@live
and input_UpdateClubInput_nullable = {
  activity?: Js.Null.t<string>,
  clubId: string,
  description?: Js.Null.t<string>,
  listed?: Js.Null.t<bool>,
  name?: Js.Null.t<string>,
  slug?: Js.Null.t<string>,
}

@live
and input_UpdateLocaleInput = {
  locale: string,
}

@live
and input_UpdateLocaleInput_nullable = {
  locale: string,
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
  gender?: enum_Gender_input,
  selfRating?: float,
  username: string,
}

@live
and input_UpdateProfileInput_nullable = {
  biography: string,
  fullName: string,
  gender?: Js.Null.t<enum_Gender_input>,
  selfRating?: Js.Null.t<float>,
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
and input_UpdateViewerContactInput = {
  email?: string,
  lineUsername?: string,
}

@live
and input_UpdateViewerContactInput_nullable = {
  email?: Js.Null.t<string>,
  lineUsername?: Js.Null.t<string>,
}

@live
and input_UpdateViewerLocationInput = {
  lat: float,
  lng: float,
}

@live
and input_UpdateViewerLocationInput_nullable = {
  lat: float,
  lng: float,
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
