// Storybook support for CompMatch.stories.tsx; the app never imports this.
// The match chooser the queue screen opens ("Choose Match"): strategy tabs,
// the recommended match and every candidate ranked by quality. It never reads
// a fragment, so the roster players here carry no Relay data.
open StoryFixturesMatch

@genType @react.component
let make = (
  ~state: [#queue | #notEnoughPlayers | #withHistory | #somePlaying | #replacePlayer]=#queue,
  ~strategy: [#competitive | #mixed]=#competitive,
  ~onSelectMatch: option<string => unit>=?,
) => {
  let players = React.useMemo0(() => plainPlayers())
  let pick = indexes => indexes->Array.map(i => players->at(i))
  let queued8 = pick([kenji, yuki, chris, aiko, hiroshi, emily, takumi, mai])
  let team = (a, b) => [players->at(a), players->at(b)]->Rating.Team.toStableId
  let none = Set.make()

  // (queued players, players already on court, teams seen in earlier rounds,
  // teams seen last round, players a replacement match must keep)
  let (queue, consumed, seenTeams, lastRoundSeenTeams, required) = switch state {
  | #queue => (queued8, [], none, none, None)
  | #notEnoughPlayers => (pick([kenji, yuki, chris]), [], none, none, None)
  // Kenji & Yuki and Chris & Aiko partnered earlier tonight (yellow), Kenji &
  // Chris last round (red), so the candidates using them are shaded.
  | #withHistory => (
      queued8,
      [],
      Set.fromArray([team(kenji, yuki), team(chris, aiko)]),
      Set.fromArray([team(kenji, chris)]),
      None,
    )
  // Twelve queued, but Kenji, Yuki, Chris and Aiko are still on court.
  | #somePlaying => (
      pick([kenji, yuki, chris, aiko, hiroshi, emily, takumi, mai, daniel, haruka, sota, sarah]),
      pick([kenji, yuki, chris, aiko]),
      none,
      none,
      None,
    )
  // Replacing Aiko in Chris & Aiko vs Hiroshi & Emily: the other three stay.
  | #replacePlayer => (
      pick([chris, hiroshi, emily, takumi, mai, daniel]),
      [],
      none,
      none,
      Some(pick([chris, hiroshi, emily])),
    )
  }
  let ids = (players: array<Rating.Player.t<_>>) => players->Array.map(p => p.id)->Set.fromArray

  <div className="max-w-3xl">
    <CompMatch
      players=queue
      session={session(players)}
      teams=None
      consumedPlayers={consumed->ids}
      seenTeams
      seenMatches={Set.make()}
      lastRoundSeenTeams
      lastRoundSeenMatches={Set.make()}
      defaultStrategy={switch strategy {
      | #competitive => Rating.CompetitivePlus
      | #mixed => Rating.Mixed
      }}
      setDefaultStrategy={_ => ()}
      priorityPlayers=[]
      requiredPlayers=?{required->Option.map(ids)}
      onSelectMatch={(match, ~disablePlayers as _=?) =>
        onSelectMatch->Option.forEach(f => f(describe(match)))}
      courts={Util.NonZeroInt.make(2)}
    />
  </div>
}
