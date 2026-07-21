%%raw("import { t, plural } from '@lingui/macro'")

// Collapsible court-availability summary: contiguous availability is grouped
// into bands, each band split into proportional, independently-selectable
// segments (exact active-court sets) with a per-segment reservation disclosure.

let ts = Lingui.UtilString.t

type courtAvailability = TimeWindow.courtAvailability

let countLocations = (courts: array<courtAvailability>): int =>
  courts
  ->Array.map(c => c.location.id)
  ->Belt.Set.String.fromArray
  ->Belt.Set.String.size

@react.component
let make = (
  ~courtAvailability: array<courtAvailability>,
  ~title: option<string>=?,
  ~defaultExpanded: bool=false,
  // When omitted, segments are display-only. The inline availability picker
  // already filters courts by the user's chosen time, so re-selecting a segment
  // there to overwrite that availability would be circular.
  ~onUseSlot: option<TimeWindow.courtSlotGroup => unit>=?,
) => {
  let intl = ReactIntl.useIntl()
  let fmt = h => TimeWindow.hourLabelIntl(intl, h)
  let (expanded, setExpanded) = React.useState(() => defaultExpanded)
  let bands = TimeWindow.groupCourtAvailabilityIntoBands(courtAvailability)
  let segmentCount = bands->Array.reduce(0, (sum, b) => sum + b.segments->Array.length)
  // Distinct courts across all segments — a court spanning several windows must
  // not be counted once per window.
  let totalCourts =
    courtAvailability->Array.map(c => c.id)->Belt.Set.String.fromArray->Belt.Set.String.size
  let locationCount = countLocations(courtAvailability)

  if totalCourts === 0 {
    React.null
  } else {
    let courtsPhrase = Lingui.UtilString.plural(
      totalCourts,
      {
        one: ts`${totalCourts->Int.toString} court`,
        other: ts`${totalCourts->Int.toString} courts`,
      },
    )
    let spansPhrase = Lingui.UtilString.plural(
      bands->Array.length,
      {
        one: ts`${bands->Array.length->Int.toString} continuous span`,
        other: ts`${bands->Array.length->Int.toString} continuous spans`,
      },
    )
    let optionsPhrase = Lingui.UtilString.plural(
      segmentCount,
      {
        one: ts`${segmentCount->Int.toString} exact option`,
        other: ts`${segmentCount->Int.toString} exact options`,
      },
    )
    let locationsPhrase = Lingui.UtilString.plural(
      locationCount,
      {
        one: ts`${locationCount->Int.toString} location`,
        other: ts`${locationCount->Int.toString} locations`,
      },
    )
    <section
      className="rounded-md border border-cyan-200 dark:border-cyan-800/50 bg-cyan-50/70 dark:bg-cyan-950/20 overflow-hidden">
      <button
        type_="button"
        onClick={_ => setExpanded(v => !v)}
        className="w-full flex items-center justify-between gap-3 px-2.5 py-2 text-left text-cyan-800 dark:text-cyan-300 hover:bg-cyan-100/70 dark:hover:bg-cyan-900/20 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cyan-500"
        ariaExpanded=expanded>
        <span className="flex min-w-0 items-center gap-2">
          <span
            className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-md bg-cyan-100 dark:bg-cyan-900/50">
            <Lucide.MapPin size=12 strokeWidth=2.5 />
          </span>
          <span className="min-w-0">
            {title
            ->Option.map(tl =>
              <span
                className="block truncate text-xs font-semibold text-gray-900 dark:text-gray-100">
                {tl->React.string}
              </span>
            )
            ->Option.getOr(React.null)}
            <span className="block font-mono text-[9px] text-cyan-700 dark:text-cyan-400">
              {(courtsPhrase ++
              " · " ++
              spansPhrase ++
              " · " ++
              optionsPhrase ++
              " · " ++
              locationsPhrase)->React.string}
            </span>
          </span>
        </span>
        <Lucide.ChevronDown
          size=14 className={`flex-shrink-0 transition-transform ${expanded ? "rotate-180" : ""}`}
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
              className="border-t border-cyan-200/70 dark:border-cyan-800/40 divide-y divide-cyan-100 dark:divide-cyan-900/40">
              {bands
              ->Array.map(band => {
                let bandSpan = band.end -. band.start
                let bandSegmentsPhrase = Lingui.UtilString.plural(
                  band.segments->Array.length,
                  {
                    one: ts`${band.segments->Array.length->Int.toString} segment`,
                    other: ts`${band.segments->Array.length->Int.toString} segments`,
                  },
                )
                <article key={band.key} className="bg-white/80 dark:bg-[#1e1f23]/80 px-2.5 py-2.5">
                  <div className="mb-2 flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1">
                    <span className="font-mono text-xs font-bold text-cyan-800 dark:text-cyan-300">
                      {(fmt(band.start) ++ "–" ++ fmt(band.end))->React.string}
                    </span>
                    <span className="text-[10px] text-gray-500 dark:text-gray-400">
                      {(ts`Continuous availability` ++ " · " ++ bandSegmentsPhrase)->React.string}
                    </span>
                  </div>
                  // Proportional, independently-selectable segments across the band.
                  <div
                    className="flex overflow-hidden rounded-md border border-cyan-300/80 dark:border-cyan-700/80">
                    {band.segments
                    ->Array.mapWithIndex((segment, index) => {
                      let canMatch =
                        segment.end -. segment.start <= TimeWindow.maxMatchableCourtHours
                      let interactive = canMatch && onUseSlot->Option.isSome
                      let share = (segment.end -. segment.start) /. bandSpan *. 100.0
                      let segLocations = countLocations(segment.slots->Array.map(s => s.court))
                      let slotCount = segment.slots->Array.length
                      <button
                        key={segment.key}
                        type_="button"
                        disabled={!interactive}
                        onClick={_ => onUseSlot->Option.forEach(cb => cb(segment))}
                        className={`min-w-0 px-1.5 py-1.5 text-center transition-colors ${index > 0
                            ? "border-l border-cyan-300/80 dark:border-cyan-700/80"
                            : ""} ${interactive
                            ? "hover:bg-cyan-100 dark:hover:bg-cyan-900/40 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cyan-500"
                            : canMatch
                            ? "cursor-default"
                            : "cursor-default opacity-65"}`}
                        style={ReactDOM.Style.make(~width=share->Float.toString ++ "%", ())}>
                        <span
                          className="block truncate font-mono text-[10px] font-bold text-cyan-800 dark:text-cyan-200">
                          {(fmt(segment.start) ++ "–" ++ fmt(segment.end))->React.string}
                        </span>
                        <span className="block truncate text-[9px] text-gray-500 dark:text-gray-400">
                          {(Lingui.UtilString.plural(
                            slotCount,
                            {
                              one: ts`${slotCount->Int.toString} court`,
                              other: ts`${slotCount->Int.toString} courts`,
                            },
                          ) ++
                          " · " ++
                          Lingui.UtilString.plural(
                            segLocations,
                            {
                              one: ts`${segLocations->Int.toString} location`,
                              other: ts`${segLocations->Int.toString} locations`,
                            },
                          ))->React.string}
                        </span>
                      </button>
                    })
                    ->React.array}
                  </div>
                  // Per-segment reservation details.
                  <div className="mt-2 space-y-1.5">
                    {band.segments
                    ->Array.map(segment => {
                      let slotCount = segment.slots->Array.length
                      let segCourtsPhrase = Lingui.UtilString.plural(
                        slotCount,
                        {
                          one: ts`${slotCount->Int.toString} court`,
                          other: ts`${slotCount->Int.toString} courts`,
                        },
                      )
                      <details key={segment.key} className="group/details">
                        <summary
                          className="inline-flex cursor-pointer list-none items-center gap-1 font-mono text-[9px] text-cyan-700 dark:text-cyan-400 hover:text-cyan-900 dark:hover:text-cyan-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-500 rounded-sm [&::-webkit-details-marker]:hidden">
                          <Lucide.ChevronDown
                            size=11 className="transition-transform group-open/details:rotate-180"
                          />
                          {(fmt(segment.start) ++
                          "–" ++
                          fmt(segment.end) ++
                          " · " ++
                          ts`View ${segCourtsPhrase} & reserve`)->React.string}
                        </summary>
                        <ul
                          className="mt-1.5 max-h-36 overflow-y-auto rounded border border-cyan-100 dark:border-cyan-900/50 divide-y divide-cyan-100 dark:divide-cyan-900/50 bg-cyan-50/40 dark:bg-cyan-950/10">
                          {segment.slots
                          ->Array.map(slot => {
                            let court = slot.court
                            let intent = slot.intent
                            <li
                              key={court.id ++ "-" ++ intent.id->Int.toString}
                              className="flex items-center justify-between gap-2 px-2 py-1.5">
                              <span
                                className="min-w-0 flex-1 truncate text-[10px] text-gray-700 dark:text-gray-300">
                                <span className="font-medium text-gray-900 dark:text-gray-100">
                                  {court.location.name->React.string}
                                </span>
                                {court.courtName
                                ->Option.map(cn => (" · " ++ cn)->React.string)
                                ->Option.getOr(React.null)}
                              </span>
                              <span
                                className="flex-shrink-0 font-mono text-[9px] text-cyan-700 dark:text-cyan-400">
                                {(fmt(intent.start) ++ "–" ++ fmt(intent.end))->React.string}
                              </span>
                              <a
                                href={court.location.reservationUrl->Option.getOr(
                                  TimeWindow.defaultReservationUrl,
                                )}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex flex-shrink-0 items-center gap-1 rounded border border-cyan-300 dark:border-cyan-700 bg-white dark:bg-cyan-950/30 px-2 py-1 text-[9px] font-semibold text-cyan-800 dark:text-cyan-300 hover:bg-cyan-100 dark:hover:bg-cyan-900/40 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-500">
                                {(ts`Reserve`)->React.string}
                                <Lucide.ExternalLink size=10 \"aria-hidden"="true" />
                              </a>
                            </li>
                          })
                          ->React.array}
                        </ul>
                      </details>
                    })
                    ->React.array}
                  </div>
                </article>
              })
              ->React.array}
            </div>
          </FramerMotion.Div>
        : React.null}
    </section>
  }
}
