// Storybook support for PrintableDraws.stories.tsx; the app never imports
// this. The print preview of every round's draws, built from rounds the way
// EventManager builds it (court numbers, #player numbers, names).
open StoryFixturesMatch

let toPrintable = (rounds: array<array<Rating.completedMatchEntity<'a>>>) =>
  rounds->Array.mapWithIndex((round, roundIdx) => {
    PrintableDraws.roundNumber: roundIdx + 1,
    matches: round->Array.mapWithIndex((entity, matchIdx) => {
      let (team1, team2) = entity.match
      let team = (players: Rating.Team.t<'a>) => {
        PrintableDraws.players: players->Array.map(
          p => {
            PrintableDraws.id: p.id,
            number: p.intId,
            name: p.name,
          },
        ),
      }
      {
        PrintableDraws.id: entity.id,
        courtNumber: matchIdx + 1,
        team1: team(team1),
        team2: team(team2),
      }
    }),
  })

// Eight rounds on three courts for the 16 regulars: rotate everyone one place
// per round and pair them off, so the sheet runs to a second page.
let longEvening = players => {
  let regulars = players->Array.slice(~start=0, ~end=16)
  Array.fromInitializer(~length=8, r => {
    let order = Array.fromInitializer(~length=16, i =>
      regulars->Array.getUnsafe(mod(i * 5 + r * 3, 16))
    )
    Array.fromInitializer(~length=3, c => {
      let p = i => order->Array.getUnsafe(c * 4 + i)
      entity(~id=`long-r${r->Int.toString}-c${c->Int.toString}`, ([p(0), p(3)], [p(1), p(2)]))
    })
  })
}

@genType @react.component
let make = (
  ~state: [#threeRounds | #empty | #singleMatch | #longNames | #manyRounds]=#threeRounds,
  ~onClose=() => (),
) => {
  let players = React.useMemo0(() => plainPlayers())
  let rounds = switch state {
  | #threeRounds => rounds(players)
  | #empty => []
  | #singleMatch => [[entity(~id="solo", doubles(players, (kenji, mai), (yuki, takumi)))]]
  | #longNames => [
      [
        entity(~id="ln-c1", doubles(players, (alexandra, maximilian), (shinnosuke, yukiko))),
        entity(~id="ln-c2", doubles(players, (kenji, yukiko), (alexandra, chris))),
      ],
    ]
  | #manyRounds => longEvening(players)
  }
  <PrintableDraws rounds={rounds->toPrintable} onClose />
}
