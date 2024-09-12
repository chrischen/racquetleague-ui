%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
open Util
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
  type highlight = Left | Right | Both | Left2 | Right2 | Both2
  @react.component
  let make = (
    ~match: Match.t<'a>,
    ~highlight: option<highlight>=?,
    ~onSelect: option<Match.t<'a> => unit>=?,
  ) => {
    let (team1, team2) = match
    <UiAction
      className="p-4 mb-2" onClick={_ => onSelect->Option.map(f => f(match))->Option.getOr()}>
      <div className="grid grid-cols-7 items-center place-content-center">
        <div
          className={Util.cx([
            "col-span-3 px-2 py-1",
            highlight
            ->Option.map(h => switch h {
              | Left | Both => "bg-yellow-100"
              | Left2 | Both2 => "bg-red-200"
              | _ => ""
            })
            ->Option.getOr(""),
          ])}>
          <span> {team1->Array.map(p => <PlayerMini key={p.id} player=p />)->React.array} </span>
        </div>
        <div className="col-span-1 text-center text-2xl text-gray-800 font-bold">
          {" VS "->React.string}
        </div>
        <div
          className={Util.cx([
            "col-span-3 justify-right text-right",
            highlight
            ->Option.map(h => switch h {
              | Right | Both => "bg-yellow-100"
              | Right2 | Both2 => "bg-red-200"
              | _ => ""
            })
            ->Option.getOr(""),
          ])}>
          <span> {team2->Array.map(p => <PlayerMini key={p.id} player=p />)->React.array} </span>
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
  ->(Array.map(_, match_to_players_set))
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

type strategy = CompetitivePlus | Competitive | Mixed | RoundRobin | Random
type stratButton = {name: string, strategy: strategy, details: string}

module Settings = {
  @react.component
  let make = () => {
    React.null
  }
}
let ts = Lingui.UtilString.t
@react.component
let make = (
  ~players: array<Player.t<'a>>,
  ~teams: NonEmptyArray.t<Team.t<'a>>,
  ~consumedPlayers: Set.t<string>,
  ~seenTeams: Set.t<string>,
  ~lastRoundSeenTeams: Set.t<string>,
  ~priorityPlayers: array<Player.t<'a>>,
  ~avoidAllPlayers: array<Player.t<'a>>,
  ~onSelectMatch: option<Match.t<'a> => unit>=?,
) => {
  let (strategy, setStrategy) = React.useState(() => CompetitivePlus)
  let intl = ReactIntl.useIntl()

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
  let availablePlayers = players->Players.filterOut(consumedPlayers)
  let teamConstraints = teams->NonEmptyArray.map(Team.toSet)
  let matches = switch strategy {
  | Mixed => strategy_by_mixed(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints)
  | RoundRobin =>
    strategy_by_round_robin(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints)
  | Random =>
    strategy_by_random(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints)
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
            onClick={_ => setStrategy(_ => tab.strategy)}
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
    <p className="mt-2 text-base leading-7 text-gray-600">
      <span className="px-2 py-1 bg-yellow-100"> {"..."->React.string} </span>
      {" = "->React.string}
      {t`This team has played before`}
      <span className="ml-2 px-2 py-1 bg-red-100"> {"..."->React.string} </span>
      {" = "->React.string}
      {t`Played last round`}
    </p>
    {matches
    ->Array.mapWithIndex(((match, quality), i) => {
      let (team1, team2) = match
      let highlight2 = switch (
        lastRoundSeenTeams->Set.has(team1->Team.toStableId),
        lastRoundSeenTeams->Set.has(team2->Team.toStableId),
      ) {
      | (true, true) => Some(MatchMini.Both2)
      | (true, false) => Some(MatchMini.Left2)
      | (false, true) => Some(MatchMini.Right2)
      | (false, false) => None
      }
      let highlight = switch (
        highlight2,
        seenTeams->Set.has(team1->Team.toStableId),
        seenTeams->Set.has(team2->Team.toStableId),
      ) {
      | (Some(Both2), true, true) => Some(MatchMini.Both2)
      | (_, true, true) => Some(MatchMini.Both)
      | (Some(Left2), true, false) => Some(Left2)
      | (_, true, false) => Some(MatchMini.Left)
      | (Some(Right2), false, true) => Some(Right2)
      | (_, false, true) => Some(MatchMini.Right)
      | (None, false, false) => None
      | (Some(h), false, false) => Some(h)
      }

      <React.Fragment key={i->Int.toString}>
        <MatchMini onSelect=?onSelectMatch match ?highlight />
        {quality->Float.toFixed(~digits=3)->React.string}
        <div className="overflow-hidden rounded-full bg-gray-200 mt-1">
          <FramerMotion.Div
            className="h-2 rounded-full bg-red-400"
            initial={width: "0%"}
            animate={{
              width: {
                switch maxQuality -. minQuality {
                | 0. => "0%"
                | _ =>
                  ((quality -. minQuality) /. (maxQuality -. minQuality) *. 100.)
                    ->Float.toFixed(~digits=3) ++ "%"
                }
              },
            }}
          />
        </div>
      </React.Fragment>
    })
    ->React.array}
  </>
}
