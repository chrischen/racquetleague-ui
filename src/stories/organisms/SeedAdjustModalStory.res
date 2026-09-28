// Storybook support for SeedAdjustModal.stories.tsx; the app never imports this.
// The organiser's drag-to-reorder seeding list, strongest first, each row with
// its avatar, skill bar and mu. At a club event a switch picks which rating
// pool players start from; the wrapper plays EventManager's part and swaps the
// players' ratings when it flips. Players are the shared match roster, read
// through EventManager's fragment so avatars are real fragment refs.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

// Ratings earned inside the club: the order shifts a little (Yuki and Aiko
// have played more club nights than Kenji), and the four occasional players
// have no club rating, so they start from the default.
let clubMu = [
  30.2,
  31.5,
  28.1,
  29.9,
  26.4,
  27.8,
  25.0,
  26.2,
  23.1,
  24.5,
  21.8,
  22.6,
  22.0,
  19.1,
  20.3,
  18.2,
]

let withClubRatings = (players: array<Rating.Player.t<'a>>) =>
  players->Array.mapWithIndex((p, i) => {
    let rating = switch clubMu->Array.get(i) {
    | Some(mu) => Rating.Rating.make(mu, p.rating.sigma)
    | None => Rating.Rating.makeDefault()
    }
    {...p, rating, ratingOrdinal: rating->Rating.Rating.ordinal}
  })

@genType @react.component
let make = (
  ~state: [
    | #checkedIn
    | #withGuests
    | #walkInsOnly
    | #clubEvent
    | #clubRatings
    | #loadingClubRatings
  ]=#checkedIn,
  ~onSave: option<array<(string, float)> => unit>=?,
  ~onClose=() => (),
  ~onUseClubRatings: option<bool => unit>=?,
) => {
  let roster = useManagerPlayers()
  let checkedIn = roster->Array.slice(~start=0, ~end=16)
  let (usingClubRatings, setUsingClubRatings) = React.useState(() =>
    switch state {
    | #clubRatings | #loadingClubRatings => true
    | _ => false
    }
  )
  let isLoading = state == #loadingClubRatings

  let players = React.useMemo2(() =>
    switch state {
    | #checkedIn => checkedIn
    // Everyone on the RSVP list, plus the two walk-ins at the default 25.0.
    | #withGuests => roster->Array.concat(StoryFixturesSession.guests())
    // The standalone round-robin tool with only walk-ins: every rating is the
    // default, so every skill bar sits at the midpoint.
    | #walkInsOnly =>
      StoryFixturesSession.guests()->Array.concat([
        guest(~name="Ryo Hayashi", ~intId=9002),
        guest(~name="Megumi Ono", ~gender=Female, ~intId=9003),
        guest(~name="Ben Clarke", ~intId=9004),
        guest(~name="Saki Fujita", ~gender=Female, ~intId=9005),
      ])
    | #clubEvent | #clubRatings | #loadingClubRatings =>
      // Still loading: the list keeps the pool it had until the club ratings arrive.
      usingClubRatings && !isLoading ? withClubRatings(roster) : roster
    }
  , (roster, usingClubRatings))

  let seedSourceOption: option<SeedAdjustModal.seedSourceOption> = switch state {
  | #clubEvent | #clubRatings | #loadingClubRatings =>
    Some({
      clubName: "Shibuya Pickleball Club",
      usingClubRatings,
      isLoading,
      onUseClubRatings: useClub => {
        setUsingClubRatings(_ => useClub)
        onUseClubRatings->Option.forEach(f => f(useClub))
      },
    })
  | _ => None
  }

  <SeedAdjustModal
    players
    onSave={seeds => onSave->Option.forEach(f => f(seeds))}
    onClose
    getUserFragmentRefs
    ?seedSourceOption
  />
}
