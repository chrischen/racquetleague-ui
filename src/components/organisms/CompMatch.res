%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

open Rating
module PlayerMini = {
  @react.component
  let make = (~player: Player.t<'a>) => {
    <>
      <span className="mr-2">
        {player.name->React.string}
        {"("->React.string}
        {player.rating.mu->Float.toFixed(~digits=2)->React.string}
        {")"->React.string}
      </span>
      <br />
    </>
  }
}

module MatchMini = {
  @react.component
  let make = (~match: Match.t<'a>, ~onSelect: option<Match.t<'a> => unit>=?) => {
    let (team1, team2) = match
    <UiAction
      className="p-4 mb-2" onClick={() => onSelect->Option.map(f => f(match))->Option.getOr()}>
      <div className="grid grid-cols-7 items-center place-content-center">
        <div className="col-span-3">
          <span> {team1->Array.map(p => <PlayerMini player=p />)->React.array} </span>
        </div>
        <div className="col-span-1 text-center text-2xl text-gray-800 font-bold">
          {" VS "->React.string}
        </div>
        <div className="col-span-3 justify-right text-right">
          <span> {team2->Array.map(p => <PlayerMini player=p />)->React.array} </span>
        </div>
      </div>
    </UiAction>
  }
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
let match_make_naive = (players: array<Player.t<'a>>): array<Match.t<'a>> => {
  players
  ->array_split_by_n(4)
  ->Array.map(p => (
    [p->Array.getUnsafe(0), p->Array.getUnsafe(3)],
    [p->Array.getUnsafe(1), p->Array.getUnsafe(2)],
  ))
}
let team_to_players_set = (team: array<Player.t<'a>>): Set.t<string> =>
  team->Array.map(p => p.id)->Set.fromArray

let match_to_players_set = ((team1, team2): Match.t<'a>): Set.t<string> =>
  team1->Array.concat(team2)->Array.map(p => p.id)->Set.fromArray

let matches_contains_match = (matches: array<Match.t<'a>>, match: Set.t<string>): bool => {
  matches
  ->Array.map(_, match_to_players_set)
  ->Array.findIndex(m => m->intersection(match)->Set.size == 4) > -1
}
let contains_match = (matches: array<(Match.t<'a>, float)>, match: Set.t<string>): bool => {
  matches
  ->Array.map(((match, _)) => match->match_to_players_set)
  ->Array.findIndex(m => m->intersection(match)->Set.size == 4) > -1
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

type matchmakingResult<'a> = {
  seenTeams: array<Set.t<string>>,
  // seenTeams: array<Team.t<'a>>,
  matches: array<Match.t<'a>>,
}
let find_all_match_combos = (availablePlayers, priorityPlayers) => {
  let teams = availablePlayers->array_combos->Array.map(tuple2array)
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
  priorityPlayers->Array.length == 0 ||
    priorityPlayers->Array.length == availablePlayers->Array.length
    ? matches
    : matches->Array.filter(((match, _)) => match->Match.contains_any_players(priorityPlayers))
}

let strategy_by_competitive = (
  players: array<Player.t<'a>>,
  consumedPlayers,
  priorityPlayers: array<Player.t<'a>>,
) => {
  players
  ->Array.toSorted((a, b) => {
    let userA = a.rating.mu
    let userB = b.rating.mu
    userA < userB ? 1. : -1.
  })
  ->array_split_by_n(8)
  ->Array.reduce([], (acc, playerSet) => {
    let matches =
      playerSet
      ->Array.filter(p => !(consumedPlayers->Set.has(p.id)))
      ->find_all_match_combos(priorityPlayers)
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
  consumedPlayers,
  priorityPlayers: array<Player.t<'a>>,
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
      ->Array.filter(p => !(consumedPlayers->Set.has(p.id)))
      ->find_all_match_combos(priorityPlayers)
      ->Array.toSorted((a, b) => {
        let (_, qualityA) = a
        let (_, qualityB) = b
        qualityA < qualityB ? 1. : -1.
      })
    acc->Array.concat(matches)
  })
}

let strategy_by_mixed = (availablePlayers, priorityPlayers) => {
  find_all_match_combos(availablePlayers, priorityPlayers)->Array.toSorted((a, b) => {
    let (_, qualityA) = a
    let (_, qualityB) = b
    qualityA < qualityB ? 1. : -1.
  })
}

let strategy_by_round_robin = (availablePlayers, priorityPlayers) => {
  let matches = find_all_match_combos(availablePlayers, priorityPlayers)
  matches
}

let strategy_by_random = (availablePlayers, priorityPlayers) => {
  let matches = find_all_match_combos(availablePlayers, priorityPlayers)
  matches->shuffle
}

type strategy = CompetitivePlus | Competitive | Mixed | RoundRobin | Random
type stratButton = {name: string, strategy: strategy, details: string}

let ts = Lingui.UtilString.t
@react.component
let make = (
  ~players: array<Player.t<'a>>,
  ~priorityPlayers: array<Player.t<'a>>,
  ~consumedPlayers: Js.Set.t<string>,
  ~onSelectMatch: option<Match.t<'a> => unit>=?,
) => {
  let (strategy, setStrategy) = React.useState(() => CompetitivePlus)
  let availablePlayers = players->Array.filter(p => !(consumedPlayers->Set.has(p.id)))
  let intl = ReactIntl.useIntl()
  // ->Array.filter(p => availablePlayers->Array.indexOf(p.id) > -1)

  let strats = [
    {
      name: ts`Competitive Plus`,
      strategy: CompetitivePlus,
      details: ts`Matches are arranged by a maximum skill-spread of +- 1 players.`,
    },
    {
      name: ts`Competitive`,
      strategy: Competitive,
      details: ts`Matches are arranged by a maximum skill-spread of +- 2 players.`,
    },
    {
      name: ts`Mixed`,
      strategy: Mixed,
      details: ts`Matches are arranged by skill while mixing strong and weak players.`,
    },
    {name: ts`Random`, strategy: Random, details: ts`Totally random teams.`},
  ]
  let matches = switch strategy {
  | Mixed => strategy_by_mixed(availablePlayers, priorityPlayers)
  | RoundRobin => strategy_by_round_robin(availablePlayers, priorityPlayers)
  | Random => strategy_by_random(availablePlayers, priorityPlayers)
  | Competitive => strategy_by_competitive(players, consumedPlayers, priorityPlayers)
  | CompetitivePlus => strategy_by_competitive_plus(players, consumedPlayers, priorityPlayers)
  }
  let matchesCount = matches->Array.length
  let matches = matches->Array.slice(~start=0, ~end=15)

  let maxQuality = matches->Array.reduce(0., (acc, (_, quality)) => quality > acc ? quality : acc)
  let minQuality =
    matches->Array.reduce(maxQuality, (acc, (_, quality)) => quality < acc ? quality : acc)
  let tab = strats->Array.find(tab => tab.strategy == strategy)
  <>
    <div className="sm:hidden">
      <label htmlFor="tabs" className="sr-only"> {t`Select a tab`} </label>
      <select
        id="tabs"
        name="tabs"
        onChange={e => {
          setStrategy(_ =>
            strats
            ->Array.find(tab => tab.name == (e->ReactEvent.Form.target)["value"])
            ->Option.map(s => s.strategy)
            ->Option.getOr(Competitive)
          )
        }}
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
    <p className="mt-2 text-base leading-7 text-gray-600">
      {t`Analyzed ${intl->ReactIntl.Intl.formatNumber(matchesCount->Int.toFloat)} matches.`}
      {" "->React.string}
      {tab->Option.map(tab => tab.details->React.string)->Option.getOr(React.null)}
    </p>
    {matches
    ->Array.mapWithIndex(((match, quality), i) => <>
      <MatchMini key={i->Int.toString} onSelect=?onSelectMatch match />
      {quality->Float.toFixed(~digits=3)->React.string}
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
