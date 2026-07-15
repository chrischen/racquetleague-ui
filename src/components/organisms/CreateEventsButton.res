%%raw("import { t } from '@lingui/macro'")

// Resolves the batch activity slug to an activity node id.
module ActivitiesQuery = %relay(`
  query CreateEventsButtonActivitiesQuery {
    activities {
      id
      slug
    }
  }
`)

// address (via Google Places) -> find-or-create Location, returns its id.
module AutocompleteLocationMutation = %relay(`
  mutation CreateEventsButtonAutocompleteLocationMutation($input: AutocompleteLocationInput!) {
    autocompleteLocation(input: $input) {
      location {
        id
      }
    }
  }
`)

// Structured single-event create, one call per suggested event.
module CreateEventMutation = %relay(`
  mutation CreateEventsButtonCreateEventMutation($connections: [ID!]!, $input: CreateEventInput!) {
    createEvent(input: $input) {
      event @appendNode(connections: $connections, edgeTypeName: "EventEdge") {
        __typename
        id
        title
        details
        maxRsvps
        minRating
        activity {
          id
          name
          slug
        }
        startDate
        endDate
        listed
        timezone
        tags
        cancelDeadline
      }
    }
  }
`)

external alert: string => unit = "alert"

// Per-event outcome of a create attempt.
type outcome =
  | Created(string) // event id
  | NeedsLocation // address didn't resolve -> show a picker
  | CreateFailed // createEvent errored (e.g. already exists) -> report, not a location problem

