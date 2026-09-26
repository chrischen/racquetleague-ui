%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")

let ts = Lingui.UtilString.t

module Mutation = %relay(`
 mutation CreateLocationEventFormMutation($input: CreateEventInput!) {
   createEvent(input: $input) {
     event {
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
let sectionBaseClass = "overflow-hidden rounded-xl border bg-white dark:bg-[#222326]"
// A section holding values that came from outside the form wears the accent
// border, so it is obvious at a glance what was filled in and still wants a
// look before submitting.
let sectionClassFor = (~prefilled: bool) =>
  Util.cx([
    sectionBaseClass,
    prefilled
      ? "border-[#a3d949] dark:border-[#bdf25d]/50"
      : "border-gray-200 dark:border-[#3a3b40]",
  ])
let sectionBodyClass = "space-y-5 border-t border-gray-200 px-4 py-4 dark:border-[#3a3b40]"
let sectionIconClass = "flex-shrink-0 text-gray-400"
// A prefilled section trades its icon for a check, which gives the accent
// border a legend: this one was filled in, give it a look.
let prefilledIcon =
  <Lucide.CheckCircle2
    size=19 className="flex-shrink-0 text-[#4d6f12] dark:text-[#bdf25d]" \"aria-hidden"="true"
  />
let sectionIcon = (~prefilled: bool, ~icon: React.element) => prefilled ? prefilledIcon : icon
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
  ~prefilled: bool,
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
      {sectionIcon(~prefilled, ~icon)}
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
let hoursOfTime = (time: string): float => ClockRangePicker.timeToMinutes(time)->Int.toFloat /. 60.0
let eventWindowOf = (startTime: string, endTime: string): TimeWindow.playIntent => {
  let start = hoursOfTime(startTime)
  let end = hoursOfTime(endTime)
  {id: 0, start, end: Js.Math.min_float(end <= start ? end +. 24.0 : end, 24.0)}
}

// Sections filled in on the organizer's behalf: an AI draft, or a link that
// carried values in its query. Two things deliberately do not count, because
// marking them would make the border meaningless: the form's own defaults (the
// two-hour window, the 24h cancel deadline), and an existing event's own values
// when it is being edited or copied — that is the event's data, not a draft
// someone else filled in.
type prefilledSections = {
  schedule: bool,
  details: bool,
  paid: bool,
  format: bool,
  players: bool,
}

let noPrefilledSections = {
  schedule: false,
  details: false,
  paid: false,
  format: false,
  players: false,
}

let hasText = (v: option<string>) => v->Option.mapOr(false, text => text != "")

// `tags` feeds two sections: the play-format chips and the skill-level pills.
let formatTags = ["rec", "comp", "dupr", "drill"]
let levelTags = Array.concat(["all level"], EventTags.specificLevels)

let sectionsOf = (
  prefilled: option<prefilledValues>,
  // A venue counts only when it arrived with the form (a ?locationId link, an
  // event being edited) or the assistant searched one out — not when the
  // organizer picks one by hand.
  ~hasVenue: bool,
): prefilledSections =>
  switch prefilled {
  | None => {...noPrefilledSections, schedule: hasVenue}
  // An event being edited or copied brings its own values to every field,
  // venue included, so nothing here was prefilled for the organizer.
  | Some({fromExistingEvent: true}) => noPrefilledSections
  | Some(pf) =>
    let tags = pf.tags->Option.getOr([])
    let hasAnyTag = candidates => tags->Array.some(tag => candidates->Array.includes(tag))
    {
      schedule: hasVenue || hasText(pf.startDate) || hasText(pf.endDate) || hasText(pf.timezone),
      details: hasText(pf.title) || hasText(pf.details),
      paid: pf.price->Option.isSome,
      format: hasAnyTag(formatTags),
      players: pf.listed->Option.isSome ||
      pf.minRating->Option.isSome ||
      pf.maxRsvps->Option.isSome ||
      pf.smartRsvpThreshold->Option.isSome ||
      pf.cancelDeadline->Option.isSome ||
      hasAnyTag(levelTags),
    }
  }

let unionSections = (a: prefilledSections, b: prefilledSections) => {
  schedule: a.schedule || b.schedule,
  details: a.details || b.details,
  paid: a.paid || b.paid,
  format: a.format || b.format,
  players: a.players || b.players,
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
  // An accepted multi-event proposal from the assistant. It supplies the
  // schedule - each event's venue, date and time - and the rest of this form
  // applies to every event. Venue picks and create outcomes are reported back
  // as updates of the current list (the owner's venue lookups land at the
  // same time); the cancel callback drops the proposal.
  ~proposedEvents: option<array<EventProposal.t>>=?,
  ~onProposedEventsChange: option<(array<EventProposal.t> => array<EventProposal.t>) => unit>=?,
  ~onCancelProposal: option<unit => unit>=?,
) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t

  let locationData = Fragment.useOpt(location)
  let (commitMutationCreate, _) = Mutation.use()
  let (commitMutationUpdate, _) = UpdateMutation.use()
  let navigate = Router.useNavigate()

  let isUpdate = eventId->Option.isSome

  // A proposal with no events is no proposal.
  let proposal = proposedEvents->Option.filter(events => events->Array.length > 0)
  let isMulti = proposal->Option.isSome
  let updateProposal = (change: array<EventProposal.t> => array<EventProposal.t>) =>
    onProposedEventsChange->Option.forEach(onChange => onChange(change))
  let (isSubmittingProposal, setIsSubmittingProposal) = React.useState(() => false)
  let (proposalError, setProposalError) = React.useState((): option<string> => None)

  // A venue present at mount came in with the form; one the organizer picks
  // later must not light the section up, so this is captured once.
  let venueArrivedWithForm = React.useRef(location->Option.isSome)
  let venuePrefilled = () => venueArrivedWithForm.current || autoSearchAddress->Option.isSome
  let (prefilledSections, setPrefilledSections) = React.useState(() =>
    sectionsOf(prefilledValues, ~hasVenue=venuePrefilled())
  )
  // The assistant's draft arrives after mount, so fold later arrivals in. Marks
  // are kept once set: editing a field doesn't change where it came from.
  React.useEffect2(() => {
    setPrefilledSections(prev => {
      let next = unionSections(prev, sectionsOf(prefilledValues, ~hasVenue=venuePrefilled()))
      // The page rebuilds its prefill record on every render, so hold on to the
      // previous value when nothing new arrived and let React skip the update.
      next == prev ? prev : next
    })
    None
  }, (prefilledValues, autoSearchAddress))
  // A proposal supplies the whole schedule, for as long as it is in force.
  let prefilledSections = isMulti ? {...prefilledSections, schedule: true} : prefilledSections

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
  let durationMinutes = ClockRangePicker.forwardDuration(
    ClockRangePicker.timeToMinutes(clockStart),
    ClockRangePicker.timeToMinutes(clockEnd),
  )
  let hasValidTimeRange = durationMinutes >= 15 && durationMinutes <= 12 * 60
  let eventWindow = eventWindowOf(clockStart, clockEnd)
  // Shared by the picker and the typed fields below it, so both accept exactly
  // the same windows.
  let eventWindowConfig = eventWindowConfigFor(eventWindow)

  // Collapsed if editing an existing event or arriving with prefilled values,
  // otherwise the schedule section opens first.
  let hasPreloadedValues = eventId->Option.isSome || prefilledValues->Option.isSome
  let (expandedSection, setExpandedSection) = React.useState(() =>
    hasPreloadedValues ? None : ScheduleSection
  )
  let toggleSection = section => setExpandedSection(current => current == section ? None : section)

  // A proposal's schedule, and any venue it still needs, is shown on arrival.
  React.useEffect(() => {
    setProposalError(_ => None)
    if isMulti {
      setExpandedSection(_ => ScheduleSection)
    }
    None
  }, [isMulti])

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

  // The event this form describes, at one venue and time. Creating, updating
  // and a proposal's events all send exactly these fields.
  let buildInput = (
    data: inputs,
    ~locationId: string,
    ~startDate: Date.t,
    ~endDate: Date.t,
  ): RelaySchemaAssets_graphql.input_CreateEventInput => {
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
    timezone: data.timezone->Option.getOr(Util.Timezone.fallback),
    // "rec" is the default, represented by the absence of type tags.
    tags: selectedTags->Array.filter(tag => tag !== "rec"),
    price: ?(isPaidEvent ? data.price : None),
    cancelDeadline: ?data.cancelDeadline,
    // Sending no threshold is what turns Smart RSVP off; the UI only offers
    // the toggle, so the value is always the default.
    smartRsvpThreshold: ?(isSmartRsvpOn ? Some(defaultSmartRsvpThreshold) : None),
  }

  // Creates one event and resolves to its id, or to nothing when the server
  // refused it.
  let createEvent = (input): promise<option<string>> =>
    Promise.make((resolve, _reject) =>
      commitMutationCreate(
        ~variables={input: input},
        ~onCompleted=(response, _errors) =>
          resolve(response.createEvent.event->Option.map(event => event.id)),
        ~onError=_ => resolve(None),
      )->RescriptRelay.Disposable.ignore
    )

  // Creates the proposal's events with this form's values, each at its own
  // venue and time. Events created by an earlier attempt are kept, so a retry
  // after a failure only creates what is still missing.
  let submitProposal = async (data: inputs, events: array<EventProposal.t>) =>
    if events->Array.some(event => EventProposal.venueId(event)->Option.isNone) {
      setProposalError(_ => Some(ts`Choose a venue for every event`))
      setExpandedSection(_ => ScheduleSection)
    } else {
      setProposalError(_ => None)
      setIsSubmittingProposal(_ => true)
      let outcome = await Promise.all(
        events->Array.map(async event =>
          switch (event.status, EventProposal.venueId(event)) {
          | (Created(_), _) | (_, None) => event
          | (Pending | Failed, Some(locationId)) =>
            let input = buildInput(
              data,
              ~locationId,
              ~startDate=event.startDate,
              ~endDate=event.endDate,
            )
            switch await createEvent(input) {
            | Some(id) => {...event, status: Created(id)}
            | None => {...event, status: Failed}
            }
          }
        ),
      )
      setIsSubmittingProposal(_ => false)
      // Only the outcomes are reported, so a venue changed meanwhile is kept.
      updateProposal(current =>
        current->Array.map(event =>
          outcome
          ->Array.find(o => o.key == event.key)
          ->Option.mapOr(event, o => {...event, status: o.status})
        )
      )
      if outcome->Array.every(EventProposal.isCreated) {
        navigate("/events", None)
      } else {
        setProposalError(_ => Some(
          ts`Some events could not be created. Try again to create the rest.`,
        ))
        setExpandedSection(_ => ScheduleSection)
      }
    }

  let onSubmit = (data: inputs) =>
    switch proposal {
    | Some(events) =>
      if isClubFormOpen {
        // Block submission if the new club form is open (unsaved club)
        onClubFormSubmitBlocked->Option.forEach(cb => cb())
      } else {
        submitProposal(data, events)->ignore
      }
    | None =>
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
        // The form's wall-clock values are in the event's zone; convert there.
        let eventTz = data.timezone->Option.getOr(Util.Timezone.fallback)
        let startDate = Util.Timezone.fromWallClock(data.startDate, eventTz)
        let endDate = Util.Timezone.fromWallClock(
          endWallClockFor(data.startDate, data.endTime),
          eventTz,
        )
        let input = buildInput(data, ~locationId, ~startDate, ~endDate)
        switch eventId {
        | Some(id) =>
          commitMutationUpdate(~variables={eventId: id, input}, ~onCompleted=(_response, _errors) =>
            navigate("/events/" ++ id, None)
          )->RescriptRelay.Disposable.ignore
        | None =>
          createEvent(input)
          ->Promise.thenResolve(id => id->Option.forEach(id => navigate("/events/" ++ id, None)))
          ->ignore
        }
      }
    }

  // ─── Proposal schedule (in place of the venue, date and time fields) ──────
  let statusChip = (status: EventProposal.status) =>
    switch status {
    | Pending => React.null
    | Created(_) =>
      <span
        className="flex-shrink-0 rounded-full bg-[#bdf25d]/30 px-2 py-0.5 text-[11px] font-semibold text-[#4d6f12] dark:text-[#bdf25d]">
        {t`Created`}
      </span>
    | Failed =>
      <span
        className="flex-shrink-0 rounded-full bg-red-100 px-2 py-0.5 text-[11px] font-semibold text-red-700 dark:bg-red-900/40 dark:text-red-300">
        {t`Failed`}
      </span>
    }
  let setVenue = (event: EventProposal.t, venue: EventProposal.venue) =>
    updateProposal(events => EventProposal.update(events, event.key, e => {...e, venue}))
  // Each event keeps its own venue, date and time, so they are listed rather
  // than edited. Only a venue the assistant could not find is picked here.
  let proposalSchedule = (events: array<EventProposal.t>) =>
    <div id="event-form-schedule" className=sectionBodyClass>
      <div className="min-w-0">
        <TimeZoneField value=tz onChange={zone => setValue(Timezone, Value(zone))} />
        <span className=hintClass>
          {t`The times below are shown in this zone, and every event is created in it.`}
        </span>
      </div>
      <div className="min-w-0">
        <span className=labelClass> {t`Events`} </span>
        <ol className="space-y-2">
          {events
          ->Array.map(event => {
            let (day, startTime) = splitStartDate(Util.Timezone.toWallClock(event.startDate, tz))
            let (_, endTime) = splitStartDate(Util.Timezone.toWallClock(event.endDate, tz))
            let minutes =
              (event.endDate->Js.Date.getTime -. event.startDate->Js.Date.getTime) /. 60000.
            let timing = `${day
              ->DateFns.parseISO
              ->DateFns.formatWithPattern("EEE, MMM d")}, ${formatWallTime(
                startTime,
              )}–${formatWallTime(endTime)} · ${ClockRangePicker.formatDuration(
                minutes->Float.toInt,
              )}`
            let isCreated = EventProposal.isCreated(event)
            <li
              key=event.key
              className="min-w-0 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2.5 dark:border-[#3a3b40] dark:bg-[#1e1f23]">
              <div className="flex items-start justify-between gap-2">
                <p className="min-w-0 text-sm font-medium text-gray-900 dark:text-gray-100">
                  {timing->React.string}
                </p>
                {statusChip(event.status)}
              </div>
              {switch event.venue {
              | Resolved({name}) =>
                <div className="mt-1 flex items-center justify-between gap-2">
                  <p
                    className="flex min-w-0 items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400">
                    <Lucide.MapPin
                      size=13 className="flex-shrink-0 text-gray-400" \"aria-hidden"="true"
                    />
                    <span className="truncate"> {name->React.string} </span>
                  </p>
                  {isCreated
                    ? React.null
                    : <button
                        type_="button"
                        onClick={_ => setVenue(event, Unresolved)}
                        className="flex-shrink-0 text-xs font-semibold text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100">
                        {t`Change`}
                      </button>}
                </div>
              | Resolving =>
                <p
                  className="mt-1 flex min-w-0 items-center gap-1.5 text-xs text-gray-500 dark:text-gray-400">
                  <Lucide.Loader2
                    size=13 className="flex-shrink-0 animate-spin" \"aria-hidden"="true"
                  />
                  <span className="truncate">
                    {event.address
                    ->Option.mapOr(ts`Finding the venue…`, address => ts`Finding ${address}…`)
                    ->React.string}
                  </span>
                </p>
              | Unresolved =>
                <div className="mt-2 min-w-0">
                  <p className="mb-1.5 text-xs text-gray-500 dark:text-gray-400">
                    {event.address
                    ->Option.mapOr(ts`Choose a venue for this event.`, address =>
                      ts`Couldn't find "${address}". Choose the venue:`
                    )
                    ->React.string}
                  </p>
                  <AutocompleteLocation
                    onSelected={_ => ()}
                    onSelectedDetails={((id, name)) => setVenue(event, Resolved({id, name}))}
                  />
                </div>
              }}
            </li>
          })
          ->React.array}
        </ol>
      </div>
    </div>

  // ─── Section summaries (shown under each header) ──────────────────────────
  let locationName = locationData->Option.flatMap(l => l.name)->Option.getOr("")
  let eventCountPhrase = (count: int) =>
    Lingui.UtilString.plural(
      count,
      {one: ts`${count->Int.toString} event`, other: ts`${count->Int.toString} events`},
    )
  let scheduleSummary = switch proposal {
  | Some(events) =>
    let days =
      events->Array.map(event =>
        Util.Timezone.toWallClock(event.startDate, tz)->String.slice(~start=0, ~end=10)
      )
    // (`None` here is option's; the section enum shadows the bare name.)
    let pick = choose =>
      days->Array.reduce((None: option<string>), (acc, day) => Some(
        acc->Option.mapOr(day, best => choose(best, day) ? best : day),
      ))
    let format = day => day->DateFns.parseISO->DateFns.formatWithPattern("MMM d")
    let span = switch (pick((a, b) => a <= b), pick((a, b) => a >= b)) {
    | (Some(first), Some(last)) =>
      first == last ? format(first) : `${format(first)} – ${format(last)}`
    | _ => ""
    }
    let missing = events->Array.filter(event => !EventProposal.isResolved(event))->Array.length
    let parts = [eventCountPhrase(events->Array.length), span]
    if missing > 0 {
      parts->Array.push(ts`${missing->Int.toString} without a venue`)->ignore
    }
    parts->Array.join(" · ")
  | None if datePart != "" =>
    let (_, endTime) = splitStartDate(endWallClockFor(startWallClock, clockEnd))
    let day = datePart->DateFns.parseISO->DateFns.formatWithPattern("EEE, MMM d")
    // The zone is named in the field itself, so the summary spends its width on
    // the duration instead.
    `${locationName} · ${day}, ${formatWallTime(clockStart)}–${formatWallTime(
        endTime,
      )} · ${ClockRangePicker.formatDuration(durationMinutes)}`
  | None => locationName != "" ? locationName : ts`Venue, date, start and end time`
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
    !isUpdate && !isMulti && prefilledValues->Option.flatMap(pf => pf.title)->Option.isSome
  let bannerClass = "rounded-lg border border-[#a3d949]/50 bg-[#bdf25d]/10 px-3 py-2.5 text-xs text-[#4d6f12] dark:border-[#bdf25d]/25 dark:text-[#bdf25d]"

  <FramerMotion.Div
    style={opacity: 0., y: -50.}
    initial={opacity: 0., scale: 1., y: -50.}
    animate={FramerMotion.opacity: 1., scale: 1., y: 0.00}
    exit={opacity: 0., scale: 1., y: -50.}>
    <WaitForMessages>
      {() => <>
        <form onSubmit={handleSubmit(onSubmit)} className="min-w-0 space-y-3 overflow-x-hidden">
          {switch proposal {
          | Some(events) =>
            <div role="status" className={Util.cx([bannerClass, "flex items-start gap-3"])}>
              <p className="min-w-0 flex-1">
                {(
                  ts`The assistant proposed ${eventCountPhrase(
                    events->Array.length,
                  )}. Each keeps its own venue, date and time; the rest of this form applies to all of them.`
                )->React.string}
              </p>
              <button
                type_="button"
                onClick={_ => onCancelProposal->Option.forEach(cb => cb())}
                className="flex-shrink-0 font-semibold underline-offset-2 hover:underline">
                {t`Discard`}
              </button>
            </div>
          | None =>
            showAssistedBanner
              ? <div role="status" className=bannerClass>
                  {t`Draft filled in. Review the details before creating the event.`}
                </div>
              : React.null
          }}
          // ─── Location & time ──────────────────────────────────────────────
          <section className={sectionClassFor(~prefilled=prefilledSections.schedule)}>
            {sectionHeader(
              ~icon=<Lucide.CalendarDays
                size=19 className=sectionIconClass \"aria-hidden"="true"
              />,
              ~title=t`Location & time`,
              ~summary=scheduleSummary,
              ~expanded={expandedSection == ScheduleSection},
              ~prefilled=prefilledSections.schedule,
              ~controls="event-form-schedule",
              ~onToggle=() => toggleSection(ScheduleSection),
            )}
            {switch (expandedSection == ScheduleSection, proposal) {
            | (false, _) => React.null
            | (true, Some(events)) => proposalSchedule(events)
            | (true, None) =>
              <div id="event-form-schedule" className=sectionBodyClass>
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
                        size=14 className="mt-0.5 flex-shrink-0 text-gray-400" \"aria-hidden"="true"
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
                <div className="min-w-0">
                  <TimeZoneField value=tz onChange={zone => setValue(Timezone, Value(zone))} />
                  <span className=hintClass>
                    {t`The date and times on this form are in this zone.`}
                  </span>
                </div>
                <div className="min-w-0 max-w-full">
                  <span className=labelClass> {t`Start and end time`} </span>
                  <TimeWindowPicker
                    intents=[eventWindow]
                    onChange=onWindowChange
                    config=eventWindowConfig
                    maxIntents=1
                    allowDelete=false
                    emptyLabel={ts`Choose an event time`}
                  />
                  <span className=hintClass>
                    {t`Drag the window to move it, or drag either edge to resize.`}
                  </span>
                  // The same window, typed rather than dragged.
                  <EventTimeRangeInputs
                    value=eventWindow
                    onChange={window => onWindowChange([window])}
                    config=eventWindowConfig
                  />
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
            }}
          </section>
          // ─── Event details ────────────────────────────────────────────────
          <section className={sectionClassFor(~prefilled=prefilledSections.details)}>
            {sectionHeader(
              ~icon=<Lucide.FileText size=19 className=sectionIconClass \"aria-hidden"="true" />,
              ~title=t`Event details`,
              ~summary=detailsSummary,
              ~expanded={expandedSection == DetailsSection},
              ~prefilled=prefilledSections.details,
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
          <section className={sectionClassFor(~prefilled=prefilledSections.paid)}>
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
              {sectionIcon(
                ~prefilled=prefilledSections.paid,
                ~icon=<Lucide.CircleDollarSign
                  size=19 className=sectionIconClass \"aria-hidden"="true"
                />,
              )}
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
                        {t`Attendees are asked to save a card when they RSVP, but nothing is authorized or charged, and you can't charge it from here. Collect the fee at the event. Club members are exempted from this.`}
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
                        {t`Attendees save a card when they RSVP and nothing is charged or held up front. From the RSVP list you can charge one attendee or everyone whenever you choose, and the money goes to your Stripe account. Club members can be exempted or not, which you can toggle from the Club home page.`}
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
          <section className={sectionClassFor(~prefilled=prefilledSections.format)}>
            {sectionHeader(
              ~icon=<Lucide.Dumbbell size=19 className=sectionIconClass \"aria-hidden"="true" />,
              ~title=t`Format`,
              ~summary=formatSummary,
              ~expanded={expandedSection == FormatSection},
              ~prefilled=prefilledSections.format,
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
          <section className={sectionClassFor(~prefilled=prefilledSections.players)}>
            {sectionHeader(
              ~icon=<Lucide.Users size=19 className=sectionIconClass \"aria-hidden"="true" />,
              ~title=t`Players`,
              ~summary=playersSummary,
              ~expanded={expandedSection == PlayersSection},
              ~prefilled=prefilledSections.players,
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
                        {t`Hold RSVPs`}
                      </span>
                      <span
                        className="mt-1 block text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                        {t`Hold new joins  in the pending list and admit players either manually or automatically with the Smart RSVPs algorithm that maximizes skill level and session quality.`}
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
          {errorText(proposalError)}
          <button
            type_="submit"
            disabled=isSubmittingProposal
            className="w-full rounded-lg bg-[#bdf25d] px-4 py-3 text-sm font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 disabled:cursor-wait disabled:opacity-60 dark:focus-visible:ring-offset-[#111111]">
            {switch proposal {
            | Some(events) =>
              isSubmittingProposal
                ? t`Creating events…`
                : (ts`Create ${eventCountPhrase(events->Array.length)}`)->React.string
            | None => isUpdate ? t`Update event` : t`Create event`
            }}
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
