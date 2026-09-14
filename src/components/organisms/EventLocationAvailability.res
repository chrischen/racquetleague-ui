%%raw("import { t } from '@lingui/macro'")

// Scraped court availability at an event's own venue, for the event's own day.
// Shown inside the event page's location section to event owners and club
// admins, so they can see at a glance whether the venue actually has a court
// covering the time they scheduled — and move the event onto a time that works
// when it doesn't.
//
// Scope note: the design this implements also has "other locations at this
// time" and "other locations and times" sections. Those need availability for
// *nearby* venues, which `Event.courtAvailability` (one venue, one day) can't
// supply. The seam for them is marked below; wiring them up is a matter of
// adding the extra courts to `alternateLocationCourts` /
// `alternateLocationTimeSlots` once the server exposes them.

let ts = Lingui.UtilString.t

module Fragment = %relay(`
  fragment EventLocationAvailability_event on Event {
    id
    title
    details
    startDate
    endDate
    timezone
    listed
    tags
    maxRsvps
    minRating
    cancelDeadline
    price
    smartRsvpThreshold
    activity {
      id
    }
    club {
      id
    }
    location {
      id
    }
    courtAvailability {
      id
      link
      location {
        id
        name
      }
      intervals {
        startHour
        endHour
      }
      hourly {
        hour
        indoorCount
        outdoorCount
        priceMin
        priceMax
      }
      courts {
        name
        courtType
        price
        intervals {
          startHour
          endHour
        }
      }
    }
  }
`)

// The response must select everything a move invalidates, or Relay keeps
// rendering the stale store: the event page's location card (its `location`
// fields + LocationMap_location), and this component's own fragment, whose
// `courtAvailability` is scoped to the (possibly re-homed) venue-day.
module UpdateMutation = %relay(`
  mutation EventLocationAvailabilityUpdateMutation(
    $eventId: ID!
    $input: CreateEventInput!
  ) {
    updateEvent(eventId: $eventId, input: $input) {
      event {
        id
        startDate
        endDate
        location {
          id
          name
          details
          address
          links
          coords {
            lat
            lng
          }
          ...LocationMap_location
        }
        ...EventLocationAvailability_event
      }
    }
  }
`)

// Project a day's availability onto the shared court-availability shape.
//
// Most scraped venues expose only the day-level opening hours — `courts` (the
// per-court breakdown) and `hourly` come back empty. In that case fall back to
// a single unnamed court carrying the day's intervals, which is how the
// discover feed renders these same venues. When the per-court breakdown *is*
// present, use it, synthesizing the per-hour rollup `summarizeCourtAvailability`
// reads from each court's surface and price so counts and price ranges match
// the other court surfaces. A court with no surface is left un-enriched, which
// that function already counts as one open court.
let courtsFromDay = (
  day: EventLocationAvailability_event_graphql.Types.fragment_courtAvailability,
  ~genericCourtName: string,
): array<TimeWindow.courtAvailability> => {
  let locationId = day.location->Option.map(l => l.id)->Option.getOr(day.id)
  let locationName = day.location->Option.flatMap(l => l.name)->Option.getOr(genericCourtName)
  let location: TimeWindow.courtLocation = {
    id: locationId,
    name: locationName,
    reservationUrl: day.link,
  }

  // Per-court cards only pay off when the scraper actually names the courts.
  // Most venues return every court unnamed (4 identical "outdoor ¥3300" rows),
  // which would render as N indistinguishable cards; collapse those to the
  // day-level record, whose `hourly` rollup still carries the true per-hour
  // court counts.
  let namedCourts = day.courts->Option.getOr([])->Array.filter(c => c.name->Option.isSome)

  switch namedCourts {
  | [] =>
    if day.intervals->Array.length == 0 {
      []
    } else {
      [
        {
          TimeWindow.id: day.id,
          location,
          courtName: None,
          hourlyStats: day.hourly->Array.map((h): TimeWindow.hourStat => {
            hour: h.hour,
            indoorCount: h.indoorCount,
            outdoorCount: h.outdoorCount,
            priceMin: h.priceMin,
            priceMax: h.priceMax,
          }),
          intents: day.intervals->Array.mapWithIndex((interval, i): TimeWindow.playIntent => {
            id: i,
            start: interval.startHour->Float.fromInt,
            end: interval.endHour->Float.fromInt,
          }),
        },
      ]
    }
  | courts =>
    courts->Array.mapWithIndex((court, index): TimeWindow.courtAvailability => {
      let intents = court.intervals->Array.mapWithIndex((interval, i): TimeWindow.playIntent => {
        id: i,
        start: interval.startHour->Float.fromInt,
        end: interval.endHour->Float.fromInt,
      })
      let surfaceCounts = switch court.courtType {
      | Some(Indoor) => Some((1, 0))
      | Some(Outdoor) => Some((0, 1))
      | Some(FutureAddedValue(_)) | None => None
      }
      let hourlyStats = switch surfaceCounts {
      | None => []
      | Some((indoorCount, outdoorCount)) =>
        court.intervals->Array.flatMap(interval =>
          Belt.Array.range(interval.startHour, interval.endHour - 1)->Array.map(
            (hour): TimeWindow.hourStat => {
              hour,
              indoorCount,
              outdoorCount,
              priceMin: court.price,
              priceMax: court.price,
            },
          )
        )
      }
      {
        // Courts are identified by name within a venue-day; fall back to the
        // index so unnamed courts still merge as distinct records.
        id: locationId ++ ":" ++ court.name->Option.getOr(Int.toString(index)),
        location,
        courtName: court.name,
        hourlyStats,
        intents,
      }
    })
  }
}

