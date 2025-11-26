%%raw("import { t } from '@lingui/macro'")

// RatingAdjustmentCard Component - Displays a rating adjustment event in the timeline
//
// This component shows when manual rating adjustments were applied, which players
// were affected, and provides a delete button to remove the adjustment.
//
// Usage Example:
// ```rescript
// <RatingAdjustmentCard
//   adjustments={adjustmentsForRound}
//   roundNumber=2
//   playersCache
//   onDelete={() => handleDeleteAdjustment(adjustmentTimestamp)}
// />
// ```

open Rating

@react.component
let make = (
  ~adjustments: array<RatingAdjustment.t>,
  ~roundNumber: int,
  ~playersCache: PlayersCache.t<'a>,
  ~onDelete: unit => unit,
) => {
  let ts = Lingui.UtilString.t

  // Group adjustments by player for display
  let adjustmentDisplay = adjustments->Array.map(adj => {
    let player = playersCache->Js.Dict.get(adj.playerId)
    let playerName = player->Option.map(p => p.name)->Option.getOr("Unknown Player")
    let sign = adj.differential >= 0. ? "+" : ""
    let differential = adj.differential->Float.toFixed(~digits=1)
    
    (playerName, `${sign}${differential}`)
  })

  <div className="my-4 mx-auto max-w-3xl">
    <div className="bg-amber-50 border-2 border-amber-300 rounded-lg shadow-sm overflow-hidden">
      // Header
      <div className="bg-amber-100 border-b border-amber-300 px-4 py-2 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Lucide.Info className="w-5 h-5 text-amber-700" />
          <span className="font-semibold text-amber-900">
            {(ts`Rating Adjustment - Applied Before Round ${roundNumber->Int.toString}`)->React.string}
          </span>
        </div>
        <button
          onClick={_ => onDelete()}
          className="p-1 rounded hover:bg-amber-200 transition-colors text-amber-700 hover:text-amber-900"
          title={ts`Delete adjustment`}>
          <Lucide.Trash2 className="w-4 h-4" />
        </button>
      </div>
      // Adjustments List
      <div className="px-4 py-3">
        <div className="flex flex-wrap gap-x-6 gap-y-2">
          {adjustmentDisplay
          ->Array.map(((playerName, differential)) => {
            <div key={playerName} className="flex items-center gap-2">
              <span className="text-sm font-medium text-slate-700">{playerName->React.string}</span>
              <span
                className={`text-sm font-mono font-bold ${differential->String.startsWith("+")
                    ? "text-green-600"
                    : "text-red-600"}`}>
                {differential->React.string}
              </span>
            </div>
          })
          ->React.array}
        </div>
      </div>
    </div>
  </div>
}
