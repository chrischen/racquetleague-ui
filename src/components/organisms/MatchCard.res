%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// MatchCard Component - Replacement for SortableSubmitMatch component
//
// This component displays a match card with two teams, scores, and editing capabilities.
// It works with the Match.t<rsvpNode> type from the Rating module.
//
// Usage Example:
// ```rescript
// <MatchCard
//   match={(team1Players, team2Players)}
//   courtNumber=1
//   minRating=20.0
//   maxRating=30.0
//   onUpdated={(completedMatch) => ...}
//   onDelete={() => ...}
// >
//   {childrenArray}
// </MatchCard>
// ```
//
// Note: This component takes children elements (player elements from DndKit) and splits
// them between team1 and team2 displays.

open Rating

type winners = Left | Right
type view = Default | SubmitMatch
type history = NoHistory | PreviousRound | LastRound

module Fragment = %relay(`
  fragment MatchCard_user on User {
    ...PlayerRow_user
    ...PlayerAvatar_user
  }
`)

module PredictionBar = {
  @react.component
  let make = (~match: Match.t<'a>) => {
    let team1 = match->fst
    let team2 = match->snd

    let outcome = Rating.predictWin([
      team1->Array.map(node => node.rating),
      team2->Array.map(node => node.rating),
    ])

    let odds = (outcome->Array.get(0)->Option.getOr(0.), outcome->Array.get(1)->Option.getOr(0.))
    let (leftOdds, rightOdds) = odds
    let odds = rightOdds -. leftOdds

    // Calculate bar lengths as percentages (0-50% of container)
    let leftOdds = odds < 0. ? Js.Math.abs_float(odds *. 100.) : 0.
    let rightOdds = odds < 0. ? 0. : odds *. 100.

    // Determine favored team: 1 = left/team1, 2 = right/team2
    let favoredTeam = if odds < 0. {
      1
    } else {
      2
    }
    let barLength = if odds < 0. {
      leftOdds
    } else {
      rightOdds
    }

    // Return favored team and bar length for positioning
    (favoredTeam, barLength)
  }
}

module Team = {
  @react.component
  let make = (
    ~players: array<Player.t<'a>>,
    ~score: option<int>,
    ~isWinner: bool,
    ~isEditing: bool,
    ~hideScores: bool,
    ~teamNumber: int,
    ~onTeamClick: unit => unit,
    ~onScoreChange: string => unit,
    ~normalizeSkillLevel: float => float,
    ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #MatchCard_user]>>,
    ~debug: bool=false,
  ) => {
    let ts = Lingui.UtilString.t

    let bgClass = if isEditing {
      "p-2 lg:pr-2 bg-slate-50 flex-1 border-b lg:border-b-0 border-slate-200"
    } else if isWinner {
      "p-2 lg:pr-2 cursor-pointer transition-all flex-1 border-b lg:border-b-0 bg-green-50 border-b-green-500 lg:border-b-0"
    } else {
      "p-2 lg:pr-2 cursor-pointer transition-all flex-1 border-b lg:border-b-0 bg-white hover:bg-slate-50 border-b-slate-200 lg:border-b-0"
    }

    <div onClick={_ => isEditing ? () : onTeamClick()} className={bgClass}>
      {isEditing
        ? // Editing mode
          <>
            <div className="flex items-center justify-between mb-2">
              <div className="text-xs font-semibold text-slate-600">
                {t`TEAM ${teamNumber->Int.toString}`}
              </div>
              <input
                type_="number"
                inputMode="numeric"
                pattern="[0-9]*"
                placeholder={ts`Score`}
                value={score->Option.map(s => s->Int.toString)->Option.getOr("")}
                onChange={e => onScoreChange(ReactEvent.Form.target(e)["value"])}
                className="w-16 px-2 py-1 text-sm text-center border border-slate-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="space-y-2">
              {players
              ->Array.map(player =>
                <PlayerRow
                  key={player.id}
                  player
                  isEditing
                  winner={None}
                  teamSide={teamNumber == 1 ? PlayerRow.Left : PlayerRow.Right}
                  skillLevel={normalizeSkillLevel(player.rating.mu)}
                  getUserFragmentRefs
                  debug
                />
              )
              ->React.array}
            </div>
          </>
        : // Display mode
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 flex items-center justify-center flex-shrink-0">
              {isWinner
                ? <Lucide.Trophy className="w-5 h-5 text-yellow-500 fill-yellow-500" />
                : score->Option.isNone
                ? <Lucide.Circle className="w-4 h-4 text-blue-500 fill-blue-500" />
                : React.null}
            </div>
            <div
              className="flex flex-col sm:flex-row sm:flex-wrap lg:flex-col gap-1.5 flex-1 min-w-0">
              {players
              ->Array.map(player =>
                <PlayerRow
                  key={player.id}
                  player
                  isEditing={false}
                  winner={isWinner
                    ? Some(teamNumber == 1 ? PlayerRow.Left : PlayerRow.Right)
                    : None}
                  teamSide={teamNumber == 1 ? PlayerRow.Left : PlayerRow.Right}
                  skillLevel={normalizeSkillLevel(player.rating.mu)}
                  getUserFragmentRefs
                  debug
                />
              )
              ->React.array}
            </div>
            {!hideScores && score->Option.isSome
              ? <div className="text-lg font-bold text-slate-800 flex-shrink-0">
                  {score->Option.getOr(0)->Int.toString->React.string}
                </div>
              : React.null}
          </div>}
    </div>
  }
}

