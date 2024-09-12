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
    t1->Array.concat(t2)->Team.toStableId
  }
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

  let getlastRoundMatches = (matches: t<'a>, restCount: int, availablePlayers: int, playersPerMatch: int): t<'a> => {
    let lastPlayedCount = getLastPlayedPlayers(matches, restCount, availablePlayers)->Array.length
    let matchesPlayed = lastPlayedCount / playersPerMatch
    matches->Array.toReversed->Array.slice(~start=0, ~end=matchesPlayed)
  }

  external parseMatches: string => array<((array<string>, array<string>), option<(float, float)>)> =
    "JSON.parse"
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
