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

// Dark-theme text for the PlayerRows inside a dark surface (this modal and
// MatchCard). PlayerRow has no dark variants of its own because it is still
// rendered on white cards elsewhere (SeedAdjustModal), so the dark surface
// lightens its name (a span; the avatar's initial is a slate-600 div on a
// light disc and must stay dark) and its #id/play-count line from outside.
let playerRowDark = "dark:[&_span.text-slate-800]:text-gray-100 dark:[&_span.text-slate-600]:text-gray-300 dark:[&_span.text-pink-700]:text-pink-300 dark:[&_span.text-pink-600]:text-pink-400 dark:[&_.text-slate-500]:text-gray-400"

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

  // Equal scores are a valid result (rated as a draw). The modal is framed
  // around the tapped team having won, so when the entry is actually a draw,
  // say so rather than letting "Winning Team" mislead.
  let isDraw = switch (winningScore, losingScore) {
  | (Some(w), Some(l)) => w == l
  | _ => false
  }

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

  // On a draw neither side won, so both headings drop the win/loss framing and
  // render identically — the modal is only framed around a winner because of
  // which team was tapped to open it, which the entered scores can contradict.
  let teamHeading = (~teamNumber: int, ~isWinningSide: bool) =>
    <div className="flex items-center gap-2">
      {if isDraw {
        <Lucide.Equal className="w-5 h-5 text-amber-600 dark:text-amber-400" />
      } else if isWinningSide {
        <Lucide.Trophy className="w-5 h-5 text-yellow-500 fill-yellow-500" />
      } else {
        React.null
      }}
      <h3
        className={isDraw
          ? "text-lg font-bold text-slate-700 dark:text-gray-200"
          : isWinningSide
          ? "text-lg font-bold text-green-700 dark:text-green-400"
          : "text-lg font-bold text-slate-600 dark:text-gray-300"}>
        {if isDraw {
          t`Team ${teamNumber->Int.toString}`
        } else if isWinningSide {
          t`Winning Team (Team ${teamNumber->Int.toString})`
        } else {
          t`Losing Team (Team ${teamNumber->Int.toString})`
        }}
      </h3>
    </div>

  // Green reads as "this team won", so the tapped side loses its accent too.
  let (accentBg, accentText, accentSelected) = isDraw
    ? ("bg-slate-100 dark:bg-[#2a2b30]", "text-slate-700 dark:text-gray-200", "bg-slate-600")
    : ("bg-green-100 dark:bg-green-900/30", "text-green-700 dark:text-green-400", "bg-green-600")

  let numberButtonBase = "h-12 flex items-center justify-center text-base font-bold transition-all border-r border-b border-slate-200 dark:border-[#2a2b30]"
  let numberButtonIdle = `${numberButtonBase} bg-white text-slate-700 hover:bg-slate-100 active:bg-slate-200 dark:bg-[#1e1f23] dark:text-gray-200 dark:hover:bg-[#2a2b30] dark:active:bg-[#3a3b40]`

  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div
      className="select-none bg-white dark:bg-[#1e1f23] rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
      // Header
      <div
        className="sticky top-0 bg-white dark:bg-[#1e1f23] border-b border-slate-200 dark:border-[#2a2b30] px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          {isDraw
            ? <Lucide.Equal className="w-6 h-6 text-amber-600 dark:text-amber-400" />
            : <Lucide.Trophy className="w-6 h-6 text-yellow-500" />}
          <h2 className="text-xl font-bold text-slate-800 dark:text-gray-100">
            {t`Enter Match Score`}
          </h2>
        </div>
        <button
          onClick={_ => onClose()}
          className="p-2 hover:bg-slate-100 dark:hover:bg-[#2a2b30] rounded-lg transition-colors"
          ariaLabel="Close">
          <Lucide.X className="w-5 h-5 text-slate-600 dark:text-gray-400" />
        </button>
      </div>
      <div className={`p-6 space-y-6 ${playerRowDark}`}>
        // Score for the team the match card was tapped on
        <div className="space-y-3">
          {teamHeading(~teamNumber=winningTeamNumber, ~isWinningSide=true)}
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
            <div className={`inline-block px-4 py-2 ${accentBg} rounded-lg`}>
              <span className={`text-3xl font-bold ${accentText}`}>
                {winningScore
                ->Option.map(s => s->Int.toString)
                ->Option.getOr("—")
                ->React.string}
              </span>
            </div>
          </div>
          <div
            className="grid grid-cols-8 gap-0 border border-slate-300 dark:border-[#3a3b40] overflow-hidden rounded-lg">
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
                  ? `${numberButtonBase} ${accentSelected} text-white`
                  : numberButtonIdle}>
                {num->Int.toString->React.string}
              </button>
            })
            ->React.array}
          </div>
        </div>
        // Score for the other team
        <div className="space-y-3">
          {teamHeading(~teamNumber=losingTeamNumber, ~isWinningSide=false)}
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
            <div className="inline-block px-4 py-2 bg-slate-100 dark:bg-[#2a2b30] rounded-lg">
              <span className="text-3xl font-bold text-slate-700 dark:text-gray-200">
                {losingScore
                ->Option.map(s => s->Int.toString)
                ->Option.getOr("—")
                ->React.string}
              </span>
            </div>
          </div>
          <div
            className="grid grid-cols-8 gap-0 border border-slate-300 dark:border-[#3a3b40] overflow-hidden rounded-lg">
            {numbers
            ->Array.map(num => {
              // Equal to the other side's score is allowed — that's a draw.
              // Only a *higher* score is blocked, since this grid belongs to
              // the team entered as the non-winner.
              let isDisabled = winningScore->Option.map(ws => num > ws)->Option.getOr(false)
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
                  `${numberButtonBase} bg-slate-50 text-slate-300 dark:bg-[#1a1a1e] dark:text-gray-600 cursor-not-allowed`
                } else if isSelected {
                  `${numberButtonBase} bg-slate-600 text-white`
                } else {
                  numberButtonIdle
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
        className="sticky bottom-0 bg-slate-50 dark:bg-[#222326] border-t border-slate-200 dark:border-[#2a2b30] px-6 py-4 flex items-center justify-end gap-3">
        {isDraw
          ? <span
              className="mr-auto flex items-center gap-1.5 text-sm font-medium text-amber-700 dark:text-amber-400">
              <Lucide.Equal className="w-4 h-4" />
              {t`Equal scores — this will be recorded as a draw`}
            </span>
          : React.null}
        <button
          onClick={_ => handleNoScore()}
          className="px-4 py-2 rounded-lg font-medium bg-amber-100 text-amber-900 hover:bg-amber-200 dark:bg-amber-900/30 dark:text-amber-300 dark:hover:bg-amber-900/50 transition-colors flex items-center gap-2">
          <Lucide.MinusCircle className="w-4 h-4" />
          {t`No Score`}
        </button>
        <button
          onClick={_ => handleSubmit()}
          disabled={!canSubmit}
          className={canSubmit
            ? "px-6 py-2 rounded-lg font-medium transition-colors bg-blue-600 text-white hover:bg-blue-700 shadow-md"
            : "px-6 py-2 rounded-lg font-medium transition-colors bg-slate-300 text-slate-500 dark:bg-[#2a2b30] dark:text-gray-500 cursor-not-allowed"}>
          {t`Save Score`}
        </button>
      </div>
    </div>
  </div>
}