let shiftHours = (date: Date.t, hours: float): Date.t =>
  Date.fromTime(date->Date.getTime +. hours *. 3600000.0)

// The full input for `updateEvent`, which replaces the event rather than
// patching it: the event as it stands, with the given overrides. Every write
// must carry every current field — updateEvent unsets Smart RSVP when the
// threshold is absent — so this is the one place that spells them out. None
// when the event lacks something CreateEventInput requires.
let updateInput = (
  event: EventLocationAvailability_event_graphql.Types.fragment,
  ~startDate: option<Util.Datetime.t>=?,
  ~endDate: option<Util.Datetime.t>=?,
  ~locationId: option<string>=?,
  ~details: option<string>=?,
): option<RelaySchemaAssets_graphql.input_CreateEventInput> =>
  switch (event.activity, event.location, event.title, event.startDate, event.endDate) {
  | (Some(activity), Some(location), Some(title), Some(currentStart), Some(currentEnd)) =>
    Some({
      activity: activity.id,
      locationId: locationId->Option.getOr(location.id),
      title,
      startDate: startDate->Option.getOr(currentStart),
      endDate: endDate->Option.getOr(currentEnd),
      clubId: ?event.club->Option.map(c => c.id),
      details: ?details->Option.orElse(event.details),
      listed: ?event.listed,
      maxRsvps: ?event.maxRsvps,
      minRating: ?event.minRating,
      price: ?event.price,
      cancelDeadline: ?event.cancelDeadline,
      smartRsvpThreshold: ?event.smartRsvpThreshold,
      tags: ?event.tags,
      timezone: ?event.timezone,
    })
  | _ => None
  }

// Everything the panel derives from the fragment, or None when the event has
// no dates or the resolver returned no availability (which is what viewers
// who aren't organizers get).
type resolved = {
  startAt: Date.t,
  endAt: Date.t,
  tz: string,
  eventWindow: TimeWindow.playIntent,
  venue: string,
  currentLocationCourts: array<TimeWindow.courtAvailability>,
  alternateTimeSlots: array<TimeWindow.alternateCourtTimeSlot>,
  alternateLocationCourts: array<TimeWindow.courtAvailability>,
}

