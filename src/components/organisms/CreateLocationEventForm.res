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
       cancelDeadline
       smartRsvpThreshold
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
         name
         slug
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
       cancelDeadline
       price
       smartRsvpThreshold
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
  cancelDeadline?: int,
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
      cancelDeadline: ?Zod.z->Zod.preprocess(
        v => Int.fromString(v),
        Zod.z->Zod.numberInt({})->Zod.optional,
      ),
    }: inputs
  ),
)

// Accordion sections, in page order. Only one is open at a time.
type expandedSection = ScheduleSection | DetailsSection | FormatSection | PlayersSection | None

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
  cancelDeadline?: int,
  smartRsvpThreshold?: float,
  // Set when these values were copied from an existing event: a missing field
  // then means the source event had none, so the form's own defaults for new
  // events must not fill it in.
  fromExistingEvent?: bool,
}

// New events default to a 24h cancel deadline (in ms, matching the select's
// option values). Updates and copies keep whatever the source event had.
let defaultCancelDeadline = 24 * 60 * 60 * 1000

// The threshold Smart RSVP is switched on at: the largest drop in mean
// simulated match quality an automatic admission may cost. Quality is on
// openskill's predictDraw scale, where an even doubles game reads ≈0.178, so
// this is a small number. The form only offers the on/off choice; the value
// itself lives in the database and can be tuned there.
let defaultSmartRsvpThreshold = 0.005

// ─── Design tokens (Magic Patterns "ManualEventForm") ────────────────────────
let labelClass = "mb-1.5 block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400"
let legendClass = "text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400"
let fieldBaseClass = "box-border h-11 min-w-0 w-full max-w-full rounded-lg border bg-white px-3 text-sm text-gray-900 outline-none transition-colors placeholder:text-gray-400 focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:bg-[#1e1f23] dark:text-gray-100"
let fieldBorderClass = "border-gray-200 dark:border-[#3a3b40]"
let fieldErrorBorderClass = "border-red-300 dark:border-red-700"
let fieldClass = Util.cx([fieldBaseClass, fieldBorderClass])
let fieldClassWithError = hasError =>
  Util.cx([fieldBaseClass, hasError ? fieldErrorBorderClass : fieldBorderClass])
let hintClass = "mt-1.5 block text-xs text-gray-500 dark:text-gray-400"
let sectionClass = "overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-[#3a3b40] dark:bg-[#222326]"
let sectionBodyClass = "space-y-5 border-t border-gray-200 px-4 py-4 dark:border-[#3a3b40]"
let sectionIconClass = "flex-shrink-0 text-gray-400"
let checkboxClass = "mt-0.5 h-5 w-5 flex-shrink-0 rounded border-gray-300 accent-[#bdf25d] focus:ring-[#94c93a] dark:border-[#3a3b40]"
let subsectionClass = "border-t border-gray-100 pt-4 dark:border-[#34353a]"
let toggleClass = active =>
  Util.cx([
    "h-11 rounded-lg border px-3 text-sm font-semibold transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a]",
    active
      ? "border-[#94c93a] bg-[#bdf25d] text-black"
      : "border-gray-200 bg-white text-gray-600 hover:border-gray-400 dark:border-[#45464d] dark:bg-[#1e1f23] dark:text-gray-300",
  ])
let pressed = active => active ? #"true" : #"false"

let sectionHeader = (
  ~icon: React.element,
  ~title: React.element,
  ~summary: string,
  ~expanded: bool,
  ~controls: string,
  ~onToggle: unit => unit,
) =>
  <h3>
    <button
      type_="button"
      onClick={_ => onToggle()}
      ariaExpanded=expanded
      ariaControls=controls
      className="flex w-full items-center gap-3 rounded-xl px-4 py-3.5 text-left focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[#94c93a]">
      icon
      <span className="min-w-0 flex-1">
        <span className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
          title
        </span>
        <span className="mt-0.5 block truncate text-xs text-gray-500 dark:text-gray-400">
          {summary->React.string}
        </span>
      </span>
      <Lucide.ChevronDown
        size=17
        className={Util.cx([
          "flex-shrink-0 text-gray-400 transition-transform duration-200 ease-[cubic-bezier(0.23,1,0.32,1)]",
          expanded ? "rotate-180" : "",
        ])}
        \"aria-hidden"="true"
      />
    </button>
  </h3>

let errorText = (message: option<string>) =>
  switch message {
  | Some(message) =>
    <p className="mt-1.5 text-xs text-red-600 dark:text-red-400"> {message->React.string} </p>
  | None => React.null
  }

// `startDate` keeps the "yyyy-MM-dd'T'HH:mm" shape the old datetime-local
// input produced, so the schema, prefill and submit paths are unchanged; the
// date input and the clock picker each read and write one half of it.
let splitStartDate = (value: string) => {
  let date = value->String.slice(~start=0, ~end=10)
  let time = value->String.slice(~start=11, ~end=16)
  (date->String.length == 10 ? date : "", time->String.length == 5 ? time : "")
}
let joinStartDate = (date, time) => date ++ "T" ++ time
let fallbackStartTime = "18:00"
let fallbackEndTime = "20:00"

