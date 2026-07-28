// Shared time-window domain model — the data types + pure functions that the
// availability picker, grids, feed, and summary all build on. Kept UI-free (no
// React components) so any of them can depend on it without pulling in the
// picker, and so a shared band-overlay component can import it without a cycle.

// A half-open interval [start, end) in hours (e.g. { start: 19., end: 22. }).
type playIntent = {
  id: int,
  start: float,
  end: float,
}

// Court availability uses the same day/time windows as player availability,
// but belongs to a Location (venue) rather than a User. Courts are kept
// separate from player demand so they never affect player counts or avatars.
type courtLocation = {
  id: string,
  name: string,
  reservationUrl: option<string>,
}

// Per-open-hour rollup for a location's courts (from the backend `hourly`
// field): how many indoor/outdoor courts are free that hour, and the
// cheapest/dearest booking price (in yen) among them.
type hourStat = {
  hour: int,
  indoorCount: int,
  outdoorCount: int,
  priceMin: option<int>,
  priceMax: option<int>,
}

type courtAvailability = {
  id: string,
  location: courtLocation,
  courtName: option<string>,
  // Per-hour indoor/outdoor + price rollup, only for hours with an open court.
  hourlyStats: array<hourStat>,
  intents: array<playIntent>,
}

// A same-day fallback window, with only the courts that cover it end to end.
// Used when the courts at a venue can't cover an event's own time window.
type alternateCourtTimeSlot = {
  start: float,
  end: float,
  courtAvailability: array<courtAvailability>,
}

// Aggregated court metrics over a time range — used for pseudo-event summaries
// and the overlay's intensity. Counts are the peak concurrent courts within the
// range; the price span covers the whole range.
type courtAvailabilitySummary = {
  courtCount: int,
  indoorCount: int,
  outdoorCount: int,
  priceLow: option<int>,
  priceHigh: option<int>,
}

type courtSlot = {
  court: courtAvailability,
  intent: playIntent,
}

type courtSlotGroup = {
  key: string,
  start: float,
  end: float,
  slots: array<courtSlot>,
}

// A contiguous run of availability (no time gaps), holding the exact
// active-court segments nested inside it. Renders as one continuous outline
// with internal dividers between segments.
type courtAvailabilityBand = {
  key: string,
  start: float,
  end: float,
  segments: array<courtSlotGroup>,
}

// A contiguous run of pseudo-event bands, collapsed into one feed-sized group.
// The original bands are kept so the group can expand back into interactive
// slot rows.
type courtPseudoEventGroup = {
  key: string,
  start: float,
  end: float,
  bands: array<courtAvailabilityBand>,
}

// Location doesn't expose a booking-page URL yet; fall back to the ONE Court
// reservation page until it does.
let defaultReservationUrl = "https://reserva.be/pboneginza"

// Merge touching or overlapping windows into the largest contiguous spans.
let mergeContiguousTimeWindows = (windows: array<playIntent>): array<playIntent> => {
  let sorted =
    windows
    ->Array.filter(w => w.end > w.start)
    ->Array.toSorted((a, b) =>
      if a.start != b.start {
        a.start -. b.start
      } else {
        a.end -. b.end
      }
    )
  let merged: array<playIntent> = []
  sorted->Array.forEach(window => {
    let lastIdx = merged->Array.length - 1
    switch merged->Array.get(lastIdx) {
    | Some(previous) if window.start <= previous.end =>
      merged->Array.set(lastIdx, {...previous, end: Js.Math.max_float(previous.end, window.end)})
    | _ => merged->Array.push(window)
    }
  })
  merged
}

// Consolidate duplicate court records (same court id) and merge each court's
// adjacent openings so every court carries its largest continuous openings.
let mergeCourtAvailabilityByCourt = (courtAvailability: array<courtAvailability>): array<
  courtAvailability,
> => {
  let byCourt: Js.Dict.t<courtAvailability> = Js.Dict.empty()
  let order: array<string> = []
  courtAvailability->Array.forEach(court =>
    switch byCourt->Js.Dict.get(court.id) {
    | Some(existing) =>
      byCourt->Js.Dict.set(
        court.id,
        {...existing, intents: Belt.Array.concat(existing.intents, court.intents)},
      )
    | None =>
      order->Array.push(court.id)
      byCourt->Js.Dict.set(court.id, court)
    }
  )
  order->Array.filterMap(id =>
    byCourt
    ->Js.Dict.get(id)
    ->Option.map(court => {...court, intents: mergeContiguousTimeWindows(court.intents)})
  )
}