let resolve = (
  event: EventLocationAvailability_event_graphql.Types.fragment,
  ~genericCourtName: string,
): option<resolved> => {
  let tz = event.timezone->Option.getOr("Asia/Tokyo")
  switch (event.startDate, event.endDate) {
  | (Some(startDate), Some(endDate)) if event.courtAvailability->Array.length > 0 =>
    let startAt = startDate->Util.Datetime.toDate
    let endAt = endDate->Util.Datetime.toDate
    let startHour = TimeWindow.hourInTimeZone(startAt, tz)
    let rawEndHour = TimeWindow.hourInTimeZone(endAt, tz)
    // An event running past midnight reads as an earlier hour in the venue's
    // zone; keep the window monotonic so it can be matched against openings.
    let endHour = rawEndHour <= startHour ? rawEndHour +. 24.0 : rawEndHour
    let eventWindow: TimeWindow.playIntent = {id: 0, start: startHour, end: endHour}

    // `courtAvailability` is the event's own venue (whole day) followed by
    // nearby venues free for exactly the event's hours. Split the two by venue
    // id — except the resolver currently returns `location: null` for some
    // rows, and the schema documents the own venue as the leading entry, so an
    // unlabelled first row is taken as the event's own venue. Unlabelled rows
    // after the first are dropped: we can neither name them nor move onto them.
    let eventVenueId = event.location->Option.map(l => l.id)
    let indexed = event.courtAvailability->Array.mapWithIndex((day, i) => (day, i))
    let isOwnVenue = ((
      day: EventLocationAvailability_event_graphql.Types.fragment_courtAvailability,
      i,
    )) =>
      switch (day.location->Option.map(l => l.id), eventVenueId) {
      | (Some(dayVenue), Some(ownVenue)) => dayVenue == ownVenue
      | (None, _) => i == 0
      | _ => false
      }
    let ownDays = indexed->Array.filter(isOwnVenue)->Array.map(((day, _)) => day)
    let nearbyDays =
      indexed
      ->Array.filter(((day, i)) => !isOwnVenue((day, i)) && day.location->Option.isSome)
      ->Array.map(((day, _)) => day)

    let venue =
      ownDays
      ->Array.get(0)
      ->Option.flatMap(d => d.location)
      ->Option.flatMap(l => l.name)
      ->Option.getOr(genericCourtName)

    let ownCourts = ownDays->Array.flatMap(day => courtsFromDay(day, ~genericCourtName))
    // Clipped to the event's own hours: these cards sit under a heading stating
    // that window, so they should print it and summarise courts over it rather
    // than over the venue's whole opening.
    let currentLocationCourts =
      TimeWindow.filterCourtAvailabilityByFullWindow(
        ownCourts,
        [eventWindow],
      )->TimeWindow.clipCourtAvailabilityTo(eventWindow)
    let alternateTimeSlots = TimeWindow.findAlternateCourtTimeSlots(ownCourts, ~eventWindow)
    // The server already restricts nearby venues to the event's exact hours;
    // re-filtering keeps the card list honest if that ever loosens.
    let alternateLocationCourts =
      TimeWindow.filterCourtAvailabilityByFullWindow(
        nearbyDays->Array.flatMap(day => courtsFromDay(day, ~genericCourtName)),
        [eventWindow],
      )->TimeWindow.clipCourtAvailabilityTo(eventWindow)
    Some({
      startAt,
      endAt,
      tz,
      eventWindow,
      venue,
      currentLocationCourts,
      alternateTimeSlots,
      alternateLocationCourts,
    })
  | _ => None
  }
}

// Whether a court at the event's own venue covers its full window. None when
// there's no availability data to judge from, so callers can hide the badge
// rather than show a false "not available".
let isAvailableAtEventTime = (
  event: EventLocationAvailability_event_graphql.Types.fragment,
  ~genericCourtName: string,
): option<bool> =>
  resolve(event, ~genericCourtName)->Option.map(r => r.currentLocationCourts->Array.length > 0)