// The clock lets the end wrap past midnight (22:00 → 01:00), which the old
// time input never allowed, so an end at or before the start is the next day.
// Works on wall-clock strings: the zone is only applied when converting.
let endWallClockFor = (startWallClock: string, endTime: string): string => {
  let (date, startTime) = splitStartDate(startWallClock)
  let endDate = if (
    ClockRangePicker.timeToMinutes(endTime) <= ClockRangePicker.timeToMinutes(startTime)
  ) {
    date->DateFns.parseISO->DateFns.addDays(1)->DateFns.formatWithPattern("yyyy-MM-dd")
  } else {
    date
  }
  joinStartDate(endDate, endTime)
}

// "HH:mm" → "h:mm AM", without going through a Date so the browser's own zone
// never leaks into text describing the event's zone.
let formatWallTime = (time: string) => {
  let minutes = ClockRangePicker.timeToMinutes(time)
  let hour = minutes / 60
  let hour12 = switch mod(hour, 12) {
  | 0 => 12
  | h => h
  }
  let minute = mod(minutes, 60)->Int.toString->String.padStart(2, "0")
  `${hour12->Int.toString}:${minute} ${hour < 12 ? "AM" : "PM"}`
}

// The schedule picker is the shared time-window track (6:00–24:00, snapping to
// 15 minutes on an hourly grid) holding exactly one window. The form keeps its "HH:mm" strings and
// converts at the edge; an end at or before the start is the next day (see
// endWallClockFor), which the track shows as hours past 24, capped at midnight.
let eventTrackHourMin = 6
let eventTrackHourMax = 24
// A window that starts before the track's usual floor (an existing early
// event, a prefill) widens the track to include it, so the window is shown and
// draggable rather than clipped off the left edge.
let eventWindowConfigFor = (window: TimeWindow.playIntent): TimeWindowPicker.windowConfig => {
  hourMin: Js.Math.min_int(eventTrackHourMin, Js.Math.floor_int(window.start)),
  hourMax: eventTrackHourMax,
  snap: 0.25,
  gridStep: 1.0,
  minDuration: 0.25,
  defaultDuration: 2.0,
}
let hoursOfTime = (time: string): float =>
  ClockRangePicker.timeToMinutes(time)->Int.toFloat /. 60.0
let eventWindowOf = (startTime: string, endTime: string): TimeWindow.playIntent => {
  let start = hoursOfTime(startTime)
  let end = hoursOfTime(endTime)
  {id: 0, start, end: Js.Math.min_float(end <= start ? end +. 24.0 : end, 24.0)}
}

