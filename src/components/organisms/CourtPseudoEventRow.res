%%raw("import { t, plural } from '@lingui/macro'")

// Renders one court-availability slot as an event-like row in the discover
// feed. There is no mini time-graph — the row is a header (span, court/location
// counts, and the viewer's own availability in this slot) that expands to:
//   1. a scoped availability editor (InlineMultiPicker clamped to the slot),
//      showing the player-demand heatmap for the slot,
//   2. the other players available in the slot,
//   3. each court in the slot with its continuous openings + reserve link.
// Saving edits the viewer's availability only within [band.start, band.end);
// the rest of the day's windows are preserved.

let ts = Lingui.UtilString.t

// A single other player's availability for this day (already scoped to the day
// by the caller); the row further clamps their intents to the slot window.
type slotPlayer = {
  id: string,
  name: string,
  initials: string,
  intents: array<TimeWindow.playIntent>,
}

type courtWithSpans = {
  court: TimeWindow.courtAvailability,
  spans: array<TimeWindow.playIntent>,
}

// Collect each court's windows across the band's segments, merge them into
// contiguous spans, and order courts by first span / location / court name.
let buildCourtsWithSpans = (band: TimeWindow.courtAvailabilityBand): array<courtWithSpans> => {
  let byCourt: Js.Dict.t<courtWithSpans> = Js.Dict.empty()
  let order: array<string> = []
  band.segments->Array.forEach(segment =>
    segment.slots->Array.forEach(slot =>
      switch byCourt->Js.Dict.get(slot.court.id) {
      | Some(existing) =>
        byCourt->Js.Dict.set(
          slot.court.id,
          {...existing, spans: Belt.Array.concat(existing.spans, [slot.intent])},
        )
      | None =>
        order->Array.push(slot.court.id)
        byCourt->Js.Dict.set(slot.court.id, {court: slot.court, spans: [slot.intent]})
      }
    )
  )
  order
  ->Array.filterMap(id =>
    byCourt
    ->Js.Dict.get(id)
    ->Option.map(c => {...c, spans: TimeWindow.mergeContiguousTimeWindows(c.spans)})
  )
  ->Array.toSorted((a, b) => {
    let aStart = a.spans->Array.get(0)->Option.map(s => s.start)->Option.getOr(0.0)
    let bStart = b.spans->Array.get(0)->Option.map(s => s.start)->Option.getOr(0.0)
    if aStart != bStart {
      aStart -. bStart
    } else {
      let byLocation = String.localeCompare(a.court.location.name, b.court.location.name)
      if byLocation != 0.0 {
        byLocation
      } else {
        String.localeCompare(
          a.court.courtName->Option.getOr(""),
          b.court.courtName->Option.getOr(""),
        )
      }
    }
  })
}

// Replace the viewer's availability that falls within [slotStart, slotEnd) with
// the slot draft, preserving (and trimming) any windows outside the slot, then
// merge touching windows so the day stays a clean set of spans.
let replaceAvailabilityInSlot = (
  availability: array<TimeWindow.playIntent>,
  slotDraft: array<TimeWindow.playIntent>,
  slotStart: float,
  slotEnd: float,
): array<TimeWindow.playIntent> => {
  let preserved = availability->Array.flatMap(intent =>
    if intent.end <= slotStart || intent.start >= slotEnd {
      [intent]
    } else {
      let fragments: array<TimeWindow.playIntent> = []
      if intent.start < slotStart {
        fragments->Array.push({...intent, end: slotStart})
      }
      if intent.end > slotEnd {
        fragments->Array.push({id: TimeWindowPicker.wid(), start: slotEnd, end: intent.end})
      }
      fragments
    }
  )
  let clampedDraft = slotDraft->Array.map((intent): TimeWindow.playIntent => {
    id: TimeWindowPicker.wid(),
    start: Js.Math.max_float(slotStart, intent.start),
    end: Js.Math.min_float(slotEnd, intent.end),
  })
  Belt.Array.concat(preserved, clampedDraft)
  ->Array.filter(i => i.end > i.start)
  ->TimeWindow.mergeContiguousTimeWindows
}

