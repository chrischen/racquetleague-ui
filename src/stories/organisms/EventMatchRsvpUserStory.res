// Storybook support for EventMatchRsvpUser.stories.tsx; the app never imports
// this. EventMatchRsvpUser is a player's card in the match queue of the
// in-person event tools (MatchesView, SubmitMatch): a big name with the
// player's number badge, tinted by their state in the session.
module Query = %relay(`
  query EventMatchRsvpUserStoryQuery {
    event(id: "evt-story-1") {
      rsvps(first: 20) {
        edges {
          node {
            id
            user {
              id
              lineUsername
              gender
              ...EventMatchRsvpUser_user
            }
            rating {
              mu
              sigma
            }
          }
        }
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventMatchRsvpUserStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  // One state for every card, or `mixed` for the queue as MatchesView shows
  // it mid-session: some queued for the next match, some playing, some
  // resting.
  ~status: [#available | #queued | #break | #playing | #mixed]=#available,
  ~compact=false,
  // The number of games each player has played this session.
  ~showPlayCount=false,
) => {
  let data = Query.use(~variables=())
  let nodes =
    data.event
    ->Option.flatMap(e => e.rsvps)
    ->Option.flatMap(c => c.edges)
    ->Option.getOr([])
    ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
  let statusFor = i =>
    switch status {
    | #available => MatchRsvpUser.Available
    | #queued => Queued
    | #break => Break
    | #playing => Playing
    | #mixed =>
      switch mod(i, 5) {
      | 0 | 1 => Playing
      | 2 => Queued
      | 3 => Available
      | _ => Break
      }
    }
  <div
    className={compact
      ? "grid grid-cols-2 gap-2 max-w-md font-sans"
      : "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 font-sans"}>
    {nodes
    ->Array.mapWithIndex((node, i) =>
      node.user
      ->Option.map(user => {
        let rating = Rating.Rating.make(
          node.rating->Option.flatMap(r => r.mu)->Option.getOr(25.),
          node.rating->Option.flatMap(r => r.sigma)->Option.getOr(25. /. 3.),
        )
        let player: Rating.player<unit> = {
          data: None,
          id: user.id,
          intId: i + 1,
          name: user.lineUsername->Option.getOr("?"),
          rating,
          ratingOrdinal: rating->Rating.Rating.ordinal,
          paid: false,
          gender: switch user.gender {
          | Some(Female) => Rating.Gender.Female
          | _ => Male
          },
          count: 0,
        }
        <EventMatchRsvpUser
          key=node.id
          user=user.fragmentRefs
          compact
          highlight={statusFor(i)}
          player
          playCount=?{showPlayCount ? Some(mod(i * 3 + 2, 7)) : None}
        />
      })
      ->Option.getOr(React.null)
    )
    ->React.array}
  </div>
}
