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
type enum_RsvpStatus = 
  | Joined
  | Waitlist
  | FutureAddedValue(string)


@live @unboxed
type enum_RsvpStatus_input = 
  | Joined
  | Waitlist


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
type rec input_CreateActivitySubscriptionInput = {
  activityId: string,
}

@live
and input_CreateActivitySubscriptionInput_nullable = {
  activityId: string,
}

@live
and input_CreateEventInput = {
  activity: string,
  details?: string,
  endDate: Util.Datetime.t,
  listed?: bool,
  locationId: string,
  maxRsvps?: int,
  startDate: Util.Datetime.t,
  title: string,
}

@live
and input_CreateEventInput_nullable = {
  activity: string,
  details?: Js.Null.t<string>,
  endDate: Util.Datetime.t,
  listed?: Js.Null.t<bool>,
  locationId: string,
  maxRsvps?: Js.Null.t<int>,
  startDate: Util.Datetime.t,
  title: string,
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
and input_EventFilters = {
  locationId?: string,
  userId?: string,
  viewer?: bool,
}

@live
and input_EventFilters_nullable = {
  locationId?: Js.Null.t<string>,
  userId?: Js.Null.t<string>,
  viewer?: Js.Null.t<bool>,
}
