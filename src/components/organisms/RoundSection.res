%%raw("import { t, plural } from '@lingui/macro'")

let t = Lingui.UtilString.t

// RoundSection Component - Collapsible round display with matches
//
// This component displays a round with its matches and can be collapsed/expanded.
// Only past rounds start collapsed; current and future rounds start expanded.
// The current round always expands when it becomes active.
//
// Usage Example:
// ```rescript
// <RoundSection
//   matches
//   roundNumber=1
//   isCurrentRound=true
//   isPastRound=false
//   sessionState={mySessionState}
//   playersCache
//   checkedInPlayerIds
//   handleMatchCanceled
//   handleMatchUpdated
//   setMatches
//   setQueue
//   setRequiredPlayers
//   setShowMatchSelector
// />
// ```

open Rating

type replacementState<'a> = {
  matchId: string,
  playerIndex: int,
  player: Player.t<'a>,
}

// Helper functions for calculating match and team history
module HistoryCalculator = {
  // Get a team signature (sorted player IDs) for comparison
  let getTeamSignature = (players: array<Player.t<'a>>): string => {
    players
    ->Array.map(p => p.id)
    ->Array.toSorted((a, b) => String.compare(a, b))
    ->Array.join(",")
  }

  // Get match signature (both teams sorted, then combined)
  let getMatchSignature = (match: Match.t<'a>): string => {
    let (team1, team2) = match
    let sig1 = getTeamSignature(team1)
    let sig2 = getTeamSignature(team2)
    // Ensure consistent ordering regardless of which team is team1/team2
    [sig1, sig2]->Array.toSorted(String.compare)->Array.join("|")
  }

  // Check if a team signature exists in previous rounds
  // Returns: NoHistory | PreviousRound | LastRound
  let checkTeamHistory = (
    teamSig: string,
    currentRoundIdx: int,
    allRounds: array<array<completedMatchEntity<'a>>>,
  ): MatchCard.history => {
    // Check last round first
    let foundInLastRound = if currentRoundIdx > 0 {
      let lastRound = allRounds->Array.get(currentRoundIdx - 1)->Option.getOr([])
      lastRound->Array.some(({match}) => {
        let (team1, team2) = match
        getTeamSignature(team1) == teamSig || getTeamSignature(team2) == teamSig
      })
    } else {
      false
    }

    if foundInLastRound {
      LastRound
    } else {
      // Check previous rounds (not including last round)
      let foundInPrevious =
        allRounds
        ->Array.sliceToEnd(~start=0)
        ->Array.filterWithIndex((_, idx) => idx < currentRoundIdx - 1)
        ->Array.some(round => {
          round->Array.some(({match}) => {
            let (team1, team2) = match
            getTeamSignature(team1) == teamSig || getTeamSignature(team2) == teamSig
          })
        })

      if foundInPrevious {
        PreviousRound
      } else {
        NoHistory
      }
    }
  }

  // Check if a match signature exists in previous rounds
  let checkMatchHistory = (
    matchSig: string,
    currentRoundIdx: int,
    allRounds: array<array<completedMatchEntity<'a>>>,
  ): MatchCard.history => {
    // Check last round first
    let foundInLastRound = if currentRoundIdx > 0 {
      let lastRound = allRounds->Array.get(currentRoundIdx - 1)->Option.getOr([])
      lastRound->Array.some(({match}) => {
        getMatchSignature(match) == matchSig
      })
    } else {
      false
    }

    if foundInLastRound {
      LastRound
    } else {
      // Check previous rounds (not including last round)
      let foundInPrevious =
        allRounds
        ->Array.sliceToEnd(~start=0)
        ->Array.filterWithIndex((_, idx) => idx < currentRoundIdx - 1)
        ->Array.some(round => {
          round->Array.some(({match}) => getMatchSignature(match) == matchSig)
        })

      if foundInPrevious {
        PreviousRound
      } else {
        NoHistory
      }
    }
  }
}

