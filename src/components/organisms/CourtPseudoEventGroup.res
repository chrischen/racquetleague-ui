%%raw("import { t, plural } from '@lingui/macro'")

// A compact summary row for a contiguous run of court-availability slots in the
// discover feed. It shows the full continuous span, its duration + underlying
// slot count, and the unique courts/locations. "View slots" expands it into the
// full CourtPseudoEventRow rows (availability editing, player heatmap, roster,
// court details) for each underlying slot.

let ts = Lingui.UtilString.t

@react.component
let make = (
  ~group: TimeWindow.courtPseudoEventGroup,
  ~availability: array<TimeWindow.playIntent>=[],
  ~players: array<CourtPseudoEventRow.slotPlayer>=[],
  ~isLastInGroup: bool=false,
  ~hasBottomBorder: bool=false,
  // Forwarded to each slot row's court cards; see CourtOpeningCard.
  ~createEvent: option<CourtOpeningCard.createEventContext>=?,
  ~onAvailabilityChange: array<TimeWindow.playIntent> => unit,
) => {
  let intl = ReactIntl.useIntl()
  let fmt = h => TimeWindow.hourLabelIntl(intl, h)
  let (expanded, setExpanded) = React.useState(() => false)

  let courts =
    group.bands
    ->Array.flatMap(band => band.segments->Array.flatMap(segment => segment.slots))
    ->Array.map(s => s.court)
  let summary = TimeWindow.summarizeCourtAvailability(
    ~fromHour=group.start->Float.toInt,
    ~toHour=group.end->Float.toInt,
    courts,
  )
  // Localized templates stay inside the render function (lingui catalogs load
  // dynamically through the tree); CourtLabels only assembles them.
  let priceLabel = CourtLabels.priceRange(summary)
  let surfaceLabel = CourtLabels.surfaceMix(
    summary,
    ~indoor=n => ts`${n} indoor`,
    ~outdoor=n => ts`${n} outdoor`,
  )
  let locationCount =
    courts->Array.map(c => c.location.id)->Belt.Set.String.fromArray->Belt.Set.String.size
  let bandCount = group.bands->Array.length

  let courtsAvailableLabel = Lingui.UtilString.plural(
    summary.courtCount,
    {
      one: ts`${summary.courtCount->Int.toString} court available`,
      other: ts`${summary.courtCount->Int.toString} courts available`,
    },
  )
  let locationsLabel = Lingui.UtilString.plural(
    locationCount,
    {
      one: ts`${locationCount->Int.toString} location`,
      other: ts`${locationCount->Int.toString} locations`,
    },
  )

  let boundaryClass = if hasBottomBorder {
    "border-b border-gray-200 dark:border-[#3a3b40]"
  } else if !isLastInGroup {
    "border-b border-cyan-100 dark:border-[#2a2b30]"
  } else {
    ""
  }

  <article className="overflow-hidden">
    <button
      type_="button"
      onClick={_ => setExpanded(v => !v)}
      className={`flex w-full items-center gap-3 border-l-2 border-l-cyan-400 bg-cyan-50/45 px-4 py-3 text-left transition-colors hover:bg-cyan-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cyan-500 md:gap-6 md:px-6 dark:border-l-cyan-500 dark:bg-cyan-950/10 dark:hover:bg-cyan-950/20 ${expanded
          ? "border-b border-cyan-100 dark:border-[#2a2b30]"
          : boundaryClass}`}
      ariaExpanded=expanded>
      <span className="flex w-12 flex-shrink-0 flex-col items-start md:w-16">
        <span className="font-mono text-sm font-bold text-cyan-800 dark:text-cyan-300">
          {fmt(group.start)->React.string}
        </span>
        <span className="mt-0.5 font-mono text-[9px] text-cyan-600 dark:text-cyan-500">
          {ts`to ${fmt(group.end)}`->React.string}
        </span>
      </span>
      <span className="flex min-w-0 flex-1 items-center gap-2.5">
        <span
          className="inline-flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-md bg-cyan-100 text-cyan-700 dark:bg-cyan-900/50 dark:text-cyan-300">
          <Lucide.MapPin size=13 strokeWidth=2.5 />
        </span>
        <span className="min-w-0">
          <span className="block truncate text-sm font-semibold text-gray-900 dark:text-gray-100">
            {courtsAvailableLabel->React.string}
          </span>
          <span
            className="mt-0.5 flex flex-wrap items-center gap-x-2 gap-y-0.5 font-mono text-[9px] text-gray-500 dark:text-gray-400">
            <span> {locationsLabel->React.string} </span>
            {switch surfaceLabel {
            | Some(s) => <span> {s->React.string} </span>
            | None => React.null
            }}
            {switch priceLabel {
            | Some(p) =>
              <span
                className="inline-flex items-center gap-1 font-semibold text-cyan-700 dark:text-cyan-300">
                <Lucide.Banknote size=10 />
                {p->React.string}
              </span>
            | None => React.null
            }}
          </span>
        </span>
      </span>
      <span
        className="flex flex-shrink-0 items-center gap-1.5 font-mono text-[9px] font-semibold uppercase tracking-wide text-cyan-700 dark:text-cyan-300">
        <span className="hidden sm:inline">
          {(expanded ? ts`Hide slots` : ts`View slots`)->React.string}
        </span>
        <Lucide.ChevronDown
          size=15 className={`transition-transform ${expanded ? "rotate-180" : ""}`}
        />
      </span>
    </button>
    {expanded
      ? <FramerMotion.Div
          className="overflow-hidden"
          initial={{FramerMotion.height: "0px", opacity: 0.}}
          animate={{FramerMotion.height: "auto", opacity: 1.}}
          exit={{FramerMotion.height: "0px", opacity: 0.}}
          transition={{FramerMotion.duration: 0.2}}>
          {group.bands
          ->Array.mapWithIndex((band, index) => {
            let isLastBand = index === bandCount - 1
            <CourtPseudoEventRow
              key={band.key}
              band
              availability
              players
              isLastInGroup={isLastBand ? isLastInGroup : false}
              hasBottomBorder={isLastBand ? hasBottomBorder : false}
              createEvent=?createEvent
              onAvailabilityChange
            />
          })
          ->React.array}
        </FramerMotion.Div>
      : React.null}
  </article>
}
