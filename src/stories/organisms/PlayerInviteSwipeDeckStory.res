// Storybook support for PlayerInviteSwipeDeck.stories.tsx; the app never
// imports this. The deck takes its players two ways, and the wrapper covers
// both. Invite mode: candidates carry a Relay fragment ref, read here from
// inviteRecommendations as EventInvites reads them. Approve mode: pending
// requests are plain profiles PkRSVPSection builds from its RSVPs; built here
// from the StoryFixturesEvent roster.
module Query = %relay(`
  query PlayerInviteSwipeDeckStoryQuery {
    inviteRecommendations(eventId: "evt-story-1", first: 12) {
      recommendations {
        availability
        user {
          id
          lineUsername
          ...PlayerInviteSwipeDeck_user @arguments(eventId: "evt-story-1")
        }
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PlayerInviteSwipeDeckStoryQuery_graphql.node->Obj.magic

// A pending request as PkRSVPSection turns it into a card: the RSVP's own
// rating (activity-scoped) and the note left with the request.
let request = (
  player: StoryFixturesEvent.player,
  index,
  ~bio: option<string>=?,
  ~note: option<string>=?,
): PlayerInviteSwipeDeck.player => {
  id: "rsvp-" ++ player.id->String.replace("user-", ""),
  name: player.lineUsername,
  source: FromProfile({
    displayName: player.lineUsername,
    picture: player.hasPicture ? Some(StoryFixturesEvent.avatar(player.lineUsername, index)) : None,
    gender: Some(player.gender == #male ? Male : Female),
    biography: bio,
    selfDupr: player.selfRating->Option.map(Rating.guessDupr),
    duprDoubles: player.duprDoubles,
    duprReliable: player.duprDoubles->Option.isSome,
    duprReliability: player.duprDoubles->Option.map(_ => 64.),
    computedDupr: player.rating->Option.map(((mu, _)) => Rating.guessDupr(mu)),
    computedSigma: player.rating->Option.map(((_, sigma)) => sigma),
    note,
  }),
  availability: None,
}

let rosterPlayer = id =>
  StoryFixturesEvent.roster->Array.findIndexOpt(p => p.id == id)->Option.flatMap(i =>
    StoryFixturesEvent.roster->Array.get(i)->Option.map(p => (p, i))
  )

let requests = () =>
  [
    rosterPlayer("user-aoi")->Option.map(((p, i)) =>
      request(
        p,
        i,
        ~bio="週末ピックルボーラー。ダブルス大好きです。",
        ~note="初心者ですが、よろしくお願いします！",
      )
    ),
    // Brand new: only his own estimate, no picture, nothing written.
    rosterPlayer("user-tom")->Option.map(((p, i)) => request(p, i)),
    // No games here yet; an established DUPR rating stands in.
    rosterPlayer("user-rin")->Option.map(((p, i)) =>
      request(
        p,
        i,
        ~bio="DUPR-rated at Shibaura, two years in. Happy on either side.",
        ~note="Can only stay until 20:30, hope that's OK.",
      )
    ),
  ]->Array.filterMap(x => x)

@genType @react.component
let make = (
  ~mode: [#invite | #approve]=#invite,
  // Which card comes first: the queue is rotated so this index leads.
  ~startAt=0,
  // Start with nobody left to review: the "Everyone reviewed" card.
  ~reviewed=false,
  ~onAccept: (string, option<string>) => unit=(_, _) => (),
  ~onClose=() => (),
) => {
  let data = Query.use(~variables=())
  let players = switch mode {
  | #approve => requests()
  | #invite =>
    data.inviteRecommendations.recommendations
    ->Option.getOr([])
    ->Array.map((r): PlayerInviteSwipeDeck.player => {
      id: r.user.id,
      name: r.user.lineUsername->Option.getOr("?"),
      source: FromFragment(r.user.fragmentRefs),
      availability: Some(
        switch r.availability {
        | Available => AvailabilityCovers
        | Unavailable => AvailabilityConflicts
        | _ => AvailabilityUnknown
        },
      ),
    })
  }
  let n = players->Array.length
  let players = reviewed
    ? []
    : n == 0
    ? players
    : Array.concat(
        players->Array.slice(~start=mod(startAt, n), ~end=n),
        players->Array.slice(~start=0, ~end=mod(startAt, n)),
      )
  <PlayerInviteSwipeDeck
    players
    eventTitle="Thursday Night Doubles"
    eventVenue=?{mode == #invite ? Some("Ariake Tennis Forest Park") : None}
    eventTimeLabel=?{mode == #invite ? Some("7:00 PM–9:00 PM") : None}
    mode={mode == #invite ? Invite : Approve}
    onAccept
    onClose
  />
}
