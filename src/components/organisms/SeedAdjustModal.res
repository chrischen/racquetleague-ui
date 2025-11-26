%%raw("import { t } from '@lingui/macro'")

// SeedAdjustModal Component - Drag-and-drop interface for adjusting player seeds
//
// This component allows users to reorder players to adjust their initial ratings.
// Players can be dragged to change their seeding order. When saved, the ratings
// are interpolated to maintain the new order.
//
// Usage Example:
// ```rescript
// <SeedAdjustModal
//   players={playersWithAdjustedSeeds}
//   onSave={adjustPlayerSeeds}
//   onClose={() => setShowSeedModal(false)}
//   getUserFragmentRefs
// />
// ```

open Rating

// Separate component to receive dragHandleProps from SortableItem
module SortableItemContent = {
  @react.component
  let make = (
    ~player: Player.t<'a>,
    ~index: int,
    ~skillLevel: float,
    ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #PlayerRow_user]>>,
    ~dragHandleProps: option<{..}>=?,
  ) => {
    let ts = Lingui.UtilString.t

    <div
      className="bg-white border-2 border-slate-200 rounded-lg hover:border-blue-400 transition-all">
      <div className="flex items-center gap-3 p-3">
        // Rank number
        <div className="flex-shrink-0 w-8 text-center">
          <span className="text-lg font-bold text-slate-700">
            {(index + 1)->Int.toString->React.string}
          </span>
        </div>
        // Drag handle - only this part is draggable
        <div
          className="flex-shrink-0 p-2 cursor-grab active:cursor-grabbing touch-none"
          ref={dragHandleProps
          ->Option.flatMap(props => props["ref"]->Obj.magic->Nullable.toOption)
          ->Option.getOr(Obj.magic(Js.Nullable.null))}
          onClick={dragHandleProps
          ->Option.flatMap(props => props["onClick"]->Obj.magic->Nullable.toOption)
          ->Option.getOr(Obj.magic(Js.Nullable.null))}
          onPointerDown={dragHandleProps
          ->Option.flatMap(props => props["onPointerDown"]->Obj.magic->Nullable.toOption)
          ->Option.getOr(Obj.magic(Js.Nullable.null))}>
          <Lucide.GripVertical className="w-5 h-5 text-slate-400" />
        </div>
        // Player info
        <div className="flex-1 min-w-0">
          <PlayerRow
            player
            isEditing={false}
            winner={None}
            teamSide={PlayerRow.Left}
            skillLevel
            getUserFragmentRefs
          />
        </div>
        // Rating display
        <div className="flex-shrink-0 text-right">
          <div className="text-sm font-semibold text-slate-700">
            {player.rating.mu->Float.toFixed(~digits=1)->React.string}
          </div>
          <div className="text-xs text-slate-500"> {(ts`mu`)->React.string} </div>
        </div>
      </div>
    </div>
  }
}

