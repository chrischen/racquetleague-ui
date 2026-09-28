// Shared fixtures for the event-day tool stories (batch F1), mainly
// EventManager. Storybook support only; the app never imports this.
//
// Everything builds on the match roster (StoryFixturesMatch) and the session
// fixtures (StoryFixturesSession): the same Thursday night at 19:00 Tokyo, 20
// RSVPs with 16 regulars checked in, two walk-ins, three courts. What this
// module adds is the storage EventManager restores itself from when it mounts:
// its TinyBase store, persisted to IndexedDB. (AiTetsu's localStorage keys are
// seeded in AiTetsuStory.res.) A wrapper clears the story event's saved state
// and writes one complete evening into it before the tool mounts, so every
// story shows the state its name says, whatever an earlier story (or a click)
// left behind.
open StoryFixturesMatch

// --- Players as the tools number them -----------------------------------------

/** The roster plus the two walk-ins (positions 20 and 21, as
 StoryFixturesSession.recordedRounds expects), numbered the way EventManager
 numbers them: by rating, strongest #1. Saved matches carry these numbers. */
let rankedPlayers = (): array<Rating.Player.t<'a>> => {
  let all = plainPlayers()->Array.concat(StoryFixturesSession.guests())
  let order =
    all
    ->Array.toSorted((a, b) => {
      let diff = b.rating.mu -. a.rating.mu
      diff != 0. ? diff : String.compare(a.id, b.id)
    })
    ->Array.map(p => p.id)
  all->Array.map(p => {...p, intId: order->Array.indexOf(p.id) + 1})
}

/** The 16 regulars and both walk-ins. */
let checkedInTonight = (players: array<Rating.Player.t<'a>>) =>
  checkedInIds(players)
  ->Set.values
  ->Array.fromIterator
  ->Array.concat([StoryFixturesSession.kaitoId, StoryFixturesSession.lisaId])

let isGuest = (p: Rating.Player.t<'a>) => p.id->String.startsWith("guest-")

// --- EventManager ---------------------------------------------------------------

@genType
type managerState = [#beforeCheckIn | #readyToGenerate | #roundInProgress | #nightFinished]

module Manager = {
  module P = EventManagerPersistence

  // Round 2 is being played: round 1 went up to the server, court 1 of round 2
  // has a score that has not, and round 3 is drawn.
  let inProgressRounds = players => {
    let r2 = round2(players)->Array.map(m => m.id == "evt-r2-c1" ? {...m, synced: false} : m)
    [round1(players), r2, round3(players)]
  }

  // Three rounds, every court scored. Rounds 1 and 2 (with the walk-ins' fourth
  // court) are synced; round 3's scores are still on this device.
  let finishedRounds = players => {
    let round3Scores = [(11., 9.), (6., 11.), (11., 4.)]
    StoryFixturesSession.recordedRounds(players)->Array.concat([
      round3(players)->Array.mapWithIndex((m, i) => {
        ...StoryFixturesSession.scored(m, round3Scores->Array.getUnsafe(i), ~round=2),
        synced: false,
      }),
    ])
  }

  // The walk-ins sat out rounds 2 and 3 back to back, which the solver reports.
  let round3Violations = () =>
    Js.Dict.fromArray([
      (
        "2",
        [
          SolverTypes.BackToBackBye({playerId: StoryFixturesSession.kaitoId}),
          SolverTypes.BackToBackBye({playerId: StoryFixturesSession.lisaId}),
        ],
      ),
    ])

  /** Forgets everything saved for `eventId`: settings, check-ins, rounds. */
  let clear = eventId => {
    P.eventStore->TinyBase.delRow("eventState", eventId)
    P.syncRoundsToDb(eventId, [])
  }

  // Who has paid the court fee (EventManager starts everyone unpaid).
  let markPaid = (eventId, players: array<Rating.Player.t<'a>>) =>
    players->Array.forEach(p =>
      if !isGuest(p) && !(StoryFixturesSession.unpaidIds->Array.includes(p.id)) {
        P.savePlayerOverride(eventId, p.id, p.name, p.gender, true)
      }
    )

  let arrived = (eventId, players, ~courts) => {
    P.saveCourtCount(eventId, courts)
    P.saveGuestPlayers(eventId, StoryFixturesSession.guests())
    P.saveCheckedInPlayerIds(eventId, checkedInTonight(players))
    markPaid(eventId, players)
  }

  /** Writes one evening into EventManager's store, replacing whatever was saved for `eventId`. */
  let seed = (eventId: string, state: managerState) => {
    clear(eventId)
    let players = rankedPlayers()
    switch state {
    | #beforeCheckIn => ()
    | #readyToGenerate =>
      arrived(eventId, players, ~courts=3)
      P.saveRatingAdjustmentHistory(eventId, StoryFixturesSession.seedAdjustments)
    | #roundInProgress =>
      arrived(eventId, players, ~courts=3)
      P.saveRatingAdjustmentHistory(eventId, StoryFixturesSession.allAdjustments)
      P.syncRoundsToDb(eventId, inProgressRounds(players))
      P.saveSolverRoundViolations(eventId, round3Violations())
      P.saveCurrentRound(eventId, 2)
    | #nightFinished =>
      arrived(eventId, players, ~courts=4)
      P.saveRatingAdjustmentHistory(eventId, StoryFixturesSession.allAdjustments)
      P.syncRoundsToDb(eventId, finishedRounds(players))
      P.saveCurrentRound(eventId, 3)
    }
  }

  let settled = () => {
    let health = P.getHealth()
    health.ready || health.failure->Option.isSome
  }

  /** Renders `children` once the store has loaded from IndexedDB and `seed` has
   run. Seeding earlier would be overwritten by that first load. */
  module Storage = {
    @react.component
    let make = (~seed: unit => unit, ~children: React.element) => {
      let (ready, setReady) = React.useState(() => false)
      React.useEffect0(() => {
        let done = ref(false)
        let finish = () =>
          if !done.contents && settled() {
            done := true
            seed()
            setReady(_ => true)
          }
        let unsubscribe = P.subscribeHealth(finish)
        finish()
        Some(unsubscribe)
      })
      ready ? children : React.null
    }
  }
}
