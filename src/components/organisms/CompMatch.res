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
  type border = Red | Yellow
  @react.component
  let make = (
    ~match: Match.t<'a>,
    ~highlight: option<highlight>=?,
    ~border: option<border>=?,
    ~onSelect: option<Match.t<'a> => unit>=?,
  ) => {
    let (team1, team2) = match
    <div className="flex pt-2 pl-2 pr-2">
      <div
        className={Util.cx([
          "flex-1 grid grid-cols-7 items-center place-content-center",
          border
          ->Option.map(h =>
            switch h {
            | Yellow => "border-yellow-100 border-4"
            | Red => "border-red-200 border-4"
            }
          )
          ->Option.getOr(""),
        ])}>
        <div
          className={Util.cx([
            "col-span-3 px-2 my-1 ml-1",
            highlight
            ->Option.map(h =>
              switch h {
              | Left | Both => "bg-yellow-100"
              | Left2 | Both2 => "bg-red-200"
              | _ => ""
              }
            )
            ->Option.getOr(""),
          ])}>
          <span> {team1->Array.map(p => <PlayerMini key={p.id} player=p />)->React.array} </span>
        </div>
        <div className="col-span-1 text-center text-2xl text-gray-800 font-bold">
          {" VS "->React.string}
        </div>
        <div
          className={Util.cx([
            "col-span-3 justify-right text-right my-1 mr-1",
            highlight
            ->Option.map(h =>
              switch h {
              | Right | Both => "bg-yellow-100"
              | Right2 | Both2 => "bg-red-200"
              | _ => ""
              }
            )
            ->Option.getOr(""),
          ])}>
          <span> {team2->Array.map(p => <PlayerMini key={p.id} player=p />)->React.array} </span>
        </div>
      </div>
      <div className="self-center p-3">
        <UiAction
          className="ml-3 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          onClick={_ => onSelect->Option.map(f => f(match))->Option.getOr()}>
          {t`Select`}
        </UiAction>
      </div>
    </div>
  }
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
  ~seenMatches: Set.t<string>,
  ~lastRoundSeenTeams: Set.t<string>,
  ~lastRoundSeenMatches: Set.t<string>,
  ~defaultStrategy: strategy,
  ~setDefaultStrategy: (strategy => strategy) => unit,
  ~priorityPlayers: array<Player.t<'a>>,
  ~avoidAllPlayers: array<Player.t<'a>>,
  ~onSelectMatch: option<(Match.t<'a>, ~dequeue: bool=?) => unit>=?,
  ~roundsCount: int,
) => {
  let (strategy, setStrategy) = React.useState(() => defaultStrategy)
  let intl = ReactIntl.useIntl()

  let strats = [
    {
      name: ts`Competitive`,
      strategy: CompetitivePlus,
      details: ts`Matches are arranged by a maximum skill-spread of +- 1 players.`,
    },
    // {
    //   name: ts`Competitive`,
    //   strategy: Competitive,
    //   details: ts`Matches are arranged by a maximum skill-spread of +- 2 players.`,
    // },
    {
      name: ts`Mixed`,
      strategy: Mixed,
      details: ts`Matches are arranged by skill while mixing strong and weak players.`,
    },
    {name: ts`Random`, strategy: Random, details: ts`Totally random teams.`},
    {
      name: "DUPR",
      strategy: DUPR,
      details: ts`Optimized for DUPR. Teams created with similar skill level players.`,
    },
    {name: ts`Round Robin`, strategy: RoundRobin, details: ts`Unique combination of matches.`},
  ]
  // let availablePlayers = players->Players.filterOut(consumedPlayers)
  let teamConstraints = teams->NonEmptyArray.map(Team.toSet)
  let matches = getMatches(
    players,
    consumedPlayers,
    strategy,
    players
    ->Array.get(0)
    ->Option.map((p1: player) => [p1]->Array.concat(priorityPlayers))
    ->Option.getOr(priorityPlayers),
    avoidAllPlayers,
    teamConstraints,
  )
  let matchesCount = matches->Array.length

  let matches = switch matchesCount {
  | 0 =>
    getMatches(
      players,
      consumedPlayers,
      strategy,
      players
      ->Array.get(0)
      ->Option.map((p1: player) => [p1]->Array.concat(priorityPlayers))
      ->Option.getOr(priorityPlayers),
      avoidAllPlayers,
      None,
    )
  | _ => matches
  }

  let matches = matches->Array.slice(~start=0, ~end=115)

  let maxQuality = matches->Array.reduce(0., (acc, (_, quality)) => quality > acc ? quality : acc)
  let minQuality =
    matches->Array.reduce(maxQuality, (acc, (_, quality)) => quality < acc ? quality : acc)

  let tab = strats->Array.find(tab => tab.strategy == strategy)

  let updateStrategy = (strategy: strategy) => {
    setStrategy(_ => strategy)
    setDefaultStrategy(_ => strategy)
  }

  <>
    <div className="sm:hidden">
      <label htmlFor="tabs" className="sr-only"> {t`Select a tab`} </label>
      <select
        id="tabs"
        name="tabs"
        onChange={e => {
          updateStrategy(
            strats
            ->Array.find(tab => tab.name == (e->ReactEvent.Form.target)["value"])
            ->Option.map(s => s.strategy)
            ->Option.getOr(Competitive),
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
            onClick={_ => updateStrategy(tab.strategy)}
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
    <p className="mt-2 text-base leading-7 text-gray-600 mb-2">
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
      let border = switch (
        lastRoundSeenMatches->Set.has(match->Match.toStableId),
        seenMatches->Set.has(match->Match.toStableId),
      ) {
      | (true, _) => Some(MatchMini.Red)
      | (_, true) => Some(MatchMini.Yellow)
      | (false, false) => None
      }

      <div className="border-zinc-600 rounded ring-1 mb-2" key={i->Int.toString}>
        <MatchMini
          onSelect=?{onSelectMatch->Option.map(f => match => {
            f(
              match,
              ~dequeue=switch strategy {
              | RoundRobin => false
              | _ => true
              },
            )
          })}
          match
          ?highlight
          ?border
        />
        // {quality->Float.toFixed(~digits=3)->React.string}
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
      </div>
    })
    ->React.array}
  </>
}
