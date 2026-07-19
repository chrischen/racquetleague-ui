%%raw("import { t, plural } from '@lingui/macro'")

// Collapsible list of court (venue) openings, grouped by identical time
// windows. Each group offers "Use this time" (≤ maxMatchableCourtHours) and a
// per-court disclosure with an external reservation link.

let ts = Lingui.UtilString.t

type courtAvailability = TimeWindowPicker.courtAvailability

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
  ~onUseSlot: TimeWindowPicker.courtSlotGroup => unit,
) => {
  let (expanded, setExpanded) = React.useState(() => defaultExpanded)
  let groups = TimeWindowPicker.groupCourtAvailabilityByTime(courtAvailability)
  let totalCourts = groups->Array.reduce(0, (sum, g) => sum + g.slots->Array.length)
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
    let optionsPhrase = Lingui.UtilString.plural(
      groups->Array.length,
      {
        one: ts`${groups->Array.length->Int.toString} time option`,
        other: ts`${groups->Array.length->Int.toString} time options`,
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
              {(courtsPhrase ++ " · " ++ optionsPhrase ++ " · " ++ locationsPhrase)->React.string}
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
              {groups
              ->Array.map(group => {
                let canMatch =
                  group.end -. group.start <= TimeWindowPicker.maxMatchableCourtHours
                let groupLocations = countLocations(group.slots->Array.map(s => s.court))
                let slotCount = group.slots->Array.length
                let groupCourtsPhrase = Lingui.UtilString.plural(
                  slotCount,
                  {
                    one: ts`${slotCount->Int.toString} court`,
                    other: ts`${slotCount->Int.toString} courts`,
                  },
                )
                let groupLocationsPhrase = Lingui.UtilString.plural(
                  groupLocations,
                  {
                    one: ts`${groupLocations->Int.toString} location`,
                    other: ts`${groupLocations->Int.toString} locations`,
                  },
                )
                <article key={group.key} className="bg-white/80 dark:bg-[#1e1f23]/80 px-2.5 py-2.5">
                  <div className="flex items-center gap-2.5">
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
                        <span
                          className="font-mono text-xs font-bold text-cyan-800 dark:text-cyan-300">
                          {(TimeWindowPicker.hourLabel(group.start) ++
                          "–" ++
                          TimeWindowPicker.hourLabel(group.end))->React.string}
                        </span>
                        <span className="text-[10px] text-gray-500 dark:text-gray-400">
                          {(ts`${groupCourtsPhrase} at ${groupLocationsPhrase}`)->React.string}
                        </span>
                      </div>
                    </div>
                    {canMatch
                      ? <button
                          type_="button"
                          onClick={_ => onUseSlot(group)}
                          className="flex-shrink-0 rounded-md border border-cyan-300 dark:border-cyan-700 bg-cyan-50 dark:bg-cyan-950/30 px-2.5 py-1.5 text-[10px] font-semibold text-cyan-800 dark:text-cyan-300 hover:bg-cyan-100 dark:hover:bg-cyan-900/40 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-500">
                          {(ts`Use this time`)->React.string}
                        </button>
                      : <span
                          className="flex-shrink-0 font-mono text-[9px] text-gray-400 dark:text-gray-500">
                          {(ts`Long opening`)->React.string}
                        </span>}
                  </div>
                  <details className="group/details mt-1.5">
                    <summary
                      className="inline-flex cursor-pointer list-none items-center gap-1 font-mono text-[9px] text-cyan-700 dark:text-cyan-400 hover:text-cyan-900 dark:hover:text-cyan-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-cyan-500 rounded-sm [&::-webkit-details-marker]:hidden">
                      <Lucide.ChevronDown
                        size=11 className="transition-transform group-open/details:rotate-180"
                      />
                      {(ts`View ${groupCourtsPhrase} & reserve`)->React.string}
                    </summary>
                    <ul
                      className="mt-1.5 max-h-36 overflow-y-auto rounded border border-cyan-100 dark:border-cyan-900/50 divide-y divide-cyan-100 dark:divide-cyan-900/50 bg-cyan-50/40 dark:bg-cyan-950/10">
                      {group.slots
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
                            {(TimeWindowPicker.hourLabel(intent.start) ++
                            "–" ++
                            TimeWindowPicker.hourLabel(intent.end))->React.string}
                          </span>
                          <a
                            href={court.location.reservationUrl->Option.getOr(
                              TimeWindowPicker.defaultReservationUrl,
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
                </article>
              })
              ->React.array}
            </div>
          </FramerMotion.Div>
        : React.null}
    </section>
  }
}
