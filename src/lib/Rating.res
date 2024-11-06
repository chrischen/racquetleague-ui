@send
external intersection: (Js.Set.t<'a>, Js.Set.t<'a>) => Js.Set.t<'a> = "intersection"

module RatingModel = {
  type t = string
  // @module("openskill/dist/models/index.js")
  // external bradleyTerryFull: t = "bradleyTerryFull"
  // @module("openskill/dist/models/index.js")
  // external bradleyTerryPart: t = "bradleyTerryPart"
  @module("../lib/rating/models/plackettLuce.ts")
  external plackettLuce: t = "plackettLuce"
}
type user = {
  name: string,
  picture: option<string>,
  // data: 'a,
}
let makeGuest = (name: string) => {
  {
    name,
    picture: None,
  }
}

module Rating: {
  type t = {
    mu: float,
    sigma: float,
  }
  type matchRatings = array<array<t>>
  type opts = {model: option<RatingModel.t>}

  let get_rating: t => float
  let make: (float, float) => t
  let makeDefault: unit => t
  let predictDraw: array<array<t>> => float
  // let predictWin: array(array(t)) => array(float);
  let ordinal: t => float
  let rate: (~ratings: matchRatings, ~opts: option<opts>=?) => matchRatings
} = {
  type t = {
    mu: float,
    sigma: float,
  }

  type matchRatings = array<array<t>>
  type opts = {model: option<RatingModel.t>}

  @module("openskill") external rating: option<t> => t = "rating"
  @module("openskill") external ordinal: t => float = "ordinal"
  @module("openskill")
  external rate: (~ratings: matchRatings, ~opts: option<opts>=?) => matchRatings = "rate"

  @module("openskill")
  external predictDraw: array<array<t>> => float = "predictDraw"
  let get_rating = t => t.mu
  let make: (float, float) => t = (mu, sigma) => {
    rating(Some({mu, sigma}))
  }

  let makeDefault: unit => t = () => {
    rating(None)
  }
}
module Player = {
  type t<'a> = {
    data: option<'a>,
    id: string,
    name: string,
    rating: Rating.t,
    ratingOrdinal: float,
    paid: bool,
  }
  let makeDefaultRatingPlayer = (name: string) => {
    let rating = Rating.makeDefault()
    {
      data: None,
      id: "guest-" ++ name,
      name,
      rating,
      ratingOrdinal: rating->Rating.ordinal,
      paid: false,
    }
  }
}

module Team = {
  type t<'a> = array<Player.t<'a>>
  // let contains_player = ((p1, p2): t<'a>, player: Player.t<'a>) =>
  //   p1.id == player.id || p2.id == player.id
  let contains_player = (players: t<'a>, player: Player.t<'a>) => {
    let players = players->Array.map(p => p.id)->Set.fromArray
    players->Set.has(player.id)
    // players->Array.findIndex(p' => player.id == p'.id) > -1
  }

  let toSet: t<'a> => Set.t<string> = team => team->Array.map(p => p.id)->Set.fromArray

  let is_equal_to = (t1: t<'a>, t2: t<'a>) => {
    let t1 = t1->Array.map(p => p.id)->Set.fromArray
    let t2 = t2->Array.map(p => p.id)->Set.fromArray
    t1->intersection(t2)->Set.size == t1->Set.size
  }

  let toStableId = (t: t<'a>) => {
    t->Array.map(p => p.id)->Array.toSorted(String.compare)->Array.join("-")
  }
}

module TeamSet = {
  type t = Set.t<string>
  let is_equal_to = (t1: t, t2: t) => {
    t1->intersection(t2)->Set.size == t1->Set.size
    // t1->Set.values->Array.fromIterator->Array.every(p => t2->Set.has(p))
  }
  let containsAllOf = (t1: t, t2: t) => {
    t2->intersection(t1)->Set.size == t2->Set.size
  }
}

module Match = {
  type t<'a> = (Team.t<'a>, Team.t<'a>)
  let contains_player = ((t1, t2): t<'a>, player: Player.t<'a>) =>
    Team.contains_player(t1, player) || Team.contains_player(t2, player)

