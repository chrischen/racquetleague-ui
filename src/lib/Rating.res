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
type rsvpNode = AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node
type player = Player.t<rsvpNode>
type team = array<player>
type match = (team, team)

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
}
