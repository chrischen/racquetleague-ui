%%raw("import { t } from '@lingui/macro'")

@react.component
let make = (~courtCount: int, ~onCourtCountChange: int => unit) => {
  open Lingui.Util

  let handleChange = evt => {
    let value = ReactEvent.Form.target(evt)["value"]
    let parsed = value->Int.fromString->Option.getOr(1)
    let clamped = Math.Int.max(1, parsed)
    onCourtCountChange(clamped)
  }

  <div className="bg-slate-800 text-white px-6 py-4 flex items-center justify-between">
    <h1 className="text-2xl font-bold"> {t`Sports Event Draws`} </h1>
    <div className="flex items-center gap-3">
      <label htmlFor="courts" className="text-sm font-medium"> {t`Available Courts:`} </label>
      <input
        id="courts"
        type_="number"
        min="1"
        max="10"
        value={courtCount->Int.toString}
        onChange={handleChange}
        className="w-20 px-3 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
    </div>
  </div>
}
