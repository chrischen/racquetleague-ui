%%raw("import { t } from '@lingui/macro'")

// Re-use the MatchCard fragment which includes picture
module Fragment = %relay(`
  fragment PlayerReplaceModal_user on User {
    picture
  }
`)

// Helper function to get skill color based on level
let getSkillColor = (skillLevel: float): string => {
  if skillLevel >= 75.0 {
    "#10b981" // green-500
  } else if skillLevel >= 50.0 {
    "#3b82f6" // blue-500
  } else if skillLevel >= 25.0 {
    "#f59e0b" // amber-500
  } else {
    "#ef4444" // red-500
  }
}

@react.component
let make = (
  ~currentPlayer: Rating.Player.t<'a>,
  ~availablePlayers: array<Rating.Player.t<'a>>,
  ~onSelect: Rating.Player.t<'a> => unit,
  ~onClose: unit => unit,
  ~getUserFragmentRefs: 'a => option<
    RescriptRelay.fragmentRefs<[> #PlayerReplaceModal_user | #MatchCard_user]>,
  >,
) => {
  open Lingui.Util

  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
      // Header
      <div
        className="sticky top-0 bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Lucide.Users className="w-6 h-6 text-blue-600" />
          <div>
            <h2 className="text-xl font-bold text-slate-800"> {t`Replace Player`} </h2>
            <p className="text-sm text-slate-600">
              {t`Replacing: `}
              <span className="font-semibold"> {currentPlayer.name->React.string} </span>
            </p>
          </div>
        </div>
        <button
          onClick={_ => onClose()}
          className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          ariaLabel="Close">
          <Lucide.X className="w-5 h-5 text-slate-600" />
        </button>
      </div>
      // Available Players List
      <div className="p-6">
        {availablePlayers->Array.length === 0
          ? <div className="text-center py-8 text-slate-500">
              <Lucide.Users className="w-12 h-12 mx-auto mb-3 text-slate-300" />
              <p className="font-medium"> {t`No available players`} </p>
              <p className="text-sm"> {t`All checked-in players are already in this round`} </p>
            </div>
          : <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {availablePlayers
              ->Array.map(player => {
                let skillLevel = player.ratingOrdinal
                let skillColor = getSkillColor(skillLevel)
                let radius = 18.0
                let circumference = 2.0 *. Js.Math._PI *. radius
                let progress = skillLevel /. 100.0 *. circumference

                // Extract picture from GraphQL fragment
                let picture =
                  player.data
                  ->Option.flatMap(getUserFragmentRefs)
                  ->Option.flatMap(fragmentRefs => {
                    let userData = Fragment.use(fragmentRefs)
                    userData.picture
                  })

                <button
                  key={player.id}
                  onClick={_ => onSelect(player)}
                  className="flex items-center gap-3 p-3 rounded-lg border-2 border-slate-200 hover:border-blue-500 hover:bg-blue-50 transition-all text-left">
                  // Avatar with skill progress
                  <div className="relative flex-shrink-0">
                    <svg className="w-12 h-12 -rotate-90" viewBox="0 0 40 40">
                      <circle
                        cx="20"
                        cy="20"
                        r={radius->Float.toString}
                        fill="none"
                        stroke="#e5e7eb"
                        strokeWidth="2"
                      />
                      <circle
                        cx="20"
                        cy="20"
                        r={radius->Float.toString}
                        fill="none"
                        stroke={skillColor}
                        strokeWidth="2"
                        strokeDasharray={circumference->Float.toString}
                        strokeDashoffset={(circumference -. progress)->Float.toString}
                        strokeLinecap="round"
                      />
                    </svg>
                    {picture
                    ->Option.map(src =>
                      <img
                        src
                        alt={player.name}
                        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-9 h-9 rounded-full object-cover"
                      />
                    )
                    ->Option.getOr(
                      <div
                        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-9 h-9 rounded-full bg-gray-200"
                      />,
                    )}
                  </div>
                  // Player Info
                  <div className="flex flex-col min-w-0 flex-1">
                    <span className="text-base font-bold text-slate-800 truncate">
                      {player.name->React.string}
                    </span>
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                      <span className="font-mono">
                        {`#${player.intId->Int.toString}`->React.string}
                      </span>
                      <span> {"•"->React.string} </span>
                      <span> {t`Skill: ${skillLevel->Float.toFixed(~digits=0)}`} </span>
                      <span> {"•"->React.string} </span>
                      <div className="flex items-center gap-1">
                        <Lucide.Play className="w-3 h-3" />
                        <span className="font-medium">
                          {player.count->Int.toString->React.string}
                        </span>
                      </div>
                    </div>
                  </div>
                </button>
              })
              ->React.array}
            </div>}
      </div>
    </div>
  </div>
}
