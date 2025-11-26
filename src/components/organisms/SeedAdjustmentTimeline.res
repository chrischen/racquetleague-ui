%%raw("import { t } from '@lingui/macro'")

// SeedAdjustmentTimeline Component - Timeline display for seed/rating adjustments
//
// This component displays rating adjustments in a collapsible timeline format,
// showing which players had rating changes and the absolute rating change amount.
//
// Usage Example:
// ```rescript
// <SeedAdjustmentTimeline
//   adjustments={adjustmentsForRound}
//   playersCache
//   getUserFragmentRefs={data => data.user->Option.map(u => u.fragmentRefs)}
//   onDelete={() => handleDeleteAdjustment(adjustmentTimestamp)}
// />
// ```

open Rating

module Fragment = %relay(`
  fragment SeedAdjustmentTimeline_user on User {
    picture
  }
`)

// PlayerAvatar sub-component that can use the fragment
module PlayerAvatar = {
  @react.component
  let make = (
    ~userFragmentRefs: option<RescriptRelay.fragmentRefs<[> #SeedAdjustmentTimeline_user]>>,
    ~name: string,
  ) => {
    let pictureUrl = userFragmentRefs->Option.flatMap(fragmentRefs => {
      let userData = Fragment.use(fragmentRefs)
      userData.picture
    })

    pictureUrl
    ->Option.map(url =>
      <img src={url} alt={name} className="w-7 h-7 rounded-full object-cover flex-shrink-0" />
    )
    ->Option.getOr(
      <div
        className="w-7 h-7 rounded-full bg-slate-200 flex-shrink-0 flex items-center justify-center">
        <span className="text-xs font-semibold text-slate-600">
          {name->String.charAt(0)->React.string}
        </span>
      </div>,
    )
  }
}

type playerChange<'a> = {
  player: Player.t<'a>,
  differential: float,
}

@react.component
let make = (
  ~adjustments: array<RatingAdjustment.t>,
  ~playersCache: PlayersCache.t<'a>,
  ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #SeedAdjustmentTimeline_user]>>,
  ~onDelete: unit => unit,
) => {
  let handleDelete = (e: ReactEvent.Mouse.t) => {
    e->ReactEvent.Mouse.stopPropagation
    onDelete()
  }
  let ts = Lingui.UtilString.t
  let (isExpanded, setIsExpanded) = React.useState(() => false)

  // Build changes array from adjustments
  let changes = React.useMemo(() => {
    adjustments
    ->Array.map(adj => {
      let player = playersCache->Js.Dict.get(adj.playerId)
      player->Option.map(p => {player: p, differential: adj.differential})
    })
    ->Array.filterMap(x => x)
  }, (adjustments, playersCache))

  // Count up/down movements based on differential
  let upCount = changes->Array.filter(c => c.differential > 0.)->Array.length
  let downCount = changes->Array.filter(c => c.differential < 0.)->Array.length

  <div className="my-4 relative">
    // Divider line
    <div className="absolute inset-0 flex items-center" ariaHidden={true}>
      <div className="w-full border-t border-slate-300" />
    </div>
    <div className="relative flex justify-center">
      <div className="bg-slate-50 px-4">
        <div
          className="bg-white rounded-lg border border-amber-300 shadow-sm hover:bg-amber-50 transition-colors w-full max-w-4xl">
          // Collapsed Header
          <div className="flex items-center justify-between px-3 py-2">
            <button
              onClick={_ => setIsExpanded(prev => !prev)}
              className="flex items-center gap-2 flex-1 text-left">
              <div
                className="w-6 h-6 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0">
                <Lucide.ArrowUpCircle className="w-3 h-3 text-amber-700" />
              </div>
              <div className="text-left">
                <h3 className="text-xs font-bold text-slate-900">
                  {(ts`Seeds Adjusted`)->React.string}
                </h3>
                <p className="text-xs text-slate-600">
                  {`${changes->Array.length->Int.toString} player${changes->Array.length != 1
                      ? "s"
                      : ""}`->React.string}
                  {upCount > 0
                    ? <span className="ml-1 text-green-600">
                        {`↑${upCount->Int.toString}`->React.string}
                      </span>
                    : React.null}
                  {downCount > 0
                    ? <span className="ml-1 text-red-600">
                        {`↓${downCount->Int.toString}`->React.string}
                      </span>
                    : React.null}
                </p>
              </div>
            </button>
            <div className="flex items-center gap-2">
              {isExpanded
                ? <button
                    onClick={handleDelete}
                    className="p-1.5 hover:bg-red-100 rounded transition-colors"
                    title="Delete seed adjustment">
                    <Lucide.Trash2 className="w-3.5 h-3.5 text-red-600" />
                  </button>
                : React.null}
              <button
                onClick={_ => setIsExpanded(prev => !prev)}
                className="p-1 hover:bg-slate-100 rounded transition-colors">
                <Lucide.ChevronDown
                  className={`w-4 h-4 text-slate-400 transition-transform ${isExpanded
                      ? "rotate-180"
                      : ""}`}
                />
              </button>
            </div>
          </div>
          // Expanded Content
          {isExpanded
            ? <div className="px-3 pb-3 pt-2 border-t border-amber-200">
                <div
                  className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2">
                  {changes
                  ->Array.map(change => {
                    let isUp = change.differential > 0.
                    let isDown = change.differential < 0.
                    let movementAmount = Js.Math.abs_float(change.differential)

                    <div
                      key={change.player.id}
                      className="flex items-center gap-2 p-2 bg-slate-50 rounded border border-slate-200">
                      // Avatar
                      {change.player.data
                      ->Option.flatMap(getUserFragmentRefs)
                      ->Option.map(userFragmentRefs =>
                        <PlayerAvatar
                          userFragmentRefs={Some(userFragmentRefs)} name={change.player.name}
                        />
                      )
                      ->Option.getOr(
                        <PlayerAvatar userFragmentRefs={None} name={change.player.name} />,
                      )}
                      // Player Info
                      <div className="flex-1 min-w-0">
                        <div className="text-xs font-semibold text-slate-800 truncate">
                          {change.player.name->React.string}
                        </div>
                        <div className="flex items-center gap-1">
                          {isUp
                            ? <div className="flex items-center gap-0.5 text-green-600">
                                <Lucide.ChevronUp className="w-3 h-3" />
                                <span className="text-xs font-bold">
                                  {movementAmount->Float.toFixed(~digits=1)->React.string}
                                </span>
                              </div>
                            : React.null}
                          {isDown
                            ? <div className="flex items-center gap-0.5 text-red-600">
                                <Lucide.ChevronDown className="w-3 h-3" />
                                <span className="text-xs font-bold">
                                  {movementAmount->Float.toFixed(~digits=1)->React.string}
                                </span>
                              </div>
                            : React.null}
                          {!isUp && !isDown
                            ? <span className="text-xs text-slate-400">
                                {"—"->React.string}
                              </span>
                            : React.null}
                        </div>
                      </div>
                    </div>
                  })
                  ->React.array}
                </div>
              </div>
            : React.null}
        </div>
      </div>
    </div>
  </div>
}
