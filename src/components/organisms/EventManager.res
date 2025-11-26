%%raw("import { t, plural } from '@lingui/macro'")
open LangProvider.Router

open Util

// EventManager Component - Simplified Sports Event Manager
//
// This component manages sports events with two types of matches:
// 1. Completed matches (with scores and round information)
// 2. Scheduled matches (awaiting results)
//
// Unlike AiTetsu, this uses a simpler state model:
// - All match-related data is derived from completed/scheduled match states
// - No complex play count tracking (derived from completed matches)
// - Round state persisted in TinyBase
//
// Usage Example:
// ```rescript
// <EventManager
//   event
//   eventId="event-123"
// />
// ```

open Rating

@send
external scrollIntoView: (Dom.element, {"behavior": string, "block": string}) => unit =
  "scrollIntoView"

module CreateLeagueMatchMutation = %relay(`
 mutation EventManagerSubmitMatchMutation(
   $matchInput: LeagueMatchInput!
 ) {
   createMatch(match: $matchInput) {
     match {
       id
       winners {
         id
         lineUsername
       }
       losers {
         id
         lineUsername
       }
       score
       createdAt
     }
     errors {
       message
     }
     ratings {
       id
       mu
       sigma
       ordinal
     }
   }
 }
`)

module Fragment = %relay(`
  fragment EventManager_event on Event
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 100 }
  )
  @refetchable(queryName: "EventManagerRsvpsRefetchQuery") {
    __id
    id
    tags
    startDate
    activity {
      id
      slug
    }
    rsvps(after: $after, first: $first, before: $before)
      @connection(key: "EventManager_event_rsvps") {
      edges {
        node {
          __id
          user {
            id
            lineUsername
            gender
            ...EventRsvpUserBar_user
            ...EventMatchRsvpUser_user
            ...PlayerCheckin_user
            ...MatchCard_user
            ...PlayerReplaceModal_user
            ...PlayerRow_user
            ...SeedAdjustmentTimeline_user
            ...PlayerAvatar_user
          }
          rating {
            id
            mu
            sigma
            ordinal
          }
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
      }
    }
  }
`)

// Type alias for the rsvpNode used in this component
type rsvpNode = EventManager_event_graphql.Types.fragment_rsvps_edges_node

// Component to display overall average quality across all rounds
module OverallAverageQualityDebug = {
  @react.component
  let make = (~rounds: array<array<completedMatchEntity<'a>>>) => {
    // Calculate total matches and total quality across all rounds
    // Also track court 1 matches separately
    let (totalMatches, totalQuality, court1Matches, court1Quality) = rounds->Array.reduce(
      (0, 0., 0, 0.),
      ((matchAcc, qualityAcc, court1Acc, court1QualityAcc), roundMatches) => {
        let (roundTotal, court1Total) = roundMatches->Array.reduceWithIndex(
          (qualityAcc, court1QualityAcc),
          ((acc, court1Acc), {match}, index) => {
            let (team1, team2) = match
            let quality = Rating.predictDraw([
              team1->Array.map(p => p.rating),
              team2->Array.map(p => p.rating),
            ])
            let newCourt1Acc = if index == 0 {
              // First match in round is court 1
              court1Acc +. quality
            } else {
              court1Acc
            }
            (acc +. quality, newCourt1Acc)
          },
        )
        let court1Count = if roundMatches->Array.length > 0 {
          court1Acc + 1
        } else {
          court1Acc
        }
        (matchAcc + roundMatches->Array.length, roundTotal, court1Count, court1Total)
      },
    )

    let averageQuality = if totalMatches > 0 {
      totalQuality /. Float.fromInt(totalMatches)
    } else {
      0.0
    }

    let court1AverageQuality = if court1Matches > 0 {
      court1Quality /. Float.fromInt(court1Matches)
    } else {
      0.0
    }

    let qualityPercent = averageQuality *. 100.0
    let court1QualityPercent = court1AverageQuality *. 100.0

    <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
      <div className="text-sm font-semibold text-blue-900">
        {React.string("Overall Match Quality Across All Rounds")}
      </div>
      <div className="text-lg font-bold text-blue-700 mt-1">
        {React.string(qualityPercent->Float.toFixed(~digits=1) ++ "%")}
      </div>
      <div className="text-xs text-blue-600 mt-1">
        {React.string(
          `${totalMatches->Int.toString} total matches across ${rounds
            ->Array.length
            ->Int.toString} rounds`,
        )}
      </div>
      <div className="mt-3 pt-3 border-t border-blue-200">
        <div className="text-sm font-semibold text-blue-900">
          {React.string("Court 1 Average Quality")}
        </div>
        <div className="text-lg font-bold text-blue-700 mt-1">
          {React.string(court1QualityPercent->Float.toFixed(~digits=1) ++ "%")}
        </div>
        <div className="text-xs text-blue-600 mt-1">
          {React.string(`${court1Matches->Int.toString} matches on court 1`)}
        </div>
      </div>
    </div>
  }
}

type syncState = Idle | Syncing | Success | Error

