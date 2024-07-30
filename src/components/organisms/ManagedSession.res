%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
module Rating: {
  type t = private {
    mu: float,
    sigma: float,
  }

  let get_rating: t => float
  let make: (float, float) => t
  let makeDefault: unit => t
  let predictDraw: array<array<t>> => float
  // let predictWin: array(array(t)) => array(float);
  let ordinal: t => float
} = {
  type t = {
    mu: float,
    sigma: float,
  }
  @module("openskill") external rating: option<t> => t = "rating"
  @module("openskill") external ordinal: t => float = "ordinal"

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
    data: 'a,
    id: string,
    name: string,
    rating: Rating.t,
  }

  @react.component
  let make = (~player: t<'a>) => {
    <span className="mr-2">
      {player.name->React.string}
      {"("->React.string}
      {player.rating.mu->Float.toFixed(~digits=2)->React.string}
      {")"->React.string}
    </span>
  }
}

module Match = {
  type t<'a> = ((Player.t<'a>, Player.t<'a>), (Player.t<'a>, Player.t<'a>))
  @react.component
  let make = (~match: t<'a>, ~onSelect: option<t<'a> => unit>=?) => {
    let ((p1, p2), (p3, p4)) = match
    <UiAction className="p-4" onClick={() => onSelect->Option.map(f => f(match))->Option.getOr()}>
      <div className="mb-2">
        <span>
          <Player player=p1 />
          <Player player=p2 />
        </span>
        {" VS "->React.string}
        <span>
          <Player player=p3 />
          <Player player=p4 />
        </span>
      </div>
    </UiAction>
  }
}

// let array_get_2_from = (from: int, arr: array<'a>): option<('a, 'a, 'a, 'a)> =>
//   // let arr = Js.Array.slice(~start=from, ~end_=from + 4, arr);
//   if from < Array.length(arr) - 1 {
//     let arr = Array.slice(arr, ~start=from, ~end=from + 2)
//     switch (arr[0], arr[1]) {
//     | (Some(a), Some(b)) => Some((a, b))
//     | _ => None
//     }
//     // Some((arr->Array.getUnsafe(0), arr->Array.getUnsafe(1), arr->Array.getUnsafe(2), arr->Array.getUnsafe(3)))
//   } else {
//     None
//   }
let array_get_4_from = (from: int, arr: array<'a>): option<('a, 'a, 'a, 'a)> =>
  // let arr = Js.Array.slice(~start=from, ~end_=from + 4, arr);
  if from < Array.length(arr) - 3 {
    let arr = Array.slice(arr, ~start=from, ~end=from + 4)
    switch (arr[0], arr[1], arr[2], arr[3]) {
    | (Some(a), Some(b), Some(c), Some(d)) => Some((a, b, c, d))
    | _ => None
    }
    // Some((arr->Array.getUnsafe(0), arr->Array.getUnsafe(1), arr->Array.getUnsafe(2), arr->Array.getUnsafe(3)))
  } else {
    None
  }
let array_split_by_4 = (arr: array<'a>) => {
  let rec loop = (from: int, acc: array<('a, 'a, 'a, 'a)>) => {
    let next = array_get_4_from(from, arr)
    switch next {
    | Some(next) => loop(from + 1, acc->Array.concat([next]))
    | None => acc
    }
  }
  loop(0, [])
}
let match_make_naive = (players: array<Player.t<'a>>): array<Match.t<'a>> => {
  players->array_split_by_4->Array.map(((p1, p2, p3, p4)) => ((p1, p4), (p2, p3)))
}

module SelectPlayersList = {
  @react.component
  let make = (
    ~players: array<Player.t<'a>>,
    ~selected: array<string>,
    ~onClick: Player.t<'a> => unit,
  ) => {
    <ul className="w-full mb-4">
      {players
      ->Array.map(player => {
        <li
          key={player.id}
          className={Util.cx([
            selected->Array.indexOf(player.id) > -1 ? "font-bold" : "",
            "inline",
            "mr-2",
          ])}>
          <UiAction className="p-4" onClick={() => onClick(player)}>
            {player.name->React.string}
          </UiAction>
        </li>
      })
      ->React.array}
    </ul>
  }
}
type team<'a> = (Player.t<'a>, Player.t<'a>);

module Team = {
  type team<'a> = (Player.t<'a>, Player.t<'a>);
  let contains_player = (((p1, p2)): team<'a>, player: Player.t<'a>) =>
    p1.id == player.id || p2.id == player.id
    // []->Array.findIndex(p' => player.id == p'.id) == -1
}
type match<'a> = (team<'a>, team<'a>);

let array_combos: array<'a> => array<('a, 'a)> = arr => {
  arr->Array.flatMapWithIndex((v, i) =>
    arr->Array.slice(~start=i + 1, ~end=Array.length(arr))->Array.map(v2 => (v, v2))
  )
}
let combos = (arr1: array<'a>, arr2: array<'a>): array<('a, 'a)> => {
  arr1->Array.flatMap(d => arr2->Array.map(v => (d, v)))
}
let match_quality: match<'a> => float = (((p1, p2), (p3, p4))) => {
  let team1 = [p1, p2]
  let team2 = [p3, p4]
  Rating.predictDraw([team1->Array.map(p => p.rating), team2->Array.map(p => p.rating)])
}
type scored_match<'a> = (match<'a>, float);

@react.component
let make = (
  ~players: array<Player.t<'a>>,
  ~consumedPlayers: Js.Set.t<string>,
  ~onSelectMatch: option<Match.t<'a> => unit>=?,
) => {
  let (activePlayers: array<Player.t<'a>>, setActivePlayers) = React.useState(_ => [])
  let activePlayers =
    activePlayers
    ->Array.filter(p => !(consumedPlayers->Set.has(p.id)))
    // ->Array.filter(p => activePlayers->Array.indexOf(p.id) > -1)
    ->Array.toSorted((a, b) => {
      let userA = a.rating.mu
      let userB = b.rating.mu
      userA < userB ? 1. : -1.
    })
  // let matches = activePlayers->match_make_naive

  let teams = activePlayers->array_combos
  let matches = teams->Array.reduce([], (acc, team)=> {
    let players' = activePlayers
    ->Array.filter(p => !(team->Team.contains_player(p)))
    // Teams of remaining players
    let teams' = players'->array_combos
    acc->Array.concat([team]->combos(teams'))
  })
  let matches = matches->Array.map(match => {
    let quality = match->match_quality
    (match, quality)
  })->Array.toSorted((a, b) => {
    let (_, qualityA) = a
    let (_, qualityB) = b
    qualityA < qualityB ? 1. : -1.
  })->Array.slice(~start=0, ~end=15)
  <>
    <UiAction
      onClick={() =>
        setActivePlayers(_ => {
          players
        })}>
      {t`select all`}
    </UiAction>
    <SelectPlayersList
      players={players}
      selected={activePlayers->Array.map((p: Player.t<'a>) => p.id)}
      onClick={player =>
        setActivePlayers(ps =>
          switch ps->Array.findIndexOpt(p => p.id == player.id) {
          | Some(_) => ps->Array.filter(v => v.id != player.id)
          | None => ps->Array.concat([player])
          }
        )}
    />
    {matches
    ->Array.mapWithIndex(((match, quality), i) => <>
      <Match key={i->Int.toString} onSelect=?onSelectMatch match />{" - "->React.string}{quality->Float.toString->React.string}
    </>)
    ->React.array}
  </>
}