@react.component
let make = (
  ~band: TimeWindow.courtAvailabilityBand,
  ~availability: array<TimeWindow.playIntent>=[],
  ~players: array<slotPlayer>=[],
  ~isLastInGroup: bool=false,
  ~hasBottomBorder: bool=false,
  ~onAvailabilityChange: array<TimeWindow.playIntent> => unit,
) => {
  let intl = ReactIntl.useIntl()
  let fmt = h => TimeWindow.hourLabelIntl(intl, h)
  let (expanded, setExpanded) = React.useState(() => false)
  let (editingAvailability, setEditingAvailability) = React.useState(() => false)
  let (playersExpanded, setPlayersExpanded) = React.useState(() => false)
  let (draft, setDraft) = React.useState(() => [])

  let duration = band.end -. band.start
  let courts = buildCourtsWithSpans(band)
  let locationCount =
    courts
    ->Array.map(c => c.court.location.id)
    ->Belt.Set.String.fromArray
    ->Belt.Set.String.size

  // Other players clamped to this slot; empties dropped.
  let overlappingPlayers =
    players
    ->Array.map(player => {
      ...player,
      intents: player.intents
      ->Array.filter(intent => intent.start < band.end && intent.end > band.start)
      ->Array.map(intent => {
        ...intent,
        start: Js.Math.max_float(intent.start, band.start),
        end: Js.Math.min_float(intent.end, band.end),
      }),
    })
    ->Array.filter(player => player.intents->Array.length > 0)
  let playerDemandIntents = overlappingPlayers->Array.flatMap(player => player.intents)

  // The viewer's own availability, clamped to this slot.
  let slotAvailability =
    availability
    ->Array.filter(intent => intent.start < band.end && intent.end > band.start)
    ->Array.map(intent => {
      ...intent,
      start: Js.Math.max_float(intent.start, band.start),
      end: Js.Math.min_float(intent.end, band.end),
    })
  let isAvailable = slotAvailability->Array.length > 0

  // Distinct location names (first-seen order) → venue-context title.
  let locationNames = {
    let seen: Js.Dict.t<bool> = Js.Dict.empty()
    let names: array<string> = []
    courts->Array.forEach(c =>
      switch seen->Js.Dict.get(c.court.location.id) {
      | Some(_) => ()
      | None =>
        seen->Js.Dict.set(c.court.location.id, true)
        names->Array.push(c.court.location.name)
      }
    )
    names
  }
  let locationTitle = switch locationNames->Array.get(0) {
  | None => ts`Courts available`
  | Some(first) =>
    locationCount <= 1 ? first : ts`${first} + ${(locationCount - 1)->Int.toString} more`
  }

  let courtSummary = TimeWindow.summarizeCourtAvailability(
    ~fromHour=band.start->Float.toInt,
    ~toHour=band.end->Float.toInt,
    courts->Array.map(c => c.court),
  )
  // Localized templates stay inside the render function (lingui catalogs load
  // dynamically through the tree); CourtLabels only assembles them.
  let priceLabel = CourtLabels.priceRange(courtSummary)
  let surfaceLabel = CourtLabels.surfaceMix(
    courtSummary,
    ~indoor=n => ts`${n} indoor`,
    ~outdoor=n => ts`${n} outdoor`,
  )
  let courtCountLabel = Lingui.UtilString.plural(
    courtSummary.courtCount,
    {
      one: ts`${courtSummary.courtCount->Int.toString} court`,
      other: ts`${courtSummary.courtCount->Int.toString} courts`,
    },
  )
  let locationLabel = Lingui.UtilString.plural(
    locationCount,
    {
      one: ts`${locationCount->Int.toString} location`,
      other: ts`${locationCount->Int.toString} locations`,
    },
  )
  let playersLabel =
    overlappingPlayers->Array.length > 0
      ? Some(
          Lingui.UtilString.plural(
            overlappingPlayers->Array.length,
            {
              one: ts`${overlappingPlayers->Array.length->Int.toString} player`,
              other: ts`${overlappingPlayers->Array.length->Int.toString} players`,
            },
          ),
        )
      : None

  let openAvailabilityEditor = () => {
    setDraft(_ =>
      isAvailable
        ? slotAvailability
        : [{TimeWindow.id: TimeWindowPicker.wid(), start: band.start, end: band.end}]
    )
    setExpanded(_ => true)
    setEditingAvailability(_ => true)
  }
  let saveAvailability = () => {
    onAvailabilityChange(replaceAvailabilityInSlot(availability, draft, band.start, band.end))
    setEditingAvailability(_ => false)
  }
  let removeSlotAvailability = () => {
    onAvailabilityChange(replaceAvailabilityInSlot(availability, [], band.start, band.end))
    setDraft(_ => [])
    setEditingAvailability(_ => false)
  }

  let slotConfig: TimeWindowPicker.windowConfig = {
    hourMin: band.start->Float.toInt,
    hourMax: band.end->Float.toInt,
    snap: 1.0,
    minDuration: Js.Math.min_float(1.0, duration),
    defaultDuration: duration,
  }

  <article
    className={`relative overflow-hidden border-l-2 border-l-cyan-400 dark:border-l-cyan-500 ${isLastInGroup
        ? ""
        : "border-b border-cyan-100 dark:border-[#2a2b30]"} ${hasBottomBorder
        ? "border-b border-gray-200 dark:border-[#3a3b40]"
        : ""}`}>
    <div
      className="flex w-full items-start gap-3 bg-cyan-50/45 px-4 py-4 md:gap-6 md:px-6 dark:bg-cyan-950/10">
      <button
        type_="button"
        onClick={_ => setExpanded(v => !v)}
        className="flex min-w-0 flex-1 items-start gap-3 text-left focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-500 md:gap-6"
        ariaExpanded=expanded>
        <span className="flex w-12 flex-shrink-0 flex-col items-start pt-0.5 md:w-16">
          <span className="font-mono text-base font-bold text-cyan-800 dark:text-cyan-300">
            {fmt(band.start)->React.string}
          </span>
          <span className="mt-1 font-mono text-[10px] text-cyan-600 dark:text-cyan-500">
            {CourtLabels.duration(
              duration,
              ~minutesOnly=ms => ts`${ms}m`,
              ~hoursOnly=hs => ts`${hs}h`,
              ~hoursMinutes=(hs, ms) => ts`${hs}h ${ms}m`,
            )->React.string}
          </span>
        </span>
        <span className="flex min-w-0 flex-1 flex-col gap-1.5">
          <span className="flex min-w-0 items-center gap-2">
            <span
              className="inline-flex h-5 w-5 flex-shrink-0 items-center justify-center rounded bg-cyan-100 text-cyan-700 dark:bg-cyan-900/50 dark:text-cyan-300">
              <Lucide.MapPin size=11 strokeWidth=2.5 />
            </span>
            <span className="truncate font-medium text-gray-900 dark:text-gray-100">
              {locationTitle->React.string}
            </span>
          </span>
          <span
            className="flex flex-wrap items-center gap-x-1.5 gap-y-0.5 text-xs text-gray-600 dark:text-gray-400">
            <span> {courtCountLabel->React.string} </span>
            <span> {React.string("·")} </span>
            <span> {locationLabel->React.string} </span>
            // {switch surfaceLabel {
            // | Some(s) =>
            //   <>
            //     <span> {React.string("·")} </span>
            //     <span> {s->React.string} </span>
            //   </>
            // | None => React.null
            // }}
            // {switch priceLabel {
            // | Some(p) =>
            //   <>
            //     <span> {React.string("·")} </span>
            //     <span
            //       className="inline-flex items-center gap-1 font-mono font-semibold text-cyan-700 dark:text-cyan-300">
            //       <Lucide.Banknote size=11 />
            //       {p->React.string}
            //     </span>
            //   </>
            // | None => React.null
            // }}
            {switch playersLabel {
            | Some(pl) =>
              <>
                <span> {React.string("·")} </span>
                <span> {pl->React.string} </span>
              </>
            | None => React.null
            }}
          </span>
          {isAvailable
            ? <span
                className="inline-flex items-center gap-1 font-mono text-[10px] font-semibold text-[#4d6f12] dark:text-[#bdf25d]">
                <Lucide.Check size=10 strokeWidth=2.5 />
                {((ts`You: `) ++
                slotAvailability
                ->Array.map(i => fmt(i.start) ++ "–" ++ fmt(i.end))
                ->Array.join(", "))->React.string}
              </span>
            : React.null}
        </span>
        <Lucide.ChevronDown
          size=15
          className={`mt-1 flex-shrink-0 text-cyan-700 transition-transform dark:text-cyan-300 ${expanded
              ? "rotate-180"
              : ""}`}
        />
      </button>
      <button
        type_="button"
        onClick={_ => openAvailabilityEditor()}
        className={`inline-flex flex-shrink-0 items-center gap-1 rounded-md border px-2.5 py-1.5 text-[10px] font-semibold transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] ${isAvailable
            ? "border-[#a3d949] bg-[#bdf25d]/20 text-[#4d6f12] hover:bg-[#bdf25d]/30 dark:text-[#bdf25d]"
            : "border-[#a3d949] bg-[#bdf25d] text-black hover:bg-[#aee050]"}`}>
        {isAvailable ? <Lucide.Pencil size=11 /> : <Lucide.Plus size=11 strokeWidth=2.5 />}
        <span className="hidden sm:inline">
          {(isAvailable ? ts`Edit time` : ts`Mark available`)->React.string}
        </span>
        <span className="sm:hidden">
          {(isAvailable ? ts`Edit` : ts`Available`)->React.string}
        </span>
      </button>
    </div>
    {expanded
      ? <FramerMotion.Div
          className="overflow-hidden bg-white dark:bg-[#222326]"
          initial={{FramerMotion.height: "0px", opacity: 0.}}
          animate={{FramerMotion.height: "auto", opacity: 1.}}
          exit={{FramerMotion.height: "0px", opacity: 0.}}
          transition={{FramerMotion.duration: 0.18}}>
          <div className="space-y-2 px-4 pb-4 pt-2 md:pl-[7.5rem] md:pr-6">
            {editingAvailability
              ? <section
                  className="rounded-md border border-[#a3d949]/70 bg-[#bdf25d]/10 p-3 dark:border-[#bdf25d]/35 dark:bg-[#bdf25d]/5">
                  <div className="mb-2 flex items-center justify-between gap-3">
                    <div>
                      <h4 className="text-xs font-semibold text-gray-900 dark:text-gray-100">
                        {(ts`Your availability in this slot`)->React.string}
                      </h4>
                      <p className="font-mono text-[9px] text-gray-500 dark:text-gray-400">
                        {((ts`Drag or resize within `) ++ fmt(band.start) ++ "–" ++ fmt(band.end))
                          ->React.string}
                      </p>
                    </div>
                    <button
                      type_="button"
                      onClick={_ => setEditingAvailability(_ => false)}
                      className="rounded p-1 text-gray-400 hover:bg-white hover:text-gray-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:hover:bg-[#2a2b30] dark:hover:text-gray-200"
                      ariaLabel={ts`Cancel editing availability`}>
                      <Lucide.X size=14 />
                    </button>
                  </div>
                  <TimeWindowPicker
                    intents=draft
                    onChange={next => setDraft(_ => next)}
                    demandIntents=playerDemandIntents
                    config=slotConfig
                    emptyLabel={ts`Tap to add time in this slot`}
                  />
                  <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
                    {isAvailable
                      ? <button
                          type_="button"
                          onClick={_ => removeSlotAvailability()}
                          className="text-[10px] font-semibold text-gray-500 hover:text-red-600 dark:text-gray-400 dark:hover:text-red-400">
                          {(ts`Remove from slot`)->React.string}
                        </button>
                      : <span />}
                    <div className="flex items-center gap-1.5">
                      <button
                        type_="button"
                        onClick={_ =>
                          setDraft(_ => [
                            {
                              TimeWindow.id: TimeWindowPicker.wid(),
                              start: band.start,
                              end: band.end,
                            },
                          ])}
                        className="rounded-md border border-gray-200 px-2.5 py-1.5 text-[10px] font-semibold text-gray-600 hover:bg-white dark:border-[#3a3b40] dark:text-gray-300 dark:hover:bg-[#2a2b30]">
                        {(ts`Full slot`)->React.string}
                      </button>
                      <button
                        type_="button"
                        onClick={_ => saveAvailability()}
                        disabled={draft->Array.length === 0}
                        className="inline-flex items-center gap-1 rounded-md bg-[#bdf25d] px-2.5 py-1.5 text-[10px] font-semibold text-black hover:bg-[#aee050] disabled:cursor-not-allowed disabled:opacity-50">
                        <Lucide.Check size=11 strokeWidth=2.5 />
                        {(ts`Save availability`)->React.string}
                      </button>
                    </div>
                  </div>
                </section>
              : React.null}
            {overlappingPlayers->Array.length > 0
              ? <section
                  className="overflow-hidden rounded-md border border-violet-100 bg-violet-50/40 dark:border-violet-900/40 dark:bg-violet-950/10">
                  <button
                    type_="button"
                    onClick={_ => setPlayersExpanded(v => !v)}
                    className="flex w-full items-center justify-between gap-3 px-3 py-2 text-left text-violet-700 hover:bg-violet-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-500 dark:text-violet-300 dark:hover:bg-violet-950/20"
                    ariaExpanded=playersExpanded>
                    <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold">
                      <Lucide.Users size=12 />
                      {Lingui.UtilString.plural(
                        overlappingPlayers->Array.length,
                        {
                          one: ts`${overlappingPlayers
                          ->Array.length
                          ->Int.toString} other player available in this slot`,
                          other: ts`${overlappingPlayers
                          ->Array.length
                          ->Int.toString} other players available in this slot`,
                        },
                      )->React.string}
                    </span>
                    <Lucide.ChevronDown
                      size=13
                      className={`transition-transform ${playersExpanded ? "rotate-180" : ""}`}
                    />
                  </button>
                  {playersExpanded
                    ? <ul
                        className="space-y-1.5 border-t border-violet-100 p-2 dark:border-violet-900/40">
                        {overlappingPlayers
                        ->Array.map(player =>
                          <li
                            key={player.id}
                            className="flex items-center gap-2.5 rounded-md border border-violet-100 bg-white/80 px-2 py-1.5 dark:border-violet-900/40 dark:bg-[#1e1f23]/80">
                            <span
                              className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-violet-100 text-[9px] font-bold text-violet-700 dark:bg-violet-900/50 dark:text-violet-300">
                              {player.initials->React.string}
                            </span>
                            <span
                              className="min-w-0 flex-1 truncate text-xs font-medium text-gray-900 dark:text-gray-100">
                              {player.name->React.string}
                            </span>
                            <span className="flex flex-shrink-0 flex-wrap justify-end gap-1">
                              {player.intents
                              ->Array.map(intent =>
                                <span
                                  key={intent.id->Int.toString}
                                  className="rounded bg-violet-100 px-1.5 py-0.5 font-mono text-[9px] text-violet-700 dark:bg-violet-900/40 dark:text-violet-300">
                                  {(fmt(intent.start) ++ "–" ++ fmt(intent.end))->React.string}
                                </span>
                              )
                              ->React.array}
                            </span>
                          </li>
                        )
                        ->React.array}
                      </ul>
                    : React.null}
                </section>
              : React.null}
            // Shared per-location card (count/surface/price scoped to the slot).
            {courts
            ->Array.map(({court, spans}) =>
              <CourtOpeningCard
                key={court.id}
                court
                spans
                fromHour={band.start->Float.toInt}
                toHour={band.end->Float.toInt}
              />
            )
            ->React.array}
          </div>
        </FramerMotion.Div>
      : React.null}
  </article>
}
