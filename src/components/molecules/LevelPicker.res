%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

// Self-reported skill levels. `value` is a DUPR rating; callers convert to the
// internal scale with Rating.duprToMu before persisting.
type levelOption = {
  value: float,
  label: string,
  range: string,
}

let options = (): array<levelOption> => [
  {value: 2.0, label: ts`Complete Beginner`, range: "2.0–2.5"},
  {value: 2.5, label: ts`Beginner`, range: "2.5–3.0"},
  {value: 3.0, label: ts`Intermediate`, range: "3.0–3.5"},
  {value: 3.5, label: ts`Intermediate+`, range: "3.5–4.0"},
  {value: 4.0, label: ts`Advanced`, range: "4.0–5.0"},
  {value: 5.0, label: ts`Pro`, range: "5.0+"},
]

// Snap an arbitrary DUPR estimate onto the closest option, so a stored rating
// that came from anywhere (a computed rating, an older scale) still preselects.
let nearest = (dupr: float): float =>
  options()->Array.reduce(2.0, (best, opt) =>
    Js.Math.abs_float(opt.value -. dupr) < Js.Math.abs_float(best -. dupr) ? opt.value : best
  )

let isSelected = (value: option<float>, optValue: float) =>
  value->Option.map(v => Js.Math.abs_float(v -. optValue) < 0.01)->Option.getOr(false)

@react.component
let make = (~value: option<float>, ~onChange: float => unit) => {
  <div className="mt-1.5 grid grid-cols-1 gap-1.5 sm:grid-cols-2">
    {options()
    ->Array.map(opt => {
      let selected = isSelected(value, opt.value)
      <button
        key={opt.range}
        type_="button"
        onClick={_ => onChange(opt.value)}
        ariaPressed={selected ? #"true" : #"false"}
        className={`flex items-center justify-between gap-3 rounded-md border px-3 py-2 text-left transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] ${selected
            ? "border-[#94c93a] bg-[#bdf25d]/25 text-gray-900 dark:text-gray-100"
            : "border-gray-200 bg-white text-gray-700 hover:bg-gray-50 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-300 dark:hover:bg-[#2a2b30]"}`}>
        <span className="text-xs font-medium"> {opt.label->React.string} </span>
        <span className="flex-shrink-0 font-mono text-[10px] text-gray-500 dark:text-gray-400">
          {opt.range->React.string}
        </span>
      </button>
    })
    ->React.array}
  </div>
}
