%%raw("import { t } from '@lingui/macro'")

@react.component
let make = (
  ~currentRound: int,
  ~onAdvanceRound: unit => unit,
  ~onPreviousRound: unit => unit,
  ~canAdvance: bool,
  ~canGoBack: bool,
) => {
  let ts = Lingui.UtilString.t

  open Lingui.Util
  let previousButtonClass = canGoBack
    ? "p-2 rounded-lg transition-colors bg-slate-200 text-slate-700 hover:bg-slate-300"
    : "p-2 rounded-lg transition-colors bg-slate-100 text-slate-400 cursor-not-allowed"

  <div
    className="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between sticky top-0 z-10 shadow-sm">
    <div className="flex items-center gap-2">
      <span className="text-sm font-medium text-slate-600"> {t`Current Round:`} </span>
      <span className="text-2xl font-bold text-blue-600">
        {React.string(currentRound->Int.toString)}
      </span>
    </div>
    <div className="flex items-center gap-2">
      <button
        onClick={_ => onPreviousRound()}
        disabled={!canGoBack}
        className={previousButtonClass}
        ariaLabel={ts`Previous Round`}>
        <Lucide.ChevronLeft className="w-5 h-5" />
      </button>
      <button
        onClick={_ => onAdvanceRound()}
        disabled={!canAdvance}
        className="px-6 py-2 rounded-lg font-medium transition-colors bg-blue-600 text-white hover:bg-blue-700 flex items-center gap-2">
        {t`Advance to Next Round`}
        <Lucide.ChevronRight className="w-5 h-5" />
      </button>
    </div>
  </div>
}