@react.component
let make = (
  ~event: RescriptRelay.fragmentRefs<[> #EventLocationAvailability_event]>,
  ~genericCourtName: string,
) => {
  let event = Fragment.use(event)
  let intl = ReactIntl.useIntl()
  let fmt = h => TimeWindow.hourLabelIntl(intl, h)
  let (expanded, setExpanded) = React.useState(() => false)
  // Moving an event reschedules everyone who already RSVP'd, so the apply
  // action takes a second click to confirm.
  let (pendingSlot, setPendingSlot) = React.useState(() => None)
  let (updateEvent, updating) = UpdateMutation.use()

  switch resolve(event, ~genericCourtName) {
  | None => React.null
  | Some({
      startAt,
      endAt,
      tz,
      eventWindow,
      venue,
      currentLocationCourts,
      alternateTimeSlots,
      alternateLocationCourts,
    }) =>
    let isAvailable = currentLocationCourts->Array.length > 0
    let statusLabel = isAvailable ? ts`Available` : ts`Not available`

    // Moving the event: `startShift` slides it within the day, `venueId`
    // re-homes it. "Other times" shifts only; "other locations" swaps venue at
    // the same hour. Nearby courts always carry a resolved venue id (rows
    // without one are dropped above), so this can never write an availability
    // id into locationId.
    let applyOption = (~startShift: float, ~venueId: option<string>) =>
      updateInput(
        event,
        ~startDate=startAt->shiftHours(startShift)->Util.Datetime.fromDate,
        ~endDate=endAt->shiftHours(startShift)->Util.Datetime.fromDate,
        ~locationId=?venueId,
      )->Option.forEach(input =>
        updateEvent(~variables={eventId: event.id, input}, ~onCompleted=(_, _) =>
          setPendingSlot(_ => None)
        )->RescriptRelay.Disposable.ignore
      )

    // The apply action rewrites the event, so it needs everything
    // CreateEventInput requires. Without it the openings stay read-only.
    let canApply = updateInput(event)->Option.isSome

    // Confirmation is keyed per option, so arming one card and then clicking a
    // different one re-arms rather than firing the wrong move.
    let slotKey = (slot: TimeWindow.alternateCourtTimeSlot) =>
      "time:" ++ slot.start->Float.toString ++ "-" ++ slot.end->Float.toString
    let venueKey = (court: TimeWindow.courtAvailability) => "venue:" ++ court.id

    let sectionHeading = label =>
      <p
        className="px-0.5 font-mono text-[9px] font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
        {label->React.string}
      </p>

    <section
      className={Util.cx([
        "mt-3 overflow-hidden rounded-md border",
        isAvailable
          ? "border-emerald-200 bg-emerald-50/60 dark:border-emerald-800/50 dark:bg-emerald-950/15"
          : "border-amber-200 bg-amber-50/60 dark:border-amber-800/50 dark:bg-amber-950/15",
      ])}>
      <button
        type_="button"
        onClick={_ => setExpanded(v => !v)}
        className="flex w-full items-center justify-between gap-3 px-3 py-2.5 text-left transition-colors hover:bg-black/[0.025] focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cyan-500 dark:hover:bg-white/[0.035]"
        ariaExpanded=expanded>
        <span className="flex min-w-0 items-center gap-2.5">
          <span
            className={Util.cx([
              "flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full",
              isAvailable
                ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/50 dark:text-emerald-300"
                : "bg-amber-100 text-amber-700 dark:bg-amber-900/50 dark:text-amber-300",
            ])}>
            {isAvailable
              ? <Lucide.CheckCircle2 size=14 strokeWidth=2.25 \"aria-hidden"="true" />
              : <Lucide.XCircle size=14 strokeWidth=2.25 \"aria-hidden"="true" />}
          </span>
          <span className="min-w-0">
            <span className="flex flex-wrap items-center gap-1.5">
              <span className="text-xs font-semibold text-gray-900 dark:text-gray-100">
                {(ts`Courts`)->React.string}
              </span>
              <span
                className={Util.cx([
                  "font-mono text-[9px] font-semibold uppercase tracking-wide",
                  isAvailable
                    ? "text-emerald-700 dark:text-emerald-300"
                    : "text-amber-700 dark:text-amber-300",
                ])}>
                {statusLabel->React.string}
              </span>
            </span>
            <span
              className="mt-0.5 flex items-center gap-1 font-mono text-[9px] text-gray-500 dark:text-gray-400">
              <Lucide.Clock3 size=10 \"aria-hidden"="true" />
              <ReactIntl.FormattedDate
                weekday=#short day=#"2-digit" month=#short value=startAt timeZone=tz
              />
              {(" · " ++ fmt(eventWindow.start) ++ "–" ++ fmt(eventWindow.end))->React.string}
            </span>
          </span>
        </span>
        <Lucide.ChevronDown
          size=15
          className={`flex-shrink-0 text-gray-400 transition-transform ${expanded
              ? "rotate-180"
              : ""}`}
          \"aria-hidden"="true"
        />
      </button>
      {expanded
        ? <FramerMotion.Div
            className="overflow-hidden"
            initial={{FramerMotion.height: "0px", opacity: 0.}}
            animate={{FramerMotion.height: "auto", opacity: 1.}}
            exit={{FramerMotion.height: "0px", opacity: 0.}}
            transition={{FramerMotion.duration: 0.18}}>
            <div
              className="space-y-3 border-t border-black/[0.06] bg-white/70 p-2.5 dark:border-white/[0.07] dark:bg-[#222326]/70">
              {isAvailable
                ? <div className="space-y-1.5">
                    {sectionHeading(ts`At ${venue} now`)}
                    <CourtAvailabilityGroups
                      courtAvailability=currentLocationCourts contentOnly=true countBasis=#sustained
                    />
                  </div>
                : <div
                    className="flex items-start gap-2 rounded-md border border-amber-200 bg-amber-50/70 px-2.5 py-2 dark:border-amber-800/50 dark:bg-amber-950/20">
                    <Lucide.AlertCircle
                      size=12
                      className="mt-0.5 flex-shrink-0 text-amber-600 dark:text-amber-400"
                      \"aria-hidden"="true"
                    />
                    <p className="text-[10px] leading-snug text-amber-800 dark:text-amber-300">
                      {(ts`No court at ${venue} covers the full event window.`)->React.string}
                    </p>
                  </div>}
              {alternateTimeSlots->Array.length > 0
                ? <div className="space-y-2">
                    {sectionHeading(ts`Other times at ${venue}`)}
                    {alternateTimeSlots
                    ->Array.map(slot => {
                      let key = slotKey(slot)
                      let isPending = pendingSlot == Some(key)
                      <article
                        key
                        className="space-y-2 rounded-md border border-cyan-200 bg-cyan-50/50 p-2.5 dark:border-cyan-800/50 dark:bg-cyan-950/15">
                        <p
                          className="font-mono text-xs font-semibold text-gray-900 dark:text-gray-100">
                          {(fmt(slot.start) ++ "–" ++ fmt(slot.end))->React.string}
                        </p>
                        {isPending
                          ? <p
                              className="text-[10px] leading-snug text-amber-800 dark:text-amber-300">
                              {(
                                ts`This reschedules everyone who already RSVP'd. Tap again to confirm.`
                              )->React.string}
                            </p>
                          : React.null}
                        <CourtAvailabilityGroups
                          courtAvailability={slot.courtAvailability}
                          contentOnly=true
                          countBasis=#sustained
                          onSelectCourt=?{canApply && !updating
                            ? Some(
                                _ =>
                                  isPending
                                    ? applyOption(
                                        ~startShift=slot.start -. eventWindow.start,
                                        ~venueId=None,
                                      )
                                    : setPendingSlot(_ => Some(key)),
                              )
                            : None}
                          selectLabel={_ => isPending ? ts`Confirm move` : ts`Use time`}
                        />
                      </article>
                    })
                    ->React.array}
                  </div>
                : !isAvailable
                ? <p className="px-0.5 text-[10px] text-gray-500 dark:text-gray-400">
                  {(
                    ts`No other same-day time at ${venue} supports the full event duration.`
                  )->React.string}
                </p>
                : React.null}
              /* Nearby venues free for exactly the event's hours. The server
                 doesn't return other-venue *other-times*, so the design's
                 fourth section ("other locations and times") has no source and
                 is intentionally absent. */
              {alternateLocationCourts->Array.length > 0
                ? <div className="space-y-1.5">
                    {sectionHeading(ts`Other locations at this time`)}
                    {alternateLocationCourts->Array.some(c => pendingSlot == Some(venueKey(c)))
                      ? <p
                          className="px-0.5 text-[10px] leading-snug text-amber-800 dark:text-amber-300">
                          {(
                            ts`This moves the event to another venue and reschedules everyone who already RSVP'd. Tap again to confirm.`
                          )->React.string}
                        </p>
                      : React.null}
                    <CourtAvailabilityGroups
                      courtAvailability=alternateLocationCourts
                      contentOnly=true
                      countBasis=#sustained
                      onSelectCourt=?{canApply && !updating
                        ? Some(
                            court =>
                              pendingSlot == Some(venueKey(court))
                                ? applyOption(~startShift=0.0, ~venueId=Some(court.location.id))
                                : setPendingSlot(_ => Some(venueKey(court))),
                          )
                        : None}
                      selectLabel={court =>
                        pendingSlot == Some(venueKey(court)) ? ts`Confirm move` : ts`Use location`}
                    />
                  </div>
                : !isAvailable
                ? <p
                  className="flex items-center gap-1.5 px-0.5 py-1 text-[10px] text-gray-400 dark:text-gray-500">
                  <Lucide.MapPin size=11 \"aria-hidden"="true" />
                  {(
                    ts`No other nearby venue has a court free for the event's hours.`
                  )->React.string}
                </p>
                : React.null}
            </div>
          </FramerMotion.Div>
        : React.null}
    </section>
  }
}
