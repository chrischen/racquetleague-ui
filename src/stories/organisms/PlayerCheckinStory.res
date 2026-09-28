// Storybook support for PlayerCheckin.stories.tsx; the app never imports this.
// The check-in panel at the top of the event manager: a tile per player,
// strongest first, to check them in, mark the court fee paid, and see their
// games played and how far their rating has moved tonight. The header opens
// team management and the seeding modal; the last tiles add walk-ins or show
// a QR code to join. It starts open while fewer than four are checked in.
//
// Players are the shared match roster, read through EventManager's fragment
// (real avatar fragment refs), with StoryFixturesSession's paid mix and
// walk-ins. The wrapper keeps check-ins and payments in state, as
// EventManager does, so tiles respond to taps.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

// How far ratings have moved after two rounds (the tile's trend badge):
// (roster position, change in mu).
let movedTonight = [
  (kenji, 0.8),
  (yuki, -1.3),
  (chris, 2.1),
  (aiko, -0.6),
  (mai, 1.4),
  (daniel, 3.2),
  (haruka, -0.9),
  (sarah, -1.7),
  (naomi, 0.5),
]

let afterTwoRounds = (players: array<Rating.Player.t<'a>>) =>
  players->Array.mapWithIndex((p, i) =>
    switch movedTonight->Array.find(((index, _)) => index == i) {
    | Some((_, change)) => {
        let rating = Rating.Rating.make(p.rating.mu +. change, p.rating.sigma)
        {...p, rating, ratingOrdinal: rating->Rating.Rating.ordinal}
      }
    | None => p
    }
  )

// Before anyone has played: no play counts, nothing paid yet.
let beforeStart = (players: array<Rating.Player.t<'a>>) =>
  players->Array.map(p => {...p, count: 0, paid: false})

@genType @react.component
let make = (
  ~state: [#empty | #arriving | #underway | #withGuests]=#underway,
  ~clubEvent=false,
  ~onToggleCheckin: option<string => unit>=?,
  ~onTogglePaid: option<string => unit>=?,
  ~onAdjustSeeds: option<array<(string, float)> => unit>=?,
  ~onOpenTeamManagement=() => (),
  ~onOpenPlayerSettings: option<string => unit>=?,
  ~onOpenAddGuests=() => (),
  ~onUseClubRatings: option<bool => unit>=?,
) => {
  let roster = useManagerPlayers()
  // (players at the start of the night, players now, who is checked in)
  let (initialPlayers, startingPlayers, startingCheckedIn) = switch state {
  | #empty => ([], [], Set.make())
  // Doors just opened: three regulars are here, nobody has played.
  | #arriving => {
      let players = roster->beforeStart
      (players, players, ["user-kenji", "user-chris", "user-mai"]->Set.fromArray)
    }
  // Two rounds in: 16 checked in, most paid, ratings moving.
  | #underway => {
      let players = roster->StoryFixturesSession.withPaidMix
      (players, players->afterTwoRounds, checkedInIds(players))
    }
  | #withGuests => {
      let players =
        roster->StoryFixturesSession.withPaidMix->Array.concat(StoryFixturesSession.guests())
      (players, players->afterTwoRounds, StoryFixturesSession.checkedInWithGuests(players))
    }
  }
  let (players, setPlayers) = React.useState(() => startingPlayers)
  let (checkedInPlayerIds, setCheckedIn) = React.useState(() => startingCheckedIn)
  let (usingClubRatings, setUsingClubRatings) = React.useState(() => false)

  let seedSourceOption: option<SeedAdjustModal.seedSourceOption> = clubEvent
    ? Some({
        clubName: "Shibuya Pickleball Club",
        usingClubRatings,
        isLoading: false,
        onUseClubRatings: useClub => {
          setUsingClubRatings(_ => useClub)
          onUseClubRatings->Option.forEach(f => f(useClub))
        },
      })
    : None

  <PlayerCheckin
    players
    checkedInPlayerIds
    onToggleCheckin={id => {
      setCheckedIn(prev => {
        let next = prev->Set.values->Array.fromIterator->Set.fromArray
        prev->Set.has(id) ? next->Set.delete(id)->ignore : next->Set.add(id)->ignore
        next
      })
      onToggleCheckin->Option.forEach(f => f(id))
    }}
    onTogglePaid={id => {
      setPlayers(prev => prev->Array.map(p => p.id == id ? {...p, paid: !p.paid} : p))
      onTogglePaid->Option.forEach(f => f(id))
    }}
    onAdjustSeeds={seeds => onAdjustSeeds->Option.forEach(f => f(seeds))}
    onOpenTeamManagement
    onOpenPlayerSettings={player => onOpenPlayerSettings->Option.forEach(f => f(player.name))}
    onOpenAddGuests
    getUserFragmentRefs
    initialPlayers
    eventUrl="https://www.pkuru.com/events/evt-story-match"
    ?seedSourceOption
  />
}
