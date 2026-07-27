%%raw("import { t } from '@lingui/macro'")

// Presentational location filter bar, shared by the events list and the
// availability page, so its copy stays location-generic — not events-specific.
// Stateless: the container (LocationFilterControl) owns the selection, geolocation
// status, and coordinates, and reacts to the two callbacks. `locations` are
// (value, label) pairs — only Tokyo for now. There is no "all"/unscoped option:
// the filter always resolves to a concrete location (a named one, or "Near me").

// Only the genuinely transient async state — whether a "Near me" request is in
// flight. The coordinate readout is derived (see the status line below), not a
// `Success` flag; errors are carried by `errorMessage`.
type status =
  | Idle
  | Loading

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
) => {
  let ts = Lingui.UtilString.t
  let nearMeActive = selectedLocation == "near-me"

  <section
    ariaLabel={ts`Filter by location`}
    className="border-b border-gray-200 bg-gray-50/70 px-4 py-2.5 dark:border-[#2a2b30] dark:bg-[#1e1f23]/70 md:px-6">
    <div className="flex flex-wrap items-center gap-2">
      <label className="relative min-w-[180px] flex-1 sm:max-w-xs">
        <span className="sr-only"> {(ts`Location`)->React.string} </span>
        <Lucide.MapPin
          size=14
          className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 dark:text-gray-500"
        />
        <select
          value=selectedLocation
          onChange={e => onSelectLocation(ReactEvent.Form.target(e)["value"])}
          className="h-9 w-full appearance-none rounded-md border border-gray-200 bg-white pl-9 pr-8 text-xs font-medium text-gray-700 shadow-sm outline-none transition-colors focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-200">
          {nearMeActive
            ? <option value="near-me" disabled=true> {(ts`Near me`)->React.string} </option>
            : React.null}
          {locations
          ->Array.map(((value, label)) =>
            <option key=value value> {label->React.string} </option>
          )
          ->React.array}
        </select>
        <span
          className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-[10px] text-gray-400"
          ariaHidden=true>
          {"▾"->React.string}
        </span>
      </label>
      <button
        type_="button"
        onClick={_ => onNearMe()}
        disabled={status == Loading}
        ariaPressed={nearMeActive ? #"true" : #"false"}
        className={Util.cx([
          "inline-flex h-9 items-center justify-center gap-1.5 rounded-md border px-3 text-xs font-semibold shadow-sm transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 disabled:cursor-wait disabled:opacity-70 dark:focus-visible:ring-offset-[#1e1f23]",
          nearMeActive
            ? "border-[#94c93a] bg-[#bdf25d] text-black hover:bg-[#aee050]"
            : "border-gray-200 bg-white text-gray-700 hover:border-gray-300 hover:bg-gray-100 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-200 dark:hover:bg-[#2a2b30]",
        ])}>
        <Lucide.Crosshair size=14 className={status == Loading ? "animate-spin" : ""} />
        {(status == Loading ? ts`Locating…` : ts`Near me`)->React.string}
      </button>
    </div>
    <div className="mt-1.5 min-h-4" ariaLive=#polite>
      // Purely derived: an error (if any) wins; otherwise show the coordinate
      // readout whenever "Near me" is the active selection, else the hint.
      {switch errorMessage {
      | Some(message) =>
        <p className="text-[10px] text-red-600 dark:text-red-400"> {message->React.string} </p>
      | None =>
        switch (nearMeActive, coordinates) {
        | (true, Some(coords)) =>
          <p className="font-mono text-[10px] text-emerald-700 dark:text-emerald-400">
            {Lingui.Util.t`Within ${nearbyRadiusKm->Int.toString} km · ${coords.lat->Js.Float.toFixedWithPrecision(
                  ~digits=3,
                )}, ${coords.lng->Js.Float.toFixedWithPrecision(~digits=3)}`}
          </p>
        | _ =>
          <p className="text-[10px] text-gray-400 dark:text-gray-500">
            {(ts`Pick a location or use your current location.`)->React.string}
          </p>
        }
      }}
    </div>
  </section>
}
