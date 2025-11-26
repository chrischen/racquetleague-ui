%%raw("import { t } from '@lingui/macro'")

// ScoreModal Component - Modal for entering match scores
//
// This component displays a modal for entering scores for a completed match.
// It shows the winning team and losing team with player avatars and names,
// and provides a grid of numbers (0-30) for score selection.
//
// Usage Example:
// ```rescript
// <ScoreModal
//   match
//   winningTeam={Team1}
//   onSubmit={(score1, score2) => handleScoreSubmit(score1, score2)}
//   onClose={handleClose}
//   getUserFragmentRefs
// />
// ```

open Rating

type teamSide = Team1 | Team2

@react.component
let make = (
  ~match: Match.t<'a>,
  ~winningTeam: teamSide,
  ~onSubmit: (int, int) => unit,
  ~onClose: unit => unit,
  ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #PlayerRow_user]>>,
) => {
  open Lingui.Util
  let (team1Score, setTeam1Score) = React.useState(() => None)
  let (team2Score, setTeam2Score) = React.useState(() => None)

  let (team1, team2) = match

  let (winningTeamPlayers, losingTeamPlayers) = switch winningTeam {
  | Team1 => (team1, team2)
  | Team2 => (team2, team1)
  }

  let winningScore = switch winningTeam {
  | Team1 => team1Score
  | Team2 => team2Score
  }

  let losingScore = switch winningTeam {
  | Team1 => team2Score
  | Team2 => team1Score
  }

  let handleSubmit = () => {
    switch (team1Score, team2Score) {
    | (Some(s1), Some(s2)) => {
        onSubmit(s1, s2)
        onClose()
      }
    | _ => ()
    }
  }

  let handleNoScore = () => {
    switch winningTeam {
    | Team1 => onSubmit(1, -1)
    | Team2 => onSubmit(-1, 1)
    }
    onClose()
  }

  let canSubmit = team1Score->Option.isSome && team2Score->Option.isSome

  // Generate number buttons 0-30
  let numbers = Array.fromInitializer(~length=31, i => i)

  let winningTeamNumber = switch winningTeam {
  | Team1 => 1
  | Team2 => 2
  }

  let losingTeamNumber = switch winningTeam {
  | Team1 => 2
  | Team2 => 1
  }

  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div
      className="select-none bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
      // Header
      <div
        className="sticky top-0 bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Lucide.Trophy className="w-6 h-6 text-yellow-500" />
          <h2 className="text-xl font-bold text-slate-800"> {t`Enter Match Score`} </h2>
        </div>
        <button
          onClick={_ => onClose()}
          className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          ariaLabel="Close">
          <Lucide.X className="w-5 h-5 text-slate-600" />
        </button>
      </div>
      <div className="p-6 space-y-6">
        // Winning Team Score
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Lucide.Trophy className="w-5 h-5 text-yellow-500 fill-yellow-500" />
            <h3 className="text-lg font-bold text-green-700">
              {t`Winning Team (Team ${winningTeamNumber->Int.toString})`}
            </h3>
          </div>
          <div className="flex items-center gap-2 mb-2">
            {winningTeamPlayers
            ->Array.map(player => {
              <PlayerRow
                key={player.id}
                player
                isEditing={false}
                winner={None}
                teamSide={PlayerRow.Left}
                skillLevel={0.}
                getUserFragmentRefs
              />
            })
            ->React.array}
          </div>
          <div className="text-center mb-2">
            <div className="inline-block px-4 py-2 bg-green-100 rounded-lg">
              <span className="text-3xl font-bold text-green-700">
                {winningScore
                ->Option.map(s => s->Int.toString)
                ->Option.getOr("—")
                ->React.string}
              </span>
            </div>
          </div>
          <div
            className="grid grid-cols-8 gap-0 border border-slate-300 overflow-hidden rounded-lg">
            {numbers
            ->Array.map(num => {
              let isSelected = winningScore->Option.map(s => s == num)->Option.getOr(false)
              <button
                key={num->Int.toString}
                onClick={_ =>
                  switch winningTeam {
                  | Team1 => setTeam1Score(_ => Some(num))
                  | Team2 => setTeam2Score(_ => Some(num))
                  }}
                className={isSelected
                  ? "h-12 flex items-center justify-center text-base font-bold transition-all border-r border-b border-slate-200 bg-green-600 text-white"
                  : "h-12 flex items-center justify-center text-base font-bold transition-all border-r border-b border-slate-200 bg-white text-slate-700 hover:bg-slate-100 active:bg-slate-200"}>
                {num->Int.toString->React.string}
              </button>
            })
            ->React.array}
          </div>
        </div>
        // Losing Team Score
        <div className="space-y-3">
          <h3 className="text-lg font-bold text-slate-600">
            {t`Losing Team (Team ${losingTeamNumber->Int.toString})`}
          </h3>
          <div className="flex items-center gap-2 mb-2">
            {losingTeamPlayers
            ->Array.map(player => {
              <PlayerRow
                key={player.id}
                player
                isEditing={false}
                winner={None}
                teamSide={PlayerRow.Left}
                skillLevel={0.}
                getUserFragmentRefs
              />
            })
            ->React.array}
          </div>
          <div className="text-center mb-2">
            <div className="inline-block px-4 py-2 bg-slate-100 rounded-lg">
              <span className="text-3xl font-bold text-slate-700">
                {losingScore
                ->Option.map(s => s->Int.toString)
                ->Option.getOr("—")
                ->React.string}
              </span>
            </div>
          </div>
          <div
            className="grid grid-cols-8 gap-0 border border-slate-300 overflow-hidden rounded-lg">
            {numbers
            ->Array.map(num => {
              let isDisabled = winningScore->Option.map(ws => num >= ws)->Option.getOr(false)
              let isSelected = losingScore->Option.map(s => s == num)->Option.getOr(false)
              <button
                key={num->Int.toString}
                onClick={_ => {
                  if !isDisabled {
                    switch winningTeam {
                    | Team1 => setTeam2Score(_ => Some(num))
                    | Team2 => setTeam1Score(_ => Some(num))
                    }
                  }
                }}
                disabled={isDisabled}
                className={if isDisabled {
                  "h-12 flex items-center justify-center text-base font-bold transition-all border-r border-b border-slate-200 bg-slate-50 text-slate-300 cursor-not-allowed"
                } else if isSelected {
                  "h-12 flex items-center justify-center text-base font-bold transition-all border-r border-b border-slate-200 bg-slate-600 text-white"
                } else {
                  "h-12 flex items-center justify-center text-base font-bold transition-all border-r border-b border-slate-200 bg-white text-slate-700 hover:bg-slate-100 active:bg-slate-200"
                }}>
                {num->Int.toString->React.string}
              </button>
            })
            ->React.array}
          </div>
        </div>
      </div>
      // Footer
      <div
        className="sticky bottom-0 bg-slate-50 border-t border-slate-200 px-6 py-4 flex items-center justify-end gap-3">
        <button
          onClick={_ => handleNoScore()}
          className="px-4 py-2 rounded-lg font-medium bg-amber-100 text-amber-900 hover:bg-amber-200 transition-colors flex items-center gap-2">
          <Lucide.MinusCircle className="w-4 h-4" />
          {t`No Score`}
        </button>
        <button
          onClick={_ => handleSubmit()}
          disabled={!canSubmit}
          className={canSubmit
            ? "px-6 py-2 rounded-lg font-medium transition-colors bg-blue-600 text-white hover:bg-blue-700 shadow-md"
            : "px-6 py-2 rounded-lg font-medium transition-colors bg-slate-300 text-slate-500 cursor-not-allowed"}>
          {t`Save Score`}
        </button>
      </div>
    </div>
  </div>
}
