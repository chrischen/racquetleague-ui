%%raw("import { t } from '@lingui/macro'")

// Native start/end fields sitting under the event's time-window picker, ported
// from the Magic Patterns EventTimeRangeInputs: the same window, typed instead
// of dragged. Bounds and the minimum duration come from the picker's own
// config, so both controls accept exactly the same windows.
//
// Editing one end moves the other only when the window would otherwise fall
// under the minimum duration — typing a start never silently drags the end
// along, which is what separates this from the picker's move-the-whole-window
// drag.

let dayMinutes = 24 * 60

let minutesOfHours = (hours: float) => Js.Math.round(hours *. 60.0)->Float.toInt
let hoursOfMinutes = (minutes: int) => minutes->Int.toFloat /. 60.0
let clampMinutes = (value, low, high) => Js.Math.min_int(high, Js.Math.max_int(low, value))

// "HH:mm" → minutes past midnight. Midnight typed into the end field means the
// end of the day rather than the start of it, so a window can run to 24:00.
let parseTimeInput = (value: string, ~isEnd: bool): option<int> =>
  switch value->String.split(":") {
  | [hours, minutes] =>
    switch (hours->Int.fromString, minutes->Int.fromString) {
    | (Some(h), Some(m)) => h == 0 && m == 0 && isEnd ? Some(dayMinutes) : Some(h * 60 + m)
    | _ => None
    }
  | _ => None
  }

let formatTimeInput = (totalMinutes: int): string => {
  let normalized = mod(mod(totalMinutes, dayMinutes) + dayMinutes, dayMinutes)
  (normalized / 60)->Int.toString->String.padStart(2, "0") ++
  ":" ++
  mod(normalized, 60)->Int.toString->String.padStart(2, "0")
}

module TimeField = {
  @react.component
  let make = (
    ~label: React.element,
    ~fieldLabel: string,
    ~value: string,
    ~onChange: string => unit,
  ) =>
    <label className="block min-w-0">
      <span
        className="mb-1 block text-[10px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
        label
      </span>
      <div
        className="box-border h-11 w-full min-w-0 overflow-hidden rounded-lg border border-gray-200 bg-white transition-colors focus-within:border-[#94c93a] focus-within:ring-2 focus-within:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#1e1f23]">
        <input
          type_="time"
          value
          step=60.
          ariaLabel=fieldLabel
          onChange={e => onChange(ReactEvent.Form.target(e)["value"])}
          className="native-time-input border-0 bg-transparent text-gray-900 outline-none dark:text-gray-100"
        />
      </div>
    </label>
}

@react.component
let make = (
  ~value: TimeWindow.playIntent,
  ~onChange: TimeWindow.playIntent => unit,
  ~config: TimeWindowPicker.windowConfig=?,
) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t

  let minMinutes =
    config->Option.flatMap(c => c.hourMin)->Option.getOr(TimeWindowPicker.hourMin) * 60
  let maxMinutes =
    config->Option.flatMap(c => c.hourMax)->Option.getOr(TimeWindowPicker.hourMax) * 60
  let minDurationMinutes = minutesOfHours(
    config->Option.flatMap(c => c.minDuration)->Option.getOr(TimeWindowPicker.minDuration),
  )
  let startMinutes = minutesOfHours(value.start)
  let endMinutes = minutesOfHours(value.end)

  let updateStart = input =>
    switch parseTimeInput(input, ~isEnd=false) {
    | None => ()
    | Some(parsed) =>
      let nextStart = clampMinutes(parsed, minMinutes, maxMinutes - minDurationMinutes)
      let nextEnd = clampMinutes(
        Js.Math.max_int(endMinutes, nextStart + minDurationMinutes),
        nextStart + minDurationMinutes,
        maxMinutes,
      )
      onChange({...value, start: hoursOfMinutes(nextStart), end: hoursOfMinutes(nextEnd)})
    }

  let updateEnd = input =>
    switch parseTimeInput(input, ~isEnd=true) {
    | None => ()
    | Some(parsed) =>
      let nextEnd = clampMinutes(parsed, minMinutes + minDurationMinutes, maxMinutes)
      let nextStart = clampMinutes(
        Js.Math.min_int(startMinutes, nextEnd - minDurationMinutes),
        minMinutes,
        nextEnd - minDurationMinutes,
      )
      onChange({...value, start: hoursOfMinutes(nextStart), end: hoursOfMinutes(nextEnd)})
    }

  <div className="mt-3 min-w-0 border-t border-gray-100 pt-3 dark:border-[#2a2b30]">
    <div className="grid min-w-0 grid-cols-2 gap-2.5">
      <TimeField
        label={t`Start`}
        fieldLabel={ts`Start time`}
        value={formatTimeInput(startMinutes)}
        onChange=updateStart
      />
      <TimeField
        label={t`End`}
        fieldLabel={ts`End time`}
        value={formatTimeInput(endMinutes)}
        onChange=updateEnd
      />
    </div>
  </div>
}
