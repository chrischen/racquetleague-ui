%%raw("import { t, plural } from '@lingui/macro'")

let ts = Lingui.UtilString.t

@react.component
let make = (
  ~totalEvents: int,
  // Each tuple: (bucketKey, rendered day content).
  // Key is used for the scroll-target id="bucket-{key}" and React key prop.
  ~buckets: array<(string, React.element)>,
  ~weekendBucketKey: string,
  ~filterByDate: option<Js.Date.t>=?,
  ~onClearFilter: option<unit => unit>=?,
  ~hasPrevious: bool=false,
  ~isLoadingPrevious: bool=false,
  ~onPrevious: option<unit => unit>=?,
  ~hasNext: bool=false,
  ~onNext: option<unit => unit>=?,
) => {
  open Lingui.Util
  let (activePill, setActivePill) = React.useState((): option<string> => None)

  <WaitForMessages>
    {() =>
      <div className="flex-1 min-w-0">
        // Filters bar
        <div
          className="px-4 py-3 border-b border-gray-200 dark:border-[#2a2b30] flex items-center gap-3 overflow-x-auto">
          <div
            className="flex items-center p-0.5 bg-white dark:bg-[#1e1f23] border border-gray-200 dark:border-[#3a3b40] rounded-lg flex-shrink-0">
            {[("today", ts`Today`), ("tomorrow", ts`Tomorrow`), (weekendBucketKey, ts`Weekend`)]
            ->Array.map(((key, label)) =>
              <button
                key=label
                className={Util.cx([
                  "px-3 py-1.5 text-sm rounded-md border whitespace-nowrap",
                  activePill == Some(key)
                    ? "bg-gray-100 dark:bg-[#2a2b30] border-gray-200 dark:border-[#3a3b40] font-medium dark:text-gray-100"
                    : "bg-white dark:bg-transparent border-transparent hover:bg-gray-50 dark:hover:bg-[#2a2b30] text-gray-600 dark:text-gray-400",
                ])}
                onClick={_ => {
                  setActivePill(_ => Some(key))
                  EventsListUtils.scrollToGroup(key)
                }}>
                {label->React.string}
              </button>
            )
            ->React.array}
          </div>
          {filterByDate
          ->Option.map(_ =>
            <div
              className="flex items-center gap-1 px-2.5 py-1 text-sm bg-white dark:bg-transparent border border-gray-800 dark:border-gray-400 rounded-md font-mono dark:text-gray-300 flex-shrink-0">
              <span> {(ts`Filtered by date`)->React.string} </span>
              <button onClick={_ => onClearFilter->Option.forEach(f => f())}>
                <Lucide.X
                  size=12
                  className="text-gray-500 dark:text-gray-400 hover:text-black dark:hover:text-white"
                />
              </button>
            </div>
          )
          ->Option.getOr(React.null)}
        </div>
        // List header
        <div
          className="px-4 md:px-6 py-4 border-b border-gray-100 dark:border-[#2a2b30] flex items-center justify-between">
          <h2 className="text-[11px] font-mono text-gray-500 dark:text-gray-400 tracking-wider">
            {(Int.toString(totalEvents) ++
            " " ++
            Lingui.UtilString.plural(
              totalEvents,
              {one: ts`event`, other: ts`events`},
            )->String.toUpperCase ++
            " · " ++
            (ts`SORTED BY START TIME`))->React.string}
          </h2>
          <AddToCalendar />
          // <button
          //   className="flex items-center gap-1.5 text-[11px] font-mono text-gray-400 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 transition-colors">
          //   <AddToCalendar />
          // </button>
        </div>
        // Events
        <div>
          {!isLoadingPrevious && hasPrevious
            ? <button
                key="prev"
                className="w-full py-3 text-center text-sm font-medium text-[#bdf25d] hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors"
                onClick={_ => onPrevious->Option.forEach(f => f())}>
                {t`← previous`}
              </button>
            : React.null}
          {buckets
          ->Array.mapWithIndex(((key, dayContent), idx) =>
            <React.Fragment key>
              <div id={"bucket-" ++ key}> {dayContent} </div>
              {idx < Array.length(buckets) - 1
                ? <div className="border-b border-gray-200 dark:border-[#3a3b40]" />
                : React.null}
            </React.Fragment>
          )
          ->React.array}
          {hasNext
            ? <button
                key="next"
                className="w-full py-3 text-center text-sm font-medium text-[#bdf25d] hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors"
                onClick={_ => onNext->Option.forEach(f => f())}>
                {t`more →`}
              </button>
            : React.null}
        </div>
      </div>}
  </WaitForMessages>
}
