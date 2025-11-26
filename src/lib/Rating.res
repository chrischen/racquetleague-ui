@send
external intersection: (Js.Set.t<'a>, Js.Set.t<'a>) => Js.Set.t<'a> = "intersection"

// Generate UUID using Web Crypto API
@val external randomUUID: unit => string = "crypto.randomUUID"

module RatingModel = {
  type t = string
  // @module("openskill/dist/models/index.js")
  // external bradleyTerryFull: t = "bradleyTerryFull"
  // @module("openskill/dist/models/index.js")
  // external bradleyTerryPart: t = "bradleyTerryPart"
  @module("../lib/rating/models/plackettLuce.ts")
  external plackettLuce: t = "plackettLuce"
}
module Gender = {
  type t = Male | Female
  let toInt = (gender: t) => {
    switch gender {
    | Male => 1
    | Female => 0
    }
  }
  let fromInt = (int: int): t => {
    switch int {
    | 0 => Female
    | _ => Male
    }
  }
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
  let predictWin: array<array<t>> => array<float>
  let ordinal: t => float
  let rate: (~ratings: matchRatings, ~opts: option<opts>=?) => matchRatings
  // let log_decay: float => float;
  let decay_by_factor: (t, float) => t
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
  @module("openskill")
  external predictWin: array<array<t>> => array<float> = "predictWin"
  let get_rating = t => t.mu
  let make: (float, float) => t = (mu, sigma) => {
    rating(Some({mu, sigma}))
  }

  let makeDefault: unit => t = () => {
    rating(None)
  }
  // let log_decay = (x: float): float => {
  //   let k = 0.00833; // About 160 starts decaying
  //   let x0 = 640.0;
  //   1.0 /. (1.0 +. exp(-. k *. (x -. x0)));
  // };
  let decay_by_factor = (t: t, factor: float): t => {
    let diff = 8.333333 -. t.sigma
    let decay = factor *. diff
    let sigma = t.sigma +. decay
    make(t.mu, sigma)
  }
}
module Player = {
  type t<'a> = {
    data: option<'a>,
    id: string,
    intId: int,
    name: string,
    rating: Rating.t,
    ratingOrdinal: float,
    paid: bool,
    gender: Gender.t,
    count: int,
  }
  let makeDefaultRatingPlayer = (name: string, gender: Gender.t, intId: int) => {
    let rating = Rating.makeDefault()
    {
      data: None,
      id: "guest-" ++ name,
      intId,
      name,
      rating,
      ratingOrdinal: rating->Rating.ordinal,
      paid: false,
      gender,
      count: 0,
    }
  }

  // Serialize player data for TinyBase storage
  let toDb = (player: t<'a>): TinyBase.row => {
    let row = Js.Dict.empty()
    row->Js.Dict.set("playerId", player.id->Js.Json.string)
    row->Js.Dict.set("intId", player.intId->Int.toFloat->Js.Json.number)
    row->Js.Dict.set("name", player.name->Js.Json.string)
    row->Js.Dict.set("ratingMu", player.rating.mu->Js.Json.number)
    row->Js.Dict.set("ratingSigma", player.rating.sigma->Js.Json.number)
    row->Js.Dict.set("genderInt", player.gender->Gender.toInt->Int.toFloat->Js.Json.number)
    row->Js.Dict.set("paid", player.paid->Js.Json.boolean)
    row->Js.Dict.set("count", player.count->Int.toFloat->Js.Json.number)
    row
  }

  // Deserialize player data from TinyBase storage
  let fromDb = (row: TinyBase.row): option<t<'a>> => {
    switch (
      row->Js.Dict.get("playerId")->Option.flatMap(v => v->Js.Json.decodeString),
      row->Js.Dict.get("intId")->Option.flatMap(v => v->Js.Json.decodeNumber),
      row->Js.Dict.get("name")->Option.flatMap(v => v->Js.Json.decodeString),
      row->Js.Dict.get("ratingMu")->Option.flatMap(v => v->Js.Json.decodeNumber),
      row->Js.Dict.get("ratingSigma")->Option.flatMap(v => v->Js.Json.decodeNumber),
      row->Js.Dict.get("genderInt")->Option.flatMap(v => v->Js.Json.decodeNumber),
    ) {
    | (Some(id), Some(intId), Some(name), Some(mu), Some(sigma), Some(genderInt)) =>
      Some({
        data: None,
        id,
        intId: intId->Float.toInt,
        name,
        rating: {mu, sigma},
        ratingOrdinal: 0.,
        paid: row
        ->Js.Dict.get("paid")
        ->Option.flatMap(v => v->Js.Json.decodeBoolean)
        ->Option.getOr(false),
        gender: Gender.fromInt(genderInt->Float.toInt),
        count: row
        ->Js.Dict.get("count")
        ->Option.flatMap(v => v->Js.Json.decodeNumber)
        ->Option.map(Float.toInt)
        ->Option.getOr(0),
      })
    | _ => None
    }
  }

  // JSON decoder for player objects (with rescript-json-combinators)
  let decodePlayer = (): Json.Decode.t<t<'a>> =>
    Json.Decode.object(field => {
      let decodeRating = Json.Decode.object(field => {
        let mu = field.required("mu", Json.Decode.float)
        let sigma = field.required("sigma", Json.Decode.float)
        Rating.make(mu, sigma)
      })

      let decodeGender = Json.Decode.int->Json.Decode.map(Gender.fromInt)

      let id = field.required("id", Json.Decode.string)
      let intId = field.required("intId", Json.Decode.int)
      let name = field.required("name", Json.Decode.string)
      let rating = field.required("rating", decodeRating)
      let ratingOrdinal = field.required("ratingOrdinal", Json.Decode.float)
      let paid = field.required("paid", Json.Decode.bool)
      let gender = field.required("gender", decodeGender)
      let count = field.optional("count", Json.Decode.int)->Option.getOr(0)

      let player: t<'a> = {
        data: None,
        id,
        intId,
        name,
        rating,
        ratingOrdinal,
        paid,
        gender,
        count,
      }
      player
    })

  // Convert player to JSON object (excluding data field, with gender as int)
  let toJson = (player: t<'a>): Js.Json.t => {
    let obj = Js.Dict.empty()
    obj->Js.Dict.set("id", player.id->Js.Json.string)
    obj->Js.Dict.set("intId", player.intId->Int.toFloat->Js.Json.number)
    obj->Js.Dict.set("name", player.name->Js.Json.string)

    let ratingObj = Js.Dict.empty()
    ratingObj->Js.Dict.set("mu", player.rating.mu->Js.Json.number)
    ratingObj->Js.Dict.set("sigma", player.rating.sigma->Js.Json.number)
    obj->Js.Dict.set("rating", ratingObj->Js.Json.object_)

    obj->Js.Dict.set("ratingOrdinal", player.ratingOrdinal->Js.Json.number)
    obj->Js.Dict.set("paid", player.paid->Js.Json.boolean)
    obj->Js.Dict.set("gender", player.gender->Gender.toInt->Int.toFloat->Js.Json.number)
    obj->Js.Dict.set("count", player.count->Int.toFloat->Js.Json.number)
    obj->Js.Json.object_
  }

  // Serialize player to JSON string (excluding data field)
  let toJsonString = (player: t<'a>): string => {
    player->toJson->Js.Json.stringifyAny->Option.getOr("{}")
  }

  // Deserialize player from JSON
  let fromJson = (json: Js.Json.t): option<t<'a>> => {
    switch json->Json.Decode.decode(decodePlayer()) {
    | Ok(player) => Some(player)
    | Error(msg) => {
        Js.log2("[Player.fromJson] Decode error:", msg)
        None
      }
    }
  }

  // Deserialize player from JSON string
  let fromJsonString = (jsonStr: string): option<t<'a>> => {
    try {
      let json = jsonStr->Js.Json.parseExn
      fromJson(json)
    } catch {
    | _ => {
        Js.log2("[Player.fromJsonString] Failed to parse:", jsonStr)
        None
      }
    }
  }
}

module Team = {
  type teamType = Regular | Anti
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

  // Serialize team to TinyBase - returns array of player rows
  let toDb = (team: t<'a>): array<TinyBase.row> => {
    team->Array.map(player => player->Player.toDb)
  }
}

module TeamCountDict = {
  type t = Map.t<string, int>

  // Create an empty dictionary
  let make = (): t => Map.make()

  // Set the last round for a team
  let setLastRound = (dict: t, teamId: string, roundNumber: int): unit => {
    dict->Map.set(teamId, roundNumber)
  }

  // Set the last round for both teams in a match
  let setMatchLastRound = (dict: t, team1Id: string, team2Id: string, roundNumber: int): unit => {
    setLastRound(dict, team1Id, roundNumber)
    setLastRound(dict, team2Id, roundNumber)
  }

  // Get the last round for a team (returns 0 if not found, meaning never played)
  let getLastRound = (dict: t, teamId: string): int => {
    dict->Map.get(teamId)->Option.getOr(0)
  }

  // Get the score for a match (sum of both team's last round numbers)
  // Lower score means teams haven't played recently
  let getMatchScore = (dict: t, team1Id: string, team2Id: string): int => {
    getLastRound(dict, team1Id) + getLastRound(dict, team2Id)
  }

