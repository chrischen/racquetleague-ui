%%raw("import { t } from '@lingui/macro'")

open Rating

// FullScreenRoundView - Full screen overlay for the current active round
//
// Displays all matches in a large, TV-friendly layout with player names and avatars.
// Shown when the user clicks the fullscreen button on the current round header.

@react.component
let make = (
  ~matches: array<completedMatchEntity<'a>>,
  ~roundNumber: int,
  ~onClose: unit => unit,
  ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #PlayerAvatar_user]>>,
) => {
  let t = Lingui.UtilString.t

  <FramerMotion.Div
    key="fullscreen-round-view"
    initial={{FramerMotion.opacity: 0.}}
    animate={{FramerMotion.opacity: 1.}}
    exit={{FramerMotion.opacity: 0.}}
    className="fixed inset-0 z-50 bg-slate-900 overflow-hidden flex flex-col">
    // Header
    <div
      className="flex-shrink-0 bg-slate-900 border-b border-slate-800 px-4 sm:px-6 py-3 flex items-center justify-between">
      <div className="flex items-center gap-4">
        <h1 className="text-3xl md:text-4xl font-extrabold text-white">
          {(t`Round ${roundNumber->Int.toString}`)->React.string}
        </h1>
        <span
          className="px-3 py-1 text-sm font-bold text-slate-900 bg-blue-400 rounded-full shadow-lg">
          {(t`ACTIVE ROUND`)->React.string}
        </span>
      </div>
      <button
        onClick={_ => onClose()}
        className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white rounded-full transition-colors"
        title={t`Close Full Screen`}>
        <Lucide.X className="w-7 h-7" />
      </button>
    </div>
    // Courts
    <div
      className="flex-1 min-h-0 min-w-0 w-full flex flex-col md:flex-row items-stretch gap-2 md:gap-4 px-3 sm:px-6 py-2 md:py-4 overflow-y-auto md:overflow-y-hidden overflow-x-hidden">
      {matches
      ->Array.mapWithIndex((matchEntity, matchIndex) => {
        let {id: matchId, match} = matchEntity
        let (team1, team2) = match
        let courtNumber = matchIndex + 1

        <div
          key={matchId}
          className="md:flex-1 min-w-0 w-full md:w-auto bg-slate-800 rounded-xl md:rounded-2xl border border-slate-700 overflow-hidden shadow-2xl flex flex-col">
          // Court Header
          <div
            className="flex-shrink-0 bg-slate-950 px-3 md:px-4 py-1 md:py-2 text-center border-b border-slate-700">
            <h2 className="text-sm md:text-2xl font-bold text-slate-300 tracking-wider">
              {(t`COURT ${courtNumber->Int.toString}`)->React.string}
            </h2>
          </div>
          // Teams
          <div
            className="flex-1 min-h-0 px-3 md:px-4 py-2 md:py-3 flex flex-col justify-center gap-1 md:gap-3">
            // Team 1
            <div className="flex flex-col gap-1 md:gap-2">
              {team1
              ->Array.map(player => {
                <div key={player.id} className="flex items-center gap-2 md:gap-3 min-w-0">
                  <PlayerAvatar
                    userFragmentRefs={player.data->Option.flatMap(getUserFragmentRefs)}
                    name={player.name}
                    skillLevel={player.ratingOrdinal}
                    size=#large
                    className="w-8 h-8 md:w-14 md:h-14 lg:w-16 lg:h-16 flex-shrink-0"
                  />
                  <span
                    className="text-sm md:text-2xl lg:text-3xl font-bold text-white truncate min-w-0">
                    {player.name->React.string}
                  </span>
                </div>
              })
              ->React.array}
            </div>
            // VS Divider
            <div className="flex items-center justify-center relative py-0.5 md:py-1">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-slate-700 md:border-t-2" />
              </div>
              <div className="relative bg-slate-800 px-2 md:px-3">
                <span className="text-xs md:text-xl font-black text-slate-500 italic">
                  {React.string("VS")}
                </span>
              </div>
            </div>
            // Team 2
            <div className="flex flex-col gap-1 md:gap-2">
              {team2
              ->Array.map(player => {
                <div key={player.id} className="flex items-center gap-2 md:gap-3 min-w-0">
                  <PlayerAvatar
                    userFragmentRefs={player.data->Option.flatMap(getUserFragmentRefs)}
                    name={player.name}
                    skillLevel={player.ratingOrdinal}
                    size=#large
                    className="w-8 h-8 md:w-14 md:h-14 lg:w-16 lg:h-16 flex-shrink-0"
                  />
                  <span
                    className="text-sm md:text-2xl lg:text-3xl font-bold text-white truncate min-w-0">
                    {player.name->React.string}
                  </span>
                </div>
              })
              ->React.array}
            </div>
          </div>
        </div>
      })
      ->React.array}
    </div>
  </FramerMotion.Div>
}
