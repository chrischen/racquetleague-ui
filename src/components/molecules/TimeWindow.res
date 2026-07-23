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

// Aggregate court metrics over the hour range [fromHour, toHour), reading each
// location's per-hour rollup. Records are de-duplicated by id so a court
// counted in multiple segments isn't double-counted. Counts are the PEAK
// concurrent courts across the range (courts free at the busiest hour); the
// price span covers every open hour in the range. Defaults to the whole day.
let summarizeCourtAvailability = (
  ~fromHour: int=0,
  ~toHour: int=24,
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

  let courtCount = ref(0)
  let indoorCount = ref(0)
  let outdoorCount = ref(0)
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
    let hTotal = hIndoor.contents + hOutdoor.contents + hUntyped.contents
    if hTotal > courtCount.contents {
      courtCount := hTotal
    }
    if hIndoor.contents > indoorCount.contents {
      indoorCount := hIndoor.contents
    }
    if hOutdoor.contents > outdoorCount.contents {
      outdoorCount := hOutdoor.contents
    }
  }
  {
    courtCount: courtCount.contents,
    indoorCount: indoorCount.contents,
    outdoorCount: outdoorCount.contents,
    priceLow: priceLow.contents,
    priceHigh: priceHigh.contents,
  }
}

// Display strings for the summary (surface mix, price range, durations) are
// assembled by CourtLabels from render-scoped lingui templates — this module
// stays i18n-free.

// ─── Time-of-day formatting ────────────────────────────────────────────────

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
