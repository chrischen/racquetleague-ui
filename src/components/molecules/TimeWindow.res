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

type courtAvailability = {
  id: string,
  location: courtLocation,
  courtName: option<string>,
  intents: array<playIntent>,
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

// Court openings longer than this are venue open-hours, not a bookable play
// window, so they can't be matched to the user's availability in one tap.
let maxMatchableCourtHours = 4.0

// Location doesn't expose a booking-page URL yet; fall back to the ONE Court
// reservation page until it does.
let defaultReservationUrl = "https://reserva.be/pboneginza"

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
    courtAvailability
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

// Keep only the individual court openings that overlap at least one of the
// user's half-open availability windows. A court can carry multiple openings,
// so filtering happens at the intent level while preserving the court entity.
let filterCourtAvailabilityByOverlap = (
  courtAvailability: array<courtAvailability>,
  userAvailability: array<playIntent>,
): array<courtAvailability> =>
  if userAvailability->Array.length == 0 {
    []
  } else {
    courtAvailability
    ->Array.map(court => {
      ...court,
      intents: court.intents->Array.filter(
        courtWindow =>
          userAvailability->Array.some(
            userWindow =>
              courtWindow.start < userWindow.end && courtWindow.end > userWindow.start,
          ),
      ),
    })
    ->Array.filter(court => court.intents->Array.length > 0)
  }