  // Build dictionary from match history with round numbers
  let fromHistory = (
    history: array<'match>,
    getTeams: 'match => (string, string),
    matchesPerRound: int,
  ): t => {
    let dict = make()
    history->Array.forEachWithIndex((match, index) => {
      let (team1Id, team2Id) = getTeams(match)
      // Calculate round number (1-indexed)
      let roundNumber = index / matchesPerRound + 1
      setMatchLastRound(dict, team1Id, team2Id, roundNumber)
    })
    dict
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

  let contains_more_than_1_players = ((t1, t2): t<'a>, players: array<Player.t<'a>>) => {
    let players = players->Array.map(p => p.id)->Set.fromArray
    let match_players =
      [t1, t2]->Array.map(t => t->Array.map(p => p.id))->Array.flatMap(x => x)->Set.fromArray

    match_players->intersection(players)->Set.size > 1
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

  // Map a function over all players in both teams
  let mapPlayers = ((t1, t2): t<'a>, fn: Player.t<'a> => Player.t<'a>): t<'a> => {
    (t1->Array.map(fn), t2->Array.map(fn))
  }

  // Increment play count for all players in the match
  let incrementPlayCounts = (match: t<'a>): t<'a> => {
    mapPlayers(match, player => {...player, count: player.count + 1})
  }

  // Get winners based on score - returns player IDs of the winning team and their score
  let getWinners = (match: t<'a>, score: (float, float)): (array<string>, float) => {
    let (team1, team2) = match
    let (team1Score, team2Score) = score
    let winningTeam = team1Score > team2Score ? team1 : team2
    let winningScore = team1Score > team2Score ? team1Score : team2Score
    (winningTeam->Array.map(p => p.id), winningScore)
  }

  // Get losers based on score - returns player IDs of the losing team and their score
  let getLosers = (match: t<'a>, score: (float, float)): (array<string>, float) => {
    let (team1, team2) = match
    let (team1Score, team2Score) = score
    let losingTeam = team1Score > team2Score ? team2 : team1
    let losingScore = team1Score > team2Score ? team2Score : team1Score
    (losingTeam->Array.map(p => p.id), losingScore)
  }

  // Serialize match to TinyBase - returns array of all player rows
  let toDb = (match: t<'a>): array<TinyBase.row> => {
    let (team1, team2) = match
    Array.concat(team1->Team.toDb, team2->Team.toDb)
  }

  // Load match from TinyBase relational tables
  // This would be used to reconstruct a match from the database
  let loadFromDb = (
    _matchRow: TinyBase.row,
    teamsTable: TinyBase.table,
    playersTable: TinyBase.table,
    matchId: string,
  ): option<t<'a>> => {
    // Get teams for this match
    let teams =
      teamsTable
      ->Js.Dict.entries
      ->Array.filterMap(((_, teamRow)) => {
        switch (
          teamRow->Js.Dict.get("matchId")->Option.map(v => v->Obj.magic),
          teamRow->Js.Dict.get("teamIndex")->Option.map(v => v->Obj.magic),
          teamRow->Js.Dict.get("playerIds")->Option.flatMap(v => v->Js.Json.decodeString),
        ) {
        | (Some(mId: string), Some(tIdx: float), Some(playerIdsStr)) if mId == matchId =>
          // Parse JSON string to get array of player IDs
          try {
            let playerIds =
              playerIdsStr
              ->Js.Json.parseExn
              ->Js.Json.decodeArray
              ->Option.getOr([])
              ->Array.filterMap(id => id->Js.Json.decodeString)

            // Get players for this team using the stored player IDs
            let players = playerIds->Array.filterMap(playerId => {
              playersTable->Js.Dict.get(playerId)->Option.flatMap(Player.fromDb)
            })

            Some((tIdx, players))
          } catch {
          | _ => None
          }
        | _ => None
        }
      })
      ->Array.toSorted(((idxA, _), (idxB, _)) => idxA < idxB ? -1. : 1.)
      ->Array.map(((_, players)) => players)

    // Reconstruct match as (team1, team2)
    switch teams {
    | [team1, team2] => Some((team1, team2))
    | _ => None
    }
  }

  // let toDndItem = (t: t<'a>): MultipleContainers.Items.t
}

module CompletedMatch = {
  type t<'a> = (Match.t<'a>, option<(float, float)>)

  let submit = (
    (match, score): t<'a>,
    activitySlug: string,
    submitMatch: (Match.t<'a>, (float, float), string) => Promise.t<unit>,
  ) => {
    switch score {
    | Some((scoreWinner, scoreLoser)) => submitMatch(match, (scoreWinner, scoreLoser), activitySlug)
    | None => Promise.resolve()
    }
  }
  let toStableId: t<'a> => string = ((t, _)) => t->Match.toStableId

  // Get winners based on score - returns player IDs of the winning team and their score
  let getWinners = ((match, score): t<'a>): option<(array<string>, float)> => {
    score->Option.map(s => match->Match.getWinners(s))
  }

  // Get losers based on score - returns player IDs of the losing team and their score
  let getLosers = ((match, score): t<'a>): option<(array<string>, float)> => {
    score->Option.map(s => match->Match.getLosers(s))
  }

  // Rate the match based on the score - returns updated teams with new ratings
  let rate = ((match, score): t<'a>): option<array<array<Player.t<'a>>>> => {
    score->Option.map(s => {
      let (team1, team2) = match
      let (team1Score, team2Score) = s
      // Determine winner and loser teams based on scores
      let (winners, losers) = team1Score > team2Score ? (team1, team2) : (team2, team1)
      Match.rate((winners, losers))
    })
  }
}
type rsvpNode = AiTetsu_event_graphql.Types.fragment_rsvps_edges_node
type eventManagerRsvpNode = EventManager_event_graphql.Types.fragment_rsvps_edges_node
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
      t->Js.Json.stringifyAny->Option.getOr("")->LzString.compress,
    )
  }
  let loadMatches = (namespace: string, players: array<Player.t<'a>>): t<'a> => {
    let players = players->Array.reduce(Js.Dict.empty(), (acc, player) => {
      acc->Js.Dict.set(player.id, player)
      acc
    })

    switch Dom.Storage2.localStorage->Dom.Storage2.getItem(namespace ++ "-matchesState") {
    | Some(state) =>
      switch state->LzString.decompress {
      | "" => []
      | decompressed => decompressed->parseMatches
      }
    // state->LzString.decompress->parseMatches
    // state->parseMatches
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
  let scored_matches = (t: t<'a>): t<'a> =>
    t->Array.filterMap(((match, score)) =>
      switch score {
      | Some(_) => Some((match, score))
      | None => None
      }
    )
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

type player<'a> = Player.t<'a>
type team<'a> = array<player<'a>>
type match<'a> = (team<'a>, team<'a>)

// Match entity with stable UUID for UI state tracking and persistence
type matchEntity<'a> = {
  id: string, // UUID for UI state tracking and server sync
  match: match<'a>,
}

// Completed match entity for EventManager
// Note: Round information is implicit from the array structure (array<array<completedMatchEntity>>)
module CompletedMatchEntity = {
  type t<'a> = {
    id: string, // UUID for UI state tracking and server sync
    match: match<'a>,
    score: option<(float, float)>, // Optional score (team1's score, team2's score)
    createdAt: Js.Date.t,
  }

  // Serialize completed match entity to TinyBase
  // Returns a single row with match ID, player data, and score
  let toDb = (entity: t<'a>): TinyBase.row => {
    let row = Js.Dict.empty()
    row->Js.Dict.set("matchId", entity.id->Js.Json.string)
    row->Js.Dict.set("type", "completedMatchEntity"->Js.Json.string)

    // Store the match as team data with player IDs
    let (team1, team2) = entity.match
    let team1Ids = team1->Array.map(p => p.id->Js.Json.string)->Js.Json.array
    let team2Ids = team2->Array.map(p => p.id->Js.Json.string)->Js.Json.array
    row->Js.Dict.set("team1PlayerIds", team1Ids)
    row->Js.Dict.set("team2PlayerIds", team2Ids)

    // Store score if available
    switch entity.score {
    | Some((team1Score, team2Score)) => {
        row->Js.Dict.set("hasScore", true->Js.Json.boolean)
        row->Js.Dict.set("team1Score", team1Score->Js.Json.number)
        row->Js.Dict.set("team2Score", team2Score->Js.Json.number)
      }
    | None => row->Js.Dict.set("hasScore", false->Js.Json.boolean)
    }

    // Store createdAt timestamp
    row->Js.Dict.set("createdAt", entity.createdAt->Js.Date.getTime->Js.Json.number)

    row
  }

  // Load completed match entity from TinyBase with full player data
  let loadFromDb = (row: TinyBase.row, playersTable: TinyBase.table): option<t<'a>> => {
    switch (
      row->Js.Dict.get("matchId")->Option.flatMap(v => v->Js.Json.decodeString),
      row->Js.Dict.get("team1PlayerIds")->Option.flatMap(v => v->Js.Json.decodeArray),
      row->Js.Dict.get("team2PlayerIds")->Option.flatMap(v => v->Js.Json.decodeArray),
      row->Js.Dict.get("createdAt")->Option.flatMap(v => v->Js.Json.decodeNumber),
    ) {
    | (Some(id), Some(team1Ids), Some(team2Ids), createdAtOpt) => {
        // Extract player IDs
        let team1PlayerIds = team1Ids->Array.filterMap(v => v->Js.Json.decodeString)
        let team2PlayerIds = team2Ids->Array.filterMap(v => v->Js.Json.decodeString)

        // Load player data
        let team1 = team1PlayerIds->Array.filterMap(playerId => {
          playersTable->Js.Dict.get(playerId)->Option.flatMap(Player.fromDb)
        })
        let team2 = team2PlayerIds->Array.filterMap(playerId => {
          playersTable->Js.Dict.get(playerId)->Option.flatMap(Player.fromDb)
        })

        // Extract score
        let score = switch row
        ->Js.Dict.get("hasScore")
        ->Option.flatMap(v => v->Js.Json.decodeBoolean) {
        | Some(true) =>
          switch (
            row->Js.Dict.get("team1Score")->Option.flatMap(v => v->Js.Json.decodeNumber),
            row->Js.Dict.get("team2Score")->Option.flatMap(v => v->Js.Json.decodeNumber),
          ) {
          | (Some(team1Score), Some(team2Score)) => Some((team1Score, team2Score))
          | _ => None
          }
        | _ => None
        }

        // Construct completed match entity
        Some({
          id,
          match: (team1, team2),
          score,
          createdAt: createdAtOpt
          ->Option.map(ts => Js.Date.fromFloat(ts))
          ->Option.getOr(Js.Date.make()),
        })
      }
    | _ => None
    }
  }
}

// Type alias for backward compatibility
type completedMatchEntity<'a> = CompletedMatchEntity.t<'a>

// Rating adjustment with metadata for historical tracking
module RatingAdjustment = {
  type t = {
    playerId: string,
    differential: float, // Amount to adjust mu by
    appliedAtRound: int, // Which round this adjustment was applied (0 = before any matches)
    timestamp: float, // When the adjustment was made (Js.Date.now())
  }

  // Serialize to JSON
  let toJson = (adj: t): Js.Json.t => {
    let dict = Js.Dict.empty()
    dict->Js.Dict.set("playerId", adj.playerId->Js.Json.string)
    dict->Js.Dict.set("differential", adj.differential->Js.Json.number)
    dict->Js.Dict.set("appliedAtRound", adj.appliedAtRound->Int.toFloat->Js.Json.number)
    dict->Js.Dict.set("timestamp", adj.timestamp->Js.Json.number)
    dict->Js.Json.object_
  }

  // Deserialize from JSON
  let fromJson = (json: Js.Json.t): option<t> => {
    json
    ->Js.Json.decodeObject
    ->Option.flatMap(dict => {
      switch (
        dict->Js.Dict.get("playerId")->Option.flatMap(v => v->Js.Json.decodeString),
        dict->Js.Dict.get("differential")->Option.flatMap(v => v->Js.Json.decodeNumber),
        dict->Js.Dict.get("appliedAtRound")->Option.flatMap(v => v->Js.Json.decodeNumber),
        dict->Js.Dict.get("timestamp")->Option.flatMap(v => v->Js.Json.decodeNumber),
      ) {
      | (Some(playerId), Some(differential), Some(appliedAtRound), Some(timestamp)) =>
        Some({
          playerId,
          differential,
          appliedAtRound: appliedAtRound->Float.toInt,
          timestamp,
        })
      | _ => None
      }
    })
  }
}

// Timeline event type for chronological processing of matches and adjustments
module TimelineEvent = {
  type t<'a> =
    | Round(array<CompletedMatchEntity.t<'a>>) // A round of matches
    | Adjustment(array<RatingAdjustment.t>) // One or more rating adjustments

  // Build timeline from rounds and adjustments
  // Timeline is ordered chronologically: seed adjustments, then alternating adjustments/rounds
  let fromRoundsAndAdjustments = (
    rounds: array<array<CompletedMatchEntity.t<'a>>>,
    adjustments: array<RatingAdjustment.t>,
  ): array<t<'a>> => {
    // Group adjustments by appliedAtRound
    let adjustmentsByRound = Map.make()
    adjustments->Array.forEach(adj => {
      let existing = adjustmentsByRound->Map.get(adj.appliedAtRound)->Option.getOr([])
      adjustmentsByRound->Map.set(adj.appliedAtRound, Array.concat(existing, [adj]))
    })

    let timeline = []

    // Add seed adjustments (appliedAtRound = -1, before any matches)
    switch adjustmentsByRound->Map.get(-1) {
    | None => ()
    | Some(seedAdjustments) => timeline->Array.push(Adjustment(seedAdjustments))
    }

    // Process each round with its adjustments
    rounds->Array.forEachWithIndex((roundMatches, roundIndex) => {
      // Add adjustments for this round (applied before the round starts)
      switch adjustmentsByRound->Map.get(roundIndex) {
      | None => ()
      | Some(roundAdjustments) => timeline->Array.push(Adjustment(roundAdjustments))
      }

      // Add the round's matches
      timeline->Array.push(Round(roundMatches))
    })

    // Add any remaining adjustments for future rounds (rounds that don't exist yet)
    // This ensures all provided adjustments are applied
    adjustments
    ->Array.filter(adj => adj.appliedAtRound >= rounds->Array.length)
    ->Array.forEach(adj => {
      switch adjustmentsByRound->Map.get(adj.appliedAtRound) {
      | None => ()
      | Some(futureAdjustments) => {
          timeline->Array.push(Adjustment(futureAdjustments))
          // Remove from map to avoid duplicates
          adjustmentsByRound->Map.delete(adj.appliedAtRound)->ignore
        }
      }
    })

    timeline
  }
}

module PlayerDecoder = {
  let decodeRating: Json.Decode.t<Rating.t> = Json.Decode.object(field => {
    let mu = field.required("mu", Json.Decode.float)
    let sigma = field.required("sigma", Json.Decode.float)
    Rating.make(mu, sigma)
  })

  let decodeGender: Json.Decode.t<Gender.t> = Json.Decode.int->Json.Decode.map(Gender.fromInt)

  let decodePlayer: Json.Decode.t<Player.t<rsvpNode>> = Json.Decode.object(field => {
    let id = field.required("id", Json.Decode.string)
    let intId = field.required("intId", Json.Decode.int)
    let name = field.required("name", Json.Decode.string)
    let rating = field.required("rating", decodeRating)
    let ratingOrdinal = field.required("ratingOrdinal", Json.Decode.float)
    let paid = field.required("paid", Json.Decode.bool)
    let gender = field.required("gender", decodeGender)
    let count = field.optional("count", Json.Decode.int)->Option.getOr(0)
    {
      Player.data: None, // Always set to None when loading from storage
      id,
      intId,
      name,
      rating,
      ratingOrdinal,
      paid,
      gender,
      count,
    }
  })
  let decodeEventManagerPlayer: Json.Decode.t<
    Player.t<eventManagerRsvpNode>,
  > = Json.Decode.object(field => {
    let id = field.required("id", Json.Decode.string)
    let intId = field.required("intId", Json.Decode.int)
    let name = field.required("name", Json.Decode.string)
    let rating = field.required("rating", decodeRating)
    let ratingOrdinal = field.required("ratingOrdinal", Json.Decode.float)
    let paid = field.required("paid", Json.Decode.bool)
    let gender = field.required("gender", decodeGender)
    let count = field.optional("count", Json.Decode.int)->Option.getOr(0)
    {
      Player.data: None, // Always set to None when loading from storage
      id,
      intId,
      name,
      rating,
      ratingOrdinal,
      paid,
      gender,
      count,
    }
  })

  let parsePlayersFromStorage = (jsonString: string): Js.Dict.t<Player.t<'a>> => {
    try {
      let json = jsonString->Js.Json.parseExn
      let resultDict = Js.Dict.empty()

      // Decode the entire dict of players
      let playersDecoder = Json.Decode.dict(decodePlayer)

      switch json->Json.Decode.decode(playersDecoder) {
      | Ok(playersDict) =>
        // Successfully decoded all players
        playersDict
        ->Js.Dict.entries
        ->Array.forEach(((key, player)) => {
          resultDict->Js.Dict.set(key, player)
        })
      | Error(_error) =>
        // If decoding as a dict of players fails, try decoding each player individually
        Js.log(_error)
        Js.log("Failed to decode all players at once, trying individual decoding")

        // Try to decode as a dict of JSON values, then decode each individually
        switch json->Js.Json.classify {
        | Js.Json.JSONObject(obj) =>
          obj
          ->Js.Dict.entries
          ->Array.forEach(((key, playerJson)) => {
            switch playerJson->Json.Decode.decode(decodePlayer) {
            | Ok(player) => resultDict->Js.Dict.set(key, player)
            | Error(_decodeError) =>
              Js.log("Failed to decode player with key: " ++ key)
              // Ignore this player and continue
              ()
            }
          })
        | _ => Js.Console.error("Players storage is not a JSON object")
        }
      }

      resultDict
    } catch {
    | Js.Exn.Error(e) =>
      Js.Console.error2("Failed to parse players JSON: ", e)
      Js.Dict.empty()
    | _ =>
      Js.Console.error("Unknown error occurred while parsing players JSON")
      Js.Dict.empty()
    }
  }
}

module Players = {
  type t<'a> = array<player<'a>>
  let sortByRatingDesc = (t: t<'a>) =>
    t->Array.toSorted((a, b) => {
      let userA = a.rating.mu
      let userB = b.rating.mu
      userA < userB ? 1. : -1.
    })

  let sortByPlayCountAsc = (t: t<'a>, session: Session.t) => {
    t->Array.toSorted((a, b) =>
      (session->Session.get(a.id)).count < (session->Session.get(b.id)).count ? -1. : 1.
    )
  }
  let sortByPlayCountDesc = (t: t<'a>, session: Session.t) => {
    t->Array.toSorted((a, b) =>
      (session->Session.get(a.id)).count < (session->Session.get(b.id)).count ? 1. : -1.
    )
  }

  let sortByOrdinalDesc = (t: t<'a>) =>
    t->Array.toSorted((a, b) => a.ratingOrdinal < b.ratingOrdinal ? 1. : -1.)

  let filterOut = (players: t<'a>, unavailable: TeamSet.t) =>
    players->Array.filter(p => !(unavailable->Set.has(p.id)))

  let mustInclude = (players: t<'a>, mustPlayers: TeamSet.t) => {
    players->Array.filter(p => mustPlayers->Set.has(p.id))
  }

  let addBreakPlayersFrom = (breakPlayers: t<'a>, players: t<'a>, breakCount: int): t<'a> => {
    players
    ->filterOut(breakPlayers->Array.map(p => p.id)->Set.fromArray)
    ->Array.slice(~start=0, ~end=breakCount - breakPlayers->Array.length)
    // ->Array.map(p => p.id)
    ->Array.concat(breakPlayers)
  }
  let savePlayers = (t: t<'a>, namespace: string) => {
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
  let loadPlayers = (players: array<Player.t<'a>>, namespace: string): array<Player.t<'a>> => {
    let storage = switch Dom.Storage2.localStorage->Dom.Storage2.getItem(
      namespace ++ "-playersState",
    ) {
    | Some(state) => state->PlayerDecoder.parsePlayersFromStorage
    | None => Js.Dict.empty()
    }
    let maxPlayerIntId = players->Array.reduce(0, (max, p) => p.intId > max ? p.intId : max)
    let guests =
      storage
      ->Js.Dict.keys
      ->Array.filter(id => id->String.startsWith("guest-"))
      ->Array.mapWithIndex((id, index) => {
        let player = storage->Js.Dict.get(id)
        switch player {
        | Some(p) => {...p, data: None}
        | None => Player.makeDefaultRatingPlayer(id, Male, maxPlayerIntId + index + 1)
        }
      })
    players
    ->Array.map(p => {
      storage->Js.Dict.get(p.id)->Option.map(store => {...store, data: p.data})->Option.getOr(p)
    })
    ->Array.concat(guests)
  }
  let calculateMeanRating = (group: t<'a>): float => {
    if group->Array.length == 0 {
      // This case should not be reached given the logic of clusterByRating,
      // as testGroup will always contain at least one player.
      // Return 0.0 or raise an error if it's considered an invalid state.
      0.0
    } else {
      let sumOfMus = group->Array.reduce(0.0, (acc, p) => acc +. p.rating.mu)
      sumOfMus /. group->Array.length->Int.toFloat
    }
  }

  let clusterByRating = (rankedPlayers_t: t<'a>, ~maxDiff: float): array<t<'a>> => {
    // rankedPlayers_t is already an array<player> due to `type t = Players.t`
    let resultingClusters: array<t<'a>> = [] // Use Js.Array2.push for mutable addition
    let currentGroup: ref<t<'a>> = ref([]) // currentGroup is array<player>

    rankedPlayers_t->Array.forEach(player => {
      let testGroup = currentGroup.contents->Array.concat([player])
      // testGroup will always have at least one player.
      let testGroupMean = calculateMeanRating(testGroup)

      let conditionMet = testGroup->Array.every(p_in_test_group => {
        Js.Math.abs_float(testGroupMean -. p_in_test_group.rating.mu) < maxDiff
      })

      if conditionMet {
        currentGroup := testGroup
      } else {
        // Finalize the current group (if not empty) and add to results
        if currentGroup.contents->Array.length > 0 {
          Js.Array2.push(resultingClusters, currentGroup.contents)->ignore
        }
        // Start a new group with the current player
        currentGroup := [player]
      }
    })

    // Add the last remaining group if it's not empty
    if currentGroup.contents->Array.length > 0 {
      Js.Array2.push(resultingClusters, currentGroup.contents)->ignore
    }

    resultingClusters
  }

  let toKMeansData = (players: t<'a>): Util.NonEmptyArray.t<array<float>> => {
    players->Array.map(player => [player.rating.mu])->Util.NonEmptyArray.fromArray
  }
  let rec findOptimalClustersRecursive = (kMeansData, currentKValue: int): KMeans.kMeansOutput => {
    // kMeansOutput is array<KMeans.clusterResult>
    if currentKValue < 1 {
      // Should ideally not be reached if initialK is capped at 1.
      // Fallback: run with k=1 if somehow currentKValue drops below 1.
      Js.Console.warn("K-Means recursion: currentKValue fell below 1. Defaulting to k=1.")
      KMeans.runKMeansWithOptimalInertia({
        data: kMeansData,
        k: 1,
        numRuns: 100, // Use 100 for stability - more runs converge to global optimum
        maxIterations: 1000,
        tolerance: 1e-6,
      })
    } else {
      let currentRunOutput = KMeans.runKMeansWithOptimalInertia({
        data: kMeansData,
        k: currentKValue,
        numRuns: 100, // Use 100 for stability - more runs converge to global optimum
        maxIterations: 1000,
        tolerance: 1e-6,
      })

      // Process with SortedClusters.make to determine the "first" cluster
      // Assumes KMeans.SortedClusters.make returns array<KMeans.clusterResult>
      let currentlySortedClusters =
        currentRunOutput->KMeans.SortedClusters.make->Util.NonEmptyArray.toArray

      if currentlySortedClusters->Array.length > 0 {
        let firstCluster = currentlySortedClusters->Array.getUnsafe(0)
        // firstCluster.points is array<array<float>>, length is number of players in it
        let firstClusterPlayerCount = firstCluster.points->Array.length

        Js.log(
          "Recursive k-means: k=" ++
          currentKValue->Int.toString ++
          ", first cluster size=" ++
          firstClusterPlayerCount->Int.toString,
        )

        if firstClusterPlayerCount >= 4 {
          // Condition met: first cluster has more than 3 players.
          // Return the result from SortedClusters.make for this k.
          currentlySortedClusters
        } else if currentKValue == 1 {
          // Base case: k is 1.
          // Return this result even if the first cluster size is not > 4 (e.g., total players <= 4).
          currentlySortedClusters
        } else {
          // Condition not met, and k > 1. Recurse with k-1.
          switch currentKValue {
          | k if k >= 3 =>
            // Combine the first two clusters
            let merged = [
              currentlySortedClusters
              ->Array.getUnsafe(0)
              ->KMeans.ClusterResult.concat(currentlySortedClusters->Array.getUnsafe(1)),
            ]->Array.concat(
              Array.slice(
                currentlySortedClusters,
                ~start=2,
                ~end=currentlySortedClusters->Array.length,
              ),
            )
            let firstCluster = merged->Array.getUnsafe(0)
            if firstCluster.points->Array.length > 3 {
              merged
            } else {
              // If the merged cluster still has <= 3 players, recurse with k-1.
              Js.Console.warn(
                "K-Means recursion: Merged cluster size is <= 3 for k=" ++
                currentKValue->Int.toString ++ ". Trying k-1.",
              )
              findOptimalClustersRecursive(kMeansData, k - 1)
            }
          | k => findOptimalClustersRecursive(kMeansData, k - 1)
          }
        }
      } else {
        // KMeans library returned no clusters (e.g., kMeansData was empty, or k was 0, or library issue).
        Js.Console.warn(
          "K-Means recursion: Library returned no clusters for k=" ++
          currentKValue->Int.toString ++ ". Trying k-1 if possible.",
        )
        if currentKValue > 1 {
          findOptimalClustersRecursive(kMeansData, currentKValue - 1)
        } else {
          // At k=1 and library returned no clusters.
          // Attempt to get a result for k=1 and sort it.
          KMeans.runKMeansWithOptimalInertia({
            data: kMeansData,
            k: 1,
            numRuns: 100, // Use 100 for stability - more runs converge to global optimum
            maxIterations: 1000,
            tolerance: 1e-6,
          })
          ->KMeans.SortedClusters.make
          ->Util.NonEmptyArray.toArray
        }
      }
    }
  }

  let findPlayerClusters = (t, k: Util.NonZeroInt.t) => {
    t
    ->toKMeansData
    ->Option.mapOr([], arr =>
      findOptimalClustersRecursive(arr, k->Util.NonZeroInt.toOption->Option.getOr(1))
    )
  }
}
module DoublesSet: {
  type t<'a> = private Players.t<'a>
  let make: Players.t<'a> => option<t<'a>>
  let toPlayers: t<'a> => Players.t<'a>
} = {
  type t<'a> = Players.t<'a>
  let make = (t: t<'a>) => {
    t->Array.length >= 4 ? Some(t) : None
  }
  let toPlayers = (t: t<'a>) => t
}
module RankedPlayers: {
  type t<'a> = private Players.t<'a>
  // Sorts the players by rating
  let make: Players.t<'a> => t<'a>
  let min_rating: (t<'a>, float) => t<'a>
  let to_players: t<'a> => Players.t<'a>
  let splitByGroups: (t<'a>, Util.NonZeroInt.t) => KMeans.SortedClusters.t
  let findTopGroup: (t<'a>, Util.NonZeroInt.t) => t<'a>
  let filter: (t<'a>, player<'a> => bool) => t<'a>
} = {
  type t<'a> = Players.t<'a>

  let make = (t: t<'a>) => {
    t->Array.toSorted((a, b) => {
      let userA = a.rating.mu
      let userB = b.rating.mu
      userA < userB ? 1. : -1.
    })
  }

  let min_rating = (playersArray: t<'a>, minRatingValue: float): t<'a> => {
    playersArray->Array.filter(player => player.rating.mu >= minRatingValue)
  }
  let to_players = t => t
  let splitByGroups = (players: t<'a>, _groups: Util.NonZeroInt.t) => {
    // let groups =
    //   groups
    //   ->Util.NonZeroInt.toOption
    //   ->Option.getOr((players->Array.length->Int.toFloat /. 6.)->Js.Math.ceil_int)

    // Groups is hard-coded to a 6 / court basis for doubles matchmaking
    let groups = (players->Array.length->Int.toFloat /. 6.)->Js.Math.ceil_int
    let clusters = (players :> t<'a>)->Players.findPlayerClusters(groups->Util.NonZeroInt.make)

    let sortedClusters = clusters->KMeans.SortedClusters.make

    sortedClusters
  }
  let findTopGroup = (players: t<'a>, groups: Util.NonZeroInt.t): t<'a> => {
    let sortedClusters = players->splitByGroups(groups)
    let minRating = sortedClusters->KMeans.SortedClusters.getMin

    players->min_rating(minRating)
    // ->to_players
    // ->DoublesSet.make
  }
  let filter = Array.filter
}

open Util
type matchmakingResult<'a> = {
  seenTeams: array<Set.t<string>>,
  // seenTeams: array<Team.t<'a>>,
  matches: array<Match.t<'a>>,
}
// Gets n from array array from a starting index, or returns the the array if
// it's less than n and minimum of 4
let array_get_n_from = (arr: array<'a>, from: int, n: int): option<array<'a>> => {
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
    let next = arr->array_get_n_from(from, n)
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
let array_combinations_n = (arr: array<'a>, n: int): array<array<'a>> => {
  let rec helper = (arr, n, acc) => {
    if n == 0 {
      [acc]
    } else if arr->Array.length == 0 {
      []
    } else {
      let head = arr->Array.getUnsafe(0)
      let tail = arr->Array.slice(~start=1, ~end=arr->Array.length)
      let withHead = helper(tail, n - 1, acc->Array.concat([head]))
      let withoutHead = helper(tail, n, acc)
      withHead->Array.concat(withoutHead)
    }
  }
  helper(arr, n, [])
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
  requiredPlayers: option<Set.t<string>>,
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

  // This block replaces the original selection.
  // It assumes a `combinations` function (provided below) is available in scope.
  // It also assumes `teams` (all 2-player teams from `availablePlayers`) is defined
  // immediately before this block, as in the original code.

  let result = {
    // Generate all unique 4-player groups from availablePlayers.
    // `combinations` should return an array of arrays, e.g., array<array<Player.t<'a>>>.
    let quads = array_combinations_n(availablePlayers, 4)

    // For each 4-player group, form the 3 distinct 2v2 matches.
    let new_matches = quads->Array.flatMap(quad => {
      // `combinations(..., 4)` should guarantee `quad` has 4 players.
      // If `availablePlayers.length < 4`, `quads` will be empty.
      let p1 = quad->Array.getUnsafe(0)
      let p2 = quad->Array.getUnsafe(1)
      let p3 = quad->Array.getUnsafe(2)
      let p4 = quad->Array.getUnsafe(3)
      [([p1, p2], [p3, p4]), ([p1, p3], [p2, p4]), ([p1, p4], [p2, p3])] // Match: (Team [p1,p2]) vs (Team [p3,p4]) // Match: (Team [p1,p3]) vs (Team [p2,p4]) // Match: (Team [p1,p4]) vs (Team [p2,p3])
    })

    // Replicate the original `result.seenTeams` content.
    // `teams` is `availablePlayers->array_combos->Array.map(tuple2array)`,
    // representing all possible 2-player teams.
    let final_seen_teams = teams->Array.map(team_players_array => team_players_array->Team.toSet) // Convert player array to Set of player IDs

    // The result of this block is this record
    {matches: new_matches, seenTeams: final_seen_teams}
  }
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

  let results = avoidAllPlayers->Array.reduce(results, (matches, antiTeam) => {
    antiTeam->Array.length < 2
      ? matches
      : [
          ...matches->Array.filter(((match, _)) =>
            !(match->Match.contains_more_than_1_players(antiTeam))
          ),
        ]
  })

  // Filter by `requiredPlayers`
  let results = // This `results` is after priorityPlayers and avoidAllPlayers filters
  switch requiredPlayers {
  | Some(reqPlayerIds) if reqPlayerIds->Set.size > 0 =>
    // Convert Set of IDs to Array of Player.t from availablePlayers
    let requiredPlayersArray = availablePlayers->Array.filter(p => reqPlayerIds->Set.has(p.id))

    // Ensure all required players were actually found in the availablePlayers.
    // If not, then no match can satisfy this constraint.
    if requiredPlayersArray->Array.length == reqPlayerIds->Set.size {
      results->Array.filter(((match, _quality)) =>
        // Check if the match contains all players from requiredPlayersArray
        match->Match.contains_all_players(requiredPlayersArray)
      )
    } else {
      // Not all required players are present in the `availablePlayers` list for this round,
      // or some IDs in `reqPlayerIds` don't correspond to any player in `availablePlayers`.
      // In this case, no match can satisfy the constraint.
      []
    }
  | _ => // No required players specified, or an empty set of required players.
    results // Pass through results from previous filters
  }

  // Apply teamConstraints filter (this part is adapted from your original selection)
  // `teamConstraints` is the NonEmptyArray.t<Set.t<string>> function parameter.
  // `implicitTeam` is defined earlier in the `find_all_match_combos` function.
  let teamConstraintsAsArray = teamConstraints->NonEmptyArray.toArray
  let finalTeamConstraintsList = teamConstraintsAsArray->Array.concat([implicitTeam])

  results->Array.filter(((match, _quality)) => {
    // This `results` is after the requiredPlayers filter
    let (team1, team2) = match
    let team1Set = team1->Team.toSet
    let team2Set = team2->Team.toSet

    // Check if team1Set is a subset of (or equal to) any constraint in finalTeamConstraintsList
    let team1SatisfiesConstraint =
      finalTeamConstraintsList->Array.findIndex(constr =>
        constr->TeamSet.containsAllOf(team1Set)
      ) > -1

    // Check if team2Set is a subset of (or equal to) any constraint in finalTeamConstraintsList
    let team2SatisfiesConstraint =
      finalTeamConstraintsList->Array.findIndex(constr =>
        constr->TeamSet.containsAllOf(team2Set)
      ) > -1

    // Both teams in the match must satisfy their respective constraint conditions.
    team1SatisfiesConstraint && team2SatisfiesConstraint
  })
}

let rec find_skip = (n: int) => {
  if n == 0 {
    1
  } else {
    find_skip(n - 1) + n + 1
  }
}

let pick_every_n_from_array = (arr: array<'a>, n: int, offset: int) => {
  arr->Array.filterWithIndex((_, i) => mod(i - offset, n) == 0)
}

let rec uniform_shuffle_array = (arr: array<'a>, n: int, offset: int) => {
  if n == offset {
    []
  } else {
    let picks = pick_every_n_from_array(arr, n, offset)
    Array.concat(picks, uniform_shuffle_array(arr, n, offset + 1))
  }
}

type strategy = CompetitivePlus | Competitive | Mixed | RoundRobin | Random | DUPR

module RankedMatches = {
  type t<'a> = array<(Match.t<'a>, float)>
  let strategy_by_competitive = (
    players: array<Player.t<'a>>,
    _consumedPlayers: Set.t<string>,
    priorityPlayers: array<Player.t<'a>>,
    avoidAllPlayers: array<array<Player.t<'a>>>,
    teams: NonEmptyArray.t<Set.t<string>>,
    requiredPlayers: option<Set.t<string>>,
  ) => {
    let groupSize = 5
    // let groupSize = Js.Math.max_int(
    //   4,
    //   (players->Array.length->Int.toFloat *. 0.41)->Js.Math.ceil_int,
    // )

    players
    ->Players.sortByRatingDesc
    ->array_split_by_n(groupSize)
    ->Array.reduce([], (acc, playerSet) => {
      let matches =
        playerSet->find_all_match_combos(priorityPlayers, avoidAllPlayers, teams, requiredPlayers)
      acc->Array.concat(matches)
    })
    ->Array.toSorted((a, b) => {
      let (_, qualityA) = a
      let (_, qualityB) = b
      qualityA < qualityB ? 1. : -1.
    })
  }
  let strategy_by_competitive_plus = (
    players: array<Player.t<'a>>,
    _consumedPlayers: Set.t<string>,
    _priorityPlayers: array<Player.t<'a>>,
    avoidAllPlayers: array<array<Player.t<'a>>>,
    teams: NonEmptyArray.t<Set.t<string>>,
    requiredPlayers: option<Set.t<string>>,
    courts: NonZeroInt.t,
    genderMixed: bool,
  ) => {
    players
    ->RankedPlayers.make
    ->(
      (sorted: RankedPlayers.t<'a>) => {
        let players = if genderMixed {
          let malePlayers =
            sorted
            ->RankedPlayers.filter(p => p.gender == Male)
            ->RankedPlayers.findTopGroup(courts)
          let femalePlayers =
            sorted
            ->RankedPlayers.filter(p => p.gender == Female)
            ->RankedPlayers.findTopGroup(courts)
          malePlayers
          ->RankedPlayers.to_players
          ->Array.concat(femalePlayers->RankedPlayers.to_players)
        } else {
          sorted->RankedPlayers.findTopGroup(courts)->RankedPlayers.to_players
        }

        players
        ->DoublesSet.make
        ->Option.map(playerSet => {
          let players = playerSet->DoublesSet.toPlayers
          let matches =
            players
            ->Array.at(0)
            ->Option.map(topPlayer => {
              players
              ->find_all_match_combos([], avoidAllPlayers, teams, requiredPlayers)
              ->Array.filter(((match, _)) => match->Match.contains_player(topPlayer))
              ->Array.toSorted(
                (a, b) => {
                  let (_, qualityA) = a
                  let (_, qualityB) = b
                  qualityA < qualityB ? 1. : -1.
                },
              )
            })
            ->Option.getOr([])
          let matches = if genderMixed {
            matches->Array.filter(((match, _)) => {
              let (team1, team2) = match
              let team1HasFemale = team1->Array.some(p => p.gender == Female)
              let team2HasFemale = team2->Array.some(p => p.gender == Female)
              team1HasFemale && team2HasFemale
            })
          } else {
            matches
          }
          matches
        })
        ->Option.getOr([])
      }
    )
  }

  let strategy_by_mixed = (
    availablePlayers,
    priorityPlayers,
    avoidAllPlayers,
    teams: NonEmptyArray.t<Set.t<string>>,
    requiredPlayers: option<Set.t<string>>,
    genderMixed: bool,
  ) => {
    let matches = find_all_match_combos(
      availablePlayers,
      priorityPlayers,
      avoidAllPlayers,
      teams,
      requiredPlayers,
    )

    let matches = if genderMixed {
      matches->Array.filter(((match, _)) => {
        let (team1, team2) = match
        let team1HasFemale = team1->Array.some(p => p.gender == Female)
        let team2HasFemale = team2->Array.some(p => p.gender == Female)
        team1HasFemale && team2HasFemale
      })
    } else {
      matches
    }

    matches->Array.toSorted((a, b) => {
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
    requiredPlayers,
  ) => {
    let count = Math.Int.max(4, availablePlayers->Array.length)
    let skip = find_skip(count - 4)
    let matches = find_all_match_combos(
      availablePlayers,
      priorityPlayers,
      avoidAllPlayers,
      teams,
      requiredPlayers,
    )
    let results = matches->uniform_shuffle_array(skip, 0)
    results
  }

  let strategy_by_random = (
    availablePlayers,
    priorityPlayers,
    avoidAllPlayers,
    teams: NonEmptyArray.t<Set.t<string>>,
    requiredPlayers: option<Set.t<string>>,
  ) => {
    let matches = find_all_match_combos(
      availablePlayers,
      priorityPlayers,
      avoidAllPlayers,
      teams,
      requiredPlayers,
    )
    matches->shuffle
  }

  let strategy_by_dupr = (availablePlayers, priorityPlayers, avoidAllPlayers, requiredPlayers) => {
    let teams =
      availablePlayers
      ->Players.sortByRatingDesc
      ->array_split_by_n(3)
      ->Array.map(Array.map(_, p => p.id))
      ->Array.map(Set.fromArray)
      ->NonEmptyArray.fromArray

    let matches = find_all_match_combos(
      availablePlayers,
      priorityPlayers,
      avoidAllPlayers,
      teams,
      requiredPlayers,
    )
    matches->Array.toSorted((a, b) => {
      let (_, qualityA) = a
      let (_, qualityB) = b
      qualityA < qualityB ? 1. : -1.
    })
  }
  // Assumes matches are already sorted by quality descending
  let recommendMatch = (
    matches: t<'a>, // t is array<(Match.t<'a>, float)>
    seenTeams: Set.t<string>,
    seenMatches: Set.t<string>,
    lastRoundSeenTeams: Set.t<string>,
    lastRoundSeenMatches: Set.t<string>,
    teamConstraints: NonEmptyArray.t<Team.t<'a>>,
    strategy: strategy,
    teamCountDict: Map.t<string, int>,
  ) => {
    // Remove teamConstraints teams from seenTeams
    teamConstraints
    ->NonEmptyArray.toArray
    ->Array.map(constr => constr->Team.toStableId)
    ->Array.map(teamId => {
      seenTeams->Set.delete(teamId)->ignore
      lastRoundSeenTeams->Set.delete(teamId)->ignore
    })
    ->ignore
    // Remove teamConstraints teams from lastRoundSeenTeams

    // Define filter functions
    let filterLRSM = ((match, _)) => !(lastRoundSeenMatches->Set.has(match->Match.toStableId))
    let filterLRST = ((match, _)) =>
      !(
        lastRoundSeenTeams->Set.has(match->fst->Team.toStableId) ||
          lastRoundSeenTeams->Set.has(match->snd->Team.toStableId)
      )
    let filterSM = ((match, _)) => !(seenMatches->Set.has(match->Match.toStableId))
    let filterST = ((match, _)) =>
      !(
        seenTeams->Set.has(match->fst->Team.toStableId) ||
          seenTeams->Set.has(match->snd->Team.toStableId)
      )

    let topQualityMatch = matches->Array.at(0)
    let qualityThreshold = switch topQualityMatch {
    | Some((_, quality)) => quality *. 0.8 // Set threshold at 90% of the top match quality
    | None => 0.39 // Default threshold if no matches are available
    }

    // Quality filter is now defined here but applied last
    let qualityFilter = ((_, quality)) => quality >= qualityThreshold

    // List of filters to try removing if necessary (most restrictive first)
    // Quality filter is not included here as it's applied separately at the end.
    let avoidanceFilters = [filterLRSM, filterSM, filterLRST, filterST]

    // Helper to apply a list of filters sequentially
    let applyFilters = (currentMatches, filtersToApply) => {
      filtersToApply->Array.reduce(currentMatches, (acc, filterFn) => acc->Array.filter(filterFn))
    }

    // Recursive function to find the best match by relaxing constraints
    let rec findResult = currentAvoidanceFilters => {
      // Apply current avoidance filters first
      let filteredByAvoidance = applyFilters(matches, currentAvoidanceFilters)
      // Then apply the quality filter (skip for Random strategy to allow truly random matches)
      let finalFiltered = if strategy == Random {
        filteredByAvoidance
      } else {
        filteredByAvoidance->Array.filter(qualityFilter)
      }

      if finalFiltered->Array.length > 0 {
        // Found matches with current avoidance filters + quality filter
        finalFiltered
      } else {
        // No matches passed quality filter with these avoidance filters.
        // Try removing the last avoidance filter.
        let fewerFilters =
          currentAvoidanceFilters->Array.slice(
            ~start=0,
            ~end=currentAvoidanceFilters->Array.length - 1,
          )

        if fewerFilters->Array.length == currentAvoidanceFilters->Array.length {
          // Base case: No avoidance filters left to remove, or slice failed unexpectedly.
          // Return matches that pass only the quality filter.
          matches->Array.filter(qualityFilter)
        } else if fewerFilters->Array.length == 0 {
          // Base case: No avoidance filters left after removing the last one.
          // Return matches that pass only the quality filter.
          matches->Array.filter(qualityFilter)
        } else {
          // Recursively call with fewer avoidance filters
          findResult(fewerFilters)
        }
      }
    }

    // For Random strategy, sort by score instead of using quality filters
    if strategy == Random {
      // Sort matches by their score (ascending - lowest first)
      let sortedByScore = matches->Array.toSorted(((matchA, _), (matchB, _)) => {
        let scoreA = TeamCountDict.getMatchScore(
          teamCountDict,
          matchA->fst->Team.toStableId,
          matchA->snd->Team.toStableId,
        )
        let scoreB = TeamCountDict.getMatchScore(
          teamCountDict,
          matchB->fst->Team.toStableId,
          matchB->snd->Team.toStableId,
        )
        (scoreA - scoreB)->Belt.Int.toFloat
      })

      // Get the lowest score
      let lowestScore = switch sortedByScore->Array.at(0) {
      | Some((match, _)) =>
        TeamCountDict.getMatchScore(
          teamCountDict,
          match->fst->Team.toStableId,
          match->snd->Team.toStableId,
        )
      | None => 0
      }

      // Filter to only matches with the lowest score
      let lowestScoreMatches = sortedByScore->Array.filter(((match, _)) => {
        let score = TeamCountDict.getMatchScore(
          teamCountDict,
          match->fst->Team.toStableId,
          match->snd->Team.toStableId,
        )
        score == lowestScore
      })

      // Randomly select from matches with the lowest score
      let randomFloat = Math.random() *. lowestScoreMatches->Array.length->Int.toFloat
      let randomIndex = randomFloat->Math.floor->Belt.Float.toInt
      lowestScoreMatches->Array.at(randomIndex)->Option.map(((match, _)) => match)
    } else if strategy == Mixed {
      // For Mixed strategy, apply only quality filter (no avoidance filters) and choose match with lowest score
      let qualityFiltered = matches->Array.filter(qualityFilter)

      // Sort by match score (ascending - lowest first)
      let sortedByScore = qualityFiltered->Array.toSorted(((matchA, _), (matchB, _)) => {
        let scoreA = TeamCountDict.getMatchScore(
          teamCountDict,
          matchA->fst->Team.toStableId,
          matchA->snd->Team.toStableId,
        )
        let scoreB = TeamCountDict.getMatchScore(
          teamCountDict,
          matchB->fst->Team.toStableId,
          matchB->snd->Team.toStableId,
        )
        (scoreA - scoreB)->Belt.Int.toFloat
      })

      // Return the match with the lowest score
      sortedByScore->Array.at(0)->Option.map(((match, _)) => match)
    } else {
      // For other strategies, use the findResult method with quality filters
      let bestMatches = findResult(avoidanceFilters)
      bestMatches->Array.at(0)->Option.map(((match, _)) => match)
    }
  }
}

let getMatches = (
  players: Players.t<'a>,
  consumedPlayers,
  strategy,
  priorityPlayers,
  avoidAllPlayers: array<array<Player.t<'a>>>,
  teamConstraints,
  requiredPlayers,
  courts,
  genderMixed,
) => {
  // let availablePlayers = players->Players.filterOut(consumedPlayers)
  // Reduce priority players to those that are selected in the queue
  // let priorityPlayers =
  //   priorityPlayers->Set.fromArray->intersection(players->Set.fromArray)->Set.values->Array.fromIterator
  let matches = switch strategy {
  | Mixed =>
    RankedMatches.strategy_by_mixed(
      players,
      priorityPlayers,
      avoidAllPlayers,
      teamConstraints,
      requiredPlayers,
      genderMixed,
    )
  | RoundRobin =>
    RankedMatches.strategy_by_round_robin(
      players,
      priorityPlayers,
      avoidAllPlayers,
      teamConstraints,
      requiredPlayers,
    )
  | Random =>
    RankedMatches.strategy_by_random(
      players,
      priorityPlayers,
      avoidAllPlayers,
      teamConstraints,
      requiredPlayers,
    )
  | DUPR =>
    RankedMatches.strategy_by_dupr(players, priorityPlayers, avoidAllPlayers, requiredPlayers)
  | Competitive =>
    RankedMatches.strategy_by_competitive(
      players,
      consumedPlayers,
      priorityPlayers,
      avoidAllPlayers,
      teamConstraints,
      requiredPlayers,
    )
  | CompetitivePlus =>
    RankedMatches.strategy_by_competitive_plus(
      players,
      consumedPlayers,
      priorityPlayers,
      avoidAllPlayers,
      teamConstraints,
      requiredPlayers,
      courts,
      genderMixed,
    )
  }
  matches
}

// Generate N matches recursively based on completed match history
// Calculates player ratings from scored matches and derives play counts
let generateMatches = (
  ~players: array<Player.t<'a>>,
  ~history: array<completedMatchEntity<'a>>,
  ~strategy: strategy,
  ~numMatches: int,
  ~avoidAllPlayers: array<array<Player.t<'a>>>=[],
  ~teamConstraints: option<array<Set.t<string>>>=?,
  ~courts: Util.NonZeroInt.t=Util.NonZeroInt.make(1),
  ~genderMixed: bool=false,
  (),
): array<matchEntity<'a>> => {
  // Initialize seen teams and matches from history
  // Split history into: all history vs. just the last round (previous round)
  // The last round is the last numMatches in the history array
  let historyLength = history->Array.length
  let lastRoundStartIndex = Math.Int.max(0, historyLength - numMatches)

  // Build team last-round dictionary from history
  let teamCountDict = TeamCountDict.fromHistory(
    history,
    completedMatch => {
      let (team1, team2) = completedMatch.match
      (team1->Team.toStableId, team2->Team.toStableId)
    },
    numMatches,
  )

  let (
    seenTeamsFromHistory,
    seenMatchesFromHistory,
    lastRoundSeenTeams,
    lastRoundSeenMatches,
  ) = history->Array.reduceWithIndex((Set.make(), Set.make(), Set.make(), Set.make()), (
    (allTeams, allMatches, lastTeams, lastMatches),
    completedMatch,
    index,
  ) => {
    let (team1, team2) = completedMatch.match
    let team1Id = team1->Team.toStableId
    let team2Id = team2->Team.toStableId
    let matchId = completedMatch.match->Match.toStableId

    // Add to all history
    allTeams->Set.add(team1Id)->ignore
    allTeams->Set.add(team2Id)->ignore
    allMatches->Set.add(matchId)->ignore

    // Also add to last round if this match is in the last round
    if index >= lastRoundStartIndex {
      lastTeams->Set.add(team1Id)->ignore
      lastTeams->Set.add(team2Id)->ignore
      lastMatches->Set.add(matchId)->ignore
    }

    (allTeams, allMatches, lastTeams, lastMatches)
  })

  // Step 3: Recursive function to generate matches
  // Note: We only track consumedPlayers within a round - seenTeams/seenMatches come from history
  @tailcall
  let rec generateMatchesRec = (
    consumedPlayers: Set.t<string>,
    accumulated: array<matchEntity<'a>>,
    remaining: int,
  ): array<matchEntity<'a>> => {
    if remaining <= 0 {
      accumulated
    } else {
      // Convert teamConstraints from option<array> to NonEmptyArray.t
      let teamConstraintsNonEmpty =
        teamConstraints->Option.flatMap(arr => arr->Array.length > 0 ? Some(arr) : None)

      // Remove consumed players from playersWithRatings before calling getMatches
      let availablePlayers = players->Array.filter(p => !(consumedPlayers->Set.has(p.id)))

      // Convert Set.t<string> constraints to Team.t<'a> (array<Player.t<'a>>)
      let teamConstraintsAsTeams = switch teamConstraintsNonEmpty {
      | Some(constraints) =>
        constraints
        ->Array.map(constraintSet => {
          players->Array.filter(p => constraintSet->Set.has(p.id))
        })
        ->NonEmptyArray.fromArray
      | None => None // No team constraints
      }

      let getCandidateMatches = (useMixed: bool) => {
        switch teamConstraintsNonEmpty {
        | Some(_) => {
            let matchesWithConstraints = getMatches(
              availablePlayers,
              consumedPlayers,
              Mixed, // Use Mixed strategy with team constraints
              [],
              avoidAllPlayers,
              teamConstraintsNonEmpty,
              None,
              courts,
              useMixed,
            )

            // If no matches found with constraints, retry without constraints using original strategy
            if matchesWithConstraints->Array.length == 0 {
              getMatches(
                availablePlayers,
                consumedPlayers,
                strategy, // Use original strategy
                [],
                avoidAllPlayers,
                None, // Remove team constraints
                None,
                courts,
                useMixed,
              )
            } else {
              matchesWithConstraints
            }
          }
        | None =>
          // No team constraints, use original strategy
          getMatches(
            availablePlayers,
            consumedPlayers,
            strategy,
            [],
            avoidAllPlayers,
            None,
            None,
            courts,
            useMixed,
          )
        }
      }

      let matches = getCandidateMatches(genderMixed)

      let selectedMatch = RankedMatches.recommendMatch(
        matches,
        seenTeamsFromHistory,
        seenMatchesFromHistory,
        lastRoundSeenTeams,
        lastRoundSeenMatches,
        teamConstraintsAsTeams,
        strategy,
        teamCountDict,
      )

      // Fallback: If mixed gender was requested but no match found, retry without mixed constraint
      let selectedMatch = switch (selectedMatch, genderMixed) {
      | (None, true) =>
        let matches = getCandidateMatches(false)
        RankedMatches.recommendMatch(
          matches,
          seenTeamsFromHistory,
          seenMatchesFromHistory,
          lastRoundSeenTeams,
          lastRoundSeenMatches,
          teamConstraintsAsTeams,
          strategy,
          teamCountDict,
        )
      | _ => selectedMatch
      }

      switch selectedMatch {
      | Some(match) => {
          // Update consumed players for this round
          let matchPlayers = Match.players(match)
          let newConsumedPlayers = matchPlayers->Array.reduce(consumedPlayers, (set, player) => {
            set->Set.add(player.id)
            set
          })

          // Update players in the match by incrementing their play count
          let updatedMatch = Match.incrementPlayCounts(match)

          // Randomize team order: 50% chance to swap teams
          let randomizedMatch = if Math.random() > 0.5 {
            let (team1, team2) = updatedMatch
            (team2, team1)
          } else {
            updatedMatch
          }

          // Create match entity with updated player counts
          let matchId = "match-" ++ Int.toString(accumulated->Array.length + 1)
          let matchEntity = {id: matchId, match: randomizedMatch}

          // Recursively generate remaining matches
          // No need to update seenTeams/seenMatches - they stay constant from history
          generateMatchesRec(
            newConsumedPlayers,
            accumulated->Array.concat([matchEntity]),
            remaining - 1,
          )
        }
      | None => accumulated // No more valid matches can be generated, return what we have
      }
    }
  }

  // Step 4: Start recursive generation
  generateMatchesRec(Set.make(), [], numMatches)
}

module OrderedQueue = {
  type t<'a> = array<'a>
  let addToQueue = (queue: t<'a>, player: 'a) => {
    let maybePlayer = queue->Array.find(p => p == player)
    switch maybePlayer {
    | Some(_) => queue
    | None => queue->Array.concat([player])
    }
  }
  let removeFromQueue = (queue: t<'a>, player: 'a) => {
    queue->Array.filter(p => p != player)
  }

  let toggle = (queue: t<'a>, player: 'a) => {
    let maybePlayer = queue->Array.find(p => p == player)
    switch maybePlayer {
    | Some(_) => queue->removeFromQueue(player)
    | None => queue->Array.concat([player])
    }
  }

  let toSet = (queue: t<'a>) => queue->Set.fromArray

  let fromSet = (set: Set.t<string>): t<'a> => {
    set->Set.values->Array.fromIterator
  }
  let filter: (t<'a>, Set.t<string>) => t<'a> = (queue, players) => {
    queue->Array.filter(p => !(players->Set.has(p)))
  }
}

module UnorderedQueue = {
  type t<'a> = Js.Set.t<'a>
  let addToQueue: (t<'a>, 'a) => t<'a> = (queue, player: 'a) => {
    let newSet = Set.make()
    queue->Set.forEach(id => newSet->Set.add(id))
    newSet->Set.add(player)->ignore
    newSet
  }
  let removeFromQueue = (queue: t<'a>, player: 'a) => {
    let newSet = Set.make()
    queue->Set.forEach(id => newSet->Set.add(id))
    newSet->Set.delete(player)->ignore
    newSet
  }

  let togglePlayer = (queue: t<'a>, player: 'a) => {
    let newSet = Set.make()
    queue->Set.forEach(id => newSet->Set.add(id))
    switch queue->Set.has(player) {
    | true => newSet->removeFromQueue(player)
    | false => newSet->addToQueue(player)
    }
  }

  let toOrdered = (queue: t<'a>) => queue->Set.values
  let toArray = (queue: t<'a>) => queue->Set.values->Array.fromIterator

  let fromArray = (arr): t<'a> => {
    arr->Set.fromArray
  }
  let filter: (t<'a>, Set.t<'a>) => t<'a> = (queue, players) => {
    queue->JsSet.difference(players)
  }
}

module PlayersCache = {
  type t<'a> = Js.Dict.t<player<'a>>

  let fromPlayers: Players.t<'a> => t<'a> = players => {
    players->Array.map(p => (p.id, p))->Js.Dict.fromArray
  }

  let get: (t<'a>, string) => option<player<'a>> = (cache, pid) => cache->Js.Dict.get(pid)
}
module Matches = {
  type t<'a> = array<Match.t<'a>>
  let toDndItems: t<'a> => MultipleContainers.Items.t = t => {
    t
    ->Array.mapWithIndex(((t1, t2), i) => {
      [t1, t2]->Array.mapWithIndex((team, j) => {
        (
          i->Int.toString ++ "." ++ j->Int.toString,
          team->Array.map(p => i->Int.toString ++ "." ++ j->Int.toString ++ ":" ++ p.id),
        )
      })
    })
    ->Array.flatMap(x => x)
    ->Js.Dict.fromArray
  }

  let fromDndItems: (MultipleContainers.Items.t, PlayersCache.t<'a>) => t<'a> = (
    items,
    playersCache,
  ) => {
    let (matches, _) =
      items
      ->Js.Dict.entries
      ->Array.map(((_, players)) => {
        let players = players->Array.map(p => {
          let p = switch p->String.split(":") {
          | [_, id] => Some(id)
          | _ => None
          }
          p->Option.flatMap(p => playersCache->PlayersCache.get(p))
        })
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

let guessDupr = (ratingMu: float): float => {
  0.05594 *. (ratingMu -. 25.) +. 3.5
}

// Calculate deprioritized players (those who should take a break)
// based on play counts and match history
let getDeprioritizedPlayers = (
  rounds: array<array<completedMatchEntity<'a>>>,
  players: array<Player.t<'a>>,
  break: int,
  strategy: strategy,
) => {
  // Return empty set if no rounds yet
  if rounds->Array.length == 0 {
    Set.make()
  } else {
    switch strategy {
    | Competitive | CompetitivePlus =>
      // Competitive strategy: prioritize players with highest play count
      let lastRounds =
        rounds->Array.slice(
          ~start=Js.Math.max_int(0, rounds->Array.length - break),
          ~end=rounds->Array.length,
        )

      let lastPlayed =
        lastRounds
        ->Array.flatMap(round => round)
        ->Array.flatMap(({match: m}) => {
          let (team1, team2) = m
          Array.concat(team1, team2)
        })

      let maxCount = players->Array.reduce(0, (acc, next) => {
        next.count > acc ? next.count : acc
      })
      let minCount = players->Array.reduce(maxCount, (acc, next) => {
        next.count < acc ? next.count : acc
      })

      // Get the break players which are players with the highest play count, sorted by descending rating
      let breakPlayers = []->Players.addBreakPlayersFrom(
        players
        ->Array.filter(p => {
          p.count == maxCount && p.count != minCount
        })
        ->Players.sortByRatingDesc,
        break,
      )

      switch breakPlayers->Array.length < break {
      // Choose break players from players that played previously + designated break players
      | true =>
        let breakAndLastPlayed =
          breakPlayers->Players.addBreakPlayersFrom(lastPlayed->Players.sortByRatingDesc, break)
        switch breakAndLastPlayed->Array.length < break {
        | true =>
          breakAndLastPlayed
          ->Players.addBreakPlayersFrom(players->Players.sortByRatingDesc, break)
          ->Array.map(p => p.id)
          ->Set.fromArray
        | false => breakAndLastPlayed->Array.map(p => p.id)->Set.fromArray
        }
      | false => breakPlayers->Array.map(p => p.id)->Set.fromArray
      }

    | Mixed | RoundRobin | Random | DUPR =>
      // Non-competitive strategy: prioritize players with most rounds since last break
      // Calculate rounds since last break for each player
      let playersWithRoundsSinceBreak = players->Array.map(player => {
        // Find the most recent round where this player took a break (did not play)
        let lastBreakRoundIndex = rounds->Array.reduceWithIndex(None, (acc, round, roundIndex) => {
          let playedInRound = round->Array.some(
            ({match: m}) => {
              let (team1, team2) = m
              Array.concat(team1, team2)->Array.some(p => p.id == player.id)
            },
          )
          if !playedInRound {
            Some(roundIndex)
          } else {
            acc
          }
        })

        // Calculate rounds since last break
        let roundsSinceLastBreak = switch lastBreakRoundIndex {
        | None => rounds->Array.length // Never took a break, highest priority
        | Some(lastIndex) => rounds->Array.length - lastIndex - 1 // Rounds since last break
        }

        (player, roundsSinceLastBreak)
      })

      // Sort by rounds since last break (descending), then take the top 'break' players
      playersWithRoundsSinceBreak
      ->Array.toSorted((a, b) => {
        let (_, roundsA) = a
        let (_, roundsB) = b
        // Sort descending (higher rounds since last break first - players who need a break most)
        Float.fromInt(roundsB - roundsA)
      })
      ->Array.slice(~start=0, ~end=break)
      ->Array.map(((player, _)) => player.id)
      ->Set.fromArray
    }
  }
}

// Process a single timeline event (either adjustments or a round of matches)
// Returns updated player state after applying the event
let processTimelineEvent = (players: array<Player.t<'a>>, event: TimelineEvent.t<'a>): array<
  Player.t<'a>,
> => {
  switch event {
  | Adjustment(adjustments) =>
    // Apply rating adjustments (only adjust mu, keep sigma unchanged)
    players->Array.map(player => {
      let totalAdjustment =
        adjustments
        ->Array.filter(adj => adj.playerId == player.id)
        ->Array.reduce(0.0, (sum, adj) => sum +. adj.differential)

      if totalAdjustment != 0.0 {
        let currentMu = player.rating.mu
        let currentSigma = player.rating.sigma
        let adjustedRating = Rating.make(currentMu +. totalAdjustment, currentSigma)
        {
          ...player,
          rating: adjustedRating,
          ratingOrdinal: adjustedRating->Rating.ordinal,
        }
      } else {
        player
      }
    })

  | Round(matches) =>
    // Process a round of matches: update counts and ratings
    let (countIncrements, ratingUpdates) = matches->Array.reduce((Map.make(), Map.make()), (
      (counts, ratings),
      {match: m, score},
    ) => {
      let (team1, team2) = m
      let allPlayers = Array.concat(team1, team2)

      // Count matches played in this round
      let newCounts = allPlayers->Array.reduce(counts, (map, player) => {
        let current = map->Map.get(player.id)->Option.getOr(0)
        map->Map.set(player.id, current + 1)
        map
      })

      // Update ratings if match was scored
      let newRatings = switch (m, score)->CompletedMatch.rate {
      | None => ratings
      | Some(updatedTeams) =>
        updatedTeams
        ->Array.flat
        ->Array.reduce(ratings, (map, player) => {
          map->Map.set(player.id, player.rating)
          map
        })
      }

      (newCounts, newRatings)
    })

    // Apply incremental updates to players (accumulate counts, update ratings)
    players->Array.map(player => {
      // Increment count by the number of matches played in this round
      let countIncrement = countIncrements->Map.get(player.id)->Option.getOr(0)
      let newCount = player.count + countIncrement

      // Update rating if it changed in this round
      switch ratingUpdates->Map.get(player.id) {
      | Some(rating) => {
          ...player,
          count: newCount,
          rating,
          ratingOrdinal: rating->Rating.ordinal,
        }
      | None => {...player, count: newCount}
      }
    })
  }
}

// Update player state by processing a timeline of events
// Timeline events are processed in order: adjustments and rounds of matches
let updatePlayerState = (
  ~players: array<Player.t<'a>>,
  ~timeline: array<TimelineEvent.t<'a>>,
): array<Player.t<'a>> => {
  timeline->Array.reduce(players, (currentPlayers, event) => {
    processTimelineEvent(currentPlayers, event)
  })
}

// Update player state with rounds and rating adjustments applied chronologically
// This is a pure function that processes the complete history (matches + adjustments) to derive final state
// The state at any point is deterministic based on the history up to that point
//
// Timeline processing order:
// 1. Seed adjustments (appliedAtRound = -1, before any matches)
// 2. For each round N:
//    a. Adjustments with appliedAtRound = N (before round N starts)
//    b. Round N matches (rating changes from wins/losses)
// 3. Final adjustments (appliedAtRound = rounds.length, after all rounds)
let toPlayerStateWithAdjustments = (
  rounds: array<array<CompletedMatchEntity.t<'a>>>,
  ~players: array<Player.t<'a>>,
  ~adjustments: array<RatingAdjustment.t>,
): array<Player.t<'a>> => {
  // Build timeline from rounds and adjustments
  let timeline = TimelineEvent.fromRoundsAndAdjustments(rounds, adjustments)

  // Process timeline events sequentially
  let finalPlayers = updatePlayerState(~players, ~timeline)

  finalPlayers
}

// Generate multiple rounds of matches recursively (tail-call optimized)
let rec generateRoundsRec = (
  ~roundNumber: int,
  ~roundsToGenerate: int,
  ~availablePlayers: array<Player.t<'a>>,
  ~completedRounds: array<array<completedMatchEntity<'a>>>,
  ~strategy: strategy,
  ~courtCount: int,
  ~teamConstraints: option<array<Set.t<string>>>=?,
  ~avoidAllPlayers: array<array<Player.t<'a>>>=[],
  ~accumulatedRounds: array<array<completedMatchEntity<'a>>>=[], // Accumulator for tail recursion
  ~genderMixed: bool=false,
  ~startTime: Js.Date.t,
  ~currentRoundIndex: int=0, // Track which round we're generating (0-indexed)
  (),
): array<array<completedMatchEntity<'a>>> => {
  // Base case: no more rounds to generate
  if roundsToGenerate <= 0 {
    accumulatedRounds
  } // Check if we have enough players for this round
  else if availablePlayers->Array.length < courtCount * 4 {
    // Not enough players, stop generating
    accumulatedRounds
  } else {
    Js.log("Generating round " ++ Int.toString(roundNumber))
    // Calculate break count (number of players that should sit out)
    let breakCount = courtCount == 0 ? 0 : availablePlayers->Array.length - courtCount * 4

    let allRounds = Array.concat(completedRounds, accumulatedRounds)
    // Get deprioritized players (those who should take a break)
    let deprioritizedPlayerIds = getDeprioritizedPlayers(
      allRounds,
      availablePlayers,
      breakCount,
      strategy,
    )

    // Filter out deprioritized players from availablePlayers
    let playersForMatches =
      availablePlayers->Array.filter(p => !(deprioritizedPlayerIds->Set.has(p.id)))

    // Convert court count to NonZeroInt.t
    let courts = Util.NonZeroInt.make(courtCount)

    // Flatten all rounds (completed + accumulated) to flat history for generateMatches
    let flatHistory = allRounds->Array.flatMap(round => round)

    // Generate matches for this round (using filtered players with pre-incremented counts)
    let matchEntities = generateMatches(
      ~players=playersForMatches,
      ~history=flatHistory,
      ~strategy,
      ~numMatches=courtCount,
      ~teamConstraints?,
      ~avoidAllPlayers,
      ~courts,
      ~genderMixed,
      (),
    )

    // Convert matchEntity to completedMatchEntity with proper UUIDs
    // Calculate createdAt with 10-minute stagger: startTime + (currentRoundIndex + 1) * 10 minutes
    let roundCreatedAt = {
      let baseTime = startTime->Js.Date.getTime
      let minutesOffset = Float.fromInt(currentRoundIndex + 1) *. 10.0 *. 60.0 *. 1000.0
      Js.Date.fromFloat(baseTime +. minutesOffset)
    }
    let roundMatches = matchEntities->Array.mapWithIndex((matchEntity, _courtNum) => {
      let entity: CompletedMatchEntity.t<'a> = {
        id: randomUUID(),
        match: matchEntity.match,
        score: None,
        createdAt: roundCreatedAt,
      }
      entity
    })

    // Update player state with only the current round's matches
    // availablePlayers already has the correct state (including rating adjustments from history)
    // so we only need to increment counts based on the newly generated round
    let timeline = [TimelineEvent.Round(roundMatches)]
    let updatedPlayers = updatePlayerState(~players=availablePlayers, ~timeline)

    // Tail-recursive call with updated players and accumulated rounds
    // completedRounds stays the same (immutable input history)
    generateRoundsRec(
      ~roundNumber=roundNumber + 1,
      ~roundsToGenerate=roundsToGenerate - 1,
      ~availablePlayers=updatedPlayers,
      ~completedRounds,
      ~strategy,
      ~courtCount,
      ~teamConstraints?,
      ~avoidAllPlayers,
      ~accumulatedRounds=Array.concat(accumulatedRounds, [roundMatches]),
      ~genderMixed,
      ~startTime,
      ~currentRoundIndex=currentRoundIndex + 1,
      (),
    )
  }
}

// Convenience wrapper for generating rounds
let generateRounds = (
  ~startRoundNumber: int=1,
  ~numberOfRounds: int,
  ~availablePlayers: array<Player.t<'a>>,
  ~completedRounds: array<array<completedMatchEntity<'a>>>,
  ~strategy: strategy,
  ~courtCount: int,
  ~teamConstraints: option<array<Set.t<string>>>=?,
  ~avoidAllPlayers: array<array<Player.t<'a>>>=[],
  ~genderMixed: bool=false,
  ~startTime: Js.Date.t,
  (),
): array<array<completedMatchEntity<'a>>> => {
  generateRoundsRec(
    ~roundNumber=startRoundNumber,
    ~roundsToGenerate=numberOfRounds,
    ~availablePlayers,
    ~completedRounds,
    ~strategy,
    ~courtCount,
    ~teamConstraints?,
    ~avoidAllPlayers,
    ~genderMixed,
    ~startTime,
    ~currentRoundIndex=0,
    (),
  )
}

// Generate a single round for reset/regeneration purposes
// Pure function that takes all necessary inputs and returns a new round
let generateSingleRound = (
  ~roundIndex: int,
  ~rounds: array<array<completedMatchEntity<'a>>>,
  ~availablePlayers: array<Player.t<'a>>,
  ~strategy: strategy,
  ~courtCount: int,
  ~teamConstraints: option<array<Set.t<string>>>=?,
  ~avoidAllPlayers: array<array<Player.t<'a>>>=[],
  ~genderMixed: bool=false,
  ~startTime: Js.Date.t,
): option<array<completedMatchEntity<'a>>> => {
  let roundsBeforeThis = if roundIndex == 0 {
    []
  } else {
    rounds->Array.filterWithIndex((_, idx) => idx < roundIndex)
  }

  let newRound = generateRounds(
    ~startRoundNumber=roundIndex + 1,
    ~numberOfRounds=1,
    ~availablePlayers,
    ~completedRounds=roundsBeforeThis,
    ~strategy,
    ~courtCount,
    ~teamConstraints?,
    ~avoidAllPlayers,
    ~genderMixed,
    ~startTime,
    (),
  )

  newRound->Array.get(0)
}