// How to collapse the per-hour court counts across a range.
//
//   #peak      — most courts free at any single hour. Right for browsing, where
//                the question is "how big is this venue".
//   #sustained — fewest free at any hour in the range, i.e. how many courts are
//                free for the WHOLE range. Right for booking, where a court
//                that frees up halfway through can't take your session.
//
// They differ whenever a range spans a partially-booked hour: a venue with four
// courts free all afternoon except one hour with three reads as "4 courts" at
// #peak and "3 courts" at #sustained.
type courtCountBasis = [#peak | #sustained]

// Aggregate court metrics over the hour range [fromHour, toHour), reading each
// location's per-hour rollup. Records are de-duplicated by id so a court
// counted in multiple segments isn't double-counted. `basis` picks how the
// per-hour counts collapse (see above); the price span always covers every open
// hour in the range. Defaults to the whole day, counted at peak.
let summarizeCourtAvailability = (
  ~fromHour: int=0,
  ~toHour: int=24,
  ~basis: courtCountBasis=#peak,
  availability: array<courtAvailability>,
): courtAvailabilitySummary => {
  let seen: Js.Dict.t<bool> = Js.Dict.empty()
  let unique: array<courtAvailability> = []
  availability->Array.forEach(item =>
    switch seen->Js.Dict.get(item.id) {
    | Some(_) => ()
    | None =>
      seen->Js.Dict.set(item.id, true)
      unique->Array.push(item)
    }
  )

  // Per-hour totals, collapsed once the whole range is walked. Kept as a list
  // rather than folded inline so #peak and #sustained share one traversal.
  let hourlyTotals: array<(int, int, int)> = []
  let priceLow = ref(None)
  let priceHigh = ref(None)
  let considerPrice = p =>
    switch p {
    | None => ()
    | Some(v) =>
      priceLow :=
        Some(
          switch priceLow.contents {
          | None => v
          | Some(cur) => Js.Math.min_int(cur, v)
          },
        )
      priceHigh :=
        Some(
          switch priceHigh.contents {
          | None => v
          | Some(cur) => Js.Math.max_int(cur, v)
          },
        )
    }

  for hour in fromHour to toHour - 1 {
    let hourF = hour->Float.fromInt
    let hIndoor = ref(0)
    let hOutdoor = ref(0)
    let hUntyped = ref(0)
    unique->Array.forEach(item =>
      if item.hourlyStats->Array.length == 0 {
        // Un-enriched record (the scraper exposed no per-court breakdown):
        // count it as one open court while an opening covers this hour, so it
        // never reads as "0 courts". No surface/price contribution.
        if item.intents->Array.some(iv => iv.start <= hourF && hourF < iv.end) {
          hUntyped := hUntyped.contents + 1
        }
      } else {
        switch item.hourlyStats->Array.find(s => s.hour == hour) {
        | None => ()
        | Some(s) =>
          hIndoor := hIndoor.contents + s.indoorCount
          hOutdoor := hOutdoor.contents + s.outdoorCount
          considerPrice(s.priceMin)
          considerPrice(s.priceMax)
        }
      }
    )
    hourlyTotals->Array.push((
      hIndoor.contents + hOutdoor.contents + hUntyped.contents,
      hIndoor.contents,
      hOutdoor.contents,
    ))
  }

  // #peak keeps the previous behaviour exactly: max over hours, floored at 0 so
  // an empty range reads as no courts. #sustained takes the min over hours, so
  // an hour with nothing open correctly drags the whole range to zero — you
  // cannot book across a gap.
  let collapse = (get: ((int, int, int)) => int) =>
    switch basis {
    | #peak => hourlyTotals->Array.reduce(0, (acc, h) => Js.Math.max_int(acc, get(h)))
    | #sustained =>
      hourlyTotals
      ->Array.reduce(None, (acc, h) =>
        switch acc {
        | None => Some(get(h))
        | Some(cur) => Some(Js.Math.min_int(cur, get(h)))
        }
      )
      ->Option.getOr(0)
    }
  {
    courtCount: collapse(((total, _, _)) => total),
    indoorCount: collapse(((_, indoor, _)) => indoor),
    outdoorCount: collapse(((_, _, outdoor)) => outdoor),
    priceLow: priceLow.contents,
    priceHigh: priceHigh.contents,
  }
}

// Display strings for the summary (surface mix, price range, durations) are
// assembled by CourtLabels from render-scoped lingui templates — this module
// stays i18n-free.

// ─── Time-of-day formatting ────────────────────────────────────────────────

// Hour-of-day as a float (19.5 = 19:30) for an instant in a given IANA zone.
// Court openings arrive as venue-local hours, so an event's instants have to be
// projected into the venue's zone before the two can be compared.
let hourInTimeZone: (Date.t, string) => float = %raw(`
  function (date, timeZone) {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone,
      hourCycle: "h23",
      hour: "2-digit",
      minute: "2-digit",
    }).formatToParts(date);
    const at = (type) => {
      const part = parts.find((p) => p.type === type);
      return part ? Number(part.value) : 0;
    };
    return at("hour") + at("minute") / 60;
  }
`)

let hourLabel = (h: float): string => {
  let hh = Js.Math.floor_int(h)
  let mm = Js.Math.round((h -. Float.fromInt(hh)) *. 60.0)->Float.toInt
  hh->Int.toString->String.padStart(2, "0") ++ ":" ++ mm->Int.toString->String.padStart(2, "0")
}

// Locale-aware time-of-day label, mirroring TimeRangeChip so court times read
// the same as the user's own availability chips (e.g. "7 PM" / "19:00" / "19時"
// per locale). Minutes are shown only when the value isn't a whole hour.
let hourLabelIntl = (intl: ReactIntl.Intl.t, h: float): string => {
  let minutes = (h -. Js.Math.floor_float(h)) *. 60.0
  intl->ReactIntl.Intl.formatTimeWithOptions(
    Js.Date.makeWithYMDHMS(~year=2000., ~month=0., ~date=1., ~hours=h, ~minutes, ~seconds=0., ()),
    minutes == 0.0
      ? ReactIntl.dateTimeFormatOptions(~hour=#numeric, ())
      : ReactIntl.dateTimeFormatOptions(~hour=#numeric, ~minute=#"2-digit", ()),
  )
}

// ─── Court availability grouping ───────────────────────────────────────────

// Split availability at every start/end boundary so each display window lists
// only the courts available for that entire span (within a segment, an
// overlapping opening necessarily covers the whole segment). Neighboring
// segments merge only when their active court sets are identical.
let groupCourtAvailabilityByTime = (courtAvailability: array<courtAvailability>): array<
  courtSlotGroup,
> => {
  let slots =
    mergeCourtAvailabilityByCourt(courtAvailability)
    ->Array.flatMap(court =>
      court.intents
      ->Array.filter(intent => intent.end > intent.start)
      ->Array.map(intent => {court, intent})
    )
    ->Array.toSorted((a, b) => {
      let byCourt = String.localeCompare(a.court.id, b.court.id)
      if byCourt != 0.0 {
        byCourt
      } else if a.intent.start != b.intent.start {
        a.intent.start -. b.intent.start
      } else if a.intent.end != b.intent.end {
        a.intent.end -. b.intent.end
      } else {
        Float.fromInt(a.intent.id - b.intent.id)
      }
    })

  // Unique, ascending boundary points (every opening's start and end).
  let sortedPoints =
    slots->Array.flatMap(s => [s.intent.start, s.intent.end])->Array.toSorted((a, b) => a -. b)
  let boundaries: array<float> = []
  sortedPoints->Array.forEach(p =>
    switch boundaries->Array.get(boundaries->Array.length - 1) {
    | Some(last) if last == p => ()
    | _ => boundaries->Array.push(p)
    }
  )

  let signatureOf = (segSlots: array<courtSlot>) =>
    segSlots->Array.map(s => s.court.id)->Array.join("|")

  let groups: array<courtSlotGroup> = []
  for i in 0 to boundaries->Array.length - 2 {
    let start = boundaries->Array.getUnsafe(i)
    let end = boundaries->Array.getUnsafe(i + 1)

    // Courts active for the entire [start, end) segment, one slot per court
    // (first in sort order wins), with the intent clamped to the segment.
    let activeSlots: array<courtSlot> = []
    let seen = Js.Dict.empty()
    slots->Array.forEach(slot =>
      if slot.intent.start < end && slot.intent.end > start {
        switch seen->Js.Dict.get(slot.court.id) {
        | Some(_) => ()
        | None =>
          seen->Js.Dict.set(slot.court.id, true)
          activeSlots->Array.push({court: slot.court, intent: {...slot.intent, start, end}})
        }
      }
    )

    if activeSlots->Array.length > 0 {
      let signature = signatureOf(activeSlots)
      let lastIdx = groups->Array.length - 1
      switch groups->Array.get(lastIdx) {
      // Extend the previous window when it's adjacent and its court set matches.
      | Some(previous) if previous.end == start && signatureOf(previous.slots) == signature =>
        groups->Array.set(
          lastIdx,
          {
            ...previous,
            end,
            key: previous.start->Float.toString ++ ":" ++ end->Float.toString ++ ":" ++ signature,
            slots: previous.slots->Array.map(s => {...s, intent: {...s.intent, end}}),
          },
        )
      | _ =>
        groups->Array.push({
          key: start->Float.toString ++ ":" ++ end->Float.toString ++ ":" ++ signature,
          start,
          end,
          slots: activeSlots,
        })
      }
    }
  }

  groups
}

// Preserve visual continuity whenever at least one court stays available: merge
// time-adjacent segments into a band while keeping the exact active-court
// segments nested for per-segment counts and actions.
let groupCourtAvailabilityIntoBands = (courtAvailability: array<courtAvailability>): array<
  courtAvailabilityBand,
> => {
  let segments = groupCourtAvailabilityByTime(courtAvailability)
  let bands: array<courtAvailabilityBand> = []
  segments->Array.forEach(segment => {
    let lastIdx = bands->Array.length - 1
    switch bands->Array.get(lastIdx) {
    | Some(previous) if previous.end == segment.start =>
      bands->Array.set(
        lastIdx,
        {
          ...previous,
          end: segment.end,
          key: previous.start->Float.toString ++ ":" ++ segment.end->Float.toString,
          segments: Belt.Array.concat(previous.segments, [segment]),
        },
      )
    | _ =>
      bands->Array.push({
        key: segment.start->Float.toString ++ ":" ++ segment.end->Float.toString,
        start: segment.start,
        end: segment.end,
        segments: [segment],
      })
    }
  })
  bands
}

// Booking-sized slot length (hours) for the discover-feed pseudo-events.
// Discover-feed pseudo-events: one band per location per LARGEST contiguous
// opening (adjacent openings merged first via mergeCourtAvailabilityByCourt).
// A single location's contiguous opening is never split into smaller slots; a
// court open 2–3 and another open 2–4 surface as two separate rows (2–3 and
// 2–4), ordered by start and possibly overlapping in time.
let groupCourtAvailabilityIntoPseudoEventBands = (courtAvailability: array<courtAvailability>): array<
  courtAvailabilityBand,
> =>
  mergeCourtAvailabilityByCourt(courtAvailability)
  ->Array.flatMap(court =>
    court.intents
    ->Array.filter(intent => intent.end > intent.start)
    ->Array.map(intent => {
      let key =
        court.id ++ ":" ++ intent.start->Float.toString ++ ":" ++ intent.end->Float.toString
      {
        key,
        start: intent.start,
        end: intent.end,
        segments: [{key, start: intent.start, end: intent.end, slots: [{court, intent}]}],
      }
    })
  )
  ->Array.toSorted((a, b) =>
    if a.start != b.start {
      a.start -. b.start
    } else {
      a.end -. b.end
    }
  )

// Collapse time-adjacent pseudo-event slots into feed-sized groups. The
// original bands stay nested so a group can expand back into interactive rows.
let groupContiguousPseudoEventBands = (bands: array<courtAvailabilityBand>): array<
  courtPseudoEventGroup,
> => {
  let sorted = bands->Array.toSorted((a, b) => a.start -. b.start)
  let groups: array<courtPseudoEventGroup> = []
  sorted->Array.forEach(band => {
    let lastIdx = groups->Array.length - 1
    switch groups->Array.get(lastIdx) {
    // Touching OR overlapping extends the group (per-location bands can
    // overlap in time), so a group spans a maximal continuous run.
    | Some(previous) if band.start <= previous.end =>
      let end = Js.Math.max_float(previous.end, band.end)
      groups->Array.set(
        lastIdx,
        {
          ...previous,
          end,
          key: previous.start->Float.toString ++ ":" ++ end->Float.toString,
          bands: Belt.Array.concat(previous.bands, [band]),
        },
      )
    | _ =>
      groups->Array.push({
        key: band.start->Float.toString ++ ":" ++ band.end->Float.toString,
        start: band.start,
        end: band.end,
        bands: [band],
      })
    }
  })
  groups
}

// Keep a court only when one of its merged contiguous openings covers a user
// window from start to end. The full qualifying opening is retained for
// court-first display.
let filterCourtAvailabilityByFullWindow = (
  courtAvailability: array<courtAvailability>,
  userAvailability: array<playIntent>,
): array<courtAvailability> => {
  let validUserWindows = userAvailability->Array.filter(w => w.end > w.start)
  if validUserWindows->Array.length == 0 {
    []
  } else {
    mergeCourtAvailabilityByCourt(courtAvailability)
    ->Array.map(court => {
      ...court,
      intents: court.intents->Array.filter(
        courtWindow =>
          validUserWindows->Array.some(
            userWindow =>
              courtWindow.start <= userWindow.start && courtWindow.end >= userWindow.end,
          ),
      ),
    })
    ->Array.filter(court => court.intents->Array.length > 0)
  }
}

// Narrow each court's openings to exactly `window`. Surfaces that render cards
// under a heading naming one specific window want the card to describe that
// window — both the hours it prints and the range its court/price summary is
// computed over. Court-first browsing, which shows a court's whole opening,
// should keep using the unclipped result.
let clipCourtAvailabilityTo = (
  courts: array<courtAvailability>,
  window: playIntent,
): array<courtAvailability> => courts->Array.map(court => {...court, intents: [window]})

// Same-day fallback start times for a fixed duration, over the courts supplied
// (callers scope these to one venue). Slides the duration across every court
// opening one whole hour at a time, keeps the starts where at least one court
// covers the window end to end, and orders them by proximity to the reference
// window so the nearest alternatives come first.
//
// Starts are whole hours because that's the only thing the data can express:
// `AvailabilityInterval.startHour`/`endHour` are integers, so a court can never
// open at half past. Sliding on a 30-minute grid would invent unbookable slots
// (a 14:30 event yielding a "13:30" alternative at a venue that only sells
// hours). The duration is preserved as-is, so a fractional-length event keeps
// its fractional end.
let findAlternateCourtTimeSlots = (
  courtAvailability: array<courtAvailability>,
  ~eventWindow: playIntent,
  ~limit: int=3,
): array<alternateCourtTimeSlot> => {
  let duration = eventWindow.end -. eventWindow.start
  if duration <= 0.0 || limit <= 0 {
    []
  } else {
    // Guard the candidate edges against binary drift so dictionary keys stay
    // stable across the accumulating slide.
    let round4 = v => Js.Math.round(v *. 10000.0) /. 10000.0
    let courts = mergeCourtAvailabilityByCourt(courtAvailability)
    let candidates: Js.Dict.t<playIntent> = Js.Dict.empty()
    let order: array<string> = []
    let addCandidate = rawStart => {
      let start = round4(rawStart)
      let end = round4(start +. duration)
      // The event's own window is the baseline, not an alternative to it.
      if !(start == eventWindow.start && end == eventWindow.end) {
        let key = Float.toString(start) ++ ":" ++ Float.toString(end)
        switch candidates->Js.Dict.get(key) {
        | Some(_) => ()
        | None =>
          order->Array.push(key)
          candidates->Js.Dict.set(key, {id: 0, start, end})
        }
      }
    }
    courts->Array.forEach(court =>
      court.intents->Array.forEach(opening => {
        let maxStart = opening.end -. duration
        if maxStart >= opening.start {
          let firstStart = Js.Math.ceil_float(opening.start -. 0.0001)
          let lastStart = Js.Math.floor_float(maxStart +. 0.0001)
          let cursor = ref(firstStart)
          while cursor.contents <= lastStart +. 0.0001 {
            addCandidate(cursor.contents)
            cursor := cursor.contents +. 1.0
          }
        }
      })
    )
    order
    ->Array.filterMap(key => candidates->Js.Dict.get(key))
    ->Array.map((candidate): alternateCourtTimeSlot => {
      start: candidate.start,
      end: candidate.end,
      // `filterCourtAvailabilityByFullWindow` deliberately keeps the court's
      // whole qualifying opening, which is right for court-first browsing but
      // wrong here: these cards sit under a heading that names one candidate
      // window, so showing "09:00–19:00" under a "14:00–17:00" heading reads as
      // a contradiction, and the card's own summary would then count courts
      // across the whole opening instead of the slot. Narrow to the candidate.
      courtAvailability: filterCourtAvailabilityByFullWindow(
        courts,
        [candidate],
      )->clipCourtAvailabilityTo(candidate),
    })
    ->Array.filter(slot => slot.courtAvailability->Array.length > 0)
    ->Array.toSorted((a, b) => {
      let aDist = Js.Math.abs_float(a.start -. eventWindow.start)
      let bDist = Js.Math.abs_float(b.start -. eventWindow.start)
      if aDist != bDist {
        aDist -. bDist
      } else {
        a.start -. b.start
      }
    })
    ->Array.slice(~start=0, ~end=limit)
  }
}
