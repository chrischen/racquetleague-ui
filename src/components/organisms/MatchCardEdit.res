%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// MatchCardEdit Component - Edit mode for MatchCard
//
// Edit mode is for the line-up. Scores are entered through the score modal
// (tap or long-press a team on the card), so this view only ever displays the
// recorded score and passes it back through untouched — there is deliberately
// no second, divergent way to type one in here.

open Rating

@react.component
let make = (
  ~match: Match.t<'a>,
  ~courtNumber: int,
  ~score: option<(float, float)>=?,
  ~onDelete: option<unit => unit>=?,
  ~onSave: ((Match.t<'a>, option<(float, float)>)) => unit,
  ~onCancel: unit => unit,
  ~team1Element: React.element,
  ~team2Element: React.element,
) => {
  let ts = Lingui.UtilString.t

  let (team1, team2) = match
  let (scoreLeft, scoreRight) = score->Option.getOr((0., 0.))

  // 1/-1 is the "winner picked, no score entered" encoding used when a team is
  // tapped rather than scored, the same pair MatchCard hides. Rendering it here
  // would show a bare "-1" as though it were a real result.
  let showScore = switch (score, scoreLeft, scoreRight) {
  | (None, _, _) => false
  | (Some(_), 1., -1.) => false
  | (Some(_), -1., 1.) => false
  | _ => true
  }

  let scoreDisplay = value =>
    <div className="w-16 text-sm text-center font-bold text-slate-800">
      {showScore ? value->Float.toString->React.string : <span className="text-slate-300"> {React.string("—")} </span>}
    </div>

  let handleSave = () => {
    // Keep the original match order - don't swap teams based on winner, and
    // hand the recorded score straight back: this view cannot change it, so
    // re-deriving it here could only ever lose one.
    onSave(((team1, team2), score))
  }

  <div className="bg-white rounded-lg border-2 border-blue-500 shadow-sm overflow-hidden">
    <div
      className="bg-blue-100 px-2 py-1 border-b border-blue-200 flex items-center justify-between">
      <span className="text-xs font-semibold text-blue-900">
        {(ts`Court ${courtNumber->Int.toString} - Editing`)->React.string}
      </span>
      <div className="flex items-center gap-1">
        {onDelete
        ->Option.map(deleteFn =>
          // Same guard as the display view's delete: deleting is destructive
          // whichever view you happen to be in.
          <ConfirmButton
            button={<button
              type_="button"
              className="p-1 text-red-700 hover:bg-red-200 rounded transition-colors"
              ariaLabel={ts`Delete match`}>
              <Lucide.Trash2 className="w-4 h-4" />
            </button>}
            title={t`Delete this match?`}
            description={t`The match will be removed from this round. You can restore the originally scheduled matches using the round reset icon.`}
            onConfirmed={deleteFn}
          />
        )
        ->Option.getOr(React.null)}
        <button
          onClick={_ => {
            handleSave()
            onCancel()
          }}
          className="p-1 text-green-700 hover:bg-green-200 rounded transition-colors"
          ariaLabel={ts`Save`}>
          <Lucide.Check className="w-4 h-4" />
        </button>
      </div>
    </div>
    <div className="flex flex-col">
      // Team 1 - Editing
      <div className="p-2 bg-slate-50 flex-1 border-b border-slate-200">
        <div className="flex items-center justify-between mb-2">
          <div className="text-xs font-semibold text-slate-600"> {(ts`TEAM 1`)->React.string} </div>
          {scoreDisplay(scoreLeft)}
        </div>
        <div className="space-y-2"> {team1Element} </div>
      </div>
      // VS Divider - Horizontal only in edit mode
      <div className="relative flex items-center justify-center bg-slate-50">
        <div
          className="absolute inset-0 flex items-center justify-center border-b border-slate-200">
          <span className="bg-slate-50 px-2 text-xs font-bold text-slate-400">
            {(ts`VS`)->React.string}
          </span>
        </div>
      </div>
      // Team 2 - Editing
      <div className="p-2 bg-slate-50 flex-1">
        <div className="flex items-center justify-between mb-2">
          <div className="text-xs font-semibold text-slate-600"> {(ts`TEAM 2`)->React.string} </div>
          {scoreDisplay(scoreRight)}
        </div>
        <div className="space-y-2"> {team2Element} </div>
      </div>
    </div>
  </div>
}
