%%raw("import { t } from '@lingui/macro'")

// Time zone field from the Magic Patterns TimeZoneField. The chosen zone reads
// as a plain name with an Edit link beside it, and only turns into a select
// when asked, so a field most organizers never touch stays quiet.
//
// The zone already in use and the viewer's own lead the list, so both are
// offered even when they are not among the ones listed below.

let ts = Lingui.UtilString.t

// Every offset is reachable, but only one place per offset is offered, so the
// list stays a short scroll instead of ~400 near-identical IANA names. Two
// exceptions share an offset on purpose: regions that differ on daylight
// saving (Phoenix and Denver, Johannesburg and Helsinki, Brisbane and Sydney)
// would otherwise be an hour out for half the year, and the app's own locales
// keep their own entry. West to east.
let selectableZones = [
  "Pacific/Pago_Pago",
  "Pacific/Honolulu",
  "America/Anchorage",
  "America/Los_Angeles",
  "America/Denver",
  "America/Phoenix",
  "America/Chicago",
  "America/New_York",
  "America/Halifax",
  "America/St_Johns",
  "America/Sao_Paulo",
  "Atlantic/South_Georgia",
  "Atlantic/Azores",
  "UTC",
  "Atlantic/Reykjavik",
  "Europe/London",
  "Africa/Lagos",
  "Europe/Berlin",
  "Africa/Johannesburg",
  "Europe/Helsinki",
  "Europe/Moscow",
  "Asia/Tehran",
  "Asia/Dubai",
  "Asia/Kabul",
  "Asia/Karachi",
  "Asia/Kolkata",
  "Asia/Kathmandu",
  "Asia/Dhaka",
  "Asia/Yangon",
  "Asia/Bangkok",
  "Asia/Shanghai",
  "Asia/Taipei",
  "Asia/Singapore",
  "Australia/Perth",
  "Asia/Tokyo",
  "Asia/Seoul",
  "Australia/Adelaide",
  "Australia/Brisbane",
  "Australia/Sydney",
  "Pacific/Guadalcanal",
  "Pacific/Auckland",
  "Pacific/Apia",
  "Pacific/Kiritimati",
]

// The everyday name for a zone. Anything off the known list falls back to its
// city, which reads better than the raw "Area/City" identifier.
let timeZoneLabel = (timeZone: string): string =>
  switch timeZone {
  | "UTC" => ts`Coordinated Universal Time`
  | "Pacific/Honolulu" => ts`Hawaii Time`
  | "America/Anchorage" => ts`Alaska Time`
  | "America/Los_Angeles" => ts`Pacific Time`
  | "America/Denver" => ts`Mountain Time`
  | "America/Chicago" => ts`Central Time`
  | "America/New_York" => ts`Eastern Time`
  | "America/Halifax" => ts`Atlantic Time`
  | "Europe/London" => ts`United Kingdom Time`
  | "Europe/Berlin" => ts`Central European Time`
  | "Europe/Helsinki" => ts`Eastern European Time`
  | "America/Phoenix" => ts`Arizona Time`
  | "America/St_Johns" => ts`Newfoundland Time`
  | "Pacific/Pago_Pago" => ts`American Samoa Time`
  | "Africa/Lagos" => ts`West Africa Time`
  | "Asia/Kolkata" => ts`India Time`
  | "Asia/Shanghai" => ts`China Time`
  | "Asia/Seoul" => ts`Korea Time`
  | "Asia/Singapore" => ts`Singapore Time`
  | "Asia/Tokyo" => ts`Japan Time`
  | "Australia/Perth" => ts`Western Australia Time`
  | "Australia/Adelaide" => ts`Central Australia Time`
  | "Australia/Brisbane" => ts`Queensland Time`
  | "Australia/Sydney" => ts`Eastern Australia Time`
  | "Pacific/Auckland" => ts`New Zealand Time`
  | "Pacific/Guadalcanal" => ts`Solomon Islands Time`
  | "Pacific/Apia" => ts`Samoa Time`
  | "Pacific/Kiritimati" => ts`Line Islands Time`
  | other =>
    switch other->String.split("/")->Array.last {
    | Some(city) if city != "" =>
      let place = city->String.replaceAll("_", " ")
      ts`${place} Time`
    | _ => ts`Local time`
    }
  }

@react.component
let make = (~value: string, ~onChange: string => unit) => {
  open Lingui.Util
  let (editing, setEditing) = React.useState(() => false)

  // Only read while editing, which is necessarily after mount, so the viewer's
  // zone never reaches the server render and cannot mismatch on hydration.
  let options = React.useMemo1(
    () =>
      Array.concat([value, Util.Timezone.browser()], selectableZones)->Array.reduce([], (
        acc,
        zone,
      ) => acc->Array.includes(zone) ? acc : Array.concat(acc, [zone])),
    [value],
  )

  <div className="min-w-0">
    <div className="flex min-w-0 items-center justify-between gap-3">
      <div className="min-w-0">
        <span
          className="block text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
          {t`Time zone`}
        </span>
        {editing
          ? React.null
          : <span
              className="mt-1 block truncate text-sm font-medium text-gray-900 dark:text-gray-100">
              {timeZoneLabel(value)->React.string}
            </span>}
      </div>
      {editing
        ? React.null
        : <button
            type_="button"
            onClick={_ => setEditing(_ => true)}
            className="flex-shrink-0 text-xs font-semibold text-[#4d6f12] underline-offset-2 hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-[#bdf25d]">
            {t`Edit`}
          </button>}
    </div>
    {editing
      ? <div className="mt-2 flex min-w-0 items-center gap-2">
          <select
            value
            onChange={e => onChange(ReactEvent.Form.target(e)["value"])}
            ariaLabel={ts`Time zone`}
            className="h-11 min-w-0 flex-1 rounded-lg border border-gray-200 bg-white px-3 text-sm font-medium text-gray-900 outline-none transition-colors focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:text-gray-100">
            {options
            ->Array.map(zone =>
              <option key=zone value=zone> {timeZoneLabel(zone)->React.string} </option>
            )
            ->React.array}
          </select>
          <button
            type_="button"
            onClick={_ => setEditing(_ => false)}
            className="h-11 flex-shrink-0 rounded-lg border border-gray-200 px-3 text-xs font-semibold text-gray-700 transition-colors hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:border-[#3a3b40] dark:text-gray-200 dark:hover:bg-[#2a2b30]">
            {t`Done`}
          </button>
        </div>
      : React.null}
  </div>
}
