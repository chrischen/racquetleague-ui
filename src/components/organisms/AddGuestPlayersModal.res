%%raw("import { t } from '@lingui/macro'")

@react.component
let make = (~onAdd: array<string> => unit, ~onClose: unit => unit) => {
  let ts = Lingui.UtilString.t
  let (namesText, setNamesText) = React.useState(() => "")

  let handleAdd = () => {
    // Split by newlines, trim whitespace, filter empty lines
    let names =
      namesText
      ->String.split("\n")
      ->Array.map(String.trim)
      ->Array.filter(name => name->String.length > 0)

    if names->Array.length > 0 {
      onAdd(names)
      onClose()
    }
  }

  let previewNames =
    namesText
    ->String.split("\n")
    ->Array.map(String.trim)
    ->Array.filter(name => name->String.length > 0)

  let previewCount = previewNames->Array.length

  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div className="bg-white rounded-xl shadow-2xl max-w-md w-full">
      // Header
      <div
        className="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between rounded-t-xl">
        <div className="flex items-center gap-3">
          <Lucide.UserPlus className="w-6 h-6 text-blue-600" />
          <h2 className="text-xl font-bold text-slate-800">
            {(ts`Add Guest Players`)->React.string}
          </h2>
        </div>
        <button
          onClick={_ => onClose()}
          className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          ariaLabel={ts`Close`}>
          <Lucide.X className="w-5 h-5 text-slate-600" />
        </button>
      </div>
      // Content
      <div className="p-6 space-y-4">
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">
            {(ts`Guest Names (one per line)`)->React.string}
          </label>
          <textarea
            value={namesText}
            onChange={e => setNamesText(ReactEvent.Form.target(e)["value"])}
            className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono text-sm"
            placeholder={(ts`John Smith`) ++
            "\n" ++
            (ts([`Jane Doe`], [])) ++
            "\n" ++
            (ts`Alex Johnson`)}
            rows={8}
          />
          <p className="text-xs text-slate-500 mt-1">
            {(ts`Enter each guest player's name on a new line`)->React.string}
          </p>
        </div>
        // Preview
        {previewCount > 0
          ? <div className="bg-slate-50 rounded-lg p-3 border border-slate-200">
              <div className="flex items-center gap-2 mb-2">
                <Lucide.Users className="w-4 h-4 text-slate-600" />
                <span className="text-sm font-semibold text-slate-700">
                  {(
                    ts`Preview (${previewCount->Int.toString} guest${previewCount !== 1
                      ? "s"
                      : ""})`
                  )->React.string}
                </span>
              </div>
              <div className="space-y-1 max-h-32 overflow-y-auto">
                {previewNames
                ->Array.mapWithIndex((name, index) =>
                  <div
                    key={index->Int.toString}
                    className="text-sm text-slate-600 flex items-center gap-2">
                    <span
                      className="w-5 h-5 rounded-full bg-slate-300 flex items-center justify-center text-xs font-bold text-slate-600">
                      {(index + 1)->Int.toString->React.string}
                    </span>
                    {name->React.string}
                  </div>
                )
                ->React.array}
              </div>
            </div>
          : React.null}
      </div>
      // Footer
      <div
        className="bg-slate-50 border-t border-slate-200 px-6 py-4 flex items-center justify-end gap-3 rounded-b-xl">
        <button
          type_="button"
          onClick={_ => onClose()}
          className="px-4 py-2 rounded-lg font-medium bg-white border border-slate-300 text-slate-700 hover:bg-slate-50 transition-colors">
          {(ts`Cancel`)->React.string}
        </button>
        <button
          type_="button"
          onClick={_ => handleAdd()}
          disabled={previewCount === 0}
          className={previewCount === 0
            ? "px-6 py-2 rounded-lg font-medium transition-colors shadow-md bg-slate-300 text-slate-500 cursor-not-allowed"
            : "px-6 py-2 rounded-lg font-medium transition-colors shadow-md bg-blue-600 text-white hover:bg-blue-700"}>
          {(
            ts`Add ${previewCount > 0
              ? previewCount->Int.toString ++ " "
              : ""}Guest${previewCount !== 1 ? "s" : ""}`
          )->React.string}
        </button>
      </div>
    </div>
  </div>
}
