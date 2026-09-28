// Storybook support for AiTetsu.stories.tsx; the app never imports this.
// AiTetsu (the league event page's session tool) reads its session from
// localStorage when it mounts: play counts, walk-ins, reported results and who
// is checked in, all keyed by the event id. The wrapper writes the chosen state
// there first and remounts the tool when it changes. Players come from the
// shared match roster (StoryFixturesMatch), so avatars and names match the
// match-play stories. The children slot holds the event's submitted matches,
// as on LeagueEventPage. Matches queued on the session screen are kept in
// AiTetsu's private TinyBase store, which the wrapper cannot reach, so those
// survive a story switch within one Storybook tab.
open StoryFixturesMatch

module Query = %relay(`
  query AiTetsuStoryQuery {
    event(id: "evt-story-aitetsu") {
      id
      ...AiTetsu_event
    }
    ...MatchHistoryListFragment @arguments(activitySlug: "pickleball")
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = AiTetsuStoryQuery_graphql.node->Obj.magic

@genType
type queueState = [#fresh | #underway]

let storageKeys = eventId => [
  eventId ++ "-sessionState",
  eventId ++ "-playersState",
  eventId ++ "-matchesState",
  eventId ++ "-playersCheckinState",
]

let reported = (m: Rating.completedMatchEntity<'a>, score): Rating.CompletedMatch.t<'a> => (
  m.match,
  Some(score),
)

// Six games reported so far: all of round 1 and round 2.
let history = players => {
  let r1 = round1(players)
  let r2 = round2(players)
  [
    reported(r1->Array.getUnsafe(0), (11., 8.)),
    reported(r1->Array.getUnsafe(1), (9., 11.)),
    reported(r1->Array.getUnsafe(2), (11., 6.)),
    reported(r2->Array.getUnsafe(0), (11., 7.)),
    reported(r2->Array.getUnsafe(1), (8., 11.)),
    reported(r2->Array.getUnsafe(2), (13., 11.)),
  ]
}

/** Replaces AiTetsu's saved session for `eventId`. */
let seed = (eventId: string, state: queueState) => {
  open Dom.Storage2
  storageKeys(eventId)->Array.forEach(key => localStorage->removeItem(key))
  switch state {
  | #fresh => ()
  | #underway =>
    // No walk-ins: AiTetsu saves them (Players.savePlayers) with the gender as
    // "Male"/"Female" but reads it back as a number, so saved guests never load.
    let players = plainPlayers()
    session(players)->Session.saveState(eventId)
    history(players)->Rating.CompletedMatches.saveMatches(eventId)
    // Check-in is stored as who is NOT here: the four long-name players.
    let absent =
      [alexandra, shinnosuke, maximilian, yukiko]->Array.map(i => (players->at(i)).id)
    localStorage->setItem(
      eventId ++ "-playersCheckinState",
      absent->Js.Json.stringifyAny->Option.getOr("[]"),
    )
  }
}

// Writes the session during the first render, before AiTetsu's mount effect reads it.
module Seeded = {
  @react.component
  let make = (~eventId, ~state, ~children: React.element) => {
    let _ = React.useState(() => seed(eventId, state))
    children
  }
}

@genType @react.component
let make = (~state: queueState=#underway) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    <Seeded key={(state :> string)} eventId=event.id state>
      <AiTetsu event=event.fragmentRefs>
        <MatchHistoryList matches=data.fragmentRefs />
      </AiTetsu>
    </Seeded>
  | None => React.null
  }
}