@react.component
let make = (
  ~players: array<Player.t<'a>>,
  ~onSave: array<(string, float)> => unit,
  ~onClose: unit => unit,
  ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #PlayerRow_user]>>,
) => {
  let ts = Lingui.UtilString.t

  // Local state for player order (initially sorted by current rating)
  let (sortedPlayers, setSortedPlayers) = React.useState(() => {
    players->Array.toSorted((a, b) => Float.compare(b.rating.mu, a.rating.mu))
  })

  // Calculate min/max ratings for normalization
  let minRating =
    sortedPlayers
    ->Array.map(p => p.rating.mu)
    ->Array.reduce(100., (acc, next) => next < acc ? next : acc)

  let maxRating =
    sortedPlayers
    ->Array.map(p => p.rating.mu)
    ->Array.reduce(0., (acc, next) => next > acc ? next : acc)

  let handleSave = () => {
    // Convert sorted players to (playerId, currentMu) tuples
    let playerData = sortedPlayers->Array.map(p => (p.id, p.rating.mu))
    onSave(playerData)
    onClose()
  }

  <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] flex flex-col">
      // Header
      <div className="p-6 border-b border-slate-200">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold text-slate-800">
              {(ts`Adjust Player Seeds`)->React.string}
            </h2>
            <p className="text-sm text-slate-600 mt-1">
              {(ts`Drag players to reorder their initial seeding`)->React.string}
            </p>
          </div>
          <button
            onClick={_ => onClose()}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
            <Lucide.X className="w-6 h-6 text-slate-600" />
          </button>
        </div>
      </div>
      // Scrollable player list
      <div className="flex-1 overflow-y-auto p-6">
        <DndKit.DndContext
          onDragEnd={event => {
            let activeId = event.active.id
            let overId = event.over->Option.map(over => over.id)

            overId->Option.forEach(overId => {
              if activeId != overId {
                setSortedPlayers(currentPlayers => {
                  let oldIndex = currentPlayers->Array.findIndex(p => p.id == activeId)
                  let newIndex = currentPlayers->Array.findIndex(p => p.id == overId)

                  if oldIndex != -1 && newIndex != -1 {
                    let mutablePlayers = currentPlayers->Array.copy
                    let item = mutablePlayers->Array.getUnsafe(oldIndex)
                    // Remove from old position
                    let _ =
                      mutablePlayers->Js.Array2.spliceInPlace(~pos=oldIndex, ~remove=1, ~add=[])
                    // Insert at new position
                    let _ =
                      mutablePlayers->Js.Array2.spliceInPlace(~pos=newIndex, ~remove=0, ~add=[item])

                    // Adjust rating only for the dropped player at its new position
                    // Get ratings of players directly above and below
                    let prevMu = if newIndex > 0 {
                      mutablePlayers->Array.get(newIndex - 1)->Option.map(p => p.rating.mu)
                    } else {
                      None
                    }

                    let nextMu =
                      mutablePlayers->Array.get(newIndex + 1)->Option.map(p => p.rating.mu)

                    // Interpolate between direct neighbors
                    let newMu = switch (prevMu, nextMu) {
                    | (Some(prev), Some(next)) => (prev +. next) /. 2.0
                    | (Some(prev), None) => prev -. 0.01 // Moved to bottom
                    | (None, Some(next)) => next +. 0.01 // Moved to top
                    | (None, None) => item.rating.mu // Only player in list
                    }

                    // Update only the moved player's rating at the new position
                    let updatedItem = {
                      ...item,
                      rating: {
                        Rating.mu: newMu,
                        sigma: item.rating.sigma,
                      },
                    }

                    // Replace the item at newIndex with the updated version
                    let _ =
                      mutablePlayers->Js.Array2.spliceInPlace(
                        ~pos=newIndex,
                        ~remove=1,
                        ~add=[updatedItem],
                      )

                    mutablePlayers
                  } else {
                    currentPlayers
                  }
                })
              }
            })
          }}>
          <DndKit.SortableContext
            items={sortedPlayers->Array.map(p => p.id)}
            strategy={DndKit.SortableContext.verticalListSortingStrategy}>
            <div className="space-y-2">
              {sortedPlayers
              ->Array.mapWithIndex((player, index) => {
                let skillLevel = if maxRating == minRating {
                  50. // If all players have same rating, show 50%
                } else {
                  (player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.
                }

                <DndKit.SortableItem key={player.id} id={player.id} handle={true}>
                  <SortableItemContent player index skillLevel getUserFragmentRefs />
                </DndKit.SortableItem>
              })
              ->React.array}
            </div>
          </DndKit.SortableContext>
        </DndKit.DndContext>
      </div>
      // Footer with actions
      <div className="p-6 border-t border-slate-200 flex items-center justify-between gap-4">
        <button
          onClick={_ => onClose()}
          className="px-6 py-2.5 text-slate-700 hover:bg-slate-100 rounded-lg transition-colors font-medium">
          {(ts`Cancel`)->React.string}
        </button>
        <button
          onClick={_ => handleSave()}
          className="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium shadow-sm">
          {(ts`Save Seed Adjustments`)->React.string}
        </button>
      </div>
    </div>
  </div>
}
