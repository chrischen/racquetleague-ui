%%raw("import { t, plural } from '@lingui/macro'")

// Experimental: renders a contiguous court-availability band as an event-like
// row in the events feed. The band is one continuous span; internal segments
// (where the active court set changes) are shown as a proportional strip and,
// when expanded, as an exact-segment selector with per-court reservation links.

let ts = Lingui.UtilString.t

let formatDuration = (duration: float): string => {
  let hours = duration->Js.Math.floor_int
  let minutes = Js.Math.round((duration -. hours->Float.fromInt) *. 60.0)->Float.toInt
  if hours == 0 {
    minutes->Int.toString ++ "m"
  } else if minutes == 0 {
    hours->Int.toString ++ "h"
  } else {
    hours->Int.toString ++ "h " ++ minutes->Int.toString ++ "m"
  }
}

@react.component
let make = (
  ~band: TimeWindow.courtAvailabilityBand,
  ~isLastInGroup: bool=false,
  ~onUseTime: TimeWindow.playIntent => unit,
) => {
  let intl = ReactIntl.useIntl()
  let fmt = h => TimeWindow.hourLabelIntl(intl, h)
  let (expanded, setExpanded) = React.useState(() => false)
  let (selectedSegmentKey, setSelectedSegmentKey) = React.useState(() =>
    band.segments->Array.get(0)->Option.map(s => s.key)->Option.getOr("")
  )
  let selectedSegment =
    band.segments
    ->Array.find(s => s.key == selectedSegmentKey)
    ->Option.orElse(band.segments->Array.get(0))

  let duration = band.end -. band.start

  // Distinct courts/locations across the whole band (segments double-count a
  // court that persists across a court-set change).
  let locationCount =
    band.segments
    ->Array.flatMap(seg => seg.slots->Array.map(s => s.court.location.id))
    ->Belt.Set.String.fromArray
    ->Belt.Set.String.size
  let locationLabel = Lingui.UtilString.plural(
    locationCount,
    {
      one: ts`${locationCount->Int.toString} location`,
      other: ts`${locationCount->Int.toString} locations`,
    },
  )

  let courtCounts = band.segments->Array.map(seg => seg.slots->Array.length)
  let minCourts =
    courtCounts->Array.reduce(courtCounts->Array.get(0)->Option.getOr(0), (a, c) =>
      Js.Math.min_int(a, c)
    )
  let maxCourts = courtCounts->Array.reduce(0, (a, c) => Js.Math.max_int(a, c))
  let courtCountLabel = if minCourts == maxCourts {
    Lingui.UtilString.plural(
      minCourts,
      {
        one: ts`${minCourts->Int.toString} court`,
        other: ts`${minCourts->Int.toString} courts`,
      },
    )
  } else {
    ts`${minCourts->Int.toString}–${maxCourts->Int.toString} courts`
  }

  let segmentsLabel = Lingui.UtilString.plural(
    band.segments->Array.length,
    {
      one: ts`${band.segments->Array.length->Int.toString} segment`,
      other: ts`${band.segments->Array.length->Int.toString} segments`,
    },
  )

  let canUseTime =
    selectedSegment
    ->Option.map(s => s.end -. s.start <= TimeWindow.maxMatchableCourtHours)
    ->Option.getOr(false)

  let useSelected = () =>
    selectedSegment->Option.forEach(s =>
      onUseTime({id: TimeWindowPicker.wid(), start: s.start, end: s.end})
    )

  <article
    className={`relative overflow-hidden border-l-2 border-l-cyan-400 dark:border-l-cyan-500 ${isLastInGroup
        ? ""
        : "border-b border-cyan-100 dark:border-[#2a2b30]"}`}>
    <button
      type_="button"
      onClick={_ => setExpanded(v => !v)}
      className="w-full px-4 md:px-6 py-4 flex items-start gap-3 md:gap-6 text-left bg-cyan-50/45 dark:bg-cyan-950/10 hover:bg-cyan-50 dark:hover:bg-cyan-950/20 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cyan-500"
      ariaExpanded=expanded>
      <span className="w-12 md:w-16 flex-shrink-0 flex flex-col items-start pt-0.5">
        <span className="font-mono font-bold text-base text-cyan-800 dark:text-cyan-300">
          {fmt(band.start)->React.string}
        </span>
        <span className="font-mono text-[10px] text-cyan-600 dark:text-cyan-500 mt-1">
          {formatDuration(duration)->React.string}
        </span>
      </span>
      <span className="flex-1 min-w-0 flex flex-col gap-1.5">
        <span className="flex items-center gap-2 min-w-0">
          <span
            className="inline-flex h-5 w-5 flex-shrink-0 items-center justify-center rounded bg-cyan-100 dark:bg-cyan-900/50 text-cyan-700 dark:text-cyan-300">
            <Lucide.MapPin size=11 strokeWidth=2.5 />
          </span>
          <span className="font-medium text-gray-900 dark:text-gray-100 truncate">
            {ts`Continuous court availability`->React.string}
          </span>
          <span
            className="inline-flex flex-shrink-0 rounded border border-cyan-200 dark:border-cyan-800 bg-white/80 dark:bg-cyan-950/30 px-1.5 py-0.5 font-mono text-[9px] uppercase tracking-wide text-cyan-700 dark:text-cyan-300">
            {ts`Open span`->React.string}
          </span>
        </span>
        <span className="text-xs text-gray-600 dark:text-gray-400 truncate">
          {(courtCountLabel ++ " · " ++ locationLabel)->React.string}
        </span>
        <span
          className="flex max-w-full items-stretch overflow-hidden rounded border border-cyan-300/80 dark:border-cyan-700/80">
          {band.segments
          ->Array.mapWithIndex((segment, index) => {
            let share = (segment.end -. segment.start) /. duration *. 100.0
            <span
              key={segment.key}
              className={`flex min-w-0 items-center justify-center px-1 py-0.5 font-mono text-[9px] font-bold text-cyan-700 dark:text-cyan-300 ${index > 0
                  ? "border-l border-cyan-300/80 dark:border-cyan-700/80"
                  : ""}`}
              style={ReactDOM.Style.make(~width=share->Float.toString ++ "%", ())}
              title={fmt(segment.start) ++
              "–" ++
              fmt(segment.end) ++
              " · " ++
              segment.slots->Array.length->Int.toString}>
              {segment.slots->Array.length->Int.toString->React.string}
            </span>
          })
          ->React.array}
        </span>
      </span>
      <span
        className="w-20 md:w-44 flex-shrink-0 flex items-center justify-end gap-2 pt-1 text-cyan-700 dark:text-cyan-300">
        <span className="hidden sm:inline font-mono text-[10px] uppercase tracking-wide">
          {segmentsLabel->React.string}
        </span>
        <Lucide.ChevronDown
          size=15 className={`transition-transform ${expanded ? "rotate-180" : ""}`}
        />
      </span>
    </button>
    {switch (expanded, selectedSegment) {
    | (true, Some(seg)) =>
      <FramerMotion.Div
        className="overflow-hidden bg-white dark:bg-[#222326]"
        initial={{FramerMotion.height: "0px", opacity: 0.}}
        animate={{FramerMotion.height: "auto", opacity: 1.}}
        exit={{FramerMotion.height: "0px", opacity: 0.}}
        transition={{FramerMotion.duration: 0.18}}>
        <div className="px-4 md:px-6 pb-4 pt-2 md:pl-[7.5rem]">
          {band.segments->Array.length > 1
            ? <div
                className="mb-2.5 flex overflow-hidden rounded-md border border-cyan-200 dark:border-cyan-800/60">
                {band.segments
                ->Array.mapWithIndex((segment, index) => {
                  let active = segment.key == seg.key
                  let share = (segment.end -. segment.start) /. duration *. 100.0
                  <button
                    key={segment.key}
                    type_="button"
                    onClick={_ => setSelectedSegmentKey(_ => segment.key)}
                    className={`min-w-0 px-2 py-1.5 text-center transition-colors ${index > 0
                        ? "border-l border-cyan-200 dark:border-cyan-800/60"
                        : ""} ${active
                        ? "bg-cyan-100 dark:bg-cyan-900/45 text-cyan-900 dark:text-cyan-100"
                        : "text-cyan-700 dark:text-cyan-300 hover:bg-cyan-50 dark:hover:bg-cyan-950/30"}`}
                    style={ReactDOM.Style.make(~width=share->Float.toString ++ "%", ())}>
                    <span className="block font-mono text-[10px] font-bold">
                      {(fmt(segment.start) ++ "–" ++ fmt(segment.end))->React.string}
                    </span>
                    <span className="block text-[9px]">
                      {Lingui.UtilString.plural(
                        segment.slots->Array.length,
                        {
                          one: ts`${segment.slots->Array.length->Int.toString} court`,
                          other: ts`${segment.slots->Array.length->Int.toString} courts`,
                        },
                      )->React.string}
                    </span>
                  </button>
                })
                ->React.array}
              </div>
            : React.null}
          <ul
            className="divide-y divide-cyan-100 dark:divide-cyan-900/40 rounded-md border border-cyan-100 dark:border-cyan-900/50 overflow-hidden">
            {seg.slots
            ->Array.map(slot => {
              let court = slot.court
              let intent = slot.intent
              <li
                key={court.id ++ "-" ++ intent.id->Int.toString}
                className="flex items-center gap-3 px-3 py-2.5 bg-cyan-50/30 dark:bg-cyan-950/10">
                <span className="flex-1 min-w-0">
                  <span
                    className="block text-xs font-medium text-gray-900 dark:text-gray-100 truncate">
                    {court.location.name->React.string}
                  </span>
                  <span
                    className="block mt-0.5 text-[10px] text-gray-500 dark:text-gray-400 truncate">
                    {(court.courtName->Option.map(cn => cn ++ " · ")->Option.getOr("") ++
                    fmt(intent.start) ++
                    "–" ++
                    fmt(intent.end))->React.string}
                  </span>
                </span>
                <a
                  href={court.location.reservationUrl->Option.getOr(
                    TimeWindow.defaultReservationUrl,
                  )}
                  target="_blank"
                  rel="noopener noreferrer"
                  onClick={e => e->ReactEvent.Mouse.stopPropagation}
                  className="inline-flex flex-shrink-0 items-center gap-1 rounded-md border border-cyan-300 dark:border-cyan-700 bg-white dark:bg-cyan-950/30 px-2.5 py-1.5 text-[10px] font-semibold text-cyan-800 dark:text-cyan-300 hover:bg-cyan-100 dark:hover:bg-cyan-900/40 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-500">
                  {ts`Reserve`->React.string}
                  <Lucide.ExternalLink size=10 \"aria-hidden"="true" />
                </a>
              </li>
            })
            ->React.array}
          </ul>
          <div className="mt-3 flex items-center justify-between gap-3">
            <p className="text-[10px] text-gray-500 dark:text-gray-400">
              {(canUseTime
                ? ts`Match your availability to the selected segment, then invite players.`
                : ts`Choose a segment up to four hours to plan this time.`)->React.string}
            </p>
            {canUseTime
              ? <button
                  type_="button"
                  onClick={_ => useSelected()}
                  className="inline-flex flex-shrink-0 items-center gap-1.5 rounded-md bg-[#bdf25d] hover:bg-[#aee050] px-3 py-1.5 text-xs font-semibold text-black transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#65a30d] focus-visible:ring-offset-2 dark:focus-visible:ring-offset-[#222326]">
                  <Lucide.CalendarPlus size=13 strokeWidth=2.5 \"aria-hidden"="true" />
                  {ts`Plan this time`->React.string}
                </button>
              : React.null}
          </div>
        </div>
      </FramerMotion.Div>
    | _ => React.null
    }}
  </article>
}