@react.component
let make = (
  ~events: array<AITypes.eventDetails>,
  ~activitySlug: string,
  ~clubId: option<string>=?,
  ~onEventsCreated: option<unit => unit>=?,
) => {
  let ts = Lingui.UtilString.t
  let environment = RescriptRelay.useEnvironmentFromContext()
  let (commitAutocomplete, _) = AutocompleteLocationMutation.use()
  let (commitCreateEvent, _) = CreateEventMutation.use()
  let navigate = Router.useNavigate()

  let (isCreating, setIsCreating) = React.useState(() => false)
  // Activity id resolved on the last create attempt; reused by the picker retry.
  let (activityId, setActivityId) = React.useState((): option<string> => None)
  // Events whose address couldn't be auto-resolved; shown with a picker to fix.
  let (unresolved, setUnresolved) = React.useState((): array<AITypes.eventDetails> => [])
  // Events already created (by reference), so re-clicking "Create All" doesn't
  // re-submit them (the server rejects duplicates).
  let (created, setCreated) = React.useState((): array<AITypes.eventDetails> => [])

  let eventCount = events->Array.length
  let buttonText = eventCount == 1 ? ts`Create This Event` : ts`Create All Events`

  let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
    "client:root"->RescriptRelay.makeDataId,
    "EventsListFragment_events",
    (),
  )

  // address -> locationId: Google Places textSearch (top hit) then the
  // autocompleteLocation upsert (find-or-create by mapsId).
  let resolveLocationId = async (address: string): result<string, unit> =>
    switch await GooglePlaces.textSearchTop(address) {
    | Some(place) =>
      switch (place.name, place.formattedAddress, place.geometry, place.placeId) {
      | (Some(name), Some(formattedAddress), Some(geometry), Some(placeId)) =>
        let resolved = await Promise.make((resolve, _reject) =>
          commitAutocomplete(
            ~variables={
              input: {
                name,
                formattedAddress,
                lat: geometry.location.lat(),
                lng: geometry.location.lng(),
                mapsId: placeId,
              },
            },
            ~onCompleted=(response, _errors) =>
              resolve(response.autocompleteLocation.location->Option.map(l => l.id)),
            ~onError=_ => resolve(None),
          )->RescriptRelay.Disposable.ignore
        )
        switch resolved {
        | Some(id) => Ok(id)
        | None => Error()
        }
      | _ => Error()
      }
    | None => Error()
    }

  // Build CreateEventInput from a suggested-event draft + resolved ids. The
  // structured fields ride in rawFields (a CreateEventInput-shaped object);
  // minRating is derived from the level tags exactly as the create form does.
  let buildInput = (
    event: AITypes.eventDetails,
    ~locationId,
    ~activityId,
  ): RelaySchemaAssets_graphql.input_CreateEventInput => {
    let raw = event.rawFields->Option.getOr(Js.Dict.empty())
    let getStr = k => raw->Js.Dict.get(k)->Option.flatMap(v => v->Js.Json.decodeString)
    let getNum = k => raw->Js.Dict.get(k)->Option.flatMap(v => v->Js.Json.decodeNumber)
    let getBool = k => raw->Js.Dict.get(k)->Option.flatMap(v => v->Js.Json.decodeBoolean)
    let getInt = k => getNum(k)->Option.map(Float.toInt)
    let getStrArray = k =>
      raw
      ->Js.Dict.get(k)
      ->Option.flatMap(v => v->Js.Json.decodeArray)
      ->Option.map(a => a->Belt.Array.keepMap(v => v->Js.Json.decodeString))

    let startDate = Js.Date.fromString(event.date)
    let endDate = Js.Date.fromString(event.time)
    // Drop "rec" (the recreational default is represented by absence), matching
    // the create form's tagsToSubmit.
    let tags = getStrArray("tags")->Option.getOr([])->Array.filter(t => t != "rec")
    let listed = getBool("listed")->Option.getOr(true)

    {
      title: event.title,
      activity: activityId,
      locationId,
      startDate: startDate->Util.Datetime.fromDate,
      endDate: endDate->Util.Datetime.fromDate,
      details: ?event.description,
      maxRsvps: ?event.maxRsvps,
      minRating: ?EventTags.minRatingFromTags(tags),
      price: ?getInt("price"),
      listed,
      timezone: ?getStr("timezone"),
      tags,
      cancelDeadline: ?getInt("cancelDeadline"),
      clubId: ?clubId,
    }
  }

  let createOne = (event, ~locationId, ~activityId): promise<result<string, unit>> =>
    Promise.make((resolve, _reject) =>
      commitCreateEvent(
        ~variables={
          connections: [connectionId],
          input: buildInput(event, ~locationId, ~activityId),
        },
        ~onCompleted=(response, _errors) =>
          resolve(
            switch response.createEvent.event {
            | Some(e) => Ok(e.id)
            | None => Error()
            },
          ),
        ~onError=_ => resolve(Error()),
      )->RescriptRelay.Disposable.ignore
    )

  let fetchActivityId = () =>
    Promise.make((resolve, _reject) => {
      let _ = ActivitiesQuery.fetch(~environment, ~variables=(), ~onResult=result =>
        switch result {
        | Ok(data) =>
          resolve(
            data.activities
            ->Array.find(a => a.slug->Option.getOr("") == activitySlug)
            ->Option.map(a => a.id),
          )
        | Error(_) => resolve(None)
        }
      )
    })

  let handleCreate = async () => {
    setIsCreating(_ => true)
    switch await fetchActivityId() {
    | None =>
      setIsCreating(_ => false)
      alert(ts`Couldn't determine the activity. Please try again.`)
    | Some(actId) =>
      setActivityId(_ => Some(actId))
      // Skip events already created (so a re-click doesn't duplicate them).
      let toCreate = events->Array.filter(e => !(created->Array.some(c => c === e)))
      let outcomes = await Promise.all(
        toCreate->Array.map(async event =>
          switch event.location {
          | Some(address) =>
            switch await resolveLocationId(address) {
            | Ok(locationId) =>
              switch await createOne(event, ~locationId, ~activityId=actId) {
              | Ok(id) => (event, Created(id))
              | Error() => (event, CreateFailed)
              }
            | Error() => (event, NeedsLocation)
            }
          | None => (event, NeedsLocation)
          }
        ),
      )
      let createdEvents =
        outcomes->Belt.Array.keepMap(((e, o)) =>
          switch o {
          | Created(_) => Some(e)
          | _ => None
          }
        )
      let createdIds =
        outcomes->Belt.Array.keepMap(((_, o)) =>
          switch o {
          | Created(id) => Some(id)
          | _ => None
          }
        )
      let needsLocation =
        outcomes->Belt.Array.keepMap(((e, o)) =>
          switch o {
          | NeedsLocation => Some(e)
          | _ => None
          }
        )
      let createFailedCount =
        outcomes->Array.filter(((_, o)) =>
          switch o {
          | CreateFailed => true
          | _ => false
          }
        )->Array.length

      setCreated(prev => Array.concat(prev, createdEvents))
      // Only address-resolution failures belong in the picker list.
      setUnresolved(_ => needsLocation)
      setIsCreating(_ => false)
      if createdIds->Array.length > 0 {
        onEventsCreated->Option.forEach(cb => cb())
      }
      switch (createdIds, needsLocation, createFailedCount) {
      | ([id], [], 0) => navigate(`/events/${id}`, None)
      | (_, [], 0) => alert(ts`${createdIds->Array.length->Int.toString} events created!`)
      | _ =>
        if createFailedCount > 0 {
          alert(
            ts`${createFailedCount->Int.toString} event(s) couldn't be created (they may already exist).`,
          )
        }
      }
    }
  }

  // The user picked a location for a previously-unresolved event.
  let handlePicked = (event: AITypes.eventDetails, locationId: string) =>
    switch activityId {
    | Some(actId) =>
      createOne(event, ~locationId, ~activityId=actId)
      ->Promise.thenResolve(result =>
        switch result {
        | Ok(_) => {
            setUnresolved(prev => prev->Array.filter(e => e !== event))
            setCreated(prev => Array.concat(prev, [event]))
            onEventsCreated->Option.forEach(cb => cb())
          }
        | Error() => alert(ts`Couldn't create that event. Please try again.`)
        }
      )
      ->ignore
    | None => ()
    }

  <div className="space-y-3">
    <button
      onClick={_ => handleCreate()->ignore}
      disabled=isCreating
      className="w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 disabled:opacity-60 text-white rounded-2xl font-medium transition-all shadow-lg shadow-purple-500/25">
      {React.string(isCreating ? ts`Creating...` : buttonText)}
    </button>
    {unresolved->Array.length > 0
      ? <div className="space-y-3">
          {unresolved
          ->Array.mapWithIndex((event, i) =>
            <div
              key={i->Int.toString}
              className="p-3 rounded-xl border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-900/20 space-y-2">
              <p className="text-sm text-amber-800 dark:text-amber-300">
                {ts`Couldn't find this location — pick it:`->React.string}
              </p>
              <p className="text-xs italic text-amber-700 dark:text-amber-400 break-words">
                {event.location->Option.getOr(event.title)->React.string}
              </p>
              <AutocompleteLocation onSelected={locationId => handlePicked(event, locationId)} />
            </div>
          )
          ->React.array}
        </div>
      : React.null}
  </div>
}
