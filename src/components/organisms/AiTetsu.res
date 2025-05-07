%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
// module FIFOQueue = {
//   type t<'a> = array<'a>
//
//   let shift: t<'a> => (option<'a>, t<'a>) = queue => (
//     queue->Array.get(0),
//     queue->Array.slice(~start=1, ~end=queue->Array.length),
//   )
//
//   let next = (queue, updateFn: (t<'a> => t<'a>) => unit) => {
//     let (player, queue) = shift(queue)
//     updateFn(_ => queue)
//     player
//   }
//   let pull: (t<'a>, 'a => bool) => t<'a> = (queue, filterFn) => {
//     queue->Array.filter(filterFn)
//   }
//
//   let push: (t<'a>, 'a) => t<'a> = (queue, item) => {
//     [...queue, item]
//   }
//   let empty = () => []
// }

module AiTetsuCreateRatingMutation = %relay(`
 mutation AiTetsuCreateRatingMutation($userId: String) {
   createLeagueRating(
     input: {
       activitySlug: "pickleball"
       namespace: "doubles:rec"
       userId: $userId
     }
   ) {
     rating {
       id
     }
   }
 }
`)
module CreateLeagueMatchMutation = %relay(`
 mutation AiTetsuSubmitMatchMutation(
   $connections: [ID!]!
   $matchInput: LeagueMatchInput!
 ) {
   createMatch(match: $matchInput) {
     match @prependNode(connections: $connections, edgeTypeName: "MatchEdge") {
       id
       winners {
         lineUsername
       }
       losers {
         lineUsername
       }
       score
       createdAt
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
  fragment AiTetsu_event on Event
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 50 }
  )
  @refetchable(queryName: "AiTetsuRsvpsRefetchQuery") {
    __id
    id
    activity {
      id
      slug
    }
    rsvps(after: $after, first: $first, before: $before)
      @connection(key: "SelectMatchRsvps_event_rsvps") {
      edges {
        node {
          __id
          user {
            id
            lineUsername
            ...EventRsvpUser_user
            ...EventMatchRsvpUser_user
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

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"
//@genType
//let default = make

open Rating
type priority<'a> = {
  prioritized: array<Player.t<'a>>,
  deprioritized: Set.t<string>,
}
open Util
module TeamListItem = {
  @react.component
  let make = (~id: int, ~team: array<Player.t<'a>>, ~onDelete: int => unit) => {
    <>
      <div className="text-xl">
        <UiAction onClick={_ => onDelete(id)}>
          <HeroIcons.XMarkIcon className="h-8 w-8 inline" />
        </UiAction>
        {t`Team ${id->Int.toString}`}
      </div>
      {team
      ->Array.map(player => <CompMatch.PlayerMini player />)
      ->React.array}
    </>
  }
}
module TeamsList = {
  @react.component
  let make = (~teams: NonEmptyArray.t<array<Player.t<'a>>>, ~onDelete: int => unit) => {
    <ul>
      {teams
      ->NonEmptyArray.mapWithIndex((team, i) => {
        <li key={i->Int.toString}>
          <TeamListItem id={i + 1} team onDelete={_ => onDelete(i)} />
        </li>
      })
      ->NonEmptyArray.toArray
      ->React.array}
    </ul>
  }
}
module TeamSelector = {
  @react.component
  let make = (~players: array<Player.t<'a>>, ~onTeamCreate, ~teamPlayers) => {
    let (sortDir, setSortDir) = React.useState(_ => SelectMatch.SortAction.Desc)
    let maxRating =
      players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
    let minRating =
      players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)

    let players = players->Array.toSorted((a, b) => {
      let userA = a.rating.mu
      let userB = b.rating.mu
      userA < userB ? sortDir == Desc ? 1. : -1. : sortDir == Desc ? -1. : 1.
    })

    let (members: array<Player.t<'a>>, setMembers) = React.useState(() => [])
    let onSelectPlayer = (player: Player.t<'a>) => {
      setMembers(_ => {
        let removed = members->Array.filter(p => p.id != player.id)
        switch removed->Array.length < members->Array.length {
        | true => removed
        | false => members->Array.concat([player])
        }
      })
    }
    <>
      <SelectMatch.SortAction sortDir setSortDir />
      <SelectMatch.SelectEventPlayersList
        players selected=members maxRating minRating onSelectPlayer disabled={teamPlayers}
      />
      <div className="mt-6 flex items-center justify-end gap-x-6">
        <UiAction
          onClick={_ => {
            switch members->Array.length {
            | 1
            | 0 => ()
            | _ =>
              onTeamCreate(members)
              setMembers(_ => [])
            }
          }}
          className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          {t`Create Team`}
        </UiAction>
      </div>
    </>
  }
}
module Leaderboard = {
  type sortDir = Desc
  @react.component
  let make = (~players: array<Player.t<'a>>) => {
    let maxRating =
      players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
    let minRating =
      players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)

    let (members: array<Player.t<'a>>, setMembers) = React.useState(() => [])
    let onSelectPlayer = (player: Player.t<'a>) => {
      setMembers(_ => {
        let removed = members->Array.filter(p => p.id != player.id)
        switch removed->Array.length < members->Array.length {
        | true => removed
        | false => members->Array.concat([player])
        }
      })
    }
    let sortDir = Desc
    let players = players->Array.toSorted((a, b) => {
      let userA = a.rating->Rating.ordinal
      let userB = b.rating->Rating.ordinal
      userA < userB ? sortDir == Desc ? 1. : -1. : sortDir == Desc ? -1. : 1.
    })
    let players1 = players->Array.slice(~start=0, ~end=players->Array.length / 3)
    let players2 =
      players->Array.slice(~start=players->Array.length / 3, ~end=players->Array.length * 2 / 3)
    let players3 =
      players->Array.slice(~start=players->Array.length * 2 / 3, ~end=players->Array.length)
    <div className="grid lg:grid-cols-3 gap-4 mt-2">
      <SelectMatch.SelectEventPlayersList
        players=players1 selected=members maxRating minRating onSelectPlayer
      />
      <SelectMatch.SelectEventPlayersList
        players=players2
        selected=members
        maxRating
        minRating
        onSelectPlayer
        playerNumberOffset={players->Array.length / 3}
      />
      <SelectMatch.SelectEventPlayersList
        players=players3
        selected=members
        maxRating
        minRating
        onSelectPlayer
        playerNumberOffset={players->Array.length * 2 / 3}
      />
    </div>
  }
}
module Checkin = {
  @react.component
  let make = (
    ~players: array<player>,
    ~disabled: Set.t<string>,
    ~onToggleCheckin: (player, bool) => unit,
  ) => {
    // ~onUpdatePlayer: (player, bool) => unit,

    let maxRating =
      players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
    let minRating =
      players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)
    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
      {players
      ->Array.map(player => {
        let status = switch (disabled->Set.has(player.id), player.paid) {
        | (false, true) => MatchRsvpUser.Queued
        | (false, false) => MatchRsvpUser.Queued
        | _ => Available
        }
        <UiAction
          key={player.id}
          onClick={_ => {
            onToggleCheckin(player, disabled->Set.has(player.id))
            ()
          }}>
          <MatchesView.PlayerView status={status} key={player.id} player minRating maxRating />
        </UiAction>
      })
      ->React.array}
    </div>
  }
}
let getDeprioritizedPlayers = (
  history: CompletedMatches.t<'a>,
  players: array<Player.t<'a>>,
  session: Session.t,
  break: int,
) => {
  let lastPlayed = history->CompletedMatches.getLastPlayedPlayers(break, players->Array.length)

  let maxCount = players->Array.reduce(0, (acc, next) => {
    let count = (session->Session.get(next.id)).count
    count > acc ? count : acc
  })
  let minCount = players->Array.reduce(maxCount, (acc, next) => {
    let count = (session->Session.get(next.id)).count
    count < acc ? count : acc
  })

  let breakPlayers =
    players
    ->Array.filter(p => {
      let count = (session->Session.get(p.id)).count
      count == maxCount && count != minCount
    })
    ->Players.sortByPlayCountDesc(session)
    ->Array.slice(~start=0, ~end=break)

  let deprioritized = switch breakPlayers->Array.length < break {
  // Choose break players from players that rested previously + designated break
  // players
  | true =>
    let breakAndLastPlayed = breakPlayers->Players.addBreakPlayersFrom(lastPlayed, break)
    switch breakAndLastPlayed->Array.length < break {
    | true =>
      breakAndLastPlayed
      ->Players.addBreakPlayersFrom(players, break)
      ->Array.map(p => p.id)
      ->Set.fromArray
    | false => breakAndLastPlayed->Array.map(p => p.id)->Set.fromArray
    }
  | false => breakPlayers->Array.map(p => p.id)->Set.fromArray
  }

  // let lowestBreakPlayerCount =
  // breakPlayers->Array.last->Option.map(p => (session->Session.get(p.id)).count)->Option.getOr(0)
  deprioritized
}
let getPriorityPlayers = (
  history: CompletedMatches.t<'a>,
  players: array<Player.t<'a>>,
  session: Session.t,
  break: int,
) => {
  let lastPlayed = history->CompletedMatches.getLastPlayedPlayers(break, players->Array.length)

  let maxCount = players->Array.reduce(0, (acc, next) => {
    let count = (session->Session.get(next.id)).count
    count > acc ? count : acc
  })
  let minCount = players->Array.reduce(maxCount, (acc, next) => {
    let count = (session->Session.get(next.id)).count
    count < acc ? count : acc
  })

  // We find the n most played players, and extend to all players who have the
  // same play count as the least played of this group
  // let (breakPlayers, breakPool, _) =
  //   players
  //   ->Players.sortByPlayCountDesc(session)
  //   ->Array.reduce(([], [], maxCount), ((breakPlayers, breakPool, maxCount), next) => {
  //     let count = (session->Session.get(next.id)).count
  //     let (breakPlayers, breakPool) = switch breakPlayers->Array.concat(breakPool)->Array.length <
  //       break {
  //     | true => (breakPlayers->Array.concat([next]), breakPool)
  //     | false => count == maxCount ? (breakPlayers->Array.concat([next]), breakPool) : (breakPlayers, breakPool)
  //     }
  //
  //     (breakPlayers, breakPool, count < maxCount ? count : maxCount)
  //   })

  let breakPlayers =
    players
    ->Array.filter(p => {
      let count = (session->Session.get(p.id)).count
      count == maxCount && count != minCount
    })
    ->Players.sortByPlayCountDesc(session)
    ->Array.slice(~start=0, ~end=break)
    ->Array.map(p => p.id)

  let deprioritized = switch breakPlayers->Array.length < break {
  // Choose break players from players that rested previously + designated break
  // players
  | true =>
    lastPlayed
    ->Players.filterOut(breakPlayers->Set.fromArray)
    ->Array.slice(~start=0, ~end=break - breakPlayers->Array.length)
    ->Array.map(p => p.id)
    ->Array.concat(breakPlayers)
    ->Set.fromArray
  | false => breakPlayers->Set.fromArray
  }

  // let lowestBreakPlayerCount =
  // breakPlayers->Array.last->Option.map(p => (session->Session.get(p.id)).count)->Option.getOr(0)
  {
    prioritized: players->Array.reduce([], (acc, next) => {
      let count = (session->Session.get(next.id)).count
      minCount != maxCount && count == minCount ? acc->Array.concat([next]) : acc
    }),
    deprioritized,
  }
}
let rsvpToPlayer = (rsvp: AiTetsu_event_graphql.Types.fragment_rsvps_edges_node): option<
  Player.t<'a>,
> => {
  switch (rsvp.user->Option.map(u => u.id), rsvp.rating) {
  | (Some(userId), rating) =>
    let rating = switch rating {
    | Some({mu: Some(mu), sigma: Some(sigma)}) => Rating.make(mu, 8.333)
    | _ => Rating.makeDefault()
    }
    {
      data: Some(rsvp),
      Player.id: userId,
      name: rsvp.user->Option.flatMap(u => u.lineUsername)->Option.getOr(""),
      ratingOrdinal: rating->Rating.ordinal,
      rating,
      paid: false,
    }->Some
  | _ => None
  }
}
// let rsvpToPlayerDefault = (rsvp: AiTetsu_event_graphql.Types.fragment_rsvps_edges_node): option<
//   Player.t<'a>,
// > => {
//   switch (rsvp.user->Option.map(u => u.id), rsvp.rating) {
//   | (Some(userId), _) =>
//     let rating = Rating.makeDefault()
//     {
//       data: Some(rsvp),
//       Player.id: userId,
//       name: rsvp.user->Option.flatMap(u => u.lineUsername)->Option.getOr(""),
//       ratingOrdinal: rating->Rating.ordinal,
//       rating,
//       paid: false,
//     }->Some
//   | _ => None
//   }
// }

let addGuestPlayer = (sessionPlayers, player: player) => {
  let existingPlayer = sessionPlayers->Array.find((p: player) => p.id == player.id)
  switch existingPlayer {
  | Some(_) => sessionPlayers
  | None => sessionPlayers->Array.concat([player])
  }
}
let removeGuestPlayer = (sessionPlayers: array<Player.t<'a>>, player: Player.t<'a>) => {
  sessionPlayers->Array.filter(p => p.id != player.id)
}

type playerSettings = TeamBuilder | AddPlayer | Settings
type screen = Advanced | Matches
@react.component
let make = (~event, ~children) => {
  let ts = Lingui.UtilString.t
  let {__id, id: eventId, activity} = Fragment.use(event)
  // let {__id, id: eventId, activity} = eventData
  let (commitMutationCreateRating, _) = AiTetsuCreateRatingMutation.use()
  let (commitMutationCreateLeagueMatch, _isMutationInFlight) = CreateLeagueMatchMutation.use()

  let (matches: array<match>, setMatches) = React.useState(() => [])
  let (manualTeamOpen, setManualTeamOpen) = React.useState(() => false)
  let (screen, setScreen) = React.useState(() => Advanced)
  // Player team constraints
  let (teams: NonEmptyArray.t<array<player>>, setTeams) = React.useState(() => NonEmptyArray.empty)
  let (settingsPane: option<playerSettings>, setSettingsPane) = React.useState(() => None)
  // let (activePlayers: array<Player.t<rsvpNode>>, setActivePlayers) = React.useState(_ => [])
  let (queue: array<string>, setQueue) = React.useState(_ => [])
  let (disabled: Js.Set.t<string>, setDisabled) = React.useState(_ => Set.make())

  let (sessionState, setSessionState) = React.useState(() => Session.make())
  let (sessionPlayers: array<Player.t<'a>>, setSessionPlayers) = React.useState(() => [])

  // Aka Tournament Mode. Use only session ratings.
  let (sessionMode, setSessionMode) = React.useState(() => false)

  // How many players to remove from the queue for a break
  let (courts: int, setCourts) = React.useState(() => 0)
  // let (breakCount: int, setBreakCount) = React.useState(() => 0)

  // Matchmaking strategy
  let (matchmakingStrategy: strategy, setMatchmakingStrategy) = React.useState(() =>
    CompetitivePlus
  )

  let (matchHistory: array<CompletedMatch.t<rsvpNode>>, setMatchHistory) = React.useState(() => [])

  let (
    locallyCompletedMatches: Js.Dict.t<CompletedMatch.t<rsvpNode>>,
    setLocallyCompletedMatches,
  ) = React.useState(() => Js.Dict.empty())
  let (requiredPlayers: option<Set.t<string>>, setRequiredPlayers) = React.useState(() => None)

  // let pushPlayer = player => {
  //   setQueue(queue => FIFOQueue.push(queue, player))
  // }
  // let nextPlayer = () => {
  //   queue->FIFOQueue.next(setQueue)
  // }
  //
  // let pullPlayer = (player: player) => {
  //   setQueue(queue => FIFOQueue.pull(queue, p => p.id != player.id))
  // }
  //
  let togglePlayer = OrderedQueue.toggle
  let toggleQueuePlayer = (player: player) => {
    setQueue(queue => queue->togglePlayer(player.id))
  }

  let {data, refetch} = Fragment.usePagination(event)
  let allPlayers = (switch sessionMode {
  | true => sessionPlayers
  | false =>
    switch sessionPlayers->Array.length >= data.rsvps->Fragment.getConnectionNodes->Array.length {
    | true => sessionPlayers
    | false =>
      data.rsvps
      ->Fragment.getConnectionNodes
      ->Array.filterMap(rsvpToPlayer)
      ->Array.concat(sessionPlayers)
    }
  } :> array<player>)
  let players = allPlayers->Array.filter(p => !(disabled->Set.has(p.id)))
  let playersCache = allPlayers->PlayersCache.fromPlayers
  let breakCount = courts == 0 ? 0 : players->Array.length - courts * 4

  let seenTeams: RescriptCore.Set.t<string> =
    matchHistory
    ->Array.flatMap(((match, _)) => [match->fst, match->snd])
    ->Array.map(t => t->Team.toStableId)
    ->Set.fromArray

  let seenMatches: RescriptCore.Set.t<string> =
    matchHistory->Array.map(m => m->CompletedMatch.toStableId)->Set.fromArray

  let lastRoundSeenTeams: RescriptCore.Set.t<string> =
    matchHistory
    ->CompletedMatches.getLastRoundMatches(breakCount, players->Array.length, 4)
    ->Array.flatMap(((match, _)) => [match->fst, match->snd])
    ->Array.map(t => t->Team.toStableId)
    ->Set.fromArray

  let lastRoundSeenMatches: RescriptCore.Set.t<string> =
    matchHistory
    ->CompletedMatches.getLastRoundMatches(breakCount, players->Array.length, 4)
    ->Array.map(m => m->CompletedMatch.toStableId)
    ->Set.fromArray

  let initializeRatings = () => {
    allPlayers->Array.map(p => {
      commitMutationCreateRating(~variables={userId: p.id})->RescriptRelay.Disposable.ignore
    })
  }
  let clearSession = () => {
    Session.make()->Session.saveState(eventId)
    []->Players.savePlayers(eventId)
    []->CompletedMatches.saveMatches(eventId)
  }
  React.useEffect0(() => {
    Js.log("Initializing player ratings")
    initializeRatings()->ignore

    Js.log("Loading state")
    let state = Session.loadState(eventId)
    let players = allPlayers->Players.loadPlayers(eventId)
    let history = CompletedMatches.loadMatches(eventId, allPlayers)
    setSessionState(_ => state)
    setSessionPlayers(_ => players)
    setMatchHistory(_ => history)

    Js.log("Disabling players by default")
    setDisabled(_ => Set.fromArray(allPlayers->Array.map(p => p.id)))
    None
  })
  React.useEffect(() => {
    let history = CompletedMatches.loadMatches(eventId, allPlayers)
    setMatchHistory(_ => history)
    None
  }, [sessionPlayers])

  let consumedPlayers =
    matches
    ->Array.flatMap(match => Array.concat(match->fst, match->snd)->Array.map(p => p.id))
    ->Set.fromArray
  let availablePlayers = players->Array.filter(p => !(consumedPlayers->Set.has(p.id)))

  let deprioritized = getDeprioritizedPlayers(matchHistory, players, sessionState, breakCount)

  let queue = queue->OrderedQueue.filter(disabled)
  let breakPlayersCount = queue->Array.length

  // Force break players to be excluded from the queue
  // let queue = queue->OrderedQueue.filter(deprioritized)

  // let queuedPlayers: array<player> = (players->Array.filter(p =>
  //   queue->Set.fromArray->Set.has(p.id)
  // ) :> array<player>)
  let queuedPlayers: array<player> =
    queue->Array.map(id => playersCache->PlayersCache.get(id))->Array.filterMap(x => x)

  let {prioritized: priorityPlayers, deprioritized: _} = getPriorityPlayers(
    matchHistory,
    queuedPlayers,
    sessionState,
    breakCount,
  )
  let availablePlayers = availablePlayers->Array.filter(p => !(deprioritized->Set.has(p.id)))

  // These players should be avoided in the same match
  let incompatiblePlayers =
    [
      "User_7e5631a2-53a9-11ef-b5a9-2b281b5a76b0",
      "User_55448d42-0843-11ef-8202-7b71b4052443",
    ]->Set.fromArray
  let avoidAllPlayers = queuedPlayers->Array.filter(p => incompatiblePlayers->Set.has(p.id))

  let maxRating =
    players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
  let minRating =
    players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)

  let queueMatch = (match, ~dequeue=true) => {
    // Randomize the team order displayed
    // Can be used to decide who starts the serve
    let match = switch Js.Math.random_int(0, 2) {
    | 0 => (match->fst, match->snd)
    | _ => (match->snd, match->fst)
    }
    let matches = matches->Array.concat([match])
    dequeue
      ? match
        ->Match.players
        ->Array.map(p => setQueue(queue => queue->OrderedQueue.removeFromQueue(p.id)))
        ->ignore
      : ()
    setMatches(_ => matches)
  }

  let dequeueMatch = index => {
    let matches = matches->Array.filterWithIndex((_, i) => i->Int.toString != index)

    setMatches(_ => matches)
  }
  let dequeueMatches = indexes => {
    let matches =
      matches->Array.filterWithIndex((_, i) => indexes->Array.indexOf(i->Int.toString) == -1)

    setMatches(_ => matches)
  }
  // @TODO: When play counts are updated, we can update deprioritized players
  let updatePlayCounts = (match: match) => {
    setSessionState(prevState => {
      let nextState =
        [match->fst, match->snd]
        ->Array.flatMap(x => x)
        ->Array.reduce(prevState, (state, p) =>
          state->Session.update(p.id, prev => {count: prev.count + 1, paid: prev.paid})
        )

      nextState->Session.saveState(eventId)
      nextState
    })
  }
  // let updatePaidStatus = (playerId: string, paid: bool) => {
  //   setSessionState(prevState => {
  //     let nextState = prevState->Session.update(playerId, prev => {count: prev.count, paid})
  //
  //     nextState->Session.saveState(eventId)
  //     nextState
  //   })
  // }

  let initializeSessionMode = () => {
    switch sessionPlayers->Array.length >= data.rsvps->Fragment.getConnectionNodes->Array.length {
    | true => ()
    | false =>
      let players =
        data.rsvps
        ->Fragment.getConnectionNodes
        // ->Array.filterMap(rsvpToPlayerDefault)
        ->Array.filterMap(rsvpToPlayer)
        ->Array.concat(sessionPlayers)
      setSessionPlayers(_ => players)
    }
  }

  let uninitializeSessionMode = () => {
    // Removes Registered players from the Session Mode
    setSessionPlayers(_ => players->Array.filter(p => p.data->Option.isNone))
  }

  let updateSessionPlayerRatings = (updatedPlayers: array<Player.t<'a>>) => {
    setSessionPlayers(players => {
      let newState = players->Array.map(p => {
        let player = updatedPlayers->Array.find(p' => p.id == p'.id)
        switch player {
        | Some(player) => player
        | None => p
        }
      })
      newState->Players.savePlayers(eventId)
      newState
    })
  }

  let submitMatch = (match: Match.t<'a>, score, activitySlug): Js.Promise.t<unit> => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      // __id,
      "root"->RescriptRelay.makeDataId,
      "MatchListFragment_matches",
      {
        LeagueEventPageQuery_graphql.Types.activitySlug: Some(activitySlug),
        namespace: Some("doubles:rec"),
        after: None,
        before: None,
        eventId: None,
        first: None,
      },
    )

    Promise.make((resolve, reject) => {
      commitMutationCreateLeagueMatch(
        ~variables={
          matchInput: {
            activitySlug,
            namespace: "doubles:rec",
            doublesMatch: {
              winners: match->fst->Array.map(p => p.id),
              losers: match->snd->Array.map(p => p.id),
              score: [score->fst, score->snd],
              createdAt: Js.Date.make()->Util.Datetime.fromDate,
            },
          },
          connections: [connectionId],
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

  let handleMatchUpdated = (
    completedMatch: CompletedMatch.t<rsvpNode>,
    matchId: string,
  ): // ID for dequeuing from 'matches' state, -1 if not applicable
  unit => {
    // Changed return type to unit, submission handled separately or in bulk
    setLocallyCompletedMatches(local => {
      local->Js.Dict.set(matchId, completedMatch)
      local
    })
  }

  // let submitSingleMatch = ((match, score): CompletedMatch.t<rsvpNode>) => {
  //   let rated_match = match->Match.rate
  //   updateSessionPlayerRatings(rated_match->Array.flatMap(x => x))
  //
  //   switch sessionMode {
  //   | true => Promise.resolve()
  //   | false =>
  //     activity
  //     ->Option.flatMap(activity =>
  //       activity.slug->Option.map(slug => {
  //         (match, score)->CompletedMatch.submit(slug, submitMatch)
  //       })
  //     )
  //     ->Option.getOr(Js.Promise.resolve())
  //   }
  // }
  let handleMatchesComplete = (matches): Promise.t<unit> => {
    // If there's nothing to process, resolve immediately
    if matches->Array.length == 0 {
      Promise.resolve()
    } else {
      setMatchHistory(history => {
        let updatedHistory = history->Array.concat(matches->Array.map(((_, match)) => match))
        // 2. Save the updated history to persistent storage
        updatedHistory->CompletedMatches.saveMatches(eventId)
        updatedHistory
      })

      // 4. Perform network submissions if not in session mode
      switch sessionMode {
      | true => {
          matches
          ->Array.map(((matchId, (match, _))) => {
            let rated_match = match->Match.rate
            updateSessionPlayerRatings(rated_match->Array.flatMap(x => x))
            updatePlayCounts(match)
            matchId
          })
          ->dequeueMatches

          Promise.resolve() // Changed Js.Promise to Promise
        }
      | false =>
        activity
        ->Option.flatMap(activity =>
          activity.slug->Option.map(slug => {
            // Create an array of submission promises
            let submissionPromises = matches->Array.map(
              ((_, completedMatch)) => {
                completedMatch
                ->CompletedMatch.submit(slug, submitMatch)
                ->Promise.thenResolve(
                  _ =>
                    matches
                    ->Array.map(
                      ((matchId, (match, _))) => {
                        let rated_match = match->Match.rate
                        updateSessionPlayerRatings(rated_match->Array.flatMap(x => x))
                        updatePlayCounts(match)
                        matchId
                      },
                    )
                    ->dequeueMatches,
                )
              },
            )
            // Wait for all submissions to complete
            Promise.all(submissionPromises)->Promise.then(_ => Promise.resolve()) // Changed Js.Promise to Promise
          })
        )
        ->Option.getOr(Promise.resolve()) // Changed Js.Promise to Promise
      }->Promise.catch(err => {
        // Changed Js.Promise to Promise
        // Handle potential errors from any of the submissions
        Js.log2("Error submitting one or more completed matches:", err)
        // Decide whether to reject the aggregate promise or resolve
        Promise.reject(err) // Changed Js.Promise to Promise
      })
    }
  }
  let breakPlayersDesc = Lingui.UtilString.plural(
    breakPlayersCount,
    {one: "player", other: "players"},
  )

  let createTeam = (team: array<player>) => {
    setTeams(teams => {
      teams->NonEmptyArray.concat(NonEmptyArray.pure(team))
    })
  }
  let onDeleteTeam = (i: int) => {
    setTeams(teams => teams->NonEmptyArray.filterWithIndex((_, i') => i' != i))
  }

  let roundsCount =
    matchHistory->CompletedMatches.getNumberOfRounds(breakCount, players->Array.length, 4)

  let selectAllPlayers = () => {
    switch queue->Array.length >= availablePlayers->Array.length {
    | true =>
      setQueue(_ => {
        []
      })
    | false =>
      setQueue(_ => {
        // Force-Rotate the optimized player between rounds
        let optimizedPlayer = Int.mod(roundsCount, availablePlayers->Array.length)
        availablePlayers
        ->Array.get(optimizedPlayer)
        ->Option.map(p =>
          [p.id, ...availablePlayers->Array.filter(p2 => p.id != p2.id)->Array.map(p => p.id)]
        )
        ->Option.getOr(availablePlayers->Array.map(p => p.id))
      })
    }
  }

  let enableAllPlayers = () => {
    switch disabled->Set.size == 0 {
    | false =>
      setDisabled(_ => {
        Set.make()
      })
    | true =>
      setDisabled(_ => {
        Set.fromArray(allPlayers->Array.map(p => p.id))
      })
    }
  }

  switch screen {
  | Advanced =>
    <Layout.Container className="mt-4">
      <Util.Helmet>
        <meta name="viewport" content="width=device-width" />
      </Util.Helmet>
      <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-1 md:gap-8">
        <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-2 md:gap-8">
          <div className="md:col-span-2 flex">
            <UiAction
              className="rounded-md bg-indigo-600 px-3.5 py-2.5 font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 text-2xl"
              onClick={_ => setScreen(_ => Matches)}>
              {t`Start Session`}
            </UiAction>
            <HeadlessUi.Field className="flex items-center ml-2">
              <HeadlessUi.Switch
                checked={sessionMode}
                onChange={v => {
                  setSessionMode(_ => v)
                  v == true ? initializeSessionMode() : uninitializeSessionMode()
                }}
                className="group relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent bg-gray-200 transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 data-[checked]:bg-indigo-600">
                <span className="sr-only"> {t`Offline Mode`} </span>
                <span
                  ariaHidden=true
                  className="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out group-data-[checked]:translate-x-5"
                />
              </HeadlessUi.Switch>
              <HeadlessUi.Switch.Label className="ml-3 text-sm">
                {t`Offline Mode`}
              </HeadlessUi.Switch.Label>
            </HeadlessUi.Field>
          </div>
          <div className="md:col-span-2">
            <h2 className="text-2xl font-semibold text-gray-900 flex">
              {t`Leaderboard`}
              <UiAction
                className="ml-2"
                onClick={_ => {
                  // setSessionMode(_ => false)
                  // uninitializeSessionMode()
                  Util.startTransition(() => {
                    // setSessionPlayers(_ => [])
                    // initializeSessionMode()
                    refetch(
                      ~variables=Fragment.makeRefetchVariables(~id=eventId),
                      ~fetchPolicy=NetworkOnly,
                      ~onComplete=_ => {
                        setSessionMode(_ => false)
                        uninitializeSessionMode()
                        // initializeSessionMode()
                        // refetch(~variables=Fragment.makeRefetchVariables(~id=eventId))
                        // initializeRatings()->ignore
                      },
                    )->ignore
                  })
                }}>
                {<HeroIcons.ArrowPathIcon className="h-8 w-8" />}
              </UiAction>
            </h2>
            <React.Suspense fallback={<div> {t`Loading...`} </div>}>
              <Leaderboard players={allPlayers} />
            </React.Suspense>
          </div>
          <div className="">
            <h2 className="text-2xl font-semibold text-gray-900"> {t`Advanced Options`} </h2>
            <div className="flex text-right">
              <div className="flex">
                <Button.Button onClick={_ => selectAllPlayers()}>
                  {t`Queue All Players`}
                </Button.Button>
                <Button.Button className="ml-2" onClick={_ => enableAllPlayers()}>
                  {t`Checkin All Players`}
                </Button.Button>
              </div>
              <UiAction
                className="ml-auto"
                onClick={_ =>
                  setSettingsPane(prev => prev == Some(TeamBuilder) ? None : Some(TeamBuilder))}>
                {settingsPane == Some(TeamBuilder)
                  ? <HeroIcons.Users className="h-8 w-8" />
                  : <HeroIcons.UsersOutline className="h-8 w-8" />}
              </UiAction>
              <UiAction
                className="ml-2"
                onClick={_ =>
                  setSettingsPane(prev => prev == Some(AddPlayer) ? None : Some(AddPlayer))}>
                {settingsPane == Some(AddPlayer)
                  ? <HeroIcons.UserPlus className="h-8 w-8" />
                  : <HeroIcons.UserPlusOutline className="h-8 w-8" />}
              </UiAction>
              <UiAction
                className="ml-2"
                onClick={_ =>
                  setSettingsPane(prev => prev == Some(Settings) ? None : Some(Settings))}>
                {settingsPane == Some(Settings)
                  ? <HeroIcons.Cog6Tooth className="h-8 w-8" />
                  : <HeroIcons.Cog6ToothOutline className="h-8 w-8" />}
              </UiAction>
            </div>
            <div className="flex mt-2">
              {switch settingsPane {
              | Some(TeamBuilder) =>
                <>
                  <p className="mt-2 text-base leading-7 text-gray-600">
                    {t`Players in teams will always be placed in a match together on the same side.`}
                  </p>
                  <TeamsList teams onDelete=onDeleteTeam />
                  <TeamSelector
                    players
                    onTeamCreate=createTeam
                    teamPlayers={teams
                    ->NonEmptyArray.toArray
                    ->Array.flatMap(x => x)}
                  />
                </>
              | Some(AddPlayer) =>
                <SessionAddPlayer
                  eventId
                  onPlayerAdd={player => {
                    setSessionPlayers(guests => {
                      let newState =
                        guests->addGuestPlayer(player.name->Player.makeDefaultRatingPlayer)
                      newState->Players.savePlayers(eventId)
                      newState
                    })
                    setSettingsPane(_ => None)
                  }}
                />
              | Some(Settings) =>
                <div className="grid grid-cols-1">
                  <SessionEvenPlayMode
                    breakCount=courts
                    breakPlayersCount
                    onChangeBreakCount={numberOnBreak => {
                      setCourts(_ => Js.Math.max_int(0, numberOnBreak))
                      setSettingsPane(_ => None)
                    }}
                  />
                  <UiAction onClick={_ => initializeRatings()->ignore}>
                    {t`Initialize Ratings`}
                  </UiAction>
                  <UiAction onClick={_ => clearSession()->ignore}>
                    {t`Clear Session (Ratings, Match Counts, and Guest Players)`}
                  </UiAction>
                </div>
              | _ => React.null
              }}
            </div>
            <div> {t`${breakPlayersCount->Int.toString} ${breakPlayersDesc} are not playing`} </div>
          </div>
        </div>
        <div className="col-span-1">
          <UiAction onClick={_ => setManualTeamOpen(prev => !prev)}> {t`manual team`} </UiAction>
        </div>
        {manualTeamOpen
          ? <SelectMatch
              players={queuedPlayers}
              onMatchQueued={match => queueMatch(match)}
              //   setSelectedMatch(_ => Some((match :> (array<player>, array<player>))))}
            >
              {match =>
                <React.Suspense fallback={<div> {t`Loading`} </div>}>
                  <SubmitMatch match minRating maxRating onComplete={handleMatchUpdated(_, "-1")} />
                </React.Suspense>}
            </SelectMatch>
          : React.null}
        <div>
          <h2 className="text-2xl font-semibold text-gray-900"> {t`Submitted Matches`} </h2>
          {children}
        </div>
        <div>
          <h2 className="text-2xl font-semibold text-gray-900"> {t`Match History`} </h2>
          {activity
          ->Option.map(activity =>
            matchHistory
            ->Array.mapWithIndex(((match, score), i) => {
              <SubmitMatch
                key={i->Int.toString}
                match
                ?score
                minRating
                maxRating
                onDelete={() => {
                  setMatchHistory(
                    mh => {
                      let mh = mh->Array.filterWithIndex(
                        (_, i') => {
                          i == i' ? false : true
                        },
                      )
                      mh->CompletedMatches.saveMatches(eventId)
                      mh
                    },
                  )
                }}
                onComplete={((match, score)) => {
                  activity.slug
                  ->Option.map(
                    slug => {
                      (match, score)->CompletedMatch.submit(slug, submitMatch)
                    },
                  )
                  ->Option.getOr(Promise.resolve())
                  ->ignore
                }}
              />
            })
            ->React.array
          )
          ->Option.getOr(React.null)}
        </div>
      </div>
    </Layout.Container>
  | Matches =>
    <MatchesView
      players
      availablePlayers
      playersCache
      handleMatchesComplete={() => {
        // Filter out tied matches
        handleMatchesComplete(
          locallyCompletedMatches
          ->Js.Dict.entries
          ->Array.filter(((_, (_, score))) => {
            switch score {
            | Some((s1, s2)) => s1 == s2 ? false : true
            | None => true
            }
          }),
        )->Promise.thenResolve(_ => {
          // 3. Clear the locally completed matches state
          setLocallyCompletedMatches(_ => Js.Dict.empty())
        })
      }}
      queue={queue->Set.fromArray}
      checkin={<Checkin
        players=allPlayers
        disabled
        onToggleCheckin={(player, status) => {
          switch status {
          | true => setDisabled(disabled => disabled->UnorderedQueue.removeFromQueue(player.id))
          | false => setDisabled(disabled => disabled->UnorderedQueue.addToQueue(player.id))
          }
        }}
        // onUpdatePlayer={(p, paid) => updatePaidStatus(p.id, paid)}
      />}
      setQueue={players => setQueue(_ => players)}
      setRequiredPlayers
      togglePlayer={toggleQueuePlayer}
      matches
      setMatches={setMatches}
      // activity
      minRating
      maxRating
      handleMatchUpdated
      handleMatchCanceled={dequeueMatch}
      onClose={_ => setScreen(_ => Advanced)}
      selectAll={selectAllPlayers}
      breakCount={courts}
      breakPlayers={deprioritized}
      consumedPlayers
      onChangeBreakCount={numberOnBreak => {
        setCourts(_ => Js.Math.max_int(0, numberOnBreak))
        setSettingsPane(_ => None)
      }}
      matchSelector={<CompMatch
        players={(queuedPlayers :> array<Player.t<'a>>)}
        session=sessionState
        teams
        consumedPlayers={Set.make()}
        seenTeams
        lastRoundSeenTeams
        seenMatches
        lastRoundSeenMatches
        defaultStrategy={matchmakingStrategy}
        setDefaultStrategy={setMatchmakingStrategy}
        // consumedPlayers={consumedPlayers
        // ->Set.values
        // ->Array.fromIterator
        // // ->Array.concat(deprioritized->Set.values->Array.fromIterator)
        // ->Set.fromArray}
        // priorityPlayers={[]}
        priorityPlayers
        avoidAllPlayers
        ?requiredPlayers
        onSelectMatch={(match, ~dequeue: option<bool>=?) => {
          // setSelectedMatch(_ => Some(([p1'.data, p2'.data], [p3'.data, p4'.data])))
          queueMatch(match, ~dequeue?)
        }}
      />}
    />
  }
}
