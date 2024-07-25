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
  @mel.module("openskill") external ordinal: t => float = "ordinal"
  @mel.module("openskill")
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
  type t = {
    id: string,
    name: string,
    rating: Rating.t,
  }

  @react.component
  let make = (~player: t) => {
    <span className="mr-2">
      {player.name->React.string}
      {"("->React.string}
      {player.rating.sigma->Float.toFixed(~digits=2)->React.string}
      {")"->React.string}
    </span>
  }
}

module Match = {
  type t = (((Player.t, Player.t), (Player.t, Player.t)))
  @react.component
  let make = (~match: t, ~onSelect: option<t => unit>=?) => {
    let ((p1, p2), (p3, p4)) = match
    <UiAction className="p-4" onClick={() => onSelect->Option.map(f => f(match))->Option.getOr()}>
      <div className="mb-2">
        <span><Player player=p1 /> <Player player=p2 /> </span>
        {" VS "->React.string}
        <span><Player player=p3 /> <Player player=p4 /> </span>
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
let match_make_naive = (players: array<Player.t>): array<Match.t> => {
  players->array_split_by_4->Array.map(((p1, p2, p3, p4)) => ((p1, p4), (p2, p3)))
}

module SelectPlayersList = {
  @react.component
  let make = (~players: array<Player.t>, ~selected: array<string>, ~onClick: Player.t => unit) => {
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
          <UiAction className="p-4" onClick={() => onClick(player)}> {player.name->React.string} </UiAction>
        </li>
      })
      ->React.array}
    </ul>
  }
}
@react.component
let make = (~players: array<Player.t>, ~onSelectMatch: option<Match.t => unit>=?) => {
  let (activePlayers: array<Player.t>, setActivePlayers) = React.useState(_ => [])
  let activePlayers = activePlayers
  // ->Array.filter(p => activePlayers->Array.indexOf(p.id) > -1)
  ->Array.toSorted((a, b) => {
    let userA = a.rating.mu
    let userB = b.rating.mu
    userA < userB ? 1. : -1.
  })
  let matches = activePlayers->match_make_naive
  <>
    <UiAction onClick={() => setActivePlayers(_ => {
			Js.log(players);
			players
		})}> {t`select all`} </UiAction>
    <SelectPlayersList
      players={players}
      selected={activePlayers->Array.map((p: Player.t) => p.id)}
      onClick={player =>
        setActivePlayers(ps =>
          switch ps->Array.findIndexOpt(p => p.id == player.id) {
          | Some(_) => ps->Array.filter(v => v.id != player.id)
          | None => ps->Array.concat([player])
          }
        )}
    />
    {matches->Array.mapWithIndex((match, i) => 
			<>
			{mod(i, 4) == 0 ? <div className="mb-4">{t`court ${((i / 4) + 1)->Int.toString}`}</div> : React.null}
			<Match key={i->Int.toString} onSelect=?onSelectMatch match /></>
		)->React.array}
  </>
}
