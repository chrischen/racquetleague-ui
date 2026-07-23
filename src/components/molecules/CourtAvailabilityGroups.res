%%raw("import { t, plural } from '@lingui/macro'")

// Collapsible court-first availability summary. Each court appears once —
// duplicates consolidated and adjacent openings merged into its largest
// continuous openings — with its reservation link and per-opening durations.
// Read-only: it never mutates the user's selected availability.

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
) => {
  let (expanded, setExpanded) = React.useState(() => defaultExpanded)
  let courts =
    TimeWindow.mergeCourtAvailabilityByCourt(courtAvailability)
    ->Array.filter(court => court.intents->Array.length > 0)
    ->Array.toSorted((a, b) => {
      let aStart = a.intents->Array.get(0)->Option.map(i => i.start)->Option.getOr(0.0)
      let bStart = b.intents->Array.get(0)->Option.map(i => i.start)->Option.getOr(0.0)
      if aStart != bStart {
        aStart -. bStart
      } else {
        let byLocation = String.localeCompare(a.location.name, b.location.name)
        if byLocation != 0.0 {
          byLocation
        } else {
          String.localeCompare(
            a.courtName->Option.getOr(""),
            b.courtName->Option.getOr(""),
          )
        }
      }
    })
  let locationCount = countLocations(courts)
  let openingCount = courts->Array.reduce(0, (total, court) => total + court.intents->Array.length)

  if courts->Array.length === 0 {
    React.null
  } else {
    // Actual court totals + surface/price aggregates from the per-hour rollup,
    // matching the pseudo-event summaries.
    let summary = TimeWindow.summarizeCourtAvailability(courts)
    // Localized templates stay inside the render function (lingui catalogs
    // load dynamically through the tree); CourtLabels only assembles them.
    let surfaceLabel = CourtLabels.surfaceMix(
      summary,
      ~indoor=n => ts`${n} indoor`,
      ~outdoor=n => ts`${n} outdoor`,
    )
    let priceLabel = CourtLabels.priceRange(summary)
    let courtsPhrase = Lingui.UtilString.plural(
      summary.courtCount,
      {
        one: ts`${summary.courtCount->Int.toString} court`,
        other: ts`${summary.courtCount->Int.toString} courts`,
      },
    )
    let openingsPhrase = Lingui.UtilString.plural(
      openingCount,
      {
        one: ts`${openingCount->Int.toString} continuous opening`,
        other: ts`${openingCount->Int.toString} continuous openings`,
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
      className="overflow-hidden rounded-md border border-cyan-200 bg-cyan-50/70 dark:border-cyan-800/50 dark:bg-cyan-950/20">
      <button
        type_="button"
        onClick={_ => setExpanded(v => !v)}
        className="flex w-full items-center justify-between gap-3 px-2.5 py-2 text-left text-cyan-800 transition-colors hover:bg-cyan-100/70 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cyan-500 dark:text-cyan-300 dark:hover:bg-cyan-900/20"
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
              openingsPhrase ++
              " · " ++
              locationsPhrase ++
              surfaceLabel->Option.map(s => " · " ++ s)->Option.getOr("") ++
              priceLabel->Option.map(p => " · " ++ p)->Option.getOr(""))->React.string}
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
              className="divide-y divide-cyan-100 border-t border-cyan-200/70 dark:divide-cyan-900/40 dark:border-cyan-800/40">
              {courts
              ->Array.map(court =>
                <CourtOpeningCard
                  key={court.id}
                  court
                  spans={court.intents}
                  className="bg-white/80 px-2.5 py-2.5 dark:bg-[#1e1f23]/80"
                />
              )
              ->React.array}
            </div>
          </FramerMotion.Div>
        : React.null}
    </section>
  }
}