@react.component
let make = (
  ~eventId: option<string>=?,
  ~location: option<RescriptRelay.fragmentRefs<[> #CreateLocationEventForm_location]>>=?,
  // When given, the Location & time section hosts the venue picker and reports
  // the chosen Location id here; the caller re-renders with that location.
  ~onLocationSelected: option<string => unit>=?,
  // An address (from the AI assistant) for the picker to resolve headlessly.
  ~autoSearchAddress: option<string>=?,
  ~stripeChargesEnabled: bool=false,
  ~prefilledValues: option<prefilledValues>=?,
  ~selectedClub: option<string>=?,
  ~selectedActivity: option<string>=?,
  ~isClubFormOpen: bool=false,
  ~onClubFormSubmitBlocked: option<unit => unit>=?,
) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t

  let locationData = Fragment.useOpt(location)
  let (commitMutationCreate, _) = Mutation.use()
  let (commitMutationUpdate, _) = UpdateMutation.use()
  let navigate = Router.useNavigate()

  let isUpdate = eventId->Option.isSome

  // The form only fills in its own defaults for a genuinely new event: editing
  // and copying both carry the source event's values, where a missing field
  // means the event has none.
  let useNewEventDefaults =
    !isUpdate && !(prefilledValues->Option.flatMap(pf => pf.fromExistingEvent)->Option.getOr(false))
  let newEventCancelDeadline = useNewEventDefaults ? Some(defaultCancelDeadline) : None

  // Determine default values from prefilledValues or use defaults
  let defaultFormValues: defaultValuesOfInputs = switch prefilledValues {
  | Some(pf) => {
      title: pf.title->Option.getOr(""),
      activity: selectedActivity->Option.getOr(""),
      maxRsvps: ?pf.maxRsvps,
      minRating: ?pf.minRating,
      startDate: pf.startDate->Option.getOr(""),
      endTime: pf.endDate->Option.getOr(""),
      timezone: ?pf.timezone->Option.map(tz => Some(tz)),
      listed: pf.listed->Option.getOr(false),
      price: ?pf.price,
      cancelDeadline: ?pf.cancelDeadline->Option.orElse(newEventCancelDeadline),
    }
  | None => {
      listed: false,
      activity: selectedActivity->Option.getOr(""),
      cancelDeadline: ?newEventCancelDeadline,
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

  // Smart RSVP is on exactly when the event carries a threshold.
  let (isSmartRsvpOn, setIsSmartRsvpOn) = React.useState(() =>
    prefilledValues->Option.flatMap(pf => pf.smartRsvpThreshold)->Option.isSome
  )

  let startDate = watch(StartDate)
  let endTime = watch(EndTime)
  let title = watch(Title)
  let maxRsvps = watch(MaxRsvps)

  let startDateStr = switch startDate {
  | Some(String(s)) => s
  | _ => ""
  }
  let endTimeStr = switch endTime {
  | Some(String(s)) => s
  | _ => ""
  }
  let titleStr = switch title {
  | Some(String(s)) => s
  | _ => ""
  }
  // Typed values arrive as strings; a prefilled max arrives as the int itself.
  let maxRsvpsStr = switch maxRsvps {
  | Some(String(s)) => s
  | _ => prefilledValues->Option.flatMap(pf => pf.maxRsvps)->Option.mapOr("", n => n->Int.toString)
  }

  let (datePart, startTimePart) = splitStartDate(startDateStr)
  let clockStart = startTimePart != "" ? startTimePart : fallbackStartTime
  let clockEnd = endTimeStr != "" ? endTimeStr : fallbackEndTime
  // The wall-clock values above are in this zone. Until the mount effect picks
  // the browser's zone (or prefill supplies the event's) it is the app default.
  let tz = switch watch(Timezone) {
  | Some(String(s)) if s != "" => s
  | _ => Util.Timezone.fallback
  }
  let startWallClock = joinStartDate(datePart, clockStart)
  // The zone list differs between Node and browsers, so it is only rendered
  // after mount; until then the select holds just the current zone.
  let (zonesReady, setZonesReady) = React.useState(() => false)
  let timezoneOptions = React.useMemo2(() => {
    let zones = zonesReady ? Util.Timezone.list() : []
    zones->Array.includes(tz) ? zones : Array.concat([tz], zones)
  }, (zonesReady, tz))
  let durationMinutes = ClockRangePicker.forwardDuration(
    ClockRangePicker.timeToMinutes(clockStart),
    ClockRangePicker.timeToMinutes(clockEnd),
  )
  let hasValidTimeRange = durationMinutes >= 15 && durationMinutes <= 12 * 60
  let eventWindow = eventWindowOf(clockStart, clockEnd)

  // Collapsed if editing an existing event or arriving with prefilled values,
  // otherwise the schedule section opens first.
  let hasPreloadedValues = eventId->Option.isSome || prefilledValues->Option.isSome
  let (expandedSection, setExpandedSection) = React.useState(() =>
    hasPreloadedValues ? None : ScheduleSection
  )
  let toggleSection = section => setExpandedSection(current => current == section ? None : section)

  // Location details expansion state
  let (isLocationDetailsExpanded, setIsLocationDetailsExpanded) = React.useState(() => false)

  // Venue picker state: a set venue can be swapped out, and an address handed
  // in for auto-search always goes through the picker.
  let (changingLocation, setChangingLocation) = React.useState(() => false)
  let (locationError, setLocationError) = React.useState((): option<string> => None)
  let showLocationPicker = switch (locationData, onLocationSelected) {
  | (_, None) => false
  | (None, Some(_)) => true
  | (Some(_), Some(_)) => changingLocation || autoSearchAddress->Option.isSome
  }

  // Auto-search runs inside the picker, so make sure it is on screen.
  React.useEffect(() => {
    if autoSearchAddress->Option.isSome {
      setExpandedSection(_ => ScheduleSection)
    }
    None
  }, [autoSearchAddress])

  let (selectedTags, setSelectedTags) = React.useState(() =>
    prefilledValues
    ->Option.flatMap(pf => pf.tags)
    ->Option.getOr(["all level"])
  )

  // Determine event type from tags
  let eventType = selectedTags->Array.includes("comp") ? "competitive" : "recreational"
  let isDrill = selectedTags->Array.includes("drill")
  let isDupr = selectedTags->Array.includes("dupr")

  // Open the first section that has a validation error.
  React.useEffect(() => {
    let errors = formState.errors
    let has = err => err->Option.isSome
    if has(errors.startDate) || has(errors.endTime) || has(errors.timezone) {
      setExpandedSection(_ => ScheduleSection)
    } else if has(errors.title) || has(errors.details) {
      setExpandedSection(_ => DetailsSection)
    } else if has(errors.activity) {
      setExpandedSection(_ => FormatSection)
    } else if has(errors.minRating) || has(errors.listed) || has(errors.maxRsvps) {
      setExpandedSection(_ => PlayersSection)
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
      // Today at the current hour, two hours long, clamped so the whole window
      // sits on the 6:00–24:00 track: in the small hours it opens at 6:00, late
      // at night at 22:00.
      let seededHour = Js.Math.min_int(
        Js.Math.max_int(currentDate->Js.Date.getHours->Float.toInt, eventTrackHourMin),
        eventTrackHourMax - 2,
      )
      let defaultStartDate =
        currentDate->DateFns.formatWithPattern("yyyy-MM-dd") ++
        "T" ++
        TimeWindow.hourToTime(seededHour->Float.fromInt)
      let defaultEndTime = TimeWindow.hourToTime((seededHour + 2)->Float.fromInt)
      setValue(StartDate, Value(defaultStartDate))
      setValue(EndTime, Value(defaultEndTime))
    }

    // The browser's zone is only known on the client; applying it here keeps
    // the server render deterministic. Edits and copies carry the event's zone.
    if !isUpdate && prefilledValues->Option.flatMap(pf => pf.timezone)->Option.isNone {
      setValue(Timezone, Value(Util.Timezone.browser()))
    }
    setZonesReady(_ => true)

    None
  }, [])

  // Update form values when prefilledValues change (from AI assistant).
  // These arrive asynchronously (after the user chats), so every prefilled field
  // must be pushed here - the useState initializers (selectedTags, isPaidEvent)
  // and react-hook-form defaultValues only run at mount and would otherwise be
  // stuck at their defaults.
  React.useEffect(() => {
    switch prefilledValues {
    | Some(pf) => {
        pf.title->Option.map(v => setValue(Title, Value(v)))->ignore
        pf.startDate->Option.map(v => setValue(StartDate, Value(v)))->ignore
        pf.endDate->Option.map(v => setValue(EndTime, Value(v)))->ignore
        pf.details->Option.map(v => setValue(Details, Value(v)))->ignore
        pf.maxRsvps->Option.map(v => setValue(MaxRsvps, Value(v->Int.toString)))->ignore

        // Tags drive the competitive/level/format multi-selects; the
        // selectedTags → minRating effect then derives the numeric rating.
        pf.tags->Option.map(tags => setSelectedTags(_ => tags))->ignore
        // Price presence flips the paid/unpaid toggle.
        pf.price
        ->Option.map(v => {
          setIsPaidEvent(_ => true)
          setValue(Price, Value(v->Int.toString))
        })
        ->ignore
        pf.listed->Option.map(v => setValue(Listed, Value(v)))->ignore
        pf.cancelDeadline
        ->Option.map(v => setValue(CancelDeadline, Value(v->Int.toString)))
        ->ignore
        pf.timezone->Option.map(v => setValue(Timezone, Value(v)))->ignore
      }
    | None => ()
    }
    None
  }, [prefilledValues])

  // Autofill minRating based on selected level tags
  React.useEffect(() => {
    let levelToRating = EventTags.levelToRating
    let specificLevels = EventTags.specificLevels

    if selectedTags->Array.includes("all level") {
      // Clear the minRating value
      setValue(MinRating, Value(""))
    } else {
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
          setValue(MinRating, Value(rating->Js.Float.toFixedWithPrecision(~digits=2)))
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

  // Date and clock handlers. Changing the date leaves both times alone, so the
  // duration is preserved for free; the clock owns start/end interplay.
  let setStartDateTime = (date, time) => setValue(StartDate, Value(joinStartDate(date, time)))
  let onDateChange = date =>
    if date != "" {
      setStartDateTime(date, clockStart)
    }
  let onStartTimeChange = time => {
    let date = datePart != "" ? datePart : Js.Date.make()->DateFns.formatWithPattern("yyyy-MM-dd")
    setStartDateTime(date, time)
  }
  let onEndTimeChange = time => setValue(EndTime, Value(time))
  // The picker holds one window; it reports the whole array on every drag step.
  let onWindowChange = (windows: array<TimeWindow.playIntent>) =>
    switch windows {
    | [window] =>
      onStartTimeChange(TimeWindow.hourToTime(window.start))
      onEndTimeChange(TimeWindow.hourToTime(window.end))
    | _ => ()
    }

  // The venue is not a react-hook-form field, so it is checked with the other
  // non-field guards in onSubmit; "" is unreachable past that guard.
  let locationId = locationData->Option.map(l => l.id)->Option.getOr("")

  let onSubmit = (data: inputs) => {
    if locationData->Option.isNone {
      setLocationError(_ => Some(ts`Choose a location for this event`))
      setExpandedSection(_ => ScheduleSection)
    } else if isClubFormOpen {
      // Block submission if the new club form is open (unsaved club)
      onClubFormSubmitBlocked->Option.forEach(cb => cb())
    } else if durationMinutes < 15 {
      // The clock never produces this, but prefilled times can: with the
      // wrap-past-midnight rule a zero-length range would become a 24-hour
      // event. Longer-than-12h ranges are left alone — they still submit as
      // a same-day span and blocking them would trap edits of legit events.
      // Open the section so the message under the picker shows.
      setExpandedSection(_ => ScheduleSection)
    } else {
      // Filter out "rec" since it's the default (represented by absence of type tags)
      let tagsToSubmit = selectedTags->Array.filter(tag => tag !== "rec")

      // The form's wall-clock values are in the event's zone; convert there.
      let eventTz = data.timezone->Option.getOr(Util.Timezone.fallback)
      let startDate = Util.Timezone.fromWallClock(data.startDate, eventTz)
      let endDate = Util.Timezone.fromWallClock(
        endWallClockFor(data.startDate, data.endTime),
        eventTz,
      )

      let priceValue = isPaidEvent ? data.price : None
      // Sending no threshold is what turns Smart RSVP off; the UI only offers
      // the toggle, so the value is always the default.
      let smartRsvpThresholdValue = isSmartRsvpOn ? Some(defaultSmartRsvpThreshold) : None

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
                locationId,
                clubId: selectedClub->Option.getOr(""),
                startDate: startDate->Util.Datetime.fromDate,
                endDate: endDate->Util.Datetime.fromDate,
                listed: data.listed,
                timezone: eventTz,
                tags: tagsToSubmit,
                price: ?priceValue,
                cancelDeadline: ?data.cancelDeadline,
                smartRsvpThreshold: ?smartRsvpThresholdValue,
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
              locationId,
              clubId: selectedClub->Option.getOr(""),
              startDate: startDate->Util.Datetime.fromDate,
              endDate: endDate->Util.Datetime.fromDate,
              listed: data.listed,
              timezone: eventTz,
              tags: tagsToSubmit,
              price: ?priceValue,
              cancelDeadline: ?data.cancelDeadline,
              smartRsvpThreshold: ?smartRsvpThresholdValue,
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

  // ─── Section summaries (shown under each header) ──────────────────────────
  let locationName = locationData->Option.flatMap(l => l.name)->Option.getOr("")
  let tzShortName = Util.Timezone.shortName(tz, Util.Timezone.fromWallClock(startWallClock, tz))
  let scheduleSummary = if datePart != "" {
    let (_, endTime) = splitStartDate(endWallClockFor(startWallClock, clockEnd))
    let day = datePart->DateFns.parseISO->DateFns.formatWithPattern("EEE, MMM d")
    `${locationName} · ${day}, ${formatWallTime(clockStart)}–${formatWallTime(
        endTime,
      )} ${tzShortName}`
  } else if locationName != "" {
    locationName
  } else {
    ts`Venue, date, start and end time`
  }

  let detailsSummary = titleStr != "" ? titleStr : ts`Title and optional notes`

  let formatSummary = {
    let parts = [eventType == "competitive" ? ts`Competitive` : ts`Recreational`]
    if isDupr {
      parts->Array.push(ts`DUPR rated`)->ignore
    }
    if isDrill {
      parts->Array.push(ts`Drill session`)->ignore
    }
    parts->Array.join(" · ")
  }

  let playersSummary = if listed {
    maxRsvpsStr != "" ? ts`Public · Up to ${maxRsvpsStr} players` : ts`Public`
  } else {
    ts`Private event`
  }

  let showAssistedBanner =
    !isUpdate && prefilledValues->Option.flatMap(pf => pf.title)->Option.isSome

  <FramerMotion.Div
    style={opacity: 0., y: -50.}
    initial={opacity: 0., scale: 1., y: -50.}
    animate={FramerMotion.opacity: 1., scale: 1., y: 0.00}
    exit={opacity: 0., scale: 1., y: -50.}>
    <WaitForMessages>
      {() => <>
        <form onSubmit={handleSubmit(onSubmit)} className="min-w-0 space-y-3 overflow-x-hidden">
          {showAssistedBanner
            ? <div
                role="status"
                className="rounded-lg border border-[#a3d949]/50 bg-[#bdf25d]/10 px-3 py-2.5 text-xs text-[#4d6f12] dark:border-[#bdf25d]/25 dark:text-[#bdf25d]">
                {t`Draft filled in. Review the details before creating the event.`}
              </div>
            : React.null}
          // ─── Location & time ──────────────────────────────────────────────
          <section className=sectionClass>
            {sectionHeader(
              ~icon=<Lucide.CalendarDays
                size=19 className=sectionIconClass \"aria-hidden"="true"
              />,
              ~title=t`Location & time`,
              ~summary=scheduleSummary,
              ~expanded={expandedSection == ScheduleSection},
              ~controls="event-form-schedule",
              ~onToggle=() => toggleSection(ScheduleSection),
            )}
            {expandedSection == ScheduleSection
              ? <div id="event-form-schedule" className=sectionBodyClass>
                  <div className="min-w-0">
                    <span className=labelClass> {t`Location`} </span>
                    {switch (showLocationPicker, locationData) {
                    | (true, _) =>
                      <div className="min-w-0">
                        <AutocompleteLocation
                          onSelected={id => {
                            setChangingLocation(_ => false)
                            setLocationError(_ => None)
                            onLocationSelected->Option.forEach(cb => cb(id))
                          }}
                          error=?locationError
                          ?autoSearchAddress
                        />
                        {changingLocation
                          ? <button
                              type_="button"
                              onClick={_ => setChangingLocation(_ => false)}
                              className="mt-1.5 text-xs font-semibold text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100">
                              {t`Keep current location`}
                            </button>
                          : React.null}
                      </div>
                    | (false, Some(chosen)) =>
                      <div
                        className="flex items-start gap-2.5 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2.5 dark:border-[#3a3b40] dark:bg-[#1e1f23]">
                        <Lucide.MapPin
                          size=14
                          className="mt-0.5 flex-shrink-0 text-gray-400"
                          \"aria-hidden"="true"
                        />
                        <div className="min-w-0 flex-1">
                          <div className="flex items-start justify-between gap-2">
                            <p
                              className="break-words text-sm font-medium text-gray-900 dark:text-gray-100">
                              {locationName->React.string}
                            </p>
                            {onLocationSelected->Option.isSome
                              ? <button
                                  type_="button"
                                  onClick={_ => setChangingLocation(_ => true)}
                                  className="flex-shrink-0 text-xs font-semibold text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100">
                                  {t`Change`}
                                </button>
                              : React.null}
                          </div>
                          {chosen.details
                          ->Option.map(details => {
                            let maxLength = 100
                            let shouldTruncate = details->String.length > maxLength
                            let displayText = if shouldTruncate && !isLocationDetailsExpanded {
                              details->String.substring(~start=0, ~end=maxLength) ++ "..."
                            } else {
                              details
                            }
                            <p
                              className="mt-0.5 break-words text-xs text-gray-500 dark:text-gray-400">
                              {displayText->React.string}
                              {shouldTruncate
                                ? <button
                                    type_="button"
                                    onClick={_ => setIsLocationDetailsExpanded(prev => !prev)}
                                    className="ml-1 whitespace-nowrap font-semibold text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100">
                                    {(
                                      isLocationDetailsExpanded ? ts`Show less` : ts`Read more...`
                                    )->React.string}
                                  </button>
                                : React.null}
                            </p>
                          })
                          ->Option.getOr(React.null)}
                        </div>
                      </div>
                    | (false, None) => React.null
                    }}
                  </div>
                  <label className="block min-w-0 max-w-full overflow-hidden">
                    <span className=labelClass> {t`Date`} </span>
                    <div
                      className={Util.cx([
                        "box-border h-11 w-full min-w-0 max-w-full overflow-hidden rounded-lg border bg-white transition-colors focus-within:border-[#94c93a] focus-within:ring-2 focus-within:ring-[#bdf25d]/40 dark:bg-[#1e1f23]",
                        formState.errors.startDate->Option.isSome
                          ? fieldErrorBorderClass
                          : fieldBorderClass,
                      ])}>
                      <input
                        id="startDate"
                        type_="date"
                        value=datePart
                        onChange={e => onDateChange(ReactEvent.Form.target(e)["value"])}
                        className="native-date-input block h-full w-full min-w-0 max-w-full border-0 bg-transparent text-gray-900 outline-none dark:text-gray-100"
                      />
                    </div>
                    {errorText(formState.errors.startDate->Option.flatMap(e => e.message))}
                  </label>
                  <label className="block min-w-0" htmlFor="timezone">
                    <span className=labelClass> {t`Time zone`} </span>
                    // Controlled, not registered: the option list only fills in
                    // after mount, and an uncontrolled select loses its selection
                    // when set to a zone it has no option for yet.
                    <select
                      id="timezone"
                      value=tz
                      onChange={e => setValue(Timezone, Value(ReactEvent.Form.target(e)["value"]))}
                      className=fieldClass>
                      {timezoneOptions
                      ->Array.map(zone =>
                        <option key=zone value=zone> {zone->React.string} </option>
                      )
                      ->React.array}
                    </select>
                    <span className=hintClass>
                      {t`The date and times on this form are in this zone.`}
                    </span>
                  </label>
                  <div className="min-w-0 max-w-full">
                    <span className=labelClass> {t`Start and end time`} </span>
                    <TimeWindowPicker
                      intents=[eventWindow]
                      onChange=onWindowChange
                      config={eventWindowConfigFor(eventWindow)}
                      maxIntents=1
                      allowDelete=false
                      emptyLabel={ts`Choose an event time`}
                    />
                    <div className="mt-2 flex flex-wrap items-center gap-1.5">
                      <span
                        className="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 font-mono text-[10px] font-semibold text-gray-600 dark:bg-[#1e1f23] dark:text-gray-300">
                        {(TimeWindow.hourToTime(eventWindow.start) ++
                        "–" ++
                        TimeWindow.hourToTime(eventWindow.end) ++
                        " · " ++
                        ClockRangePicker.formatDuration(durationMinutes))->React.string}
                      </span>
                    </div>
                    <span className=hintClass>
                      {t`Drag the window to move it, or drag either edge to resize.`}
                    </span>
                    {!hasValidTimeRange
                      ? <p className="mt-2 text-xs text-red-600 dark:text-red-400">
                          {durationMinutes < 15
                            ? t`Events must be at least 15 minutes long.`
                            : t`Events can be up to 12 hours long.`}
                        </p>
                      : React.null}
                    {errorText(formState.errors.endTime->Option.flatMap(e => e.message))}
                  </div>
                </div>
              : React.null}
          </section>
          // ─── Event details ────────────────────────────────────────────────
          <section className=sectionClass>
            {sectionHeader(
              ~icon=<Lucide.FileText size=19 className=sectionIconClass \"aria-hidden"="true" />,
              ~title=t`Event details`,
              ~summary=detailsSummary,
              ~expanded={expandedSection == DetailsSection},
              ~controls="event-form-details",
              ~onToggle=() => toggleSection(DetailsSection),
            )}
            {expandedSection == DetailsSection
              ? <div id="event-form-details" className=sectionBodyClass>
                  <label className="block min-w-0">
                    <span className=labelClass> {t`Event title`} </span>
                    <input
                      {...register(Title)}
                      id="title"
                      type_="text"
                      placeholder={ts`Friday night pickleball`}
                      className={fieldClassWithError(formState.errors.title->Option.isSome)}
                    />
                    {errorText(formState.errors.title->Option.flatMap(e => e.message))}
                  </label>
                  <label className="block" htmlFor="details">
                    <span className=labelClass>
                      {t`Event notes`}
                      {" "->React.string}
                      <span className="font-normal normal-case"> {t`(optional)`} </span>
                    </span>
                    <textarea
                      {...register(Details, ~options={required: false})}
                      id="details"
                      rows=3
                      defaultValue=""
                      placeholder={ts`Anything players should know before joining or arriving.`}
                      className="w-full resize-y rounded-lg border border-gray-200 bg-white px-3 py-2.5 text-sm leading-relaxed text-gray-900 outline-none transition-colors placeholder:text-gray-400 focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:text-gray-100"
                    />
                  </label>
                </div>
              : React.null}
          </section>
          // ─── Paid event ───────────────────────────────────────────────────
          <section className=sectionClass>
            <label className="flex cursor-pointer items-center gap-3 px-4 py-4">
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
                className="h-5 w-5 flex-shrink-0 rounded border-gray-300 accent-[#bdf25d] focus:ring-[#94c93a] dark:border-[#3a3b40]"
              />
              <Lucide.CircleDollarSign size=19 className=sectionIconClass \"aria-hidden"="true" />
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
                  {t`Paid event`}
                </span>
                <span className="mt-0.5 block text-xs text-gray-500 dark:text-gray-400">
                  {t`Attendees save a card when they RSVP. Nothing is charged automatically.`}
                </span>
              </span>
            </label>
            {isPaidEvent
              ? <div className="border-t border-gray-200 px-4 py-4 dark:border-[#3a3b40]">
                  <label className="block min-w-0" htmlFor="price">
                    <span className=labelClass> {t`Participation fee`} </span>
                    <div className="relative">
                      <span
                        className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3 text-sm text-gray-500">
                        {"¥"->React.string}
                      </span>
                      <input
                        {...register(Price, ~options={required: false})}
                        id="price"
                        type_="number"
                        min="1"
                        placeholder={ts`Enter price`}
                        className={Util.cx([fieldClass, "pl-8"])}
                      />
                    </div>
                  </label>
                  <div className="mt-3 space-y-2 text-sm">
                    <div
                      className={!stripeChargesEnabled
                        ? "rounded-lg border border-[#a3d949]/60 bg-[#bdf25d]/10 p-3 dark:border-[#bdf25d]/25 dark:bg-[#bdf25d]/5"
                        : "rounded-lg border border-gray-200 p-3 dark:border-[#3a3b40]"}>
                      <div className="flex items-center gap-1.5">
                        <span className="font-semibold text-gray-700 dark:text-gray-300">
                          {t`Without a Stripe account`}
                        </span>
                        {!stripeChargesEnabled
                          ? <span
                              className="rounded bg-[#bdf25d]/25 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-[#547817] dark:text-[#bdf25d]">
                              {t`Active`}
                            </span>
                          : React.null}
                      </div>
                      <p
                        className="mt-0.5 text-xs leading-relaxed text-gray-600 dark:text-gray-400">
                        {t`Attendees are asked to save a card when they RSVP, but nothing is authorized or charged, and you can't charge it from here. Collect the fee at the event.`}
                      </p>
                    </div>
                    <div
                      className={stripeChargesEnabled
                        ? "rounded-lg border border-[#a3d949]/60 bg-[#bdf25d]/10 p-3 dark:border-[#bdf25d]/25 dark:bg-[#bdf25d]/5"
                        : "rounded-lg border border-gray-200 p-3 dark:border-[#3a3b40]"}>
                      <div className="flex items-center gap-1.5">
                        <span className="font-semibold text-gray-700 dark:text-gray-300">
                          {t`With a Stripe account`}
                        </span>
                        {stripeChargesEnabled
                          ? <span
                              className="rounded bg-[#bdf25d]/25 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-[#547817] dark:text-[#bdf25d]">
                              {t`Active`}
                            </span>
                          : React.null}
                      </div>
                      <p
                        className="mt-0.5 text-xs leading-relaxed text-gray-600 dark:text-gray-400">
                        {t`Attendees save a card when they RSVP and nothing is charged or held up front. From the RSVP list you can charge one attendee or everyone whenever you choose, and the money goes to your Stripe account.`}
                        {!stripeChargesEnabled
                          ? <>
                              {" "->React.string}
                              <a
                                href="/settings/profile"
                                className="font-semibold text-[#4d6f12] underline hover:opacity-80 dark:text-[#bdf25d]">
                                {t`Connect a Stripe account to enable this`}
                              </a>
                            </>
                          : React.null}
                      </p>
                    </div>
                  </div>
                  // Applies in both modes: the organizer can always let someone in
                  // without a card.
                  <p className="mt-3 text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                    {t`Anyone held as pending can be moved into the event from the RSVP list, which bypasses the payment requirement for them.`}
                  </p>
                </div>
              : React.null}
          </section>
          // ─── Format ───────────────────────────────────────────────────────
          <section className=sectionClass>
            {sectionHeader(
              ~icon=<Lucide.Dumbbell size=19 className=sectionIconClass \"aria-hidden"="true" />,
              ~title=t`Format`,
              ~summary=formatSummary,
              ~expanded={expandedSection == FormatSection},
              ~controls="event-form-format",
              ~onToggle=() => toggleSection(FormatSection),
            )}
            {expandedSection == FormatSection
              ? <div id="event-form-format" className=sectionBodyClass>
                  <fieldset>
                    <legend className=legendClass> {t`Event type`} </legend>
                    <div className="mt-2 grid grid-cols-2 gap-2">
                      <button
                        type_="button"
                        ariaPressed={pressed(eventType == "recreational")}
                        onClick={_ =>
                          setSelectedTags(tags =>
                            tags
                            ->Array.filter(t => t != "comp" && t != "dupr")
                            ->Array.concat(["rec"])
                          )}
                        className={toggleClass(eventType == "recreational")}>
                        {t`Recreational`}
                      </button>
                      <button
                        type_="button"
                        ariaPressed={pressed(eventType == "competitive")}
                        onClick={_ =>
                          setSelectedTags(tags =>
                            tags
                            ->Array.filter(t => t != "rec")
                            ->Array.concat(["comp"])
                          )}
                        className={toggleClass(eventType == "competitive")}>
                        {t`Competitive`}
                      </button>
                    </div>
                  </fieldset>
                  <fieldset>
                    <legend className=legendClass> {t`Format options`} </legend>
                    <div className="mt-2 grid grid-cols-2 gap-2">
                      {eventType == "competitive"
                        ? <button
                            type_="button"
                            ariaPressed={pressed(isDupr)}
                            onClick={_ =>
                              setSelectedTags(tags =>
                                isDupr
                                  ? tags->Array.filter(t => t != "dupr")
                                  : tags->Array.concat(["dupr"])
                              )}
                            className={toggleClass(isDupr)}>
                            {t`DUPR rated`}
                          </button>
                        : React.null}
                      <button
                        type_="button"
                        ariaPressed={pressed(isDrill)}
                        onClick={_ =>
                          setSelectedTags(tags =>
                            isDrill
                              ? tags->Array.filter(t => t != "drill")
                              : tags->Array.concat(["drill"])
                          )}
                        className={toggleClass(isDrill)}>
                        {t`Drill session`}
                      </button>
                    </div>
                  </fieldset>
                </div>
              : React.null}
          </section>
          // ─── Find players ─────────────────────────────────────────────────
          <section className=sectionClass>
            {sectionHeader(
              ~icon=<Lucide.Users size=19 className=sectionIconClass \"aria-hidden"="true" />,
              ~title=t`Players`,
              ~summary=playersSummary,
              ~expanded={expandedSection == PlayersSection},
              ~controls="event-form-players",
              ~onToggle=() => toggleSection(PlayersSection),
            )}
            {expandedSection == PlayersSection
              ? <div id="event-form-players" className=sectionBodyClass>
                  <label className="flex cursor-pointer items-start gap-3">
                    <input
                      id="findPlayers"
                      type_="checkbox"
                      checked={listed}
                      onChange={_ => setValue(Listed, Value(!listed))}
                      className=checkboxClass
                    />
                    <span className="min-w-0">
                      <span
                        className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
                        {t`Find players for your event?`}
                      </span>
                      <span
                        className="mt-1 block text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                        {t`List your event publicly to help fill open spots.`}
                      </span>
                    </span>
                  </label>
                  {listed
                    ? <div
                        role="status"
                        className="inline-flex items-center gap-1.5 rounded-md bg-emerald-50 px-2.5 py-1.5 text-xs font-semibold text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300">
                        <Lucide.Check size=13 strokeWidth=2.5 \"aria-hidden"="true" />
                        {t`This event is public`}
                      </div>
                    : React.null}
                  // The level applies to private events too (it drives the
                  // minimum rating and the row's level tag), so it is not
                  // gated on the listing toggle.
                  <LevelTagPills
                    selected=selectedTags
                    onChange={tags => setSelectedTags(_ => tags)}
                    legend={t`Skill level`}
                  />
                  <label className="block min-w-0" htmlFor="minRating">
                    <span className=labelClass>
                      {t`Minimum rating`}
                      {" "->React.string}
                      <span className="font-normal normal-case"> {t`(optional)`} </span>
                    </span>
                    <input
                      {...register(MinRating, ~options={required: false})}
                      id="minRating"
                      type_="number"
                      step=0.01
                      placeholder={ts`No minimum`}
                      className={fieldClassWithError(formState.errors.minRating->Option.isSome)}
                    />
                    {errorText(formState.errors.minRating->Option.flatMap(e => e.message))}
                  </label>
                  <label
                    className={Util.cx(["flex cursor-pointer items-start gap-3", subsectionClass])}>
                    <input
                      id="smartRsvp"
                      type_="checkbox"
                      checked={isSmartRsvpOn}
                      onChange={_ => setIsSmartRsvpOn(on => !on)}
                      className=checkboxClass
                    />
                    <span>
                      <span
                        className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
                        {t`Smart RSVP`}
                      </span>
                      <span
                        className="mt-1 block text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                        {t`Hold new joins and admit players automatically based on match quality.`}
                      </span>
                    </span>
                  </label>
                  <label className={Util.cx(["block min-w-0", subsectionClass])} htmlFor="maxRsvps">
                    <span className=labelClass>
                      {t`Max players`}
                      {" "->React.string}
                      <span className="font-normal normal-case"> {t`(optional)`} </span>
                    </span>
                    <input
                      {...register(MaxRsvps, ~options={required: false})}
                      id="maxRsvps"
                      type_="number"
                      min="1"
                      placeholder={ts`No limit`}
                      className={fieldClassWithError(formState.errors.maxRsvps->Option.isSome)}
                    />
                    {errorText(formState.errors.maxRsvps->Option.flatMap(e => e.message))}
                  </label>
                  <label
                    className={Util.cx(["block min-w-0", subsectionClass])}
                    htmlFor="cancelDeadline">
                    <span className=labelClass> {t`Cancel deadline`} </span>
                    <select
                      {...register(CancelDeadline, ~options={required: false})}
                      id="cancelDeadline"
                      className=fieldClass>
                      <option value=""> {(ts`No deadline`)->React.string} </option>
                      <option value="3600000"> {(ts`1 hour before`)->React.string} </option>
                      <option value="7200000"> {(ts`2 hours before`)->React.string} </option>
                      <option value="21600000"> {(ts`6 hours before`)->React.string} </option>
                      <option value="43200000"> {(ts`12 hours before`)->React.string} </option>
                      <option value="86400000"> {(ts`24 hours before`)->React.string} </option>
                      <option value="172800000"> {(ts`48 hours before`)->React.string} </option>
                      <option value="259200000"> {(ts`72 hours before`)->React.string} </option>
                      <option value="604800000"> {(ts`1 week before`)->React.string} </option>
                    </select>
                    <span className=hintClass>
                      {t`Attendees cannot cancel their RSVP after this deadline.`}
                    </span>
                  </label>
                </div>
              : React.null}
          </section>
          <button
            type_="submit"
            className="w-full rounded-lg bg-[#bdf25d] px-4 py-3 text-sm font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 dark:focus-visible:ring-offset-[#111111]">
            {isUpdate ? t`Update event` : t`Create event`}
          </button>
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