module MatchQualityDebug = {
  @react.component
  let make = (~match: Match.t<'a>) => {
    let (team1, team2) = match
    let matchQuality = Rating.predictDraw([
      team1->Array.map(p => p.rating),
      team2->Array.map(p => p.rating),
    ])

    <span className="text-xs text-slate-500 font-mono">
      {`Q: ${matchQuality->Float.toFixed(~digits=3)}`->React.string}
    </span>
  }
}

@react.component
let make = (
  ~defaultView: view=Default,
  ~children: array<React.element>,
  ~match: Match.t<'a>,
  ~courtNumber: int,
  ~minRating: float,
  ~maxRating: float,
  ~score: option<(float, float)>=?,
  ~onDelete: option<unit => unit>=?,
  ~onRebalance: option<unit => unit>=?,
  ~onUpdated: option<CompletedMatch.t<'a> => unit>=?,
  ~debug: bool=false,
  ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #MatchCard_user]>>,
  ~team1History: history=NoHistory,
  ~team2History: history=NoHistory,
  ~matchHistory: history=NoHistory,
) => {
  let ts = Lingui.UtilString.t
  let (view, setView) = React.useState(() => defaultView)
  let (selectedWinner, setSelectedWinner) = React.useState(() => None)

  // Helper to normalize skill level based on minRating and maxRating
  let normalizeSkillLevel = (mu: float): float => {
    if maxRating == minRating {
      50. // If all players have same rating, show 50%
    } else {
      (mu -. minRating) /. (maxRating -. minRating) *. 100.
    }
  }

  let (team1, team2) = match

  // Score values for display mode
  let (scoreLeftValue, scoreRightValue) =
    score->Option.map(((left, right)) => (left, right))->Option.getOr((0., 0.))

  // Determine the current winner based on score values
  let currentWinner = switch (scoreLeftValue, scoreRightValue) {
  | (left, right) if left > right => Some(Left)
  | (left, right) if right > left => Some(Right)
  | _ => None
  }

  let handleSave = ((updatedMatch, updatedScore)) => {
    onUpdated
    ->Option.map(f => {
      f((updatedMatch, updatedScore))->ignore
    })
    ->ignore
  }

  // Handle long-press to open score modal
  let handleLongPress = (team: winners) => {
    let winningTeam = switch team {
    | Left => ScoreModal.Team1
    | Right => ScoreModal.Team2
    }
    setSelectedWinner(_ => Some(winningTeam))
  }

  // Handle regular click to select winner
  let handleClick = (team: winners) => {
    let scoreData = switch team {
    | Left => (1., -1.)
    | Right => (-1., 1.)
    }
    handleSave(((team1, team2), Some(scoreData)))
  }

  // Setup UseLongPress for Team 1
  let options1: UseLongPress.options<unit> = {
    threshold: 500,
    cancelOnMovement: true,
    detect: #pointer,
    onCancel: (_event, _meta) => (), // Prevent click from firing after movement
  }
  let bindTeam1 = UseLongPress.use(Some((_event, _meta) => handleLongPress(Left)), Some(options1))

  // Setup UseLongPress for Team 2
  let options2: UseLongPress.options<unit> = {
    threshold: 500,
    cancelOnMovement: true,
    detect: #pointer,
    onCancel: (_event, _meta) => (), // Prevent click from firing after movement
  }
  let bindTeam2 = UseLongPress.use(Some((_event, _meta) => handleLongPress(Right)), Some(options2))

  // Split children into team elements
  let team1El = children->Array.get(0)->Option.getOr(React.null)
  let team2El = children->Array.get(1)->Option.getOr(React.null)

  // Get prediction bar data
  let (favoredTeam, barLength) = PredictionBar.make({match: match})

  // Hide scores if they are winner/loser indicators (1/-1 or -1/1)
  let hideScores = switch (scoreLeftValue, scoreRightValue) {
  | (1., -1.) => true
  | (-1., 1.) => true
  | _ => false
  }

  // Get border color based on match history
  let getMatchBorderColor = () => {
    switch matchHistory {
    | LastRound => "border-red-500"
    | PreviousRound => "border-amber-400"
    | NoHistory => "border-slate-200"
    }
  }

  // Get team background color based on history and winner status
  let getTeamBgColor = (teamHistory: history, isWinner: bool) => {
    if isWinner {
      "bg-green-50"
    } else {
      switch teamHistory {
      | LastRound => "bg-red-50"
      | PreviousRound => "bg-amber-50"
      | NoHistory => "bg-white"
      }
    }
  }

  // Get team border color based on history (for mobile bottom border)
  let getTeamBorderColor = (teamHistory: history) => {
    switch teamHistory {
    | LastRound => "border-b-red-500 lg:border-b-0"
    | PreviousRound => "border-b-amber-400 lg:border-b-0"
    | NoHistory => "border-b-slate-200 lg:border-b-0"
    }
  }

  // Render based on view state
  switch view {
  | SubmitMatch =>
    // Edit mode - delegated to MatchCardEdit component
    <MatchCardEdit
      match
      courtNumber
      ?score
      ?onDelete
      onSave={completedMatch => {
        handleSave(completedMatch)
        setView(_ => Default)
      }}
      onCancel={() => setView(_ => Default)}
      team1Element={team1El}
      team2Element={team2El}
    />

  | Default =>
    // Display mode - new TypeScript design with prediction bars
    <>
      <div
        className={`bg-white rounded-lg border-2 shadow-sm overflow-hidden ${getMatchBorderColor()}`}>
        <div
          className="bg-slate-100 px-2 py-1 border-b border-blue-200 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold text-slate-600">
              {t`Court ${courtNumber->Int.toString}`}
            </span>
            {onRebalance
            ->Option.map(rebalanceFn =>
              <button
                onClick={_ => rebalanceFn()}
                className="p-1 text-slate-600 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors"
                ariaLabel={ts`Rebalance match`}>
                <Lucide.Shuffle className="w-3.5 h-3.5" />
              </button>
            )
            ->Option.getOr(React.null)}
            {matchHistory != NoHistory
              ? <div className="flex items-center gap-1">
                  <Lucide.AlertTriangle
                    className={matchHistory == LastRound
                      ? "w-3 h-3 text-red-600"
                      : "w-3 h-3 text-amber-600"}
                  />
                  <span
                    className={matchHistory == LastRound
                      ? "text-xs font-medium text-red-600"
                      : "text-xs font-medium text-amber-600"}>
                    {matchHistory == LastRound ? t`Last Round` : t`Repeat`}
                  </span>
                </div>
              : React.null}
            {debug ? <MatchQualityDebug match /> : React.null}
          </div>
          <div className="flex items-center gap-1">
            {onDelete
            ->Option.map(deleteFn =>
              <ConfirmButton
                button={<button
                  type_="button"
                  className="p-1 text-slate-600 hover:text-red-600 hover:bg-red-50 rounded transition-colors"
                  ariaLabel={ts`Delete match`}>
                  <Lucide.Trash2 className="w-3.5 h-3.5" />
                </button>}
                title={t`Delete this match?`}
                description={t`The match will be removed from this round. You can restore the originally scheduled matches using the round reset icon.`}
                onConfirmed={deleteFn}
              />
            )
            ->Option.getOr(React.null)}
            <button
              onClick={_ => setView(_ => SubmitMatch)}
              className="p-1 text-slate-600 hover:text-blue-600 hover:bg-slate-200 rounded transition-colors"
              ariaLabel={ts`Edit match`}>
              <Lucide.Edit2 className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
        <div className="flex flex-col lg:flex-row relative">
          // Favored team indicator bar (progress bar)
          {favoredTeam == 1
            ? <>
                // Mobile: vertical bar on left, extends up
                <div
                  className="lg:hidden absolute left-0 top-1/2 w-1 bg-blue-500 -translate-y-full"
                  style={ReactDOM.Style.make(
                    ~height=barLength->Float.toFixed(~digits=3) ++ "%",
                    (),
                  )}
                />
                // Desktop: horizontal bar at bottom, extends left from middle
                <div
                  className="hidden lg:block absolute left-1/2 bottom-0 h-1 bg-blue-500 -translate-x-full"
                  style={ReactDOM.Style.make(~width=barLength->Float.toFixed(~digits=3) ++ "%", ())}
                />
              </>
            : React.null}
          {favoredTeam == 2
            ? <>
                // Mobile: vertical bar on left, extends down
                <div
                  className="lg:hidden absolute left-0 top-1/2 w-1 bg-blue-500"
                  style={ReactDOM.Style.make(
                    ~height=barLength->Float.toFixed(~digits=3) ++ "%",
                    (),
                  )}
                />
                // Desktop: horizontal bar at bottom, extends right from middle
                <div
                  className="hidden lg:block absolute left-1/2 bottom-0 h-1 bg-blue-500"
                  style={ReactDOM.Style.make(~width=barLength->Float.toFixed(~digits=3) ++ "%", ())}
                />
              </>
            : React.null}
          {
            let h1 = bindTeam1(None)
            <div
              onClick={_ => handleClick(Left)}
              onMouseDown={h1.onMouseDown}
              onMouseUp={h1.onMouseUp}
              onMouseMove={h1.onMouseMove}
              onMouseLeave={h1.onMouseLeave}
              onTouchStart={h1.onTouchStart}
              onTouchEnd={h1.onTouchEnd}
              onTouchMove={h1.onTouchMove}
              onPointerUp={h1.onPointerUp}
              onPointerDown={h1.onPointerDown}
              onPointerMove={h1.onPointerMove}
              onPointerLeave={h1.onPointerLeave}
              style={ReactDOM.Style.make(~userSelect="none", ())}
              className={`p-2 lg:pr-2 cursor-pointer transition-all flex-1 lg:flex-none lg:w-1/2 border-b lg:border-b-0 overflow-hidden ${getTeamBgColor(
                  team1History,
                  currentWinner == Some(Left),
                )} ${getTeamBorderColor(team1History)} hover:bg-slate-50`}>
              <div className="flex items-center gap-2 min-w-0">
                <div className="w-5 h-5 flex items-center justify-center flex-shrink-0">
                  {currentWinner == Some(Left)
                    ? <Lucide.Trophy className="w-5 h-5 text-yellow-500 fill-yellow-500" />
                    : currentWinner == None
                    ? <Lucide.Circle className="w-4 h-4 text-blue-500 fill-blue-500" />
                    : currentWinner == None && team1History == LastRound
                    ? <Lucide.AlertTriangle className="w-4 h-4 text-red-600" />
                    : currentWinner == None && team1History == PreviousRound
                    ? <Lucide.AlertTriangle className="w-4 h-4 text-amber-600" />
                    : React.null}
                </div>
                <div
                  className="flex flex-col sm:flex-row sm:flex-wrap lg:flex-col gap-1.5 flex-1 min-w-0">
                  {team1
                  ->Array.map(player => {
                    let winner =
                      currentWinner->Option.map(w => w == Left ? PlayerRow.Left : PlayerRow.Right)
                    // Always increment display count - players are in this match regardless of score status
                    <PlayerRow
                      key={player.id}
                      player
                      isEditing={false}
                      winner
                      teamSide={PlayerRow.Left}
                      skillLevel={normalizeSkillLevel(player.rating.mu)}
                      getUserFragmentRefs
                      debug
                      incrementDisplayCount={true}
                    />
                  })
                  ->React.array}
                </div>
                {!hideScores && (scoreLeftValue != 0. || scoreRightValue != 0.)
                  ? <div className="text-lg font-bold text-slate-800 flex-shrink-0">
                      {scoreLeftValue->Float.toString->React.string}
                    </div>
                  : React.null}
              </div>
            </div>
          }
          // VS Divider - Horizontal on mobile, Vertical on desktop
          <div
            className="relative lg:absolute lg:left-1/2 lg:-translate-x-1/2 lg:top-0 lg:bottom-0 lg:w-px flex items-center justify-center">
            <div
              className="lg:hidden absolute inset-0 flex items-center justify-center border-b border-slate-200">
              <span className="bg-white px-2 text-xs font-bold text-slate-400"> {t`VS`} </span>
            </div>
            <div
              className="hidden lg:flex relative w-full h-full bg-slate-200 items-center justify-center">
              <span className="absolute bg-white px-1 text-xs font-bold text-slate-400">
                {t`VS`}
              </span>
            </div>
          </div>
          {
            let h2 = bindTeam2(None)
            <div
              onClick={_ => handleClick(Right)}
              onMouseDown={h2.onMouseDown}
              onMouseUp={h2.onMouseUp}
              onMouseMove={h2.onMouseMove}
              onMouseLeave={h2.onMouseLeave}
              onTouchStart={h2.onTouchStart}
              onTouchEnd={h2.onTouchEnd}
              onTouchMove={h2.onTouchMove}
              onPointerUp={h2.onPointerUp}
              onPointerDown={h2.onPointerDown}
              onPointerMove={h2.onPointerMove}
              onPointerLeave={h2.onPointerLeave}
              style={ReactDOM.Style.make(~userSelect="none", ())}
              className={`p-2 lg:pl-2 lg:pr-2 cursor-pointer transition-all flex-1 lg:flex-none lg:w-1/2 overflow-hidden ${getTeamBgColor(
                  team2History,
                  currentWinner == Some(Right),
                )} hover:bg-slate-50`}>
              <div className="flex items-center gap-2 min-w-0">
                <div className="w-5 h-5 flex items-center justify-center flex-shrink-0 lg:order-3">
                  {currentWinner == Some(Right)
                    ? <Lucide.Trophy className="w-5 h-5 text-yellow-500 fill-yellow-500" />
                    : currentWinner == None && team2History == LastRound
                    ? <Lucide.AlertTriangle className="w-4 h-4 text-red-600" />
                    : currentWinner == None && team2History == PreviousRound
                    ? <Lucide.AlertTriangle className="w-4 h-4 text-amber-600" />
                    : React.null}
                </div>
                <div
                  className="flex flex-col sm:flex-row sm:flex-wrap lg:flex-col gap-1.5 flex-1 min-w-0 lg:order-1">
                  {team2
                  ->Array.map(player => {
                    let winner =
                      currentWinner->Option.map(w => w == Left ? PlayerRow.Left : PlayerRow.Right)
                    // Always increment display count - players are in this match regardless of score status
                    <PlayerRow
                      key={player.id}
                      player
                      isEditing={false}
                      winner
                      teamSide={PlayerRow.Right}
                      skillLevel={normalizeSkillLevel(player.rating.mu)}
                      getUserFragmentRefs
                      debug
                      incrementDisplayCount={true}
                    />
                  })
                  ->React.array}
                </div>
                {!hideScores && (scoreLeftValue != 0. || scoreRightValue != 0.)
                  ? <div className="text-lg font-bold text-slate-800 flex-shrink-0 lg:order-2">
                      {scoreRightValue->Float.toString->React.string}
                    </div>
                  : React.null}
              </div>
            </div>
          }
        </div>
      </div>
      {selectedWinner
      ->Option.map(winningTeam => {
        <ScoreModal
          match
          winningTeam
          onSubmit={(score1, score2) => {
            let scoreData = (score1->Int.toFloat, score2->Int.toFloat)
            handleSave(((team1, team2), Some(scoreData)))
            setSelectedWinner(_ => None)
          }}
          onClose={() => setSelectedWinner(_ => None)}
          getUserFragmentRefs
        />
      })
      ->Option.getOr(React.null)}
    </>
  }
}
