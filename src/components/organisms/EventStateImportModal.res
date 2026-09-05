%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// Takes an exported history string and shows exactly what accepting it would do
// before anything is written. The preview is recomputed on every keystroke
// rather than memoised, so it always describes the manager's current state.
@react.component
let make = (
  ~preview: string => result<EventStateTransfer.counts, string>,
  ~onImport: string => unit,
  ~disabled: bool,
  ~onClose: unit => unit,
) => {
  let ts = Lingui.UtilString.t
  let (text, setText) = React.useState(() => "")

  let previewResult = text->String.trim == "" ? None : Some(preview(text))

  let canImport = switch previewResult {
  | Some(Ok(counts)) => counts.EventStateTransfer.importedMatches > 0
  | _ => false
  }

  let countRow = (label: React.element, value: int, emphasis: string) =>
    <div className="flex items-center justify-between text-sm">
      <span className="text-slate-600"> label </span>
      <span className={emphasis}> {React.string(value->Int.toString)} </span>
    </div>

  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full">
      <div
        className="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between rounded-t-xl">
        <div className="flex items-center gap-3">
          <Lucide.Upload className="w-6 h-6 text-blue-600" />
          <h2 className="text-xl font-bold text-slate-800"> {t`Import History`} </h2>
        </div>
        <button
          onClick={_ => onClose()}
          className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          ariaLabel={ts`Close`}>
          <Lucide.X className="w-5 h-5 text-slate-600" />
        </button>
      </div>
      <div className="p-6 space-y-4">
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">
            {t`Paste an exported history`}
          </label>
          <textarea
            value={text}
            onChange={e => setText(ReactEvent.Form.target(e)["value"])}
            className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono text-xs"
            placeholder={ts`{"format":"pkuru-event-history", ...}`}
            rows={10}
          />
          <p className="text-xs text-slate-500 mt-1">
            {t`Rounds are placed in the timeline by their timestamps, so importing can add rounds before the ones already here.`}
          </p>
        </div>
        {switch previewResult {
        | None => React.null
        | Some(Error(message)) =>
          <div
            className="flex items-start gap-3 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            <Lucide.AlertTriangle className="w-4 h-4 mt-0.5 shrink-0" />
            <span className="flex-1"> {React.string(message)} </span>
          </div>
        | Some(Ok(counts)) =>
          <div className="bg-slate-50 rounded-lg p-3 border border-slate-200 space-y-1">
            {countRow(
              t`Rounds to import`,
              counts.EventStateTransfer.importedRounds,
              "font-semibold text-slate-800",
            )}
            {countRow(
              t`Matches to import`,
              counts.importedMatches,
              counts.importedMatches > 0 ? "font-semibold text-green-600" : "font-semibold text-slate-400",
            )}
            {countRow(
              t`Skipped, players not in this event`,
              counts.skippedMissingPlayers,
              counts.skippedMissingPlayers > 0
                ? "font-semibold text-amber-600"
                : "font-semibold text-slate-400",
            )}
            {countRow(
              t`Skipped, already here`,
              counts.skippedDuplicates,
              counts.skippedDuplicates > 0
                ? "font-semibold text-amber-600"
                : "font-semibold text-slate-400",
            )}
            {countRow(
              t`Skipped rating adjustments`,
              counts.skippedAdjustments,
              counts.skippedAdjustments > 0
                ? "font-semibold text-amber-600"
                : "font-semibold text-slate-400",
            )}
            <p className="text-xs text-slate-500 pt-2">
              {t`Imported matches count as already synced, and keep their original ids so syncing again cannot duplicate them on the server.`}
            </p>
          </div>
        }}
        {disabled
          ? <p className="text-xs text-amber-600">
              {t`Wait for the draw currently being generated to finish.`}
            </p>
          : React.null}
      </div>
      <div
        className="bg-slate-50 border-t border-slate-200 px-6 py-4 flex items-center justify-end gap-3 rounded-b-xl">
        <button
          type_="button"
          onClick={_ => onClose()}
          className="px-4 py-2 rounded-lg font-medium bg-white border border-slate-300 text-slate-700 hover:bg-slate-50 transition-colors">
          {t`Cancel`}
        </button>
        <button
          type_="button"
          onClick={_ => onImport(text)}
          disabled={disabled || !canImport}
          className={disabled || !canImport
            ? "px-6 py-2 rounded-lg font-medium transition-colors shadow-md bg-slate-300 text-slate-500 cursor-not-allowed"
            : "px-6 py-2 rounded-lg font-medium transition-colors shadow-md bg-blue-600 text-white hover:bg-blue-700"}>
          {t`Import`}
        </button>
      </div>
    </div>
  </div>
}
