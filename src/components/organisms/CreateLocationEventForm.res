%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

module Mutation = %relay(`
 mutation CreateLocationEventFormMutation(
   $connections: [ID!]!
   $input: CreateEventInput!
 ) {
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
     }
   }
 }
`)

module UpdateMutation = %relay(`
 mutation CreateLocationEventFormUpdateMutation(
   $eventId: ID!
   $input: CreateEventInput!
 ) {
   updateEvent(eventId: $eventId, input: $input) {
     event {
       __typename
       id
       title
       details
       maxRsvps
       minRating
       timezone
       activity {
         id
       }
       location {
         id
       }
       club {
         id
         name
         slug
       }
       startDate
       endDate
       listed
       tags
     }
     rsvps {
       id
       listType
       joinTime
       rsvpId
     }
   }
 }
`)

module Fragment = %relay(`
  fragment CreateLocationEventForm_location on Location {
    id
    name
    details
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

@rhf
type inputs = {
  title: Zod.string_,
  activity: Zod.string_,
  // clubId: Zod.string_,
  maxRsvps?: int,
  minRating?: Zod.number,
  startDate: Zod.string_,
  endTime: Zod.string_,
  timezone: Zod.optional<Zod.string_>,
  details: Zod.optional<Zod.string_>,
  listed: bool,
  price?: int,
}

let schema = Zod.z->Zod.object(
  (
    {
      title: Zod.z->Zod.string({required_error: ts`title is required`})->Zod.String.min(1),
      activity: Zod.z->Zod.string({required_error: ts`activity is required`}),
      // clubId: Zod.z->Zod.string({required_error: ts`club is required`}),
      maxRsvps: ?Zod.z->Zod.preprocess(
        v => Int.fromString(v),
        Zod.z->Zod.numberInt({})->Zod.optional,
      ),
      minRating: ?Zod.z->Zod.preprocess(
        v => Float.fromString(v),
        Zod.z->Zod.number({})->Zod.optional,
      ),
      startDate: Zod.z->Zod.string({required_error: ts`event date is required`})->Zod.String.min(1),
      endTime: Zod.z->Zod.string({required_error: ts`end time is required`})->Zod.String.min(5),
      timezone: Zod.z->Zod.string({})->Zod.optional,
      details: Zod.z->Zod.string({})->Zod.optional,
      listed: Zod.z->Zod.boolean({}),
      price: ?Zod.z->Zod.preprocess(v => Int.fromString(v), Zod.z->Zod.numberInt({})->Zod.optional),
    }: inputs
  ),
)

type expandedSection = EventDetailsSection | ActivityFormatSection | FindPlayersSection | None

type prefilledValues = {
  title?: string,
  activitySlug?: string,
  clubId?: string,
  maxRsvps?: int,
  minRating?: float,
  startDate?: string,
  endDate?: string,
  details?: string,
  listed?: bool,
  timezone?: string,
  tags?: array<string>,
  price?: int,
}

// Calculate duration in hours between start date and end time
let calculateDurationHours = (startDateTime: Js.Date.t, endDateTime: Js.Date.t): option<float> => {
  let diffInMillis = endDateTime->DateFns.getTime -. startDateTime->DateFns.getTime
  let durationHours = diffInMillis /. (1000.0 *. 60.0 *. 60.0)
  durationHours > 0.0 ? Some(durationHours) : None
}

@react.component
let make = (
  ~eventId: option<string>=?,
  ~location,
  ~prefilledValues: option<prefilledValues>=?,
  ~selectedClub: option<string>=?,
  ~selectedActivity: option<string>=?,
  ~isClubFormOpen: bool=false,
  ~onClubFormSubmitBlocked: option<unit => unit>=?,
) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let td = Lingui.UtilString.dynamic

  let location = Fragment.use(location)
  let (commitMutationCreate, _) = Mutation.use()
  let (commitMutationUpdate, _) = UpdateMutation.use()
  let navigate = Router.useNavigate()

  let isUpdate = eventId->Option.isSome

  // Determine default values from prefilledValues or use defaults
  let defaultFormValues: defaultValuesOfInputs = switch prefilledValues {
  | Some(pf) => {
      title: pf.title->Option.getOr(""),
      activity: selectedActivity->Option.getOr(""),
      maxRsvps: ?pf.maxRsvps,
      minRating: ?pf.minRating,
      startDate: pf.startDate->Option.getOr(""),
      endTime: pf.endDate->Option.getOr(""),
      listed: pf.listed->Option.getOr(false),
      price: ?pf.price,
    }
  | None => {
      listed: false,
      activity: selectedActivity->Option.getOr(""),
    }
  }

  let {register, handleSubmit, formState, setValue, watch} = useFormOfInputs(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: defaultFormValues,
    },
  )

  let listed =
    watch(Listed)
    ->Option.map(listed =>
      switch listed {
      | Bool(bool) => bool
      | _ => false
      }
    )
    ->Option.getOr(false)

  let (isPaidEvent, setIsPaidEvent) = React.useState(() =>
    prefilledValues->Option.flatMap(pf => pf.price)->Option.isSome
  )

  let startDate = watch(StartDate)
  let endTime = watch(EndTime)
  let title = watch(Title)

  // Collapsible sections state - accordion behavior (only one section open at a time)
  // Collapsed if editing existing event or has prefilled values, expanded if creating new
  let hasPreloadedValues = eventId->Option.isSome || prefilledValues->Option.isSome
  let (expandedSection, setExpandedSection) = React.useState(() =>
    hasPreloadedValues ? None : EventDetailsSection
  )

  let eventDetailsExpanded = expandedSection == EventDetailsSection
  let activityFormatExpanded = expandedSection == ActivityFormatSection
  let findPlayersExpanded = expandedSection == FindPlayersSection

  let setEventDetailsExpanded = (expanded: bool) =>
    setExpandedSection(_ => expanded ? EventDetailsSection : None)
  let setActivityFormatExpanded = (expanded: bool) =>
    setExpandedSection(_ => expanded ? ActivityFormatSection : None)
  let setFindPlayersExpanded = (expanded: bool) =>
    setExpandedSection(_ => expanded ? FindPlayersSection : None)

  // Track if start date changes are user-initiated
  let (isUserInitiatedChange, setIsUserInitiatedChange) = React.useState(() => false)

  // Track event duration in hours to preserve it when start time changes
  let (eventDurationHours, setEventDurationHours) = React.useState(() => 2.0)

  // Location details expansion state
  let (isLocationDetailsExpanded, setIsLocationDetailsExpanded) = React.useState(() => false)

  let (selectedTags, setSelectedTags) = React.useState(() =>
    prefilledValues
    ->Option.flatMap(pf => pf.tags)
    ->Option.getOr(["all level"])
  )

  // Determine event type from tags
  let eventType = selectedTags->Array.includes("comp") ? "competitive" : "recreational"
  let isDrill = selectedTags->Array.includes("drill")
  let isDupr = selectedTags->Array.includes("dupr")

  // Auto-expand sections when they contain validation errors
  React.useEffect(() => {
    let errors = formState.errors

    // Check if Event Details section has errors
    let hasEventDetailsErrors =
      errors.title->Option.isSome ||
      errors.startDate->Option.isSome ||
      errors.endTime->Option.isSome ||
      errors.details->Option.isSome ||
      errors.maxRsvps->Option.isSome

    // Check if Format section has errors
    let hasFormatErrors = errors.activity->Option.isSome

    // Check if Find Players section has errors
    let hasFindPlayersErrors = errors.minRating->Option.isSome || errors.listed->Option.isSome

    // Expand the first section with errors
    if hasEventDetailsErrors {
      setExpandedSection(_ => EventDetailsSection)
    } else if hasFormatErrors {
      setExpandedSection(_ => ActivityFormatSection)
    } else if hasFindPlayersErrors {
      setExpandedSection(_ => FindPlayersSection)
    }
    None
  }, [formState.errors])

  React.useEffect(() => {
    // Only set default dates if creating new event without prefilled dates
    let hasPrefilledDates =
      prefilledValues
      ->Option.flatMap(pf =>
        switch (pf.startDate, pf.endDate) {
        | (Some(sd), Some(ed)) if sd != "" && ed != "" => Some(true)
        | _ => None
        }
      )
      ->Option.isSome

    if !isUpdate && !hasPrefilledDates {
      // @NOTE: Date.make runs an effect therefore cannot be part of the render
      let now = Js.Date.make()
      let currentISODate =
        Js.Date.fromFloat(now->Js.Date.getTime -. now->Js.Date.getTimezoneOffset *. 60000.)
        ->Js.Date.toISOString
        ->String.slice(~start=0, ~end=16)

      let currentDate = DateFns.parseISO(currentISODate)
      let defaultStartDate = currentDate->DateFns.formatWithPattern("yyyy-MM-dd'T'HH:00")

      let defaultStartDateTime = defaultStartDate->DateFns.parseISO
      let defaultEndTime =
        defaultStartDateTime
        ->DateFns.addHours(2.0)
        ->DateFns.formatWithPattern("HH:mm")
      setValue(StartDate, Value(defaultStartDate))
      setValue(EndTime, Value(defaultEndTime))

      // Calculate and store the duration from the default values
      let defaultEndDateTime = DateFns2.parse(defaultEndTime, "HH:mm", defaultStartDateTime)
      calculateDurationHours(defaultStartDateTime, defaultEndDateTime)
      ->Option.map(duration => setEventDurationHours(_ => duration))
      ->ignore
    }

    None
  }, [])

  // Update form values when prefilledValues change (from AI assistant)
  React.useEffect(() => {
    switch prefilledValues {
    | Some(pf) => {
        pf.title->Option.map(v => setValue(Title, Value(v)))->ignore
        pf.startDate->Option.map(v => setValue(StartDate, Value(v)))->ignore
        pf.endDate->Option.map(v => setValue(EndTime, Value(v)))->ignore
        pf.details->Option.map(v => setValue(Details, Value(v)))->ignore
        pf.maxRsvps->Option.map(v => setValue(MaxRsvps, Value(v->Int.toString)))->ignore

        // Calculate and store the duration from prefilled values
        switch (pf.startDate, pf.endDate) {
        | (Some(startDateStr), Some(endTimeStr)) if startDateStr != "" && endTimeStr != "" => {
            let startDateTime = startDateStr->DateFns.parseISO
            let endDateTime = DateFns2.parse(endTimeStr, "HH:mm", startDateTime)
            calculateDurationHours(startDateTime, endDateTime)
            ->Option.map(duration => setEventDurationHours(_ => duration))
            ->ignore
          }
        | _ => ()
        }
      }
    | None => ()
    }
    None
  }, [prefilledValues])

  // Track duration when user manually changes end time
  React.useEffect(() => {
    switch (startDate, endTime) {
    | (Some(String(startDateStr)), Some(String(endTimeStr)))
      if startDateStr != "" && endTimeStr != "" => {
        let startDateTime = startDateStr->DateFns.parseISO
        let endDateTime = DateFns2.parse(endTimeStr, "HH:mm", startDateTime)
        calculateDurationHours(startDateTime, endDateTime)
        ->Option.map(duration => setEventDurationHours(_ => duration))
        ->ignore
      }
    | _ => ()
    }
    None
  }, [endTime])

  // Update end time when start date changes, preserving the event duration
  React.useEffect(() => {
    if isUserInitiatedChange {
      switch startDate {
      | Some(String(startDateStr)) if startDateStr != "" => {
          let newEndTime =
            startDateStr
            ->DateFns.parseISO
            ->DateFns.addHours(eventDurationHours)
            ->DateFns.formatWithPattern("HH:mm")
          setValue(EndTime, Value(newEndTime))
        }
      | _ => ()
      }
      setIsUserInitiatedChange(_ => false)
    }
    None
  }, [startDate])

  // Autofill minRating based on selected level tags
  React.useEffect(() => {
    // Map of level tags to rating values
    let levelToRating = tag =>
      switch tag {
      | "3.0+" => Some(11.0)
      | "3.5+" => Some(17.0)
      | "4.0+" => Some(21.0)
      | "4.5+" => Some(25.0)
      | "5.0+" => Some(30.0)
      | _ => None
      }

    // Check if "all level" is selected
    if selectedTags->Array.includes("all level") {
      // Clear the minRating value
      setValue(MinRating, Value(""))
    } else {
      // Get all specific level tags that have rating mappings
      let specificLevels = ["3.0+", "3.5+", "4.0+", "4.5+", "5.0+"]
      let selectedSpecificLevels =
        selectedTags->Array.filter(tag => specificLevels->Array.includes(tag))

      // If we have specific level tags selected, use the lowest one
      if selectedSpecificLevels->Array.length > 0 {
        // Find the lowest level tag (earliest in the list)
        let lowestLevel =
          specificLevels->Array.find(level => selectedSpecificLevels->Array.includes(level))

        lowestLevel
        ->Option.flatMap(levelToRating)
        ->Option.forEach(rating => {
          setValue(MinRating, Value(rating->Float.toString))
        })
      }
    }

    None
  }, [selectedTags])

  // Sync selectedActivity prop → form activity field
  React.useEffect(() => {
    selectedActivity->Option.forEach(id => setValue(Activity, Value(id)))
    None
  }, [selectedActivity])

  let onSubmit = (data: inputs) => {
    // Block submission if the new club form is open (unsaved club)
    if isClubFormOpen {
      onClubFormSubmitBlocked->Option.forEach(cb => cb())
    } else {
      // Filter out "rec" since it's the default (represented by absence of type tags)
      let tagsToSubmit = selectedTags->Array.filter(tag => tag !== "rec")

      let startDate = data.startDate->DateFns.parseISO
      let endDate = DateFns2.parse(data.endTime, "HH:mm", startDate)

      let priceValue = isPaidEvent ? data.price : None

      if isUpdate {
        // Update existing event
        switch eventId {
        | Some(id) =>
          commitMutationUpdate(
            ~variables={
              eventId: id,
              input: {
                title: data.title,
                activity: data.activity,
                maxRsvps: ?data.maxRsvps,
                minRating: ?data.minRating,
                details: data.details->Option.getOr(""),
                locationId: location.id,
                clubId: selectedClub->Option.getOr(""),
                startDate: startDate->Util.Datetime.fromDate,
                endDate: endDate->Util.Datetime.fromDate,
                listed: data.listed,
                timezone: ?data.timezone,
                tags: tagsToSubmit,
                price: ?priceValue,
              },
            },
            ~onCompleted=(_response, _errors) => {
              navigate("/events/" ++ id, None)
            },
          )->RescriptRelay.Disposable.ignore
        | None => () // Should never happen
        }
      } else {
        // Create new event
        let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
          "client:root"->RescriptRelay.makeDataId,
          "EventsListFragment_events",
          (),
        )

        commitMutationCreate(
          ~variables={
            input: {
              title: data.title,
              activity: data.activity,
              maxRsvps: ?data.maxRsvps,
              minRating: ?data.minRating,
              details: data.details->Option.getOr(""),
              locationId: location.id,
              clubId: selectedClub->Option.getOr(""),
              startDate: startDate->Util.Datetime.fromDate,
              endDate: endDate->Util.Datetime.fromDate,
              listed: data.listed,
              timezone: ?data.timezone,
              tags: tagsToSubmit,
              price: ?priceValue,
            },
            connections: [connectionId],
          },
          ~onCompleted=(response, _errors) => {
            response.createEvent.event
            ->Option.map(event => navigate("/events/" ++ event.id, None))
            ->ignore
          },
        )->RescriptRelay.Disposable.ignore
      }
    } // end isClubFormOpen guard
  }
  // Helper functions for summaries
  let getEventDetailsSummary = () => {
    let parts = []
    switch title {
    | Some(String(t)) if t != "" => parts->Array.push(t)->ignore
    | _ => ()
    }
    switch (startDate, endTime) {
    | (Some(String(sd)), Some(String(et))) if sd != "" && et != "" => {
        let startDateParsed = sd->DateFns.parseISO
        let dateFormatted = startDateParsed->DateFns.formatWithPattern("EEEE, MMMM d, yyyy")
        let startTimeFormatted = startDateParsed->DateFns.formatWithPattern("h:mm a")
        parts->Array.push(`${dateFormatted} ${ts`at`} ${startTimeFormatted}`)->ignore
      }
    | _ => ()
    }
    parts->Array.length > 0 ? parts->Array.join(" • ") : ts`Not set`
  }

  let getFormatSummary = () => {
    let parts = []
    if eventType == "competitive" {
      parts->Array.push(ts`Competitive`)->ignore
    } else {
      parts->Array.push(ts`Recreational`)->ignore
    }
    if isDupr {
      parts->Array.push(ts`DUPR rated`)->ignore
    }
    if isDrill {
      parts->Array.push(ts`Drill session`)->ignore
    }
    parts->Array.length > 0 ? parts->Array.join(" • ") : ts`Not set`
  }

  let getFindPlayersSummary = () => {
    if listed {
      let levelTags =
        selectedTags->Array.filter(tag =>
          ["all level", "3.0+", "3.5+", "4.0+", "4.5+", "5.0+"]->Array.includes(tag)
        )
      if levelTags->Array.length > 0 {
        (ts`Public`) ++ " • " ++ levelTags->Array.join(", ")
      } else {
        ts`Public event`
      }
    } else {
      ts`Private event`
    }
  }

  let formatEventDateTime = () => {
    switch (startDate, endTime) {
    | (Some(String(sd)), Some(String(et))) if sd != "" && et != "" => {
        let startDateParsed = sd->DateFns.parseISO
        let endDateParsed = DateFns2.parse(et, "HH:mm", startDateParsed)

        let durationMs = endDateParsed->DateFns.getTime -. startDateParsed->DateFns.getTime
        let durationHours = Float.toInt(durationMs /. (1000.0 *. 60.0 *. 60.0))
        let durationMinutes = Float.toInt(
          mod_float(durationMs, 1000.0 *. 60.0 *. 60.0) /. (1000.0 *. 60.0),
        )

        let durationText = if durationHours > 0 {
          if durationMinutes > 0 {
            ts`${durationHours->Int.toString} hours and ${durationMinutes->Int.toString} minutes`
          } else {
            ts`${durationHours->Int.toString} hours`
          }
        } else if durationMinutes > 0 {
          ts`${durationMinutes->Int.toString} minutes`
        } else {
          ""
        }

        Some({
          "startDate": startDateParsed,
          "endDate": endDateParsed,
          "duration": durationText,
        })
      }
    | _ => None
    }
  }

  let formattedEventDateTime = formatEventDateTime()

  <FramerMotion.Div
    style={opacity: 0., y: -50.}
    initial={opacity: 0., scale: 1., y: -50.}
    animate={FramerMotion.opacity: 1., scale: 1., y: 0.00}
    exit={opacity: 0., scale: 1., y: -50.}>
    <WaitForMessages>
      {() => <>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          // Location display
          <div
            className="px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg bg-gray-50 dark:bg-[#222222]">
            <p
              className="text-gray-900 dark:text-gray-100 font-medium break-words overflow-wrap-anywhere">
              {location.name->Option.getOr("")->React.string}
            </p>
            {location.details
            ->Option.map(details => {
              let maxLength = 100
              let shouldTruncate = details->String.length > maxLength
              let displayText = if shouldTruncate && !isLocationDetailsExpanded {
                details->String.substring(~start=0, ~end=maxLength) ++ "..."
              } else {
                details
              }
              <div className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                <p className="inline break-words overflow-wrap-anywhere">
                  {displayText->React.string}
                </p>
                {shouldTruncate
                  ? <button
                      type_="button"
                      onClick={_ => setIsLocationDetailsExpanded(prev => !prev)}
                      className="ml-1 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 font-medium inline whitespace-nowrap">
                      {(isLocationDetailsExpanded ? ts`Show less` : ts`Read more...`)->React.string}
                    </button>
                  : React.null}
              </div>
            })
            ->Option.getOr(React.null)}
          </div>
          // Event Details Section - Collapsible (merged with Date & Time)
          <div
            className="border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
            <button
              type_="button"
              onClick={_ => setEventDetailsExpanded(!eventDetailsExpanded)}
              className="w-full px-4 py-4 hover:bg-gray-50 dark:hover:bg-[#222222] transition-colors flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Lucide.FileText
                  className="w-5 h-5 text-gray-400 dark:text-gray-500 flex-shrink-0"
                />
                <div className="text-left flex-1 min-w-0">
                  <div className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                    {t`Event Details`}
                  </div>
                  {!eventDetailsExpanded
                    ? <div
                        className="text-xs text-gray-600 dark:text-gray-400 mt-0.5 line-clamp-2 break-words"
                        style={ReactDOM.Style.make(~overflowWrap="anywhere", ())}>
                        {getEventDetailsSummary()->React.string}
                      </div>
                    : React.null}
                </div>
              </div>
              <Lucide.ChevronDown
                className={Util.cx([
                  "w-5 h-5 text-gray-400 dark:text-gray-500 transform transition-transform flex-shrink-0",
                  eventDetailsExpanded ? "rotate-180" : "",
                ])}
              />
            </button>
            {eventDetailsExpanded
              ? <div
                  className="px-4 pb-4 pt-6 space-y-6 border-t border-gray-100 dark:border-gray-800">
                  // Date & Time
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label
                        htmlFor="startDate"
                        className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                        {t`Start date and time`}
                      </label>
                      <input
                        {...register(StartDate)}
                        id="startDate"
                        type_="datetime-local"
                        onChange={e => {
                          setIsUserInitiatedChange(_ => true)
                          let target = ReactEvent.Form.target(e)
                          setValue(StartDate, Value(target["value"]))
                        }}
                        className={Util.cx([
                          "block w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 font-mono",
                          formState.errors.startDate->Option.isSome
                            ? "border-red-300 dark:border-red-700"
                            : "border-gray-300 dark:border-gray-700",
                        ])}
                      />
                      {switch formState.errors.startDate {
                      | Some({message: ?Some(message)}) =>
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                          {message->React.string}
                        </p>
                      | _ => React.null
                      }}
                    </div>
                    <div>
                      <label
                        htmlFor="endTime"
                        className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                        {t`End time`}
                      </label>
                      <input
                        {...register(EndTime)}
                        id="endTime"
                        type_="time"
                        className={Util.cx([
                          "block w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 font-mono",
                          formState.errors.endTime->Option.isSome
                            ? "border-red-300 dark:border-red-700"
                            : "border-gray-300 dark:border-gray-700",
                        ])}
                      />
                      {switch formState.errors.endTime {
                      | Some({message: ?Some(message)}) =>
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                          {message->React.string}
                        </p>
                      | _ => React.null
                      }}
                    </div>
                  </div>
                  {switch formattedEventDateTime {
                  | Some(dateTime) =>
                    <div
                      className="p-4 bg-gray-50 dark:bg-[#222222] rounded-lg border border-gray-200 dark:border-gray-700">
                      <div className="flex items-start gap-3">
                        <Lucide.Calendar
                          className="w-5 h-5 text-gray-400 dark:text-gray-500 mt-1 flex-shrink-0"
                        />
                        <div className="flex-1 min-w-0">
                          <p
                            className="text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-1">
                            {t`Event schedule`}
                          </p>
                          <p
                            className="text-base font-medium text-gray-900 dark:text-gray-100 mb-2 break-words">
                            <ReactIntl.FormattedDate
                              weekday=#long
                              month=#long
                              day=#numeric
                              year=#numeric
                              value={dateTime["startDate"]}
                              timeZone="Asia/Tokyo"
                            />
                          </p>
                          <div className="flex items-center gap-2 flex-wrap">
                            <div className="flex items-center gap-1.5">
                              <Lucide.Clock
                                className="w-4 h-4 text-gray-400 dark:text-gray-500 flex-shrink-0"
                              />
                              <span
                                className="text-base font-bold text-gray-900 dark:text-gray-100 font-mono whitespace-nowrap">
                                <ReactIntl.FormattedTime
                                  value={dateTime["startDate"]} timeZone="Asia/Tokyo"
                                />
                              </span>
                            </div>
                            <span className="text-gray-400"> {"→"->React.string} </span>
                            <span
                              className="text-base font-bold text-gray-900 dark:text-gray-100 font-mono whitespace-nowrap">
                              <ReactIntl.FormattedTime
                                value={dateTime["endDate"]} timeZone="Asia/Tokyo"
                              />
                            </span>
                            {dateTime["duration"] != ""
                              ? <>
                                  <span className="text-gray-400"> {"•"->React.string} </span>
                                  <span
                                    className="text-gray-600 dark:text-gray-400 whitespace-nowrap">
                                    {dateTime["duration"]->React.string}
                                  </span>
                                </>
                              : React.null}
                          </div>
                        </div>
                      </div>
                    </div>
                  | None => React.null
                  }}
                  // Title and Max Attendees
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div className="md:col-span-2">
                      <label
                        htmlFor="title"
                        className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                        {t`Event title`}
                      </label>
                      <input
                        {...register(Title)}
                        id="title"
                        type_="text"
                        placeholder={ts`Friday Night Pickleball`}
                        className={Util.cx([
                          "block w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100",
                          formState.errors.title->Option.isSome
                            ? "border-red-300 dark:border-red-700"
                            : "border-gray-300 dark:border-gray-700",
                        ])}
                      />
                      {switch formState.errors.title {
                      | Some({message: ?Some(message)}) =>
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                          {message->React.string}
                        </p>
                      | _ => React.null
                      }}
                    </div>
                    <div>
                      <label
                        htmlFor="maxRsvps"
                        className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                        {t`Max RSVPs (optional)`}
                      </label>
                      <input
                        {...register(MaxRsvps, ~options={required: false})}
                        id="maxRsvps"
                        type_="number"
                        placeholder={ts`No limit`}
                        className="block w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 font-mono"
                      />
                    </div>
                  </div>
                  // Event Details
                  <div>
                    <label
                      htmlFor="details"
                      className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                      {t`Event details (optional)`}
                    </label>
                    <textarea
                      {...register(Details, ~options={required: false})}
                      id="details"
                      rows=3
                      defaultValue=""
                      placeholder={ts`Add any additional information about the event...`}
                      className="block w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors resize-none bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100"
                    />
                  </div>
                </div>
              : React.null}
          </div>
          // Paid Event Section
          <div
            className="border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
            <div className="px-4 py-4">
              <div className="flex items-start gap-3">
                <input
                  id="paidEvent"
                  type_="checkbox"
                  checked={isPaidEvent}
                  onChange={_ => {
                    let newValue = !isPaidEvent
                    setIsPaidEvent(_ => newValue)
                    if !newValue {
                      setValue(Price, Value(""))
                    }
                  }}
                  className="h-5 w-5 text-blue-600 focus:ring-blue-500 border-gray-300 rounded mt-0.5"
                />
                <div className="flex-1">
                  <label
                    htmlFor="paidEvent"
                    className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
                    {t`Paid event`}
                  </label>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                    {t`Require payment from attendees`}
                  </p>
                </div>
              </div>
              {isPaidEvent
                ? <div className="mt-4 ml-8">
                    <label
                      htmlFor="price" className="block text-sm font-semibold text-gray-900 mb-2">
                      {t`Price`}
                    </label>
                    <div className="relative">
                      <span
                        className="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-500 text-sm">
                        {"¥"->React.string}
                      </span>
                      <input
                        {...register(Price, ~options={required: false})}
                        id="price"
                        type_="number"
                        min="1"
                        placeholder={ts`Enter price`}
                        className="block w-full pl-8 pr-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 font-mono"
                      />
                    </div>
                  </div>
                : React.null}
            </div>
          </div>
          // Activity & Format Section - Collapsible
          <div
            className="border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
            <button
              type_="button"
              onClick={_ => setActivityFormatExpanded(!activityFormatExpanded)}
              className="w-full px-4 py-4 hover:bg-gray-50 dark:hover:bg-[#222222] transition-colors flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Lucide.Dumbbell
                  className="w-5 h-5 text-gray-400 dark:text-gray-500 flex-shrink-0"
                />
                <div className="text-left flex-1 min-w-0">
                  <div className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                    {t`Format`}
                  </div>
                  {!activityFormatExpanded
                    ? <div
                        className="text-xs text-gray-600 dark:text-gray-400 mt-0.5 line-clamp-2 break-words"
                        style={ReactDOM.Style.make(~overflowWrap="anywhere", ())}>
                        {getFormatSummary()->React.string}
                      </div>
                    : React.null}
                </div>
              </div>
              <Lucide.ChevronDown
                className={Util.cx([
                  "w-5 h-5 text-gray-400 dark:text-gray-500 transform transition-transform flex-shrink-0",
                  activityFormatExpanded ? "rotate-180" : "",
                ])}
              />
            </button>
            {activityFormatExpanded
              ? <div
                  className="px-4 pb-4 pt-6 space-y-6 border-t border-gray-100 dark:border-gray-800">
                  // Event type
                  <div>
                    <label
                      className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-3">
                      {t`Event type`}
                    </label>
                    <div className="grid grid-cols-2 gap-3">
                      {[("recreational", t`Recreational`), ("competitive", t`Competitive`)]
                      ->Array.map(((value, label)) =>
                        <label
                          key={value}
                          className={Util.cx([
                            "relative flex items-center justify-center px-4 py-3 border-2 rounded-lg cursor-pointer transition-all",
                            eventType == value
                              ? "border-[#a3e635] bg-[#f7fee7] dark:bg-[#3f6212]/20"
                              : "border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-500 bg-white dark:bg-[#222222]",
                          ])}>
                          <input
                            type_="radio"
                            checked={eventType == value}
                            onChange={_ => {
                              if value == "competitive" {
                                setSelectedTags(tags =>
                                  tags
                                  ->Array.filter(t => t != "rec")
                                  ->Array.concat(["comp"])
                                )
                              } else {
                                setSelectedTags(tags =>
                                  tags
                                  ->Array.filter(t => t != "comp" && t != "dupr")
                                  ->Array.concat(["rec"])
                                )
                              }
                            }}
                            className="sr-only"
                          />
                          <span
                            className={Util.cx([
                              "text-sm font-medium",
                              eventType == value
                                ? "text-[#4d7c0f] dark:text-[#a3e635]"
                                : "text-gray-700 dark:text-gray-300",
                            ])}>
                            {label}
                          </span>
                        </label>
                      )
                      ->React.array}
                    </div>
                    <div
                      className="mt-3 flex items-start gap-2 p-3 bg-gray-50 dark:bg-[#222222] rounded-lg border border-gray-200 dark:border-gray-700">
                      <Lucide.Info
                        className="w-4 h-4 text-gray-500 dark:text-gray-400 mt-0.5 flex-shrink-0"
                      />
                      <p className="text-sm text-gray-700 dark:text-gray-300">
                        {eventType == "competitive"
                          ? t`Serious play with rankings and ratings. Games may affect your player rating.`
                          : t`Casual play focused on fun and social interaction. Perfect for all skill levels.`}
                      </p>
                    </div>
                  </div>
                  {eventType == "competitive"
                    ? <div
                        className="pl-4 border-l-2 border-gray-200 dark:border-gray-700 space-y-3">
                        <label
                          className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-3">
                          {t`Format options`}
                        </label>
                        <div className="grid grid-cols-2 gap-3">
                          <button
                            type_="button"
                            onClick={_ =>
                              setSelectedTags(tags =>
                                isDupr
                                  ? tags->Array.filter(t => t != "dupr")
                                  : tags->Array.concat(["dupr"])
                              )}
                            className={Util.cx([
                              "relative flex items-center justify-center px-4 py-3 border rounded-lg transition-all",
                              isDupr
                                ? "border-[#a3e635] bg-[#f7fee7] dark:bg-[#3f6212]/20"
                                : "border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-500 bg-white dark:bg-[#222222]",
                            ])}>
                            <span
                              className={Util.cx([
                                "text-sm font-medium",
                                isDupr
                                  ? "text-[#4d7c0f] dark:text-[#a3e635]"
                                  : "text-gray-700 dark:text-gray-300",
                              ])}>
                              {t`DUPR rated`}
                            </span>
                          </button>
                          <button
                            type_="button"
                            onClick={_ =>
                              setSelectedTags(tags =>
                                isDrill
                                  ? tags->Array.filter(t => t != "drill")
                                  : tags->Array.concat(["drill"])
                              )}
                            className={Util.cx([
                              "relative flex items-center justify-center px-4 py-3 border rounded-lg transition-all",
                              isDrill
                                ? "border-[#a3e635] bg-[#f7fee7] dark:bg-[#3f6212]/20"
                                : "border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-500 bg-white dark:bg-[#222222]",
                            ])}>
                            <span
                              className={Util.cx([
                                "text-sm font-medium",
                                isDrill
                                  ? "text-[#4d7c0f] dark:text-[#a3e635]"
                                  : "text-gray-700 dark:text-gray-300",
                              ])}>
                              {t`Drill session`}
                            </span>
                          </button>
                        </div>
                      </div>
                    : <div className="pl-4 border-l-2 border-gray-200 dark:border-gray-700">
                        <label
                          className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-3">
                          {t`Format options`}
                        </label>
                        <button
                          type_="button"
                          onClick={_ =>
                            setSelectedTags(tags =>
                              isDrill
                                ? tags->Array.filter(t => t != "drill")
                                : tags->Array.concat(["drill"])
                            )}
                          className={Util.cx([
                            "relative flex items-center justify-center px-4 py-3 border rounded-lg transition-all",
                            isDrill
                              ? "border-[#a3e635] bg-[#f7fee7] dark:bg-[#3f6212]/20"
                              : "border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-500 bg-white dark:bg-[#222222]",
                          ])}>
                          <span
                            className={Util.cx([
                              "text-sm font-medium",
                              isDrill
                                ? "text-[#4d7c0f] dark:text-[#a3e635]"
                                : "text-gray-700 dark:text-gray-300",
                            ])}>
                            {t`Drill session`}
                          </span>
                        </button>
                      </div>}
                </div>
              : React.null}
          </div>
          // Find Players Section - Collapsible
          <div
            className="border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
            <button
              type_="button"
              onClick={_ => setFindPlayersExpanded(!findPlayersExpanded)}
              className="w-full px-4 py-4 hover:bg-gray-50 dark:hover:bg-[#222222] transition-colors flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Lucide.Users className="w-5 h-5 text-gray-400 dark:text-gray-500 flex-shrink-0" />
                <div className="text-left flex-1 min-w-0">
                  <div className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                    {t`Find Players`}
                  </div>
                  {!findPlayersExpanded
                    ? <div
                        className="text-xs text-gray-600 dark:text-gray-400 mt-0.5 line-clamp-2 break-words"
                        style={ReactDOM.Style.make(~overflowWrap="anywhere", ())}>
                        {getFindPlayersSummary()->React.string}
                      </div>
                    : React.null}
                </div>
              </div>
              <Lucide.ChevronDown
                className={Util.cx([
                  "w-5 h-5 text-gray-400 dark:text-gray-500 transform transition-transform flex-shrink-0",
                  findPlayersExpanded ? "rotate-180" : "",
                ])}
              />
            </button>
            {findPlayersExpanded
              ? <div className="px-4 pb-4 pt-6 border-t border-gray-100 dark:border-gray-800">
                  <div className="flex items-start gap-3 mb-4">
                    <input
                      id="findPlayers"
                      type_="checkbox"
                      checked={listed}
                      onChange={_ => setValue(Listed, Value(!listed))}
                      className="h-5 w-5 text-[#a3e635] focus:ring-[#a3e635] border-gray-300 dark:border-gray-600 rounded mt-0.5 bg-white dark:bg-[#222222]"
                    />
                    <div>
                      <label
                        htmlFor="findPlayers"
                        className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
                        {t`Find players for your event?`}
                      </label>
                      <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                        {t`List your event publicly to help fill open spots`}
                      </p>
                    </div>
                  </div>
                  {listed
                    ? <div className="ml-8 space-y-3">
                        <label
                          className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                          {t`Skill level`}
                        </label>
                        <div className="flex flex-wrap gap-2">
                          {["all level", "3.0+", "3.5+", "4.0+", "4.5+", "5.0+"]
                          ->Array.map(tag =>
                            <button
                              key={tag}
                              type_="button"
                              onClick={_ =>
                                setSelectedTags(tags => {
                                  let isCurrentlySelected = tags->Array.includes(tag)

                                  if isCurrentlySelected {
                                    // Deselect the tag
                                    let newTags = tags->Array.filter(t => t != tag)
                                    // If no tags are selected, default to "all level"
                                    newTags->Array.length == 0 ? ["all level"] : newTags
                                  } else if tag == "all level" {
                                    // Select "all level" and remove all specific level tags
                                    let specificLevels = ["3.0+", "3.5+", "4.0+", "4.5+", "5.0+"]
                                    tags
                                    ->Array.filter(t => !(specificLevels->Array.includes(t)))
                                    ->Array.concat([tag])
                                  } else {
                                    // Select a specific level tag and remove "all level"
                                    tags->Array.filter(t => t != "all level")->Array.concat([tag])
                                  }
                                })}
                              className={Util.cx([
                                "px-3 py-1.5 rounded-full text-xs font-medium transition-all border",
                                selectedTags->Array.includes(tag)
                                  ? "bg-gray-900 dark:bg-gray-100 text-white dark:text-gray-900 border-gray-900 dark:border-gray-100"
                                  : "bg-white dark:bg-[#222222] text-gray-700 dark:text-gray-300 border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600",
                              ])}>
                              {tag->React.string}
                            </button>
                          )
                          ->React.array}
                        </div>
                        <div className="mt-4">
                          <label
                            htmlFor="minRating"
                            className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                            {t`Minimum rating (optional)`}
                          </label>
                          <input
                            {...register(MinRating, ~options={required: false})}
                            id="minRating"
                            type_="number"
                            step=0.1
                            placeholder={ts`No minimum`}
                            className="block w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 font-mono"
                          />
                          {switch formState.errors.minRating {
                          | Some({message: ?Some(message)}) =>
                            <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                              {message->React.string}
                            </p>
                          | _ => React.null
                          }}
                        </div>
                      </div>
                    : React.null}
                </div>
              : React.null}
          </div>
          <div className="pt-6">
            <button
              type_="submit"
              className="w-full bg-[#a3e635] text-gray-900 py-4 px-6 rounded-lg font-bold hover:bg-[#84cc16] focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:ring-offset-2 dark:focus:ring-offset-[#111111] transition-colors shadow-sm">
              {isUpdate ? t`Update Event` : t`Create Event`}
            </button>
          </div>
        </form>
      </>}
    </WaitForMessages>
  </FramerMotion.Div>
}

let td = Lingui.UtilString.td

// NOTE: Force lingui to extract these dynamic Activity names
@live
td({id: "Badminton"})->ignore
@live
td({id: "Table Tennis"})->ignore
@live
td({id: "Pickleball"})->ignore
@live
td({id: "Futsal"})->ignore
@live
td({id: "Basketball"})->ignore
@live
td({id: "Volleyball"})->ignore
@live
td({id: "Crossminton"})->ignore
@live
td({id: "Padel"})->ignore

@live
td({id: "drill"})->ignore
@live
td({id: "comp"})->ignore
@live
td({id: "rec"})->ignore
@live
td({id: "all level"})->ignore
