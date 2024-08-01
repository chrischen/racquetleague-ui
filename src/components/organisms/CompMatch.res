%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

open Rating
module PlayerMini = {
  // type t<'a> = {
  //   data: 'a,
  //   id: string,
  //   name: string,
  //   rating: Rating.Rating.t,
  // }

  @react.component
  let make = (~player: Player.t<'a>) => {
    <span className="mr-2">
      {player.name->React.string}
      {"("->React.string}
      {player.rating.mu->Float.toFixed(~digits=2)->React.string}
      {")"->React.string}
    </span>
  }
}

module MatchMini = {
  @react.component
  let make = (~match: Match.t<'a>, ~onSelect: option<Match.t<'a> => unit>=?) => {
    let (team1, team2) = match
    <UiAction className="p-4" onClick={() => onSelect->Option.map(f => f(match))->Option.getOr()}>
      <div className="mb-2">
        <span> {team1->Array.map(p => <PlayerMini player=p />)->React.array} </span>
        {" VS "->React.string}
        <span> {team2->Array.map(p => <PlayerMini player=p />)->React.array} </span>
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
  players->array_split_by_4->Array.map(((p1, p2, p3, p4)) => ([p1, p4], [p2, p3]))
}

let array_combos: array<'a> => array<('a, 'a)> = arr => {
  arr->Array.flatMapWithIndex((v, i) =>
    arr->Array.slice(~start=i + 1, ~end=Array.length(arr))->Array.map(v2 => (v, v2))
  )
}
let combos = (arr1: array<'a>, arr2: array<'a>): array<('a, 'a)> => {
  arr1->Array.flatMap(d => arr2->Array.map(v => (d, v)))
}
let tuple2array = ((a, b)) => [a, b]
let match_quality: Match.t<'a> => float = ((team1, team2)) => {
  Rating.predictDraw([team1->Array.map(p => p.rating), team2->Array.map(p => p.rating)])
}
// type scored_match<'a> = (Match.t<'a>, float)

type sortedArray<'a> = {value: 'a, sort: float}
let shuffle = arr =>
  arr
  ->Array.map(value => {value, sort: Math.random()})
  ->Array.toSorted((a, b) => a.sort -. b.sort)
  ->Array.map(({value}) => value)

let strategy_by_quality = matches =>
  matches->Array.toSorted((a, b) => {
    let (_, qualityA) = a
    let (_, qualityB) = b
    qualityA < qualityB ? 1. : -1.
  })

let strategy_by_round_robin = matches => matches

let strategy_by_random = matches => matches->shuffle

type strategy = Quality | RoundRobin | Random
type stratButton = {name: string, strategy: strategy}

let ts = Lingui.UtilString.t
let strats = [{name: ts`Quality`, strategy: Quality}, {name: ts`Random`, strategy: Random}]
@react.component
let make = (
  ~players: array<Player.t<'a>>,
  ~priorityPlayers: array<Player.t<'a>>,
  ~consumedPlayers: Js.Set.t<string>,
  ~onSelectMatch: option<Match.t<'a> => unit>=?,
) => {
  let (strategy, setStrategy) = React.useState(() => Quality)
  let activePlayers =
    players
    ->Array.filter(p => !(consumedPlayers->Set.has(p.id)))
    // ->Array.filter(p => activePlayers->Array.indexOf(p.id) > -1)
    ->Array.toSorted((a, b) => {
      let userA = a.rating.mu
      let userB = b.rating.mu
      userA < userB ? 1. : -1.
    })

  let teams = activePlayers->array_combos->Array.map(tuple2array)
  let matches =
    teams
    ->Array.reduce([], (acc, team) => {
      let players' = activePlayers->Array.filter(p => !(team->Team.contains_player(p)))
      // Teams of remaining players
      let teams' = players'->array_combos->Array.map(tuple2array)
      acc->Array.concat([team]->combos(teams'))
    })
    ->Array.map(match => {
      let quality = match->match_quality
      (match, quality)
    })

  let matches =
    priorityPlayers->Array.length == 0 ||
      priorityPlayers->Array.length == activePlayers->Array.length
      ? matches
      : matches->Array.filter(((match, _)) => match->Match.contains_any_players(priorityPlayers))

  let matches = switch strategy {
  | Quality => strategy_by_quality(matches)->Array.slice(~start=0, ~end=15)
  | RoundRobin => strategy_by_round_robin(matches)->Array.slice(~start=0, ~end=15)
  | Random => strategy_by_random(matches)->Array.slice(~start=0, ~end=15)
  }

  let maxQuality = matches->Array.reduce(0., (acc, (_, quality)) => quality > acc ? quality : acc)
  let minQuality =
    matches->Array.reduce(maxQuality, (acc, (_, quality)) => quality < acc ? quality : acc)
  <>
    <div className="sm:hidden">
      <label htmlFor="tabs" className="sr-only"> {t`Select a tab`} </label>
      <select
        id="tabs"
        name="tabs"
        onChange={e =>
          setStrategy(_ =>
            strats
            ->Array.find(tab => tab.name == (e->ReactEvent.Form.currentTarget)["value"])
            ->Option.map(s => s.strategy)
            ->Option.getOr(Quality)
          )}
        defaultValue={strats
        ->Array.find(tab => tab.strategy == strategy)
        ->Option.map(s => s.name)
        ->Option.getOr("")}
        className="block w-full rounded-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500">
        {strats
        ->Array.map(tab =>
          <option key={tab.name} value={tab.name}> {tab.name->React.string} </option>
        )
        ->React.array}
      </select>
    </div>
    <div className="hidden sm:block">
      <nav ariaLabel="Tabs" className="flex space-x-4">
        {strats
        ->Array.map(tab =>
          <UiAction
            key={tab.name}
            // \"aria-current"={tab.current ? 'page' : undefined}
            onClick={() => setStrategy(_ => tab.strategy)}
            className={Util.cx([
              strategy == tab.strategy
                ? "bg-indigo-100 text-indigo-700"
                : "text-gray-500 hover:text-gray-700",
              "rounded-md px-3 py-2 text-sm font-medium",
            ])}>
            {tab.name->React.string}
          </UiAction>
        )
        ->React.array}
      </nav>
    </div>
    {matches
    ->Array.mapWithIndex(((match, quality), i) => <>
      <MatchMini key={i->Int.toString} onSelect=?onSelectMatch match />
      <div className="overflow-hidden rounded-full bg-gray-200 mt-1">
        <FramerMotion.Div
          className="h-2 rounded-full bg-red-400"
          initial={width: "0%"}
          animate={{
            width: ((quality -. minQuality) /. (maxQuality -. minQuality) *. 100.)
              ->Float.toFixed(~digits=3) ++ "%",
          }}
        />
      </div>
    </>)
    ->React.array}
  </>
}