  let contains_any_players = ((t1, t2): t<'a>, players: array<Player.t<'a>>) => {
    let players = players->Array.map(p => p.id)->Set.fromArray
    let match_players =
      [t1, t2]->Array.map(t => t->Array.map(p => p.id))->Array.flatMap(x => x)->Set.fromArray

    match_players->intersection(players)->Set.size > 0
  }

  let contains_all_players = ((t1, t2): t<'a>, players: array<Player.t<'a>>) => {
    let players = players->Array.map(p => p.id)->Set.fromArray
    let match_players =
      [t1, t2]->Array.map(t => t->Array.map(p => p.id))->Array.flatMap(x => x)->Set.fromArray

    players->intersection(match_players)->Set.size == players->Set.size
  }

  let rate = ((winners, losers)) => {
    Rating.rate(
      ~ratings=[winners, losers]->Array.map(Array.map(_, (player: Player.t<'a>) => player.rating)),
      ~opts=Some({model: Some(RatingModel.plackettLuce)}),
    )->Belt.Array.zipBy([winners, losers], (new_ratings, old_teams) => {
      new_ratings->Belt.Array.zipBy(old_teams, (new_rating, old_player) => {
        {...old_player, Player.rating: new_rating}
      })
    })
  }

  let toStableId = ((t1, t2): t<'a>) => {
    [t1->Team.toStableId, t2->Team.toStableId]->Array.toSorted(String.compare)->Array.join("-")
  }

  let players = ((t1, t2)) => [t1, t2]->Array.flatMap(x => x)

  // let toDndItem = (t: t<'a>): MultipleContainers.Items.t
}

module CompletedMatch = {
  type t<'a> = (Match.t<'a>, option<(float, float)>)

  let submit = (
    (match, score): t<'a>,
    activitySlug: string,
    submitMatch: (Match.t<'a>, (float, float), string) => Js.Promise.t<unit>,
  ) => {
    switch score {
    | Some((scoreWinner, scoreLoser)) => submitMatch(match, (scoreWinner, scoreLoser), activitySlug)
    | None => Js.Promise.resolve()
    }
  }
  let toStableId: t<'a> => string = ((t, _)) => t->Match.toStableId
}
type rsvpNode = AiTetsu_event_graphql.Types.fragment_rsvps_edges_node
module CompletedMatches = {
  type t<'a> = array<CompletedMatch.t<'a>>

  let getLastPlayedPlayers = (matches: t<'a>, restCount: int, availablePlayers: int): array<
    Player.t<'a>,
  > => {
    let playersCount = availablePlayers - restCount

    let teams =
      matches
      ->Array.toReversed
      ->Array.flatMap(((match, _)) => [match->fst, match->snd])
    teams
    ->Array.flatMap(p => p)
    ->Array.slice(~start=0, ~end=playersCount)
  }

  let getLastRoundMatches = (
    matches: t<'a>,
    restCount: int,
    availablePlayers: int,
    playersPerMatch: int,
  ): t<'a> => {
    let lastPlayedCount = getLastPlayedPlayers(matches, restCount, availablePlayers)->Array.length
    let matchesPlayed = lastPlayedCount / playersPerMatch
    matches->Array.toReversed->Array.slice(~start=0, ~end=matchesPlayed)
  }

  let getNumberOfRounds = (
    matches: t<'a>,
    restCount: int,
    availablePlayers: int,
    playersPerMatch: int,
  ): int => {
    let lastPlayedCount = getLastPlayedPlayers(matches, restCount, availablePlayers)->Array.length
    let matchesLastPlayed = lastPlayedCount / playersPerMatch
    let rounds = switch matchesLastPlayed {
    | 0 => 0
    | n => matches->Array.length / n
    }
    rounds
  }

  external parseMatches: string => array<(
    (array<string>, array<string>),
    Js.Null_undefined.t<(float, float)>,
  )> = "JSON.parse"
  let saveMatches = (t: t<'a>, namespace: string) => {
    let t = t->Array.map((((team1, team2), score)) => {
      ((team1->Array.map(p => p.id), team2->Array.map(p => p.id)), score)
    })
    Dom.Storage2.localStorage->Dom.Storage2.setItem(
      namespace ++ "-matchesState",
      t->Js.Json.stringifyAny->Option.getOr(""),
    )
  }
  let loadMatches = (namespace: string, players: array<Player.t<rsvpNode>>): t<'a> => {
    let players = players->Array.reduce(Js.Dict.empty(), (acc, player) => {
      acc->Js.Dict.set(player.id, player)
      acc
    })

    switch Dom.Storage2.localStorage->Dom.Storage2.getItem(namespace ++ "-matchesState") {
    | Some(state) => state->parseMatches
    | None => []
    }
    ->Array.map((((team1, team2), score)) => {
      let score = Js.Null_undefined.toOption(score)
      (
        (
          team1
          ->Array.map(p => players->Js.Dict.get(p))
          ->Array.reduce(Some([]), (acc, player) =>
            acc->Option.flatMap(
              acc =>
                switch player {
                | Some(p) => Some(acc->Array.concat([p]))
                | None => None
                },
            )
          ),
          team2
          ->Array.map(p => players->Js.Dict.get(p))
          ->Array.reduce(Some([]), (acc, player) =>
            acc->Option.flatMap(
              acc =>
                switch player {
                | Some(p) => Some(acc->Array.concat([p]))
                | None => None
                },
            )
          ),
        ),
        score,
      )
    })
    ->Array.filterMap((((team1, team2), score)) =>
      switch (team1, team2) {
      | (Some(t1), Some(t2)) => Some(((t1, t2), score))
      | _ => None
      }
    )
  }
}

module DoublesTeam = {
  type t<'a> = (Player.t<'a>, Player.t<'a>)
  type errs = TwoPlayersRequired
  let fromTeam = (team: Team.t<'a>): result<t<'a>, errs> => {
    switch team {
    | [p1, p2] => Ok((p1, p2))
    | _ => Error(TwoPlayersRequired)
    }
  }
}

module DoublesMatch = {
  type t<'a> = (DoublesTeam.t<'a>, DoublesTeam.t<'a>)
  type errs = DoublesTeam.errs
  let fromMatch = ((t1, t2): Match.t<'a>): result<t<'a>, errs> => {
    let t1 = t1->DoublesTeam.fromTeam
    let t2 = t2->DoublesTeam.fromTeam
    switch (t1, t2) {
    | (Ok(t1), Ok(t2)) => Ok((t1, t2))
    | (Error(e), _)
    | (_, Error(e)) =>
      Error(e)
    }
  }
}

type player = Player.t<rsvpNode>
type team = array<player>
type match = (team, team)

external parsePlayers: string => Js.Dict.t<Player.t<rsvpNode>> = "JSON.parse"
module Players = {
  type t = array<player>
  let sortByRatingDesc = (t: t) =>
    t->Array.toSorted((a, b) => {
      let userA = a.rating.mu
      let userB = b.rating.mu
      userA < userB ? 1. : -1.
    })

  let sortByPlayCountAsc = (t: t, session: Session.t) => {
    t->Array.toSorted((a, b) =>
      (session->Session.get(a.id)).count < (session->Session.get(b.id)).count ? -1. : 1.
    )
  }
  let sortByPlayCountDesc = (t: t, session: Session.t) => {
    t->Array.toSorted((a, b) =>
      (session->Session.get(a.id)).count < (session->Session.get(b.id)).count ? 1. : -1.
    )
  }

  let sortByOrdinalDesc = (t: t) =>
    t->Array.toSorted((a, b) => a.ratingOrdinal < b.ratingOrdinal ? 1. : -1.)

  let filterOut = (players: t, unavailable: TeamSet.t) =>
    players->Array.filter(p => !(unavailable->Set.has(p.id)))

  let addBreakPlayersFrom = (breakPlayers: t, players: t, breakCount: int): t => {
    players
    ->filterOut(breakPlayers->Array.map(p => p.id)->Set.fromArray)
    ->Array.slice(~start=0, ~end=breakCount - breakPlayers->Array.length)
    // ->Array.map(p => p.id)
    ->Array.concat(breakPlayers)
  }
  let savePlayers = (t: t, namespace: string) => {
    let t = t->Array.map(p => {...p, data: None})
    let t = t->Array.reduce(Js.Dict.empty(), (acc, player) => {
      acc->Js.Dict.set(player.id, player)
      acc
    })

    Dom.Storage2.localStorage->Dom.Storage2.setItem(
      namespace ++ "-playersState",
      t->Js.Json.stringifyAny->Option.getOr(""),
    )
  }
  let loadPlayers = (players: array<Player.t<rsvpNode>>, namespace: string): array<
    Player.t<rsvpNode>,
  > => {
    let storage = switch Dom.Storage2.localStorage->Dom.Storage2.getItem(
      namespace ++ "-playersState",
    ) {
    | Some(state) => state->parsePlayers
    | None => Js.Dict.empty()
    }
    players->Array.map(p => {
      storage->Js.Dict.get(p.id)->Option.map(store => {...store, data: p.data})->Option.getOr(p)
    })
  }
}
open Util
type matchmakingResult<'a> = {
  seenTeams: array<Set.t<string>>,
  // seenTeams: array<Team.t<'a>>,
  matches: array<Match.t<'a>>,
}
// Gets n from array array from a starting index, or returns the the array if
// it's less than n and minimum of 4
let array_get_n_from = (from: int, n: int, arr: array<'a>): option<array<'a>> => {
  let n = if arr->Array.length > 3 && arr->Array.length < n {
    arr->Array.length
  } else {
    n
  }

  // if arr->Array.length > 3 && arr->Array.length < n {
  //   Some(arr)
  // } else
  if from < Array.length(arr) - (n - 1) {
    let arr = Array.slice(arr, ~start=from, ~end=from + n)
    if n == arr->Array.length {
      Some(arr)
    } else {
      None
    }
    // } else {
    //   None
    // }
  } else {
    None
  }
}
let array_split_by_n = (arr: array<'a>, n) => {
  let rec loop = (from: int, acc: array<array<'a>>) => {
    let next = array_get_n_from(from, n, arr)
    switch next {
    | Some(next) => loop(from + 1, acc->Array.concat([next]))
    | None => acc
    }
  }
  loop(0, [])
}
let array_combos: array<'a> => array<('a, 'a)> = arr => {
  arr->Array.flatMapWithIndex((v, i) =>
    arr->Array.slice(~start=i + 1, ~end=Array.length(arr))->Array.map(v2 => (v, v2))
  )
}
let combos = (arr1: array<'a>, arr2: array<'a>): array<('a, 'a)> => {
  arr1->Array.flatMap(d => arr2->Array.map(v => (d, v)))
}
let match_quality: Match.t<'a> => float = ((team1, team2)) => {
  Rating.predictDraw([team1->Array.map(p => p.rating), team2->Array.map(p => p.rating)])
}
type sortedArray<'a> = {value: 'a, sort: float}
let shuffle = arr =>
  arr
  ->Array.map(value => {value, sort: Math.random()})
  ->Array.toSorted((a, b) => a.sort -. b.sort)
  ->Array.map(({value}) => value)

let tuple2array = ((a, b)) => [a, b]
let team_to_players_set = (team: array<Player.t<'a>>): Set.t<string> =>
  team->Array.map(p => p.id)->Set.fromArray

let find_all_match_combos = (
  availablePlayers: array<Player.t<'a>>,
  priorityPlayers,
  avoidAllPlayers,
  teamConstraints: NonEmptyArray.t<Set.t<string>>,
) => {
  let teams = availablePlayers->array_combos->Array.map(tuple2array)

  // Implicitly the unassigned players form a team
  let teamConstraintsSet =
    teamConstraints
    ->NonEmptyArray.toArray
    ->Array.map(a => a->Set.values->Array.fromIterator)
    ->Array.flatMap(x => x)
    ->Set.fromArray
  let implicitTeam: Set.t<string> =
    availablePlayers
    ->Array.filter(p => !(teamConstraintsSet->Set.has(p.id)))
    ->Array.map(p => p.id)
    ->Set.fromArray

  let result = teams->Array.reduce({seenTeams: [], matches: []}, ({seenTeams, matches}, team) => {
    let players' = availablePlayers->Array.filter(p => !(team->Team.contains_player(p)))
    // Teams of remaining players
    let teams' = players'->array_combos->Array.map(tuple2array)
    let teams' = teams'->Array.filter(t => {
      seenTeams->Array.findIndex(t' => t'->TeamSet.is_equal_to(t->team_to_players_set)) == -1
    })

    {
      seenTeams: seenTeams->Array.concat([team->team_to_players_set]),
      matches: matches->Array.concat([team]->combos(teams')),
    }
  })
  let {matches} = result
  let matches = matches->Array.map(match => {
    let quality = match->match_quality
    (match, quality)
  })

  // Constraints
  let results =
    priorityPlayers->Array.length == 0
      ? matches
      : matches->Array.filter(((match, _)) => match->Match.contains_any_players(priorityPlayers))

  let results =
    avoidAllPlayers->Array.length < 2
      ? results
      : results->Array.filter(((match, _)) => !(match->Match.contains_all_players(avoidAllPlayers)))

  teamConstraints
  ->Option.map(teamConstraints => {
    let teamConstraints = teamConstraints->Array.concat([implicitTeam])
    results->Array.filter(((match, _)) => {
      let (team1, team2) = match
      let team1 = team1->Team.toSet
      let team2 = team2->Team.toSet
      // Include match if it contains any of the teams
      let constr1 =
        teamConstraints->Array.findIndex(
          teamConstraint => {
            teamConstraint->TeamSet.containsAllOf(team1)
          },
        ) > -1
      let constr2 =
        teamConstraints->Array.findIndex(
          teamConstraint => {
            teamConstraint->TeamSet.containsAllOf(team2)
          },
        ) > -1
      constr1 && constr2
    })
  })
  ->Option.getOr(results)
}
let strategy_by_competitive = (
  players: array<Player.t<'a>>,
  consumedPlayers: Set.t<string>,
  priorityPlayers: array<Player.t<'a>>,
  avoidAllPlayers: array<Player.t<'a>>,
  teams: NonEmptyArray.t<Set.t<string>>,
) => {
  players
  ->Players.sortByRatingDesc
  ->array_split_by_n(8)
  ->Array.reduce([], (acc, playerSet) => {
    let matches =
      playerSet
      ->Players.filterOut(consumedPlayers)
      ->find_all_match_combos(priorityPlayers, avoidAllPlayers, teams)
      ->Array.toSorted((a, b) => {
        let (_, qualityA) = a
        let (_, qualityB) = b
        qualityA < qualityB ? 1. : -1.
      })
    acc->Array.concat(matches)
  })
}
let strategy_by_competitive_plus = (
  players: array<Player.t<'a>>,
  consumedPlayers: Set.t<string>,
  priorityPlayers: array<Player.t<'a>>,
  avoidAllPlayers: array<Player.t<'a>>,
  teams: NonEmptyArray.t<Set.t<string>>,
) => {
  players
  ->Array.toSorted((a, b) => {
    let userA = a.rating.mu
    let userB = b.rating.mu
    userA < userB ? 1. : -1.
  })
  ->array_split_by_n(6)
  ->Array.reduce([], (acc, playerSet) => {
    let matches =
      playerSet
      ->Players.filterOut(consumedPlayers)
      ->find_all_match_combos(priorityPlayers, avoidAllPlayers, teams)
      ->Array.toSorted((a, b) => {
        let (_, qualityA) = a
        let (_, qualityB) = b
        qualityA < qualityB ? 1. : -1.
      })
    acc->Array.concat(matches)
  })
}

let strategy_by_mixed = (
  availablePlayers,
  priorityPlayers,
  avoidAllPlayers,
  teams: NonEmptyArray.t<Set.t<string>>,
) => {
  find_all_match_combos(
    availablePlayers,
    priorityPlayers,
    avoidAllPlayers,
    teams,
  )->Array.toSorted((a, b) => {
    let (_, qualityA) = a
    let (_, qualityB) = b
    qualityA < qualityB ? 1. : -1.
  })
}

let strategy_by_round_robin = (
  availablePlayers,
  priorityPlayers,
  avoidAllPlayers,
  teams: NonEmptyArray.t<Set.t<string>>,
) => {
  let matches = find_all_match_combos(availablePlayers, priorityPlayers, avoidAllPlayers, teams)
  matches
}

let strategy_by_random = (
  availablePlayers,
  priorityPlayers,
  avoidAllPlayers,
  teams: NonEmptyArray.t<Set.t<string>>,
) => {
  let matches = find_all_match_combos(availablePlayers, priorityPlayers, avoidAllPlayers, teams)
  matches->shuffle
}

let strategy_by_dupr = (availablePlayers, priorityPlayers, avoidAllPlayers) => {
  let teams =
    availablePlayers
    ->Players.sortByRatingDesc
    ->array_split_by_n(3)
    ->Array.map(Array.map(_, p => p.id))
    ->Array.map(Set.fromArray)
    ->NonEmptyArray.fromArray

  let matches = find_all_match_combos(availablePlayers, priorityPlayers, avoidAllPlayers, teams)
  matches->Array.toSorted((a, b) => {
    let (_, qualityA) = a
    let (_, qualityB) = b
    qualityA < qualityB ? 1. : -1.
  })
}

type strategy = CompetitivePlus | Competitive | Mixed | RoundRobin | Random | DUPR
let rec getMatches = (
  players: Players.t,
  consumedPlayers,
  strategy,
  priorityPlayers,
  avoidAllPlayers,
  teamConstraints,
) => {
  let availablePlayers = players->Players.filterOut(consumedPlayers)
  let matches = switch strategy {
  | Mixed => strategy_by_mixed(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints)
  | RoundRobin =>
    strategy_by_round_robin(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints)
  | Random =>
    strategy_by_random(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints)
  | DUPR => strategy_by_dupr(availablePlayers, priorityPlayers, avoidAllPlayers)
  | Competitive =>
    strategy_by_competitive(
      players,
      consumedPlayers,
      priorityPlayers,
      avoidAllPlayers,
      teamConstraints,
    )
  | CompetitivePlus =>
    strategy_by_competitive_plus(
      players,
      consumedPlayers,
      priorityPlayers,
      avoidAllPlayers,
      teamConstraints,
    )
  }
  matches
}
module PlayersCache = {
  type t = Js.Dict.t<player>

  let fromPlayers: Players.t => t = players => {
    players->Array.map(p => (p.id, p))->Js.Dict.fromArray
  }

  let get: (t, string) => option<player> = (cache, pid) => cache->Js.Dict.get(pid)
}
module Matches = {
  type t<'a> = array<Match.t<'a>>
  let toDndItems: t<'a> => MultipleContainers.Items.t = t => {
    t
    ->Array.map(((t1, t2)) => {
      [t1, t2]
    })
    ->Array.flatMap(x => x)
    ->Array.mapWithIndex((team, i) => {
      (i->Int.toString, team->Array.map(p => p.id))
    })
    ->Js.Dict.fromArray
  }

  let fromDndItems: (MultipleContainers.Items.t, PlayersCache.t) => t<'a> = (
    items,
    playersCache,
  ) => {
    let (matches, _) =
      items
      ->Js.Dict.entries
      ->Array.map(((_, players)) => {
        let players = players->Array.map(p => playersCache->PlayersCache.get(p))
        // switch players {
        // | [Some(p1), Some(p2), Some(p3), Some(p4)] => Some(([p1, p2], ([p3, p4])))
        // | _ => None
        // }
        players->Array.filterMap(x => x)
      })
      ->Array.reduce(([], (None, None)), ((matches, buildingMatch), team) => {
        switch buildingMatch {
        | (Some(t1), None) => (matches->Array.concat([(t1, team)]), (None, None))
        | (None, Some(t2)) => (matches->Array.concat([(team, t2)]), (None, None))
        | (None, None) => (matches, (Some(team), None))
        | (Some(t1), Some(t2)) => (matches->Array.concat([(t1, t2)]), (Some(team), None))
        }
        // matches->Array.concat([x])
      })
    matches
  }
}