module AverageQualityDebug = {
  @react.component
  let make = (~matches: array<completedMatchEntity<'a>>, ~isCurrentRound: bool) => {
    let matchCount = matches->Array.length
    let averageQuality = if matchCount > 0 {
      let totalQuality = matches->Array.reduce(0., (acc, {match}) => {
        let (team1, team2) = match
        let quality = Rating.predictDraw([
          team1->Array.map(p => p.rating),
          team2->Array.map(p => p.rating),
        ])
        acc +. quality
      })
      totalQuality /. Float.fromInt(matchCount)
    } else {
      0.
    }

    <span className={`text-xs font-mono ${isCurrentRound ? "text-blue-600" : "text-slate-400"}`}>
      {`Avg Q: ${averageQuality->Float.toFixed(~digits=3)}`->React.string}
    </span>
  }
}

@react.component
let make = (
  ~matches: array<completedMatchEntity<'a>>,
  ~roundNumber: int,
  ~isCurrentRound: bool,
  ~isPastRound: bool,
  ~playersCache: PlayersCache.t<'a>,
  ~checkedInPlayerIds: Set.t<string>,
  ~handleMatchCanceled: string => unit,
  ~handleMatchUpdated: (CompletedMatch.t<'a>, string) => unit,
  ~setMatches: (array<completedMatchEntity<'a>> => array<completedMatchEntity<'a>>) => unit,
  ~setQueue: array<string> => unit,
  ~setRequiredPlayers: (option<Set.t<string>> => option<Set.t<string>>) => unit,
  ~setShowMatchSelector: (bool => bool) => unit,
  ~onRebalance: option<unit => unit>=?,
  ~onRebalanceMatch: option<string => unit>=?,
  ~onReset: option<bool => unit>=?,
  ~debug: bool=false,
  ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #MatchCard_user]>>,
  ~allRounds: array<array<completedMatchEntity<'a>>>,
) => {
  let ts = Lingui.UtilString.t
  let matchCount = matches->Array.length
  let matchText = Lingui.UtilString.plural(matchCount, {one: ts`match`, other: ts`matches`})

  // Player replacement modal state
  let (replacementState, setReplacementState) = React.useState(() => None)

  // Only past rounds start collapsed; current and future rounds start expanded
  let (isExpanded, setIsExpanded) = React.useState(() => !isPastRound)

  // Derive checked-in players from playersCache and checkedInPlayerIds
  let checkedInPlayers = React.useMemo2(() => {
    playersCache
    ->Js.Dict.values
    ->Array.filter(p => checkedInPlayerIds->Set.has(p.id))
  }, (playersCache, checkedInPlayerIds))

  // Calculate consumed players (those playing in this round, regardless of match completion status)
  let consumedPlayers = React.useMemo1(() => {
    matches
    ->Array.flatMap(({match: m}) => {
      let (team1, team2) = m
      Array.concat(team1, team2)
    })
    ->Array.map(p => p.id)
    ->Set.fromArray
  }, [matches])

  // Calculate standby players (checked-in players on break - not playing in this round)
  let standbyPlayers = React.useMemo2(() => {
    checkedInPlayers->Array.filter(p => !(consumedPlayers->Set.has(p.id)))
  }, (checkedInPlayers, consumedPlayers))

  // Handler for triggering player replacement modal
  let handleReplacePlayerClick = (matchId: string, playerIndex: int, player: Player.t<'a>) => {
    setReplacementState(_ => Some({matchId, playerIndex, player}))
  }

  let handlePlayerSelect = (newPlayer: Player.t<'a>) => {
    replacementState
    ->Option.map(({matchId, playerIndex}) => {
      // Replace the player in the match
      setMatches(matches => {
        matches->Array.map(
          matchEntity => {
            if matchEntity.id == matchId {
              let (team1, team2) = matchEntity.match
              let allPlayers = Array.concat(team1, team2)

              // Replace the player at the specified index
              let updatedPlayers =
                allPlayers->Array.mapWithIndex((p, i) => i == playerIndex ? newPlayer : p)

              // Split back into teams
              let team1Size = team1->Array.length
              let newTeam1 = updatedPlayers->Array.slice(~start=0, ~end=team1Size)
              let newTeam2 = updatedPlayers->Array.sliceToEnd(~start=team1Size)

              {...matchEntity, match: (newTeam1, newTeam2)}
            } else {
              matchEntity
            }
          },
        )
      })
    })
    ->ignore
    setReplacementState(_ => None)
  }

  let handleCloseReplaceModal = () => {
    setReplacementState(_ => None)
  }

  // Find match and player index for a given player
  let findPlayerInMatches = (playerId: string) => {
    matches
    ->Array.findIndexOpt(({match: m}) => {
      let (team1, team2) = m
      Array.concat(team1, team2)->Array.some(p => p.id == playerId)
    })
    ->Option.flatMap(matchIndex => {
      let matchEntity = matches->Array.getUnsafe(matchIndex)
      let (team1, team2) = matchEntity.match
      let allPlayers = Array.concat(team1, team2)

      allPlayers
      ->Array.findIndexOpt(p => p.id == playerId)
      ->Option.map(playerIndex => (matchEntity.id, playerIndex))
    })
  }

  // Update expansion state when round status changes
  React.useEffect2(() => {
    if isCurrentRound {
      // Current round should always be expanded
      setIsExpanded(_ => true)
    } else if isPastRound {
      // When a round becomes past, collapse it
      setIsExpanded(_ => false)
    }
    None
  }, (isCurrentRound, isPastRound))

  // Calculate min/max ratings for normalization
  let minRating =
    matches
    ->Array.flatMap(({match: m}) => {
      let (team1, team2) = m
      Array.concat(team1, team2)
    })
    ->Array.map(p => p.rating.mu)
    ->Array.reduce(100., (acc, next) => next < acc ? next : acc)

  let maxRating =
    matches
    ->Array.flatMap(({match: m}) => {
      let (team1, team2) = m
      Array.concat(team1, team2)
    })
    ->Array.map(p => p.rating.mu)
    ->Array.reduce(0., (acc, next) => next > acc ? next : acc)

  // Calculate current round index for history checking
  let currentRoundIdx = roundNumber - 1

  let matchesGrid = if !isCurrentRound {
    // For non-active rounds (past and future), render matches without drag-and-drop functionality
    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
      {matches
      ->Array.mapWithIndex((matchEntity, matchIndex) => {
        let {id: matchId, match, score} = matchEntity
        let courtNumber = matchIndex + 1

        // Calculate history for this match
        let (team1, team2) = match
        let team1Sig = HistoryCalculator.getTeamSignature(team1)
        let team2Sig = HistoryCalculator.getTeamSignature(team2)
        let matchSig = HistoryCalculator.getMatchSignature(match)

        let team1History = HistoryCalculator.checkTeamHistory(team1Sig, currentRoundIdx, allRounds)
        let team2History = HistoryCalculator.checkTeamHistory(team2Sig, currentRoundIdx, allRounds)
        let matchHistory = HistoryCalculator.checkMatchHistory(matchSig, currentRoundIdx, allRounds)

        <MatchCard
          key={matchId}
          match
          ?score
          courtNumber
          minRating
          maxRating
          onDelete={() => ()}
          onRebalance=?{onRebalanceMatch->Option.map(fn => () => fn(matchId))}
          onUpdated={_ => ()}
          getUserFragmentRefs
          debug
          team1History
          team2History
          matchHistory>
          {[]}
        </MatchCard>
      })
      ->React.array}
    </div>
  } else {
    <DndKit.DndContext onDragEnd={_ => ()}>
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
        <MultipleContainers
          minimal=true
          renderContainer={(children, matchIndex) => {
            matches
            ->Array.get(matchIndex)
            ->Option.map(({id: matchId, match, score}) => {
              let courtNumber = matchIndex + 1

              // Calculate history for this match
              let (team1, team2) = match
              let team1Sig = HistoryCalculator.getTeamSignature(team1)
              let team2Sig = HistoryCalculator.getTeamSignature(team2)
              let matchSig = HistoryCalculator.getMatchSignature(match)

              let team1History = HistoryCalculator.checkTeamHistory(
                team1Sig,
                currentRoundIdx,
                allRounds,
              )
              let team2History = HistoryCalculator.checkTeamHistory(
                team2Sig,
                currentRoundIdx,
                allRounds,
              )
              let matchHistory = HistoryCalculator.checkMatchHistory(
                matchSig,
                currentRoundIdx,
                allRounds,
              )

              <MatchCard
                key={matchId}
                match
                ?score
                courtNumber
                minRating
                maxRating
                onDelete={() => handleMatchCanceled(matchId)}
                onRebalance=?{onRebalanceMatch->Option.map(fn => () => fn(matchId))}
                onUpdated={completedMatch => handleMatchUpdated(completedMatch, matchId)}
                getUserFragmentRefs
                debug
                team1History
                team2History
                matchHistory>
                {children}
              </MatchCard>
            })
            ->Option.getOr(React.null)
          }}
          items={matches->Array.map(({match: m}) => m)->Matches.toDndItems}
          setItems={updateFn => {
            setMatches(matches => {
              let matchesOnly = matches->Array.map(({match: m}) => m)
              let items = matchesOnly->Matches.toDndItems
              let updatedMatches = updateFn(items)->Matches.fromDndItems(playersCache)
              // Preserve IDs and scores when updating matches
              matches->Array.mapWithIndex((entity, i) => {
                let newMatch = updatedMatches->Array.getUnsafe(i)
                {...entity, match: newMatch}
              })
            })
          }}
          deleteContainer={i => handleMatchCanceled(i)}
          renderValue={value => {
            let value = switch value->String.split(":") {
            | [ids, id] =>
              switch ids->String.split(".") {
              | [matchId, _] => Some((matchId, id))
              | _ => None
              }
            | _ => None
            }
            let player = value->Option.flatMap(((matchId, value)) =>
              playersCache
              ->PlayersCache.get(value)
              ->Option.flatMap(player =>
                matchId->Int.fromString->Option.map(matchId => (matchId, player))
              )
            )
            player
            ->Option.map(((matchId, player)) => {
              // Calculate normalized skill level for this player
              let skillLevel = if maxRating == minRating {
                50. // If all players have same rating, show 50%
              } else {
                (player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.
              }

              <UiAction
                className="w-full"
                onClick={_ => {
                  let matchEntity = matches->Array.get(matchId)
                  matchEntity
                  ->Option.map(({match: m}) => {
                    let matchPlayers =
                      m
                      ->Match.players
                      ->Array.map(player => player.id)
                      ->Array.filter(p => p != player.id)
                    let replacements =
                      checkedInPlayers
                      ->Array.map(player => player.id)
                      ->Set.fromArray
                      ->Util.JsSet.difference(consumedPlayers)
                    let newQueue =
                      matchPlayers->Array.concat(replacements->Set.values->Array.fromIterator)
                    setRequiredPlayers(_ => Some(matchPlayers->Set.fromArray))
                    setQueue(newQueue)
                  })
                  ->ignore

                  setShowMatchSelector(_ => true)
                }}>
                <PlayerRow
                  player
                  isEditing={true}
                  winner={None}
                  teamSide={PlayerRow.Left}
                  skillLevel
                  getUserFragmentRefs
                  onClick={_ => {
                    findPlayerInMatches(player.id)
                    ->Option.map(((matchId, playerIndex)) => {
                      handleReplacePlayerClick(matchId, playerIndex, player)
                    })
                    ->ignore
                  }}
                />
              </UiAction>
            })
            ->Option.getOr(React.null)
          }}
        />
      </div>
    </DndKit.DndContext>
  }

  let displayedPlayers = standbyPlayers->Array.slice(~start=0, ~end=5)
  let remainingCount = standbyPlayers->Array.length - 5
  let (showAllNotPlaying, setShowAllNotPlaying) = React.useState(() => false)

  <div
    className={isCurrentRound
      ? "mb-6 rounded-xl transition-all bg-blue-50 border-4 border-blue-500 p-4 shadow-xl"
      : "mb-6 rounded-xl transition-all opacity-50 p-1"}>
    // Header
    {!isCurrentRound
      ? <button
          onClick={_ => setIsExpanded(prev => !prev)}
          className="w-full flex items-center justify-between gap-3 mb-3 hover:opacity-80 transition-opacity">
          <div className="flex items-center gap-3 min-w-0">
            <h2 className="text-xl font-bold text-slate-800 flex-shrink-0">
              {(t`Round ${roundNumber->Int.toString}`)->React.string}
            </h2>
            <span className="text-sm text-slate-500 flex-shrink-0">
              {(t`${matchCount->Int.toString} ${matchText}`)->React.string}
            </span>
          </div>
          <Lucide.ChevronDown
            className={`w-5 h-5 text-slate-600 transition-transform flex-shrink-0 ${isExpanded
                ? "rotate-180"
                : ""}`}
          />
        </button>
      : <div className="flex items-center justify-between gap-3 mb-3 flex-wrap">
          <div className="flex items-center gap-3 flex-wrap">
            <h2 className="text-xl font-bold text-blue-900">
              {(t`Round ${roundNumber->Int.toString}`)->React.string}
            </h2>
            <span
              className="px-3 py-1 text-sm font-bold text-white bg-blue-600 rounded-full shadow-md">
              {(t`ACTIVE ROUND`)->React.string}
            </span>
            <span className="text-sm text-blue-700">
              {(t`${matchCount->Int.toString} ${matchText}`)->React.string}
            </span>
            {debug ? <AverageQualityDebug matches isCurrentRound /> : React.null}
          </div>
          <div className="flex items-center gap-2">
            {onRebalance->Option.isSome
              ? <div
                  onClick={e => {
                    e->ReactEvent.Mouse.stopPropagation
                    onRebalance->Option.forEach(fn => fn())
                  }}
                  className="p-2 hover:bg-blue-100 rounded-lg transition-colors cursor-pointer"
                  title={t`Rebalance this round with current players`}
                  role="button"
                  tabIndex={0}
                  onKeyDown={e => {
                    if e->ReactEvent.Keyboard.key == "Enter" || e->ReactEvent.Keyboard.key == " " {
                      e->ReactEvent.Keyboard.preventDefault
                      e->ReactEvent.Keyboard.stopPropagation
                      onRebalance->Option.forEach(fn => fn())
                    }
                  }}>
                  <Lucide.Shuffle className="w-5 h-5 text-blue-600" />
                </div>
              : React.null}
            {onReset->Option.isSome
              ? <>
                  <div
                    onClick={e => {
                      e->ReactEvent.Mouse.stopPropagation
                      onReset->Option.forEach(fn => fn(true))
                    }}
                    className="p-2 hover:bg-purple-100 rounded-lg transition-colors cursor-pointer flex items-center gap-0.5"
                    title={t`Reset this round with mixed gender pairs`}
                    role="button"
                    tabIndex={0}
                    onKeyDown={e => {
                      if (
                        e->ReactEvent.Keyboard.key == "Enter" || e->ReactEvent.Keyboard.key == " "
                      ) {
                        e->ReactEvent.Keyboard.preventDefault
                        e->ReactEvent.Keyboard.stopPropagation
                        onReset->Option.forEach(fn => fn(true))
                      }
                    }}>
                    <Lucide.Mars className="w-4 h-4 text-blue-600" />
                    <Lucide.Venus className="w-4 h-4 text-pink-600" />
                  </div>
                  <div
                    onClick={e => {
                      e->ReactEvent.Mouse.stopPropagation
                      onReset->Option.forEach(fn => fn(false))
                    }}
                    className="p-2 hover:bg-red-100 rounded-lg transition-colors cursor-pointer"
                    title={t`Reset this round with all checked-in players`}
                    role="button"
                    tabIndex={0}
                    onKeyDown={e => {
                      if (
                        e->ReactEvent.Keyboard.key == "Enter" || e->ReactEvent.Keyboard.key == " "
                      ) {
                        e->ReactEvent.Keyboard.preventDefault
                        e->ReactEvent.Keyboard.stopPropagation
                        onReset->Option.forEach(fn => fn(false))
                      }
                    }}>
                    <Lucide.RotateCcw className="w-5 h-5 text-red-600" />
                  </div>
                </>
              : React.null}
          </div>
        </div>}
    // Matches
    {isExpanded
      ? <>
          <div
            style={!isCurrentRound
              ? ReactDOM.Style.make(~pointerEvents="none", ())
              : ReactDOM.Style.make()}>
            {matchesGrid}
          </div>
          // Not Playing Section
          {standbyPlayers->Array.length > 0
            ? <div className="mt-3">
                <button
                  onClick={_ => setShowAllNotPlaying(prev => !prev)}
                  className="flex items-center gap-2 hover:opacity-80 transition-opacity">
                  <div className="flex items-center -space-x-2">
                    {displayedPlayers
                    ->Array.mapWithIndex((player, index) => {
                      <PlayerAvatar
                        key={player.id}
                        userFragmentRefs={player.data->Option.flatMap(getUserFragmentRefs)}
                        name={player.name}
                        skillLevel={player.ratingOrdinal}
                        size=#small
                        className="w-6 h-6"
                        style={ReactDOM.Style.make(
                          ~zIndex=(displayedPlayers->Array.length - index)->Int.toString,
                          (),
                        )}
                      />
                    })
                    ->React.array}
                    {remainingCount > 0
                      ? <div
                          className="w-6 h-6 rounded-full bg-slate-300 border-2 border-white flex items-center justify-center"
                          style={ReactDOM.Style.make(~zIndex="0", ())}>
                          <span className="text-xs font-bold text-slate-600">
                            {`+${remainingCount->Int.toString}`->React.string}
                          </span>
                        </div>
                      : React.null}
                  </div>
                  <Lucide.ChevronDown
                    className={`w-3 h-3 text-slate-400 transition-transform ${showAllNotPlaying
                        ? "rotate-180"
                        : ""}`}
                  />
                </button>
                // Expanded List
                {showAllNotPlaying
                  ? <div
                      className="mt-2 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2">
                      {standbyPlayers
                      ->Array.map(player => {
                        <div
                          key={player.id}
                          className="flex items-center gap-2 p-2 rounded-lg bg-slate-50 border border-slate-200">
                          <PlayerAvatar
                            userFragmentRefs={player.data->Option.flatMap(getUserFragmentRefs)}
                            name={player.name}
                            skillLevel={player.ratingOrdinal}
                            size=#small
                            className="w-7 h-7 flex-shrink-0"
                          />
                          <div className="flex-1 min-w-0">
                            <div className="text-xs font-medium text-slate-800 truncate">
                              {player.name->React.string}
                            </div>
                          </div>
                        </div>
                      })
                      ->React.array}
                    </div>
                  : React.null}
              </div>
            : React.null}
        </>
      : React.null}
    {replacementState
    ->Option.map(({player}) => {
      <PlayerReplaceModal
        currentPlayer={player}
        availablePlayers={standbyPlayers}
        onSelect={handlePlayerSelect}
        onClose={handleCloseReplaceModal}
        getUserFragmentRefs
      />
    })
    ->Option.getOr(React.null)}
  </div>
}
