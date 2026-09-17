%%raw("import { t } from '@lingui/macro'")

// Presentational filters toolbar, shared by the events list and the
// availability page, so its location copy stays location-generic — not
// events-specific. Stateless apart from the open/closed state of the location
// editor popover: the container (LocationFilterControl) owns the selection,
// geolocation status, and coordinates, and reacts to the two callbacks.
// `locations` are (value, label) pairs — only Tokyo for now. There is no
// "all"/unscoped option: the filter always resolves to a concrete location (a
// named one, or "Near me").
//
// The events list additionally passes `eventFilters` to append event-specific
// controls (open-spots toggle, minimum-level select) after the location
// cluster; the availability page leaves it off and gets the location cluster
// alone.

// Only the genuinely transient async state — whether a "Near me" request is in
// flight. The coordinate readout is derived (see the popover readout), not a
// `Success` flag; errors are carried by `errorMessage`.
type status =
  | Idle
  | Loading

// Event-list-only filter controls; the cluster itself lives in
// EventFiltersToolbar so lists without a location can show it alone.
type eventFilters = EventFiltersToolbar.eventFilters

let controlClass = EventFiltersToolbar.controlClass

@react.component
let make = (
  ~locations: array<(string, string)>,
  ~selectedLocation: string,
  ~status: status,
  ~coordinates: option<UseUserLocation.coords>,
  ~nearbyRadiusKm: int,
  ~errorMessage: option<string>,
  ~onSelectLocation: string => unit,
  ~onNearMe: unit => unit,
  ~eventFilters: option<eventFilters>=?,
) => {
  let ts = Lingui.UtilString.t
  let (editorOpen, setEditorOpen) = React.useState(() => false)
  let nearMeActive = selectedLocation == "near-me"

  let radius = nearbyRadiusKm->Int.toString
  let locationLabel = nearMeActive
    ? ts`Near me · ${radius} km`
    : locations
      ->Array.find(((value, _)) => value == selectedLocation)
      ->Option.map(((_, label)) => label)
      ->Option.getOr(selectedLocation)

  <section
    ariaLabel={ts`Event filters`}
    className="border-b border-gray-200 bg-gray-50/70 px-4 py-2 dark:border-[#2a2b30] dark:bg-[#1e1f23]/70 md:px-6">
    <div className="flex flex-wrap items-center gap-1.5">
      <div className="relative min-w-0">
        <div className="flex h-8 min-w-0 items-center gap-1.5 pr-1 text-xs text-gray-600 dark:text-gray-300">
          <Lucide.MapPin size=13 className="flex-shrink-0 text-gray-400" />
          <span className="hidden text-gray-400 sm:inline"> {(ts`Location:`)->React.string} </span>
          <span className="max-w-[150px] truncate font-semibold" ariaLive=#polite>
            {locationLabel->React.string}
          </span>
          <button
            type_="button"
            onClick={_ => setEditorOpen(open_ => !open_)}
            ariaExpanded=editorOpen
            ariaControls="event-location-editor"
            className="ml-0.5 inline-flex h-7 items-center gap-0.5 rounded px-1.5 text-[10px] font-semibold text-gray-500 transition-colors hover:bg-gray-200/70 hover:text-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-gray-400 dark:hover:bg-[#2a2b30] dark:hover:text-gray-100">
            {(editorOpen ? ts`Done` : ts`Change`)->React.string}
            <Lucide.ChevronDown
              size=11 className={editorOpen ? "transition-transform rotate-180" : "transition-transform"}
            />
          </button>
        </div>
        {editorOpen
          ? <div
              id="event-location-editor"
              className="absolute left-0 top-full z-50 mt-1.5 w-[min(320px,calc(100vw-2rem))] rounded-lg border border-gray-200 bg-white p-2 shadow-xl dark:border-[#3a3b40] dark:bg-[#222326]">
              <label className="relative block">
                <span className="sr-only"> {(ts`Location`)->React.string} </span>
                <Lucide.MapPin
                  size=13
                  className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400"
                />
                <select
                  value=selectedLocation
                  onChange={e => {
                    onSelectLocation(ReactEvent.Form.target(e)["value"])
                    setEditorOpen(_ => false)
                  }}
                  className={controlClass ++ " w-full appearance-none pl-8 pr-7"}>
                  {nearMeActive
                    ? <option value="near-me" disabled=true>
                        {(ts`Near me`)->React.string}
                      </option>
                    : React.null}
                  {locations
                  ->Array.map(((value, label)) =>
                    <option key=value value> {label->React.string} </option>
                  )
                  ->React.array}
                </select>
                <span
                  className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-[9px] text-gray-400"
                  ariaHidden=true>
                  {"▾"->React.string}
                </span>
              </label>
              <div className="mt-2 flex items-center gap-2">
                <button
                  type_="button"
                  onClick={_ => onNearMe()}
                  disabled={status == Loading}
                  ariaPressed={nearMeActive ? #"true" : #"false"}
                  className={Util.cx([
                    "inline-flex h-8 flex-shrink-0 items-center justify-center gap-1.5 rounded-md border px-2.5 text-xs font-semibold shadow-sm transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] disabled:cursor-wait disabled:opacity-70",
                    nearMeActive
                      ? "border-[#94c93a] bg-[#bdf25d] text-black"
                      : "border-gray-200 bg-white text-gray-700 hover:bg-gray-100 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:text-gray-200 dark:hover:bg-[#2a2b30]",
                  ])}>
                  <Lucide.Crosshair size=13 className={status == Loading ? "animate-spin" : ""} />
                  {(status == Loading ? ts`Locating…` : ts`Use near me`)->React.string}
                </button>
                <div className="min-w-0 flex-1" ariaLive=#polite>
                  // An error (if any) wins; otherwise show the coordinate
                  // readout whenever "Near me" is the active selection.
                  {switch (errorMessage, nearMeActive, coordinates) {
                  | (Some(message), _, _) =>
                    <p className="text-[9px] leading-tight text-red-600 dark:text-red-400">
                      {message->React.string}
                    </p>
                  | (None, true, Some(coords)) =>
                    <p className="truncate font-mono text-[9px] text-emerald-700 dark:text-emerald-400">
                      {(coords.lat->Js.Float.toFixedWithPrecision(~digits=3) ++
                      ", " ++
                      coords.lng->Js.Float.toFixedWithPrecision(~digits=3))->React.string}
                    </p>
                  | _ => React.null
                  }}
                </div>
              </div>
            </div>
          : React.null}
      </div>
      {switch eventFilters {
      | None => React.null
      | Some(filters) =>
        <>
          <span className="mx-0.5 hidden h-5 w-px bg-gray-200 dark:bg-[#3a3b40] sm:block" ariaHidden=true />
          <EventFiltersToolbar.Controls filters />
        </>
      }}
    </div>
  </section>
}