@react.component
let make = (
  ~event: RescriptRelay.fragmentRefs<[> #EventManager_event]>,
  ~eventId as _: string,
  ~debug: bool=false,
) => {
  let data = Fragment.use(event)
  open Lingui.Util
  let ts = Lingui.UtilString.t

  // Mutation hook for submitting matches
  let (commitMutationCreateLeagueMatch, _isMutationInFlight) = CreateLeagueMatchMutation.use()

  // Determine namespace from event tags: if "comp" tag exists => doubles:comp, else doubles:rec
  let eventTags: array<string> = data.tags->Option.getOr([])
  let eventNamespace = eventTags->Array.includes("comp") ? "doubles:comp" : "doubles:rec"

  // Get event start time for staggering match creation timestamps
  let eventStartTime =
    data.startDate->Option.map(Util.Datetime.toDate)->Option.getOr(Js.Date.make())

  // Submit match function (simplified - no connection updates)
  let submitMatch = (
    match: Match.t<'a>,
    score,
    activitySlug,
    matchId: string,
    createdAt: Js.Date.t,
  ): Promise.t<unit> => {
    let namespace = eventNamespace

    // Get winners and losers with their scores
    let (winnerIds, winnerScore) = match->Match.getWinners(score)
    let (loserIds, loserScore) = match->Match.getLosers(score)

    Promise.make((resolve, reject) => {
      commitMutationCreateLeagueMatch(
        ~variables={
          matchInput: {
            activitySlug,
            namespace,
            doublesMatch: {
              winners: winnerIds,
              losers: loserIds,
              score: [winnerScore, loserScore],
              createdAt: createdAt->Util.Datetime.fromDate,
            },
            syncId: matchId,
          },
        },
        ~onCompleted=(_, errs) => {
          switch errs {
          | Some(errs) => Js.log(errs)
          | None => resolve()
          }
        },
        ~onError=e => {
          reject(e)
        },
      )->RescriptRelay.Disposable.ignore
    })
  }

  // Debug mode state
  let (debugMode, setDebugMode) = React.useState(() => debug)

  // Sync state
  let (syncState, setSyncState) = React.useState(() => Idle)
  let (syncProgress, setSyncProgress) = React.useState(() => 0)

  // Reset sync state after success/error
  React.useEffect1(() => {
    switch syncState {
    | Success | Error => {
        let timeoutId = setTimeout(() => {
          setSyncState(_ => Idle)
          setSyncProgress(_ => 0)
        }, 2000)
        Some(() => clearTimeout(timeoutId))
      }
    | _ => None
    }
  }, [syncState])

  // === STATE MANAGEMENT ===

  // Guest players state - separate from RSVP players
  let (guestPlayers: array<Player.t<rsvpNode>>, setGuestPlayers) = React.useState(() => [])

  // Next guest player ID (starting at 9000)
  let (nextGuestId, setNextGuestId) = React.useState(() => 9000)

  // Modal state for adding guest players
  let (showAddGuestsModal, setShowAddGuestsModal) = React.useState(() => false)

  // Load player overrides once and store in state
  let (
    playerOverrides: Js.Dict.t<EventManagerPersistence.playerOverride>,
    setPlayerOverrides,
  ) = React.useState(() => Js.Dict.empty())

  // Extract players from RSVPs and merge with guest players - memoized to prevent unnecessary recalculations
  let players: array<Player.t<rsvpNode>> = React.useMemo4(() => {
    (data.rsvps
    ->Option.flatMap(rsvps => rsvps.edges)
    ->Option.getOr([])
    ->Array.filterMap(edge => {
      edge
      ->Option.flatMap(edge => edge.node)
      ->Option.flatMap(
        rsvp => {
          switch rsvp.user {
          | Some(user) => {
              // Get override data for this player if it exists
              let override = playerOverrides->Js.Dict.get(user.id)

              // Extract override values (using bind since o.name/gender/paid are already options)
              let overrideName = override->Option.flatMap(o => o.name)
              let overrideGender = override->Option.flatMap(o => o.gender)
              let overridePaid = override->Option.flatMap(o => o.paid)

              // Get rating from RSVP data or use default
              let (mu, sigma, ordinal) = switch rsvp.rating {
              | Some(rating) => (
                  rating.mu->Option.getOr(25.0),
                  rating.sigma->Option.getOr(8.333),
                  rating.ordinal->Option.getOr(0.0),
                )
              | None => (25.0, 8.333, 0.0) // Default rating for players without rating data
              }

              Some({
                Player.data: Some(rsvp),
                id: user.id,
                intId: 0, // Will be set based on array index
                name: overrideName->Option.getOr(user.lineUsername->Option.getOr("Unknown")),
                rating: {
                  Rating.mu,
                  sigma,
                },
                ratingOrdinal: ordinal,
                paid: overridePaid->Option.getOr(false),
                gender: overrideGender->Option.getOr(
                  switch user.gender {
                  | Some(Male) => Gender.Male
                  | Some(Female) => Gender.Female
                  | _ => Gender.Male
                  },
                ),
                count: 0,
              })
            }
          | None => None
          }
        },
      )
    })
    ->Array.concat(guestPlayers)
    ->Array.toSorted((a, b) => {
      // Sort by rating (mu) descending, then by ID for stable ordering
      let ratingDiff = b.rating.mu -. a.rating.mu
      if ratingDiff != 0. {
        ratingDiff
      } else {
        String.compare(a.id, b.id)
      }
    })
    ->Array.mapWithIndex((player, i) => {...player, intId: i + 1}) :> array<Player.t<rsvpNode>>)
  }, (data.rsvps, guestPlayers, playerOverrides, nextGuestId))

  // All matches organized by rounds: array<array<completedMatchEntity>>
  // Each element is a round containing matches (completed or not)
  let (rounds, setRounds): (
    array<array<completedMatchEntity<'a>>>,
    (array<array<completedMatchEntity<'a>>> => array<array<completedMatchEntity<'a>>>) => unit,
  ) = React.useState(() => [])

  // Track if matches have been modified (scores updated) in current or previous rounds
  // This prevents unnecessary recalculations when only viewing future rounds
  let (isDirty, setIsDirty) = React.useState(() => false)

  // Checked-in players (by ID)
  // Will be loaded from TinyBase in useEffect
  let (checkedInPlayerIds, setCheckedInPlayerIds) = React.useState(() => Set.make())

  // Current round number (0 = setup/pre-round view, 1+ = round views)
  // Will be loaded from TinyBase in useEffect
  let (currentRoundInt, setCurrentRoundInt) = React.useState(() => 0)

  // Ref for current round section to enable smooth scrolling
  let currentRoundRef = React.useRef(Nullable.null)

  // Court count
  // Will be loaded from TinyBase in useEffect
  let (courtCount, setCourtCount) = React.useState(() => 3)

  // Match generation strategy
  let (strategy, setStrategy) = React.useState(() => CompetitivePlus)

  // Rating adjustment history (chronological list of adjustments with round metadata)
  let (ratingAdjustmentHistory, setRatingAdjustmentHistory) = React.useState(() => [])

  // Track when adjustment was just made to trigger round reset in effect
  let (pendingRoundReset, setPendingRoundReset) = React.useState(() => None)

  // Team constraints for matchmaking
  let (teams: NonEmptyArray.t<array<Player.t<rsvpNode>>>, setTeams) = React.useState(() =>
    NonEmptyArray.empty
  )
  let (antiTeams: NonEmptyArray.t<array<Player.t<rsvpNode>>>, setAntiTeams) = React.useState(() =>
    NonEmptyArray.empty
  )

  // Team management modal state
  let (teamManagementOpen, setTeamManagementOpen) = React.useState(() => false)

  // Player settings modal state
  let (playerSettingsOpen, setPlayerSettingsOpen) = React.useState(() => None)

  // Convert teams to team constraints for match generation
  let teamConstraints = React.useMemo(() => {
    let teamsArray = teams->NonEmptyArray.toArray
    if teamsArray->Array.length > 0 {
      Some(teamsArray->Array.map(Team.toSet))
    } else {
      None
    }
  }, [teams])

  // Convert anti-teams to avoidAllPlayers for match generation
  let avoidAllPlayers = React.useMemo(() => {
    antiTeams->NonEmptyArray.toArray
  }, [antiTeams])

  // Check if any future rounds have scores recorded
  // If so, we should NOT auto-regenerate to avoid overwriting entered scores
  let futureRoundsHaveScores = React.useMemo2(() => {
    rounds->Array.someWithIndex((round, index) => {
      index >= currentRoundInt && round->Array.some(match => match.score->Option.isSome)
    })
  }, (rounds, currentRoundInt))

  // Scroll to current round when it changes
  React.useEffect1(() => {
    currentRoundRef.current
    ->Nullable.toOption
    ->Option.forEach(element => {
      element->scrollIntoView({"behavior": "smooth", "block": "center"})
    })
    None
  }, [currentRoundInt])

  // === DERIVED DATA ===

  // Load matches from TinyBase on initial mount
  React.useEffect1(() => {
    // Load court count from TinyBase
    let storedCourtCount = EventManagerPersistence.loadCourtCount(data.id)
    setCourtCount(_ => storedCourtCount)

    // Load checked-in player IDs from TinyBase
    let storedCheckedInIds = EventManagerPersistence.loadCheckedInPlayerIds(data.id)
    if storedCheckedInIds->Array.length > 0 {
      setCheckedInPlayerIds(_ => storedCheckedInIds->Set.fromArray)
    }

    // Load current round from TinyBase
    let storedCurrentRound = EventManagerPersistence.loadCurrentRound(data.id)
    setCurrentRoundInt(_ => storedCurrentRound)

    // Load rating adjustment history from TinyBase
    let storedHistory = EventManagerPersistence.loadRatingAdjustmentHistory(data.id)
    setRatingAdjustmentHistory(_ => storedHistory)

    // Load teams from TinyBase
    let storedTeams = EventManagerPersistence.loadTeams(data.id)
    if storedTeams->Array.length > 0 {
      setTeams(_ => storedTeams->NonEmptyArray.fromArray)
    }

    // Load anti-teams from TinyBase
    let storedAntiTeams = EventManagerPersistence.loadAntiTeams(data.id)
    if storedAntiTeams->Array.length > 0 {
      setAntiTeams(_ => storedAntiTeams->NonEmptyArray.fromArray)
    }

    // Load player overrides from TinyBase
    let storedPlayerOverrides = EventManagerPersistence.loadPlayerOverrides(data.id)
    setPlayerOverrides(_ => storedPlayerOverrides)

    // Load guest players from TinyBase
    let storedGuestPlayers = EventManagerPersistence.loadGuestPlayers(data.id)
    if storedGuestPlayers->Array.length > 0 {
      setGuestPlayers(_ => storedGuestPlayers)
      // Set next guest ID based on existing guest players
      let maxGuestId = storedGuestPlayers->Array.reduce(8999, (max, player) => {
        let playerId = player.id->Int.fromString->Option.getOr(0)
        playerId > max ? playerId : max
      })
      setNextGuestId(_ => maxGuestId + 1)
    }

    // Create a map of userId -> rsvp for fast lookup
    let rsvpMap =
      data.rsvps
      ->Fragment.getConnectionNodes
      ->Array.filterMap(rsvp =>
        rsvp.user
        ->Option.map(u => u.id)
        ->Option.map(userId => (userId, rsvp))
      )
      ->Js.Dict.fromArray

    let rawMatches = EventManagerPersistence.loadMatchesFromDb(data.id, rsvpMap)

    // Group raw matches by round index
    let roundsMap = Map.make()
    rawMatches->Array.forEach(((
      matchId,
      team1Players,
      team2Players,
      roundIndex,
      score,
      createdAt,
    )) => {
      let roundMatches = roundsMap->Map.get(roundIndex)->Option.getOr([])
      roundsMap->Map.set(
        roundIndex,
        roundMatches->Array.concat([(matchId, team1Players, team2Players, score, createdAt)]),
      )
    })

    // Convert to array of rounds (players already loaded with their ratings)
    let maxRound =
      rawMatches->Array.reduce(0, (max, (_, _, _, roundIndex, _, _)) =>
        roundIndex > max ? roundIndex : max
      )

    let loadedRounds = []
    for i in 0 to maxRound {
      let roundData = roundsMap->Map.get(i)->Option.getOr([])

      let round = roundData->Array.filterMap(((
        matchId,
        team1Players,
        team2Players,
        score,
        createdAt,
      )) => {
        // Only include match if both teams have players
        if team1Players->Array.length > 0 && team2Players->Array.length > 0 {
          let entity: completedMatchEntity<'a> = {
            id: matchId,
            match: (team1Players, team2Players),
            score,
            createdAt,
          }
          Some(entity)
        } else {
          None
        }
      })
      loadedRounds->Array.push(round)
    }

    if (
      loadedRounds->Array.length > 0 && loadedRounds->Array.some(round => round->Array.length > 0)
    ) {
      setRounds(_ => loadedRounds)

      // Correct current round if it's in an invalid state
      // Valid range: 0 to loadedRounds.length (inclusive)
      if currentRoundInt < 0 || currentRoundInt > loadedRounds->Array.length {
        let newRoundInt = loadedRounds->Array.length
        setCurrentRoundInt(_ => newRoundInt)
        EventManagerPersistence.saveCurrentRound(data.id, newRoundInt)
      }
    }

    None
  }, [data.id])

  // Wrapper for setRounds that persists to TinyBase
  let updateRounds = (
    updater: array<array<completedMatchEntity<'a>>> => array<array<completedMatchEntity<'a>>>,
  ) => {
    setRounds(currentRounds => {
      let newRounds = updater(currentRounds)
      // Sync to TinyBase
      EventManagerPersistence.syncRoundsToDb(data.id, newRounds)
      newRounds
    })
  }

  // Get checked-in players - memoized to prevent flashing on regeneration
  // Get players with updated state (counts and ratings) up to AND INCLUDING current round
  // Applies rating adjustments chronologically between rounds
  let playersWithCounts = React.useMemo(() => {
    // Always use toPlayerStateWithAdjustments to ensure round 0 adjustments (appliedAtRound = -1) are applied
    // Even on round 0, there may be rating adjustments that need to be applied
    // currentRoundInt is 1-indexed (round 1, 2, 3...)
    // When viewing round N, we want to include round N in the counts
    // Round N corresponds to rounds[N-1] (array index N-1)
    // So we need to process rounds [0, 1, ..., N-1]
    // Include adjustments up to current round (appliedAtRound < currentRoundInt)
    let adjustmentsUpToCurrent =
      ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound < currentRoundInt)
    rounds
    ->Array.slice(~start=0, ~end=currentRoundInt)
    ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrent)
  }, (rounds, currentRoundInt, ratingAdjustmentHistory, players))

  // Filter to only checked-in players with their updated ratings
  let checkedInPlayers = React.useMemo2(() => {
    playersWithCounts->Array.filter(p => checkedInPlayerIds->Set.has(p.id))
  }, (playersWithCounts, checkedInPlayerIds))

  // Build players cache for quick lookup using playersWithCounts (with updated counts)
  let playersCache = React.useMemo1(() => {
    playersWithCounts->Array.map(p => (p.id, p))->Js.Dict.fromArray
  }, [playersWithCounts])

  // Effect to handle round reset after rating adjustments
  // Only triggers when pendingRoundReset changes (not when rounds change)
  React.useEffect(() => {
    pendingRoundReset->Option.forEach(roundIndex => {
      if roundIndex >= 0 {
        Js.log("Regenerating round " ++ (roundIndex + 1)->Int.toString ++ " after seed adjustment")

        // Use the current state via updater function to avoid depending on rounds
        updateRounds(
          currentRounds => {
            // Get player state up to (but not including) the round being reset in terms of play counts
            // But include rating adjustments for the current round (roundIndex)
            let adjustmentsUpToCurrentRound =
              ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound <= roundIndex)
            let playersForReset =
              currentRounds
              ->Array.slice(~start=0, ~end=roundIndex)
              ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrentRound)
              ->Array.filter(p => checkedInPlayerIds->Set.has(p.id))

            // Generate new round with adjusted ratings
            switch generateSingleRound(
              ~roundIndex,
              ~rounds=currentRounds,
              ~availablePlayers=playersForReset,
              ~strategy,
              ~courtCount,
              ~teamConstraints?,
              ~avoidAllPlayers,
              ~startTime=eventStartTime,
            ) {
            | Some(newRound) =>
              currentRounds->Array.mapWithIndex(
                (round, idx) => idx == roundIndex ? newRound : round,
              )
            | None => currentRounds
            }
          },
        )
      }
      // Clear the pending reset
      setPendingRoundReset(_ => None)
    })
    None
  }, (
    pendingRoundReset,
    ratingAdjustmentHistory,
    players,
    checkedInPlayerIds,
    strategy,
    courtCount,
  ))

  // Auto-regenerate future rounds when dirty for Competitive/Mixed strategies
  // Only triggers when isDirty changes (not when rounds change)
  React.useEffect1(() => {
    if isDirty && currentRoundInt > -1 {
      // Only auto-regenerate for competitive and mixed strategies
      let shouldAutoRegenerate = switch strategy {
      | CompetitivePlus | Competitive | Mixed => true
      | RoundRobin | Random | DUPR => false
      }

      // Check if any future rounds have scores recorded
      // If so, we should NOT auto-regenerate to avoid overwriting entered scores
      if shouldAutoRegenerate && !futureRoundsHaveScores {
        Js.log("Auto-regenerating future rounds after current round changes")

        // Use updater function to access current rounds without depending on them
        updateRounds(currentRounds => {
          // Regenerate only future rounds (after current round)
          let pastAndCurrentRounds =
            currentRounds->Array.filterWithIndex((_, i) => i + 1 <= currentRoundInt)
          let numberOfRoundsToGenerate = 10

          let newRounds = generateRounds(
            ~startRoundNumber=currentRoundInt + 1,
            ~numberOfRounds=numberOfRoundsToGenerate,
            ~availablePlayers=checkedInPlayers,
            ~completedRounds=pastAndCurrentRounds,
            ~strategy,
            ~courtCount,
            ~teamConstraints?,
            ~startTime=eventStartTime,
            (),
          )

          Array.concat(pastAndCurrentRounds, newRounds)
        })

        setIsDirty(_ => false)

        // Reset dirty state after 2 seconds
        // let timeoutId = setTimeout(() => {
        //   setIsDirty(_ => false)
        // }, 2000)

        None
      } else {
        None
      }
    } else {
      None
    }
  }, [isDirty])

  // === EVENT HANDLERS ===

  // Handle resetting a round - regenerates matches for specified round
  let handleResetRound = (roundIndex: int, ~genderMixed: bool=false) => {
    // Get player state from matches BEFORE the round being reset (previous rounds only)
    // BUT include rating adjustments FOR the current round (these are applied before the round starts)
    // Example: resetting round 2 (roundIndex=1) uses:
    //   - Match history from rounds 0 only (before round 1)
    //   - Rating adjustments with appliedAtRound <= 1 (seed adjustments + adjustments for round 1)
    let adjustmentsUpToCurrentRound =
      ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound <= roundIndex)
    let playersForReset =
      rounds
      ->Array.slice(~start=0, ~end=roundIndex)
      ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrentRound)
      ->Array.filter(p => checkedInPlayerIds->Set.has(p.id))

    generateSingleRound(
      ~roundIndex,
      ~rounds,
      ~availablePlayers=playersForReset,
      ~strategy,
      ~courtCount,
      ~teamConstraints?,
      ~avoidAllPlayers,
      ~genderMixed,
      ~startTime=eventStartTime,
    )->Option.forEach(newRound => {
      // Replace just this round
      updateRounds(rounds => {
        rounds->Array.mapWithIndex(
          (round, idx) => {
            if idx == roundIndex {
              newRound
            } else {
              round
            }
          },
        )
      })
    })
  }

  // Function to save adjusted player seeds
  // Takes an array of (playerId, adjustedMu) tuples from SeedAdjustModal
  // Creates new adjustment entries with current round and timestamp, overwrites existing adjustments for same player at same round
  let adjustPlayerSeeds = (sortedPlayers: array<(string, float)>) => {
    setRatingAdjustmentHistory(prevHistory => {
      // Build a map of original mu values for all players
      let originalMuMap =
        checkedInPlayers
        ->Array.map(p => (p.id, p.rating.mu))
        ->Js.Dict.fromArray

      let targetRound = currentRoundInt - 1 // Convert to 0-indexed roundIndex (-1 when on round 0)

      // Create new adjustment entries for players with changed ratings
      let timestamp = Js.Date.now()
      let newAdjustments = []
      let adjustedPlayerIds = Set.make()

      sortedPlayers->Array.forEach(((playerId, adjustedMu)) => {
        originalMuMap
        ->Js.Dict.get(playerId)
        ->Option.forEach(
          originalMu => {
            let differential = adjustedMu -. originalMu
            if differential != 0.0 {
              adjustedPlayerIds->Set.add(playerId)->ignore
              newAdjustments
              ->Array.push({
                RatingAdjustment.playerId,
                differential,
                appliedAtRound: targetRound,
                timestamp,
              })
              ->ignore
            }
          },
        )
      })

      // Remove any existing adjustments for the same players at the same round
      // Keep all other adjustments (different rounds or different players)
      let filteredHistory =
        prevHistory->Array.filter(adj =>
          !(adj.appliedAtRound == targetRound && adjustedPlayerIds->Set.has(adj.playerId))
        )

      // Append new adjustments to filtered history
      let updatedHistory = Array.concat(filteredHistory, newAdjustments)

      // Persist to TinyBase
      EventManagerPersistence.saveRatingAdjustmentHistory(data.id, updatedHistory)

      // Mark as dirty to trigger regeneration prompt
      setIsDirty(_ => true)

      updatedHistory
    })

    // Schedule round reset to regenerate matches with adjusted player state
    // targetRound is the round where adjustments are applied (0-indexed)
    // We need to regenerate the round AFTER the adjustments (targetRound + 1 in 1-indexed terms)
    // But targetRound is already the roundIndex we want to regenerate
    // When on currentRoundInt=1, targetRound=0, and we want to regenerate round index 0
    // The reset will happen in the useEffect after state has updated
    if currentRoundInt > 0 {
      // Regenerate the current round (currentRoundInt is 1-indexed, so currentRoundInt-1 is the array index)
      setPendingRoundReset(_ => Some(currentRoundInt - 1))
    }
  }

  // Handle match completion - update the match with score in current round
  let handleMatchCompleted = (matchId: string, completedMatch: CompletedMatch.t<'a>) => {
    let (match, score) = completedMatch

    // Mark as dirty only if scores were actually provided and strategy requires auto-regeneration
    if score->Option.isSome {
      switch strategy {
      | CompetitivePlus | Competitive | Mixed => setIsDirty(_ => true)
      | _ => ()
      }
    }

    updateRounds(rounds => {
      let updated = rounds->Array.map(round => {
        // Check if this round contains the match
        let hasMatch = round->Array.some(m => m.id == matchId)
        if hasMatch {
          // Update match with score
          round->Array.map(
            m => {
              if m.id == matchId {
                // If score is being set for the first time (was None, now Some), update createdAt
                let shouldUpdateCreatedAt = m.score->Option.isNone && score->Option.isSome
                let updatedCreatedAt = shouldUpdateCreatedAt ? Js.Date.make() : m.createdAt
                Js.log("Setting createdAt")
                Js.log(updatedCreatedAt)
                {...m, match, score, createdAt: updatedCreatedAt}
              } else {
                m
              }
            },
          )
        } else {
          round
        }
      })
      updated
    })
  }

  // Handle match cancellation - remove from any round
  let handleMatchCanceled = (matchId: string) => {
    updateRounds(rounds => {
      rounds->Array.mapWithIndex((round, _) => {
        // Check if this round contains the match to delete
        let hasMatch = round->Array.some(m => m.id == matchId)
        if hasMatch {
          // Only mark as dirty if deleting from current or previous rounds
          // (not future rounds, as those don't affect player states yet)
          setIsDirty(_ => true)
          round->Array.filter(m => m.id != matchId)
        } else {
          round
        }
      })
    })
  }

  // Toggle player check-in
  let handleToggleCheckin = (playerId: string) => {
    setIsDirty(_ => true)
    setCheckedInPlayerIds(prev => {
      let newSet = Set.fromArray(prev->Set.values->Array.fromIterator)
      if prev->Set.has(playerId) {
        newSet->Set.delete(playerId)->ignore
      } else {
        newSet->Set.add(playerId)->ignore
      }
      // Persist to TinyBase
      let playerIdsArray = newSet->Set.values->Array.fromIterator
      EventManagerPersistence.saveCheckedInPlayerIds(data.id, playerIdsArray)
      newSet
    })
  }

  // Handle rebalancing a specific round with its current players
  let handleRebalanceRound = (roundIndex: int) => {
    // Get player IDs from the current round only
    let currentRoundPlayerIds: Set.t<string> =
      rounds
      ->Array.get(roundIndex)
      ->Option.map(roundMatches =>
        roundMatches
        ->Array.flatMap(({match: m}) => Match.players(m))
        ->Array.map(p => p.id)
        ->Set.fromArray
      )
      ->Option.getOr(Set.make())

    // Get player state up to (but not including) this round in terms of play counts
    // But include rating adjustments for this round
    let adjustmentsUpToCurrentRound =
      ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound <= roundIndex)
    let playersBeforeRound =
      rounds
      ->Array.slice(~start=0, ~end=roundIndex)
      ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrentRound)

    // Filter to only the players who were in this round
    let currentRoundPlayers =
      playersBeforeRound->Array.filter(p => currentRoundPlayerIds->Set.has(p.id))

    // Generate a single new round with the correctly calculated player state
    // Use only the players from the current round and the selected strategy
    generateSingleRound(
      ~roundIndex,
      ~rounds,
      ~availablePlayers=currentRoundPlayers,
      ~strategy=CompetitivePlus,
      ~courtCount,
      ~teamConstraints?,
      ~avoidAllPlayers,
      ~startTime=eventStartTime,
    )->Option.forEach(newRound => {
      // Replace just this round
      updateRounds(rounds => {
        rounds->Array.mapWithIndex(
          (round, idx) => {
            if idx == roundIndex {
              newRound
            } else {
              round
            }
          },
        )
      })
    })
  }

  let handleRebalanceMatch = (roundIndex: int, matchId: string) => {
    // Get the specific match to rebalance
    rounds
    ->Array.get(roundIndex)
    ->Option.flatMap(roundMatches => roundMatches->Array.find(({id}) => id == matchId))
    ->Option.forEach(({match}) => {
      // Get players from this match only
      let matchPlayers = Match.players(match)
      let matchPlayerIds = matchPlayers->Array.map(p => p.id)->Set.fromArray

      // Get player state up to (but not including) this round
      let adjustmentsUpToCurrentRound =
        ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound <= roundIndex)
      let playersBeforeRound =
        rounds
        ->Array.slice(~start=0, ~end=roundIndex)
        ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrentRound)

      // Filter to only the players in this match
      let matchPlayersWithState =
        playersBeforeRound->Array.filter(p => matchPlayerIds->Set.has(p.id))

      // Generate a new match with only these players
      // Since we're generating a "round" with just these players, it will create one match
      generateSingleRound(
        ~roundIndex,
        ~rounds,
        ~availablePlayers=matchPlayersWithState,
        ~strategy,
        ~courtCount=1, // Only one match
        ~teamConstraints?,
        ~avoidAllPlayers=[],
        ~startTime=eventStartTime,
      )->Option.forEach(newRound => {
        // Get the new match from the generated round
        newRound
        ->Array.get(0)
        ->Option.forEach(
          newMatchEntity => {
            // Replace just this match in the round
            updateRounds(
              rounds => {
                rounds->Array.mapWithIndex(
                  (round, idx) => {
                    if idx == roundIndex {
                      round->Array.map(
                        matchEntity => {
                          if matchEntity.id == matchId {
                            // Keep the same ID and score, just update the match
                            {...matchEntity, match: newMatchEntity.match}
                          } else {
                            matchEntity
                          }
                        },
                      )
                    } else {
                      round
                    }
                  },
                )
              },
            )
          },
        )
      })
    })
  }

  // Handle draw generation using Rating.generateRounds (tail-call recursive)
  let handleGenerateDraws = () => {
    let numberOfRoundsToGenerate = 10

    if rounds->Array.length == 0 || currentRoundInt == 0 {
      // Initial generation or regeneration from round 0: start from round 1
      // When on round 0, playersWithCounts already includes round 0 adjustments applied by toPlayerStateWithAdjustments
      // Filter to checked-in players only
      let playersForGeneration = checkedInPlayers

      // When on round 0, no rounds are completed yet, so pass empty array
      let pastAndCurrentRounds = rounds->Array.filterWithIndex((_, i) => i + 1 <= currentRoundInt)

      let newRounds = generateRounds(
        ~startRoundNumber=1,
        ~numberOfRounds=numberOfRoundsToGenerate,
        ~availablePlayers=playersForGeneration,
        ~completedRounds=pastAndCurrentRounds,
        ~strategy,
        ~courtCount,
        ~teamConstraints?,
        ~avoidAllPlayers,
        ~startTime=eventStartTime,
        (),
      )
      updateRounds(_ => newRounds)
      setCurrentRoundInt(_ => 1)
      EventManagerPersistence.saveCurrentRound(data.id, 1)

      // Clear rating adjustments for future rounds (round 1 and beyond)
      setRatingAdjustmentHistory(prevHistory => {
        let filteredHistory = prevHistory->Array.filter(adj => adj.appliedAtRound < 0)
        EventManagerPersistence.saveRatingAdjustmentHistory(data.id, filteredHistory)
        filteredHistory
      })

      // Reset dirty flag after regeneration
      setIsDirty(_ => false)
    } else {
      // Regeneration: keep past/current rounds, replace future rounds
      let pastAndCurrentRounds = rounds->Array.filterWithIndex((_, i) => i + 1 <= currentRoundInt)

      // Use players with state updated through current round (includes play counts and rating adjustments)
      // This ensures future rounds are generated based on the actual state at end of current round
      let newRounds = generateRounds(
        ~startRoundNumber=currentRoundInt + 1,
        ~numberOfRounds=numberOfRoundsToGenerate,
        ~availablePlayers=checkedInPlayers,
        ~completedRounds=pastAndCurrentRounds,
        ~strategy,
        ~courtCount,
        ~teamConstraints?,
        ~avoidAllPlayers,
        ~startTime=eventStartTime,
        (),
      )

      updateRounds(_ => Array.concat(pastAndCurrentRounds, newRounds))

      // Clear rating adjustments for future rounds (currentRoundInt and beyond)
      // Keep adjustments for past rounds and current round
      setRatingAdjustmentHistory(prevHistory => {
        let filteredHistory = prevHistory->Array.filter(adj => adj.appliedAtRound < currentRoundInt)
        EventManagerPersistence.saveRatingAdjustmentHistory(data.id, filteredHistory)
        filteredHistory
      })

      // Reset dirty flag after regeneration
      setIsDirty(_ => false)
    }
  }

  // Handle court count change
  let handleCourtCountChange = (count: int) => {
    setCourtCount(_ => count)
    setIsDirty(_ => true)
    EventManagerPersistence.saveCourtCount(data.id, count)
  }

  // Handle advance to next round
  let handleAdvanceRound = () => {
    if currentRoundInt < rounds->Array.length {
      let newRoundInt = currentRoundInt + 1
      setCurrentRoundInt(_ => newRoundInt)
      EventManagerPersistence.saveCurrentRound(data.id, newRoundInt)
    }
  }

  // Handle go to previous round
  let handlePreviousRound = () => {
    if currentRoundInt > 0 {
      let newRoundInt = currentRoundInt - 1
      setCurrentRoundInt(_ => newRoundInt)
      EventManagerPersistence.saveCurrentRound(data.id, newRoundInt)
    }
  }

  // Handle sync scores - submit all completed matches to server
  let handleSyncScores = async () => {
    setSyncState(_ => Syncing)
    setSyncProgress(_ => 0)

    // Get activity slug
    let activitySlug = data.activity->Option.flatMap(a => a.slug)

    switch activitySlug {
    | None => {
        Js.log("No activity slug found, cannot sync scores")
        setSyncState(_ => Error)
      }
    | Some(slug) => {
        // Collect all matches with scores from all rounds
        let matchesWithScores =
          rounds
          ->Array.flatMap(round => round)
          ->Array.filterMap(({id, match, score, createdAt}) => {
            score->Option.map(scoreValue => (id, match, scoreValue, createdAt))
          })

        let totalMatches = matchesWithScores->Array.length

        if totalMatches == 0 {
          Js.log("No scored matches to sync")
          setSyncState(_ => Success)
        } else {
          // Submit matches with 500ms delay between each
          let results = []
          for i in 0 to totalMatches - 1 {
            let (matchId, match, scoreValue, createdAt) = matchesWithScores->Array.getUnsafe(i)

            try {
              await submitMatch(match, scoreValue, slug, matchId, createdAt)
              results->Array.push(Ok())->ignore
              let progress = Float.fromInt(i + 1) /. Float.fromInt(totalMatches) *. 100.
              setSyncProgress(_ => progress->Float.toInt)
              // 500ms delay between submissions
              await Promise.make((resolve, _) => {
                let _ = setTimeout(() => resolve(), 500)
              })
            } catch {
            | error => {
                Js.log2("Error syncing match:", error)
                results->Array.push(Error())->ignore
              }
            }
          }

          // Check if all succeeded
          let allSucceeded = results->Array.every(result =>
            switch result {
            | Ok() => true
            | Error() => false
            }
          )

          setSyncState(_ => allSucceeded ? Success : Error)
        }
      }
    }
  }

  // Can go back if not on round 0
  let canGoBack = currentRoundInt > 0

  // Can advance if there are more rounds
  let canAdvance = currentRoundInt < rounds->Array.length

  // Helper to extract user fragmentRefs from rsvpNode
  let getUserFragmentRefs = (rsvpNode: rsvpNode) => {
    rsvpNode.user->Option.map(user => user.fragmentRefs)
  }

  let hasExistingDraws = rounds->Array.length > 0

  // Handle reset storage - clears all TinyBase data for this event
  let handleResetStorage = () => {
    EventManagerPersistence.clearEventData(data.id)
    // Reset all state to initial values
    setRounds(_ => [])
    setCurrentRoundInt(_ => 0)
    setCourtCount(_ => 3)
    setCheckedInPlayerIds(_ => Set.make())
    setRatingAdjustmentHistory(_ => [])
    setIsDirty(_ => false)
    setTeams(_ => NonEmptyArray.empty)
    setAntiTeams(_ => NonEmptyArray.empty)
    setPlayerOverrides(_ => Js.Dict.empty())
  }

  // Handle delete rating adjustment - removes adjustment from history and triggers recalculation
  let handleDeleteAdjustment = (timestamp: float) => {
    setRatingAdjustmentHistory(prevHistory => {
      let updatedHistory = prevHistory->Array.filter(adj => adj.timestamp != timestamp)

      // Persist to TinyBase
      EventManagerPersistence.saveRatingAdjustmentHistory(data.id, updatedHistory)

      // Mark as dirty to trigger regeneration prompt
      setIsDirty(_ => true)

      updatedHistory
    })

    // If we're in an active round, schedule round reset to regenerate without the deleted adjustment
    // The reset will happen in the useEffect after state has updated
    if currentRoundInt > 0 {
      setPendingRoundReset(_ => Some(currentRoundInt - 1))
    }
  }

  // Handle updating a player's settings
  let handleUpdatePlayer = (updatedPlayer: Player.t<rsvpNode>) => {
    // Save player overrides to TinyBase
    EventManagerPersistence.savePlayerOverride(
      data.id,
      updatedPlayer.id,
      updatedPlayer.name,
      updatedPlayer.gender,
      updatedPlayer.paid,
    )

    // Update player overrides state to trigger re-render
    setPlayerOverrides(prev => {
      let updated = Js.Dict.empty()
      prev->Js.Dict.entries->Array.forEach(((k, v)) => updated->Js.Dict.set(k, v))
      updated->Js.Dict.set(
        updatedPlayer.id,
        {
          EventManagerPersistence.playerId: updatedPlayer.id,
          name: Some(updatedPlayer.name),
          gender: Some(updatedPlayer.gender),
          paid: Some(updatedPlayer.paid),
        },
      )
      updated
    })

    // Mark as dirty to trigger regeneration
    setIsDirty(_ => true)

    // Schedule round reset to regenerate matches with updated player data
    // This ensures gender changes are reflected in match generation (e.g., for gender-mixed doubles)
    if currentRoundInt > 0 {
      // Regenerate the current round (currentRoundInt is 1-indexed, so currentRoundInt-1 is the array index)
      setPendingRoundReset(_ => Some(currentRoundInt - 1))
    }

    // Close modal
    setPlayerSettingsOpen(_ => None)
  }

  // Handle adding guest players from the modal
  let handleAddGuestPlayers = (names: array<string>) => {
    // Create guest players with unique IDs starting from nextGuestId
    let newGuests = names->Array.mapWithIndex((name, index) => {
      let guestId = nextGuestId + index
      Player.makeDefaultRatingPlayer(name, Gender.Male, guestId)
    })

    // Add new guests to existing guest players
    let updatedGuestPlayers = guestPlayers->Array.concat(newGuests)
    setGuestPlayers(_ => updatedGuestPlayers)

    // Update next guest ID
    setNextGuestId(prev => prev + names->Array.length)

    // Auto check-in the new guest players
    setCheckedInPlayerIds(prev => {
      let newSet = Set.fromArray(prev->Set.values->Array.fromIterator)
      newGuests->Array.forEach(guest => {
        newSet->Set.add(guest.id)->ignore
      })
      newSet
    })

    // Save to TinyBase
    EventManagerPersistence.saveGuestPlayers(data.id, updatedGuestPlayers)

    // Save updated checked-in IDs
    let updatedCheckedInIds = checkedInPlayerIds->Set.values->Array.fromIterator
    let newGuestIds = newGuests->Array.map(g => g.id)
    EventManagerPersistence.saveCheckedInPlayerIds(
      data.id,
      updatedCheckedInIds->Array.concat(newGuestIds),
    )

    // Close modal
    setShowAddGuestsModal(_ => false)
  }

  // Handle deleting a guest player
  let handleDeleteGuestPlayer = (playerId: string) => {
    // Remove from guest players
    let updatedGuestPlayers = guestPlayers->Array.filter(p => p.id != playerId)
    setGuestPlayers(_ => updatedGuestPlayers)

    // Remove from checked-in players if present
    setCheckedInPlayerIds(prev => {
      let newSet = Set.fromArray(prev->Set.values->Array.fromIterator)
      newSet->Set.delete(playerId)->ignore
      newSet
    })

    // Remove from teams if present
    let updatedTeams =
      teams
      ->NonEmptyArray.toArray
      ->Array.map(team => team->Array.filter(p => p.id != playerId))
      ->Array.filter(team => team->Array.length > 0)
    if updatedTeams->Array.length > 0 {
      setTeams(_ => updatedTeams->NonEmptyArray.fromArray)
      EventManagerPersistence.saveTeams(data.id, updatedTeams)
    } else {
      setTeams(_ => None)
      EventManagerPersistence.saveTeams(data.id, [])
    }

    // Remove from anti-teams if present
    let updatedAntiTeams =
      antiTeams
      ->NonEmptyArray.toArray
      ->Array.map(team => team->Array.filter(p => p.id != playerId))
      ->Array.filter(team => team->Array.length > 0)
    if updatedAntiTeams->Array.length > 0 {
      setAntiTeams(_ => updatedAntiTeams->NonEmptyArray.fromArray)
      EventManagerPersistence.saveAntiTeams(data.id, updatedAntiTeams)
    } else {
      setAntiTeams(_ => None)
      EventManagerPersistence.saveAntiTeams(data.id, [])
    }

    // Save to TinyBase
    EventManagerPersistence.saveGuestPlayers(data.id, updatedGuestPlayers)
    EventManagerPersistence.saveCheckedInPlayerIds(
      data.id,
      checkedInPlayerIds->Set.values->Array.fromIterator->Array.filter(id => id != playerId),
    )

    // Mark as dirty to trigger regeneration
    setIsDirty(_ => true)
  }

  // Convert teams from NonEmptyArray to TeamManagementModal.teamData format
  let teamsAsData: array<TeamManagementModal.teamData> =
    teams
    ->NonEmptyArray.toArray
    ->Array.mapWithIndex((team, index) => {
      {
        TeamManagementModal.id: index,
        name: ts`Team ${(index + 1)->Int.toString}`,
        playerIds: team->Array.map(p => p.id),
      }
    })

  // === RENDER ===

  <>
    {teamManagementOpen
      ? <TeamManagementModal
          teams={teamsAsData}
          antiTeams={antiTeams
          ->NonEmptyArray.toArray
          ->Array.mapWithIndex((team, index) => {
            {
              TeamManagementModal.id: index,
              name: ts`Anti-Team ${(index + 1)->Int.toString}`,
              playerIds: team->Array.map(p => p.id),
            }
          })}
          players={playersWithCounts}
          onSave={(updatedTeams, updatedAntiTeams) => {
            // Handle Teams
            let newTeams = updatedTeams->Array.filterMap(teamData => {
              let teamPlayers =
                teamData.playerIds->Array.filterMap(id =>
                  playersWithCounts->Array.find(p => p.id == id)
                )

              if teamPlayers->Array.length > 0 {
                Some(teamPlayers)
              } else {
                None
              }
            })

            setTeams(_ => newTeams->NonEmptyArray.fromArray)
            EventManagerPersistence.saveTeams(data.id, newTeams)

            // Handle Anti-Teams
            let newAntiTeams = updatedAntiTeams->Array.filterMap(teamData => {
              let teamPlayers =
                teamData.playerIds->Array.filterMap(id =>
                  playersWithCounts->Array.find(p => p.id == id)
                )

              if teamPlayers->Array.length > 0 {
                Some(teamPlayers)
              } else {
                None
              }
            })

            setAntiTeams(_ => newAntiTeams->NonEmptyArray.fromArray)
            EventManagerPersistence.saveAntiTeams(data.id, newAntiTeams)

            setTeamManagementOpen(_ => false)
            setIsDirty(_ => true)
          }}
          onClose={() => setTeamManagementOpen(_ => false)}
        />
      : React.null}
    {playerSettingsOpen
    ->Option.map((player: Player.t<rsvpNode>) => {
      // Check if this is a guest player (no data means it's a guest)
      let isGuest = player.data->Option.isNone
      if isGuest {
        <PlayerSettingsModal
          player
          onSave={handleUpdatePlayer}
          onClose={() => setPlayerSettingsOpen(_ => None)}
          onDelete={() => handleDeleteGuestPlayer(player.id)}
        />
      } else {
        <PlayerSettingsModal
          player onSave={handleUpdatePlayer} onClose={() => setPlayerSettingsOpen(_ => None)}
        />
      }
    })
    ->Option.getOr(React.null)}
    {showAddGuestsModal
      ? <AddGuestPlayersModal
          onAdd={handleAddGuestPlayers} onClose={() => setShowAddGuestsModal(_ => false)}
        />
      : React.null}
    <div className="min-h-screen bg-slate-50 flex flex-col">
      <div className="bg-slate-800 text-white px-6 py-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold"> {React.string("Sports Event Draws")} </h1>
          <div className="flex items-center gap-2">
            {debugMode
              ? <button
                  onClick={_ => handleResetStorage()}
                  className="px-3 py-1 text-sm font-semibold rounded bg-red-600 hover:bg-red-700 transition-colors">
                  {t`Reset Storage`}
                </button>
              : React.null}
            <Link
              to="/event-manager-guide"
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 transition-colors text-white no-underline">
              <Lucide.CircleHelp className="w-5 h-5" />
              <span className="text-sm font-medium"> {t`Help`} </span>
            </Link>
            <button
              onClick={_ => setDebugMode(prev => !prev)}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 transition-colors">
              <Lucide.CircleHelp className="w-5 h-5" />
              <span className="text-sm font-medium">
                {debugMode ? t`Debug: ON` : t`Debug: OFF`}
              </span>
            </button>
          </div>
        </div>
      </div>
      <PlayerCheckin
        players={playersWithCounts}
        checkedInPlayerIds
        onToggleCheckin={handleToggleCheckin}
        onAdjustSeeds={adjustPlayerSeeds}
        onOpenTeamManagement={() => setTeamManagementOpen(_ => true)}
        onOpenPlayerSettings={player => setPlayerSettingsOpen(_ => Some(player))}
        onOpenAddGuests={() => setShowAddGuestsModal(_ => true)}
        getUserFragmentRefs
        initialPlayers={players}
      />
      {!hasExistingDraws
        ? <DrawGenerator
            courtCount
            onCourtCountChange={handleCourtCountChange}
            checkedInPlayerCount={checkedInPlayerIds->Set.size}
            hasExistingDraws={false}
            strategy
            onStrategyChange={s => setStrategy(_ => s)}
            onGenerateDraws={handleGenerateDraws}
            isInitiallyExpanded={true}
            highlight={isDirty}
            futureRoundsHaveScores
          />
        : React.null}
      {hasExistingDraws
        ? <>
            <RoundHeader
              currentRound={currentRoundInt}
              onAdvanceRound={handleAdvanceRound}
              onPreviousRound={handlePreviousRound}
              canAdvance
              canGoBack
            />
            <div className="flex-1 overflow-auto p-6">
              {debugMode && rounds->Array.length > 0
                ? <OverallAverageQualityDebug rounds />
                : React.null}
              {currentRoundInt == 0
                ? <DrawGenerator
                    courtCount
                    onCourtCountChange={handleCourtCountChange}
                    checkedInPlayerCount={checkedInPlayerIds->Set.size}
                    hasExistingDraws={rounds->Array.length > 0}
                    strategy
                    onStrategyChange={s => setStrategy(_ => s)}
                    onGenerateDraws={handleGenerateDraws}
                    isInitiallyExpanded={true}
                    highlight={isDirty}
                    futureRoundsHaveScores
                  />
                : React.null}
              {
                // Display rating adjustments for round 0 (appliedAtRound = -1)
                // These are adjustments made before any rounds are generated
                let adjustmentsForRound0 =
                  ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound == -1)

                if adjustmentsForRound0->Array.length > 0 {
                  <SeedAdjustmentTimeline
                    adjustments={adjustmentsForRound0}
                    playersCache
                    getUserFragmentRefs={data => data.user->Option.map(u => u.fragmentRefs)}
                    onDelete={() => {
                      // Delete all adjustments with the same timestamp (same batch)
                      adjustmentsForRound0
                      ->Array.get(0)
                      ->Option.forEach(adj => handleDeleteAdjustment(adj.timestamp))
                    }}
                  />
                } else {
                  React.null
                }
              }
              {rounds
              ->Array.mapWithIndex((roundMatches, roundIndex) => {
                let roundNum = roundIndex + 1
                let isCurrentRound = roundNum == currentRoundInt
                let isPastRound = roundNum < currentRoundInt

                // Get adjustments that should be applied before this round
                // appliedAtRound is 0-indexed (matches roundIndex)
                let adjustmentsForRound =
                  ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound == roundIndex)

                <React.Fragment key={roundNum->Int.toString}>
                  // Display rating adjustments that apply at this round (before the round)
                  {if adjustmentsForRound->Array.length > 0 {
                    <SeedAdjustmentTimeline
                      adjustments={adjustmentsForRound}
                      playersCache
                      getUserFragmentRefs={data => data.user->Option.map(u => u.fragmentRefs)}
                      onDelete={() => {
                        // Delete all adjustments with the same timestamp (same batch)
                        adjustmentsForRound
                        ->Array.get(0)
                        ->Option.forEach(adj => handleDeleteAdjustment(adj.timestamp))
                      }}
                    />
                  } else {
                    React.null
                  }}
                  {isCurrentRound
                    ? <div ref={currentRoundRef->ReactDOM.Ref.domRef}>
                        <RoundSection
                          matches={roundMatches}
                          roundNumber={roundNum}
                          isCurrentRound
                          isPastRound
                          playersCache
                          checkedInPlayerIds
                          handleMatchCanceled={matchId => handleMatchCanceled(matchId)}
                          handleMatchUpdated={(completedMatch, matchId) =>
                            handleMatchCompleted(matchId, completedMatch)}
                          setMatches={updateFn => {
                            updateRounds(rounds => {
                              rounds->Array.mapWithIndex(
                                (round, idx) => {
                                  if idx == roundIndex {
                                    updateFn(round)
                                  } else {
                                    round
                                  }
                                },
                              )
                            })
                          }}
                          setQueue={_ => ()}
                          setRequiredPlayers={_ => ()}
                          setShowMatchSelector={_ => ()}
                          onRebalance={() => handleRebalanceRound(roundIndex)}
                          onRebalanceMatch={matchId => handleRebalanceMatch(roundIndex, matchId)}
                          onReset={genderMixed => handleResetRound(roundIndex, ~genderMixed)}
                          getUserFragmentRefs
                          debug={debugMode}
                          allRounds={rounds}
                        />
                      </div>
                    : <RoundSection
                        matches={roundMatches}
                        roundNumber={roundNum}
                        isCurrentRound
                        isPastRound
                        playersCache
                        checkedInPlayerIds
                        handleMatchCanceled={matchId => handleMatchCanceled(matchId)}
                        handleMatchUpdated={(completedMatch, matchId) =>
                          handleMatchCompleted(matchId, completedMatch)}
                        setMatches={updateFn => {
                          updateRounds(rounds => {
                            rounds->Array.mapWithIndex(
                              (round, idx) => {
                                if idx == roundIndex {
                                  updateFn(round)
                                } else {
                                  round
                                }
                              },
                            )
                          })
                        }}
                        setQueue={_ => ()}
                        setRequiredPlayers={_ => ()}
                        setShowMatchSelector={_ => ()}
                        onRebalance={() => handleRebalanceRound(roundIndex)}
                        onRebalanceMatch={matchId => handleRebalanceMatch(roundIndex, matchId)}
                        onReset={genderMixed => handleResetRound(roundIndex, ~genderMixed)}
                        getUserFragmentRefs
                        debug={debugMode}
                        allRounds={rounds}
                      />}
                  {isCurrentRound
                    ? <DrawGenerator
                        courtCount
                        onCourtCountChange={handleCourtCountChange}
                        checkedInPlayerCount={checkedInPlayerIds->Set.size}
                        hasExistingDraws={rounds->Array.length > roundNum}
                        strategy
                        onStrategyChange={s => setStrategy(_ => s)}
                        onGenerateDraws={handleGenerateDraws}
                        isInitiallyExpanded={currentRoundInt == 0}
                        highlight={isDirty}
                        futureRoundsHaveScores
                      />
                    : React.null}
                </React.Fragment>
              })
              ->React.array}
              // Sync Scores Button - At the end
              {rounds->Array.length > 0
                ? <div className="mt-8 flex justify-center">
                    <button
                      onClick={_ => handleSyncScores()->ignore}
                      disabled={syncState == Syncing}
                      className={switch syncState {
                      | Idle => "flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-blue-600 hover:bg-blue-700 text-white hover:shadow-xl"
                      | Syncing => "flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-blue-500 text-white cursor-wait"
                      | Success => "flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-green-600 text-white"
                      | Error => "flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-red-600 text-white"
                      }}>
                      {switch syncState {
                      | Idle =>
                        <>
                          <Lucide.RotateCcw className="w-5 h-5" />
                          <span> {t`Sync Scores`} </span>
                        </>
                      | Syncing =>
                        <>
                          <Lucide.RotateCcw className="w-5 h-5 animate-spin" />
                          <span> {t`Syncing... ${syncProgress->Int.toString}%`} </span>
                        </>
                      | Success =>
                        <>
                          <Lucide.Check className="w-5 h-5" />
                          <span> {t`Scores Synced!`} </span>
                        </>
                      | Error =>
                        <>
                          <Lucide.AlertCircle className="w-5 h-5" />
                          <span> {t`Sync Failed`} </span>
                        </>
                      }}
                    </button>
                  </div>
                : React.null}
            </div>
          </>
        : React.null}
    </div>
  </>
}
