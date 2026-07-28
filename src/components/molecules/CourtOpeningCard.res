%%raw("import { t, plural } from '@lingui/macro'")

// Unified per-location court-opening card: venue name, actual court count with
// indoor/outdoor split and price range (from the per-hour rollup), a reserve
// link, and the continuous openings with durations. Shared by the pseudo-event
// rows (slot-scoped summary) and the court-first availability summaries
// (CourtAvailabilityGroups), so every surface renders court details the same
// way.

let ts = Lingui.UtilString.t

@react.component
let make = (
  ~court: TimeWindow.courtAvailability,
  ~spans: array<TimeWindow.playIntent>,
  // Hour range for the count/price summary; defaults to the hull of `spans`.
  ~fromHour: option<int>=?,
  ~toHour: option<int>=?,
  ~className: string="rounded-md border border-cyan-100 bg-cyan-50/30 px-3 py-2.5 dark:border-cyan-900/50 dark:bg-cyan-950/10",
  // Optional primary action alongside the reserve link — used where a court
  // opening can be applied to something (e.g. moving an event onto this time).
  // Omitted, the card stays read-only.
  ~onSelect: option<TimeWindow.courtAvailability => unit>=?,
  ~selectLabel: option<string>=?,
  // #peak for browsing ("how big is this venue"), #sustained where the card
  // stands for a bookable window ("how many courts can take the whole slot").
  ~countBasis: TimeWindow.courtCountBasis=#peak,
) => {
  let intl = ReactIntl.useIntl()
  let fmt = h => TimeWindow.hourLabelIntl(intl, h)

  let summaryFrom =
    fromHour->Option.getOr(
      spans->Array.reduce(24.0, (m, s) => Js.Math.min_float(m, s.start))->Float.toInt,
    )
  // Round the end UP: a span ending at 17:30 still occupies hour 17, and
  // truncating would drop it from the summary. No-op for the whole-hour spans
  // every other caller passes.
  let summaryTo =
    toHour->Option.getOr(
      spans
      ->Array.reduce(0.0, (m, s) => Js.Math.max_float(m, s.end))
      ->Js.Math.ceil_float
      ->Float.toInt,
    )
  let summary = TimeWindow.summarizeCourtAvailability(
    ~fromHour=summaryFrom,
    ~toHour=summaryTo,
    ~basis=countBasis,
    [court],
  )
  // Lingui macro calls must stay inside the render function (catalogs load
  // dynamically through the tree), so the localized templates live here and
  // CourtLabels only assembles them.
  let price = CourtLabels.priceRange(summary)
  let surface = CourtLabels.surfaceMix(
    summary,
    ~indoor=n => ts`${n} indoor`,
    ~outdoor=n => ts`${n} outdoor`,
  )
  let durationLabel = hours =>
    CourtLabels.duration(
      hours,
      ~minutesOnly=ms => ts`${ms}m`,
      ~hoursOnly=hs => ts`${hs}h`,
      ~hoursMinutes=(hs, ms) => ts`${hs}h ${ms}m`,
    )
  let courtCountLabel = Lingui.UtilString.plural(
    summary.courtCount,
    {
      one: ts`${summary.courtCount->Int.toString} court`,
      other: ts`${summary.courtCount->Int.toString} courts`,
    },
  )

  <article className>
    <div className="flex items-start justify-between gap-3">
      <span className="min-w-0">
        <span className="block truncate text-xs font-semibold text-gray-900 dark:text-gray-100">
          {court.location.name->React.string}
        </span>
        <span
          className="mt-0.5 flex flex-wrap items-center gap-x-1.5 gap-y-0.5 text-[10px] text-gray-500 dark:text-gray-400">
          {switch court.courtName {
          | Some(cn) =>
            <>
              <span> {cn->React.string} </span>
              <span> {React.string("·")} </span>
            </>
          | None => React.null
          }}
          <span> {courtCountLabel->React.string} </span>
          {switch surface {
          | Some(s) =>
            <>
              <span> {React.string("·")} </span>
              <span> {s->React.string} </span>
            </>
          | None => React.null
          }}
          {switch price {
          | Some(p) =>
            <>
              <span> {React.string("·")} </span>
              <span className="font-mono font-semibold text-cyan-700 dark:text-cyan-300">
                {p->React.string}
              </span>
            </>
          | None => React.null
          }}
        </span>
      </span>
      <span className="flex flex-shrink-0 items-center gap-1.5">
        {switch onSelect {
        | Some(onSelect) =>
          <button
            type_="button"
            onClick={_ => onSelect(court)}
            className="rounded-md border border-[#a3d949] bg-[#bdf25d] px-2.5 py-1.5 text-[10px] font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a]">
            {selectLabel->Option.getOr(ts`Use option`)->React.string}
          </button>
        | None => React.null
        }}
        <a
          href={court.location.reservationUrl->Option.getOr(TimeWindow.defaultReservationUrl)}
          target="_blank"
          rel="noopener noreferrer"
          onClick={e => e->ReactEvent.Mouse.stopPropagation}
          className="inline-flex items-center gap-1 rounded-md border border-cyan-300 bg-white px-2.5 py-1.5 text-[10px] font-semibold text-cyan-800 transition-colors hover:bg-cyan-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-500 dark:border-cyan-700 dark:bg-cyan-950/30 dark:text-cyan-300 dark:hover:bg-cyan-900/40">
          {(ts`Reserve`)->React.string}
          <Lucide.ExternalLink size=10 \"aria-hidden"="true" />
        </a>
      </span>
    </div>
    <ul className="mt-2 space-y-1">
      {spans
      ->Array.map(span =>
        <li
          key={court.id ++ "-" ++ span.start->Float.toString ++ "-" ++ span.end->Float.toString}
          className="flex items-center justify-between gap-3 border-l-2 border-cyan-400 py-1 pl-2 dark:border-cyan-500">
          <span
            className="inline-flex items-center gap-1.5 font-mono text-[10px] font-semibold text-cyan-800 dark:text-cyan-200">
            <Lucide.Clock3 size=11 \"aria-hidden"="true" />
            {(fmt(span.start) ++ "–" ++ fmt(span.end))->React.string}
          </span>
          <span className="font-mono text-[9px] text-gray-400 dark:text-gray-500">
            {durationLabel(span.end -. span.start)->React.string}
          </span>
        </li>
      )
      ->React.array}
    </ul>
  </article>
}
