%%raw("import { t } from '@lingui/macro'")

// The event-list filter controls: an open-spots toggle, a minimum-level
// select and a Clear button. `Controls` is the bare cluster, which
// LocationFilter appends after its location cluster on the Discover lists;
// `make` is the same cluster as a toolbar of its own, for lists without a
// location (a club's schedule).

// `minimumLevel` is a DUPR-scale level; the events list persists it in the
// `level` URL param, which the route loaders pass to the server as
// EventFilters.level. `showOpenOnly` drives the caller's client-side
// open-spots filter.
type eventFilters = {
  showOpenOnly: bool,
  onShowOpenOnlyChange: bool => unit,
  minimumLevel: option<float>,
  onMinimumLevelChange: option<float> => unit,
}

let controlClass = "h-8 rounded-md border border-gray-200 bg-white text-xs font-medium text-gray-700 shadow-sm outline-none transition-colors focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-200"

module Controls = {
  @react.component
  let make = (~filters: eventFilters) => {
    let ts = Lingui.UtilString.t
    let filtersActive = filters.showOpenOnly || filters.minimumLevel->Option.isSome
    <>
      <button
        type_="button"
        onClick={_ => filters.onShowOpenOnlyChange(!filters.showOpenOnly)}
        ariaPressed={filters.showOpenOnly ? #"true" : #"false"}
        className={Util.cx([
          "inline-flex h-8 items-center justify-center gap-1.5 rounded-md border px-2.5 text-xs font-semibold shadow-sm transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-1",
          filters.showOpenOnly
            ? "border-[#94c93a] bg-[#bdf25d] text-black hover:bg-[#aee050]"
            : "border-gray-200 bg-white text-gray-700 hover:bg-gray-100 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-200 dark:hover:bg-[#2a2b30]",
        ])}>
        <Lucide.SlidersHorizontal size=13 />
        {(ts`Open spots`)->React.string}
      </button>
      <label className="relative w-[118px]">
        <span className="sr-only"> {(ts`Minimum event level`)->React.string} </span>
        <select
          value={filters.minimumLevel->Option.map(v => v->Js.Float.toString)->Option.getOr("all")}
          onChange={e => {
            let value: string = ReactEvent.Form.target(e)["value"]
            filters.onMinimumLevelChange(value == "all" ? None : Float.fromString(value))
          }}
          className={controlClass ++ " w-full appearance-none px-2.5 pr-7"}>
          <option value="all"> {(ts`All levels`)->React.string} </option>
          <option value="3"> {"3.0+"->React.string} </option>
          <option value="3.5"> {"3.5+"->React.string} </option>
          <option value="4"> {"4.0+"->React.string} </option>
        </select>
        <span
          className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-[9px] text-gray-400"
          ariaHidden=true>
          {"▾"->React.string}
        </span>
      </label>
      {filtersActive
        ? <button
            type_="button"
            onClick={_ => {
              filters.onShowOpenOnlyChange(false)
              filters.onMinimumLevelChange(None)
            }}
            className="h-8 px-1.5 text-[10px] font-semibold text-gray-500 hover:text-gray-900 focus:outline-none focus-visible:underline dark:text-gray-400 dark:hover:text-gray-100">
            {(ts`Clear`)->React.string}
          </button>
        : React.null}
    </>
  }
}

@react.component
let make = (~filters: eventFilters) => {
  let ts = Lingui.UtilString.t
  <section
    ariaLabel={ts`Event filters`}
    className="border-b border-gray-200 bg-gray-50/70 px-4 py-2 dark:border-[#2a2b30] dark:bg-[#1e1f23]/70 md:px-6">
    <div className="flex flex-wrap items-center gap-1.5"> <Controls filters /> </div>
  </section>
}
