%%raw("import { t } from '@lingui/macro'")
%%raw("import { css, cx } from '@linaria/core'")

module Fragment = %relay(`
  fragment PlayerCheckin_user on User
  {
    ...PlayerAvatar_user
    lineUsername
  }
`)

@react.component
let make = (
  ~players: array<Rating.Player.t<'a>>,
  ~checkedInPlayerIds: Set.t<string>,
  ~onToggleCheckin: string => unit,
  ~onTogglePaid: string => unit,
  ~onAdjustSeeds: array<(string, float)> => unit,
  ~onOpenTeamManagement: unit => unit,
  ~onOpenPlayerSettings: Rating.Player.t<'a> => unit,
  ~onOpenAddGuests: unit => unit,
  ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #PlayerCheckin_user]>>,
  ~initialPlayers: array<Rating.Player.t<'a>>,
) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let checkedInCount = checkedInPlayerIds->Set.size
  let (isExpanded, setIsExpanded) = React.useState(() => false)
  let (showSeedModal, setShowSeedModal) = React.useState(() => false)
  let totalPlayers = players->Array.length

  // Calculate rating changes (current mu - initial mu)
  let ratingChanges = React.useMemo2(() => {
    let initialMuMap = initialPlayers->Array.reduce(Map.make(), (acc, player) => {
      acc->Map.set(player.id, player.rating.mu)
      acc
    })

    players->Array.reduce(Map.make(), (acc, player) => {
      initialMuMap
      ->Map.get(player.id)
      ->Option.map(
        initialMu => {
          let change = player.rating.mu -. initialMu
          if change != 0.0 {
            acc->Map.set(player.id, change)
          }
          acc
        },
      )
      ->Option.getOr(acc)
    })
  }, (players, initialPlayers))

  // Collapse the section when 4 or more players are checked in
  React.useEffect1(() => {
    if checkedInCount < 4 {
      setIsExpanded(_ => true)
    }
    None
  }, [checkedInCount])

  // Sort players by rating (mu) from highest to lowest
  let sortedPlayers = React.useMemo1(() => {
    players->Array.toSorted((a, b) => {
      b.rating.mu -. a.rating.mu
    })
  }, [players])

  // Calculate normalized skill levels (0-100) based on mu ratings
  let (minMu, maxMu) = React.useMemo1(() => {
    if players->Array.length == 0 {
      (0., 0.)
    } else {
      let muValues = players->Array.map(p => p.rating.mu)
      let min = muValues->Array.reduce(1e10, (acc, val) => acc < val ? acc : val)
      let max = muValues->Array.reduce(-1e10, (acc, val) => acc > val ? acc : val)
      (min, max)
    }
  }, [players])

  let normalizeSkillLevel = (mu: float): float => {
    if maxMu == minMu {
      50. // If all players have same rating, show 50%
    } else {
      (mu -. minMu) /. (maxMu -. minMu) *. 100.
    }
  }

  <div className="bg-white border-b border-slate-200">
    <div className="px-6 py-4">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <button
          onClick={_ => setIsExpanded(prev => !prev)}
          className="flex items-center gap-3 hover:opacity-80 transition-opacity">
          <Lucide.UserCheck className="w-5 h-5 text-blue-600 flex-shrink-0" />
          <h2 className="text-lg font-semibold text-slate-800"> {t`Player Check-in`} </h2>
          <span className="text-sm text-slate-500">
            {t`${checkedInCount->Int.toString} of ${totalPlayers->Int.toString} checked in`}
          </span>
        </button>
        <div className="flex items-center gap-2">
          <button
            onClick={_ => onOpenAddGuests()}
            className="p-2 rounded-lg transition-colors flex items-center gap-1 bg-green-600 text-white hover:bg-green-700"
            title={ts`Add guest players`}>
            <Lucide.UserPlus className="w-4 h-4" />
          </button>
          <button
            onClick={_ => onOpenTeamManagement()}
            className="p-2 rounded-lg transition-colors flex items-center gap-1 bg-slate-600 text-white hover:bg-slate-700"
            title="Manage teams">
            <Lucide.Users className="w-4 h-4" />
          </button>
          <button
            onClick={_ => setShowSeedModal(_ => true)}
            className={"p-2 rounded-lg transition-colors flex items-center gap-1 bg-blue-600 text-white hover:bg-blue-700"}
            title="Adjust player seeds">
            <Lucide.ArrowUpNarrowWide className="w-4 h-4" />
            <Lucide.User className="w-4 h-4" />
          </button>
          <button
            onClick={_ => setIsExpanded(prev => !prev)}
            className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
            <Lucide.ChevronDown
              className={isExpanded
                ? "w-5 h-5 text-slate-600 transition-transform rotate-180"
                : "w-5 h-5 text-slate-600 transition-transform"}
            />
          </button>
        </div>
      </div>
    </div>
    {isExpanded
      ? <div className="px-6 pb-4">
          <ul
            className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3 list-none">
            <FramerMotion.AnimatePresence>
              {sortedPlayers
              ->Array.map(player => {
                let isCheckedIn = checkedInPlayerIds->Set.has(player.id)
                let playCount = player.count
                let buttonClass = isCheckedIn
                  ? "relative flex flex-col gap-2 p-2 rounded-lg border-2 transition-all border-green-500 bg-green-50"
                  : "relative flex flex-col gap-2 p-2 rounded-lg border-2 transition-all border-slate-200 bg-slate-50"
                let nameClass = isCheckedIn
                  ? "text-sm font-medium truncate w-full text-slate-800"
                  : "text-sm font-medium truncate w-full text-slate-500"

                // Calculate normalized skill level for this player
                let skillLevel = normalizeSkillLevel(player.rating.mu)

                <FramerMotion.Li
                  layout=true
                  key={player.id}
                  style={originX: 0.05, originY: 0.05}
                  initial={opacity: 0., scale: 0.8}
                  animate={opacity: 1., scale: 1.}
                  exit={opacity: 0., scale: 0.8}>
                  <div className={buttonClass}>
                    <button
                      onClick={e => {
                        e->ReactEvent.Mouse.stopPropagation
                        onOpenPlayerSettings(player)
                      }}
                      className="absolute top-1 right-1 p-1 hover:bg-slate-200 rounded transition-colors z-10"
                      title="Player settings">
                      <Lucide.Settings className="w-3 h-3 text-slate-500" />
                    </button>
                    <button
                      onClick={_ => onToggleCheckin(player.id)}
                      className="flex items-center gap-2 hover:opacity-80 transition-opacity w-full">
                      <PlayerAvatar
                        userFragmentRefs={player.data->Option.flatMap(getUserFragmentRefs)}
                        name={player.name}
                        skillLevel
                        size=#medium
                      />
                      <div className="flex flex-col items-start min-w-0 flex-1">
                        <span className={nameClass}> {player.name->React.string} </span>
                        <span className="text-xs text-slate-400 font-mono">
                          {`#${player.intId->Int.toString}`->React.string}
                        </span>
                      </div>
                      {isCheckedIn
                        ? <Lucide.UserCheck className="w-4 h-4 text-green-600 flex-shrink-0" />
                        : <Lucide.UserX className="w-4 h-4 text-slate-400 flex-shrink-0" />}
                    </button>
                    <div className="flex items-center justify-between gap-2 px-1">
                      {playCount > 0
                        ? <div className="flex items-center gap-1 text-xs text-slate-600">
                            <Lucide.Play className="w-3 h-3" />
                            <span className="font-medium">
                              {playCount->Int.toString->React.string}
                            </span>
                          </div>
                        : React.null}
                      {ratingChanges
                      ->Map.get(player.id)
                      ->Option.map(change => {
                        let isPositive = change > 0.0
                        let changeText = change->Float.toFixed(~digits=1)
                        <div
                          className={isPositive
                            ? "flex items-center gap-0.5 text-xs font-bold text-green-600"
                            : "flex items-center gap-0.5 text-xs font-bold text-red-600"}>
                          {isPositive
                            ? <Lucide.TrendingUp className="w-3 h-3" />
                            : <Lucide.TrendingDown className="w-3 h-3" />}
                          {changeText->React.string}
                        </div>
                      })
                      ->Option.getOr(React.null)}
                      <button
                        onClick={e => {
                          e->ReactEvent.Mouse.stopPropagation
                          onTogglePaid(player.id)
                        }}
                        className={player.paid
                          ? "px-1.5 py-0.5 rounded transition-all flex-shrink-0 ml-auto bg-green-600 hover:bg-green-700 text-white text-xs font-bold"
                          : "px-1.5 py-0.5 rounded transition-all flex-shrink-0 ml-auto bg-slate-300 hover:bg-slate-400 text-slate-600 text-xs font-bold"}
                        title={player.paid ? ts`Paid` : ts`Not paid`}>
                        {t`$`}
                      </button>
                    </div>
                  </div>
                </FramerMotion.Li>
              })
              ->React.array}
            </FramerMotion.AnimatePresence>
          </ul>
        </div>
      : React.null}
    {showSeedModal
      ? <SeedAdjustModal
          players
          onSave={onAdjustSeeds}
          onClose={() => setShowSeedModal(_ => false)}
          getUserFragmentRefs
        />
      : React.null}
  </div>
}
