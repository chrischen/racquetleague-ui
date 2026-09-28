// Shared fixtures for the match-play organism stories (batch E1): MatchCard,
// ScoreModal, RoundSection, FullScreenRoundView and the older queue screens.
// Storybook support only; the app never imports this.
//
// One roster serves both halves of a story. `eventMock` turns it into the
// story event and its RSVPs (the TSX passes it as `parameters.relay.mocks.Query.event`),
// and the hooks below read those RSVPs back through the fragments the app
// itself uses (EventManager_event for the round tools, AiTetsu_event for the
// queue screens) and pair each with its roster entry. So a player's name,
// rating, play count and avatar agree everywhere, and the fragment refs handed
// to avatars and name labels are real ones.

module Query = %relay(`
  query StoryFixturesMatchQuery {
    event(id: "evt-story-match") {
      ...AiTetsu_event
      ...EventManager_event
    }
  }
`)

type entry = {
  id: string,
  name: string,
  gender: Rating.Gender.t,
  mu: float,
  sigma: float,
  // Games already played this session: the play count on a player row.
  count: int,
  // Whether the account has a profile picture; the rest show an initial.
  hasPicture: bool,
}

let e = (id, name, gender, mu, sigma, count, hasPicture) => {
  id,
  name,
  gender,
  mu,
  sigma,
  count,
  hasPicture,
}

// Strongest first, the order EventManager numbers players in (#1 is the top
// seed). Ratings are on the internal openskill scale (default 25 ± 8.33).
let roster = [
  e("user-kenji", "Kenji Tanaka", Male, 32.4, 3.1, 3, true),
  e("user-yuki", "Yuki Sato", Female, 30.9, 3.4, 3, true),
  e("user-chris", "Chris Chen", Male, 29.6, 2.8, 2, false),
  e("user-aiko", "Aiko Suzuki", Female, 28.8, 3.9, 3, true),
  e("user-hiroshi", "Hiroshi Watanabe", Male, 27.5, 4.2, 2, true),
  e("user-emily", "Emily Parker", Female, 26.9, 5.1, 2, false),
  e("user-takumi", "Takumi Ito", Male, 26.1, 3.6, 3, true),
  e("user-mai", "Mai Yamamoto", Female, 25.2, 4.8, 2, true),
  e("user-daniel", "Daniel Kim", Male, 24.6, 6.0, 1, false),
  e("user-haruka", "Haruka Nakamura", Female, 23.8, 4.4, 2, true),
  e("user-sota", "Sota Kobayashi", Male, 22.9, 5.5, 2, true),
  e("user-sarah", "Sarah Johnson", Female, 22.1, 6.8, 1, false),
  e("user-ren", "Ren Kato", Male, 21.3, 5.0, 2, true),
  e("user-naomi", "Naomi Yoshida", Female, 20.4, 7.2, 1, true),
  e("user-tom", "Tom Wilson", Male, 19.6, 7.9, 1, false),
  e("user-rina", "Rina Yamada", Female, 18.7, 8.3, 0, true),
  // Long display names, for truncation.
  e("user-alexandra", "Alexandra Montgomery-Fitzgerald", Female, 27.7, 3.8, 2, true),
  e("user-shinnosuke", "Shinnosuke Higashikuninomiya", Male, 26.3, 4.1, 2, false),
  e("user-maximilian", "Maximilian von Hohenberg-Schwarzenau", Male, 24.4, 5.2, 1, true),
  e("user-yukiko", "中村 由紀子 (Tuesday Beginners)", Female, 21.9, 6.1, 1, true),
]

// Roster positions, so presets read as names rather than numbers.
let kenji = 0
let yuki = 1
let chris = 2
let aiko = 3
let hiroshi = 4
let emily = 5
let takumi = 6
let mai = 7
let daniel = 8
let haruka = 9
let sota = 10
let sarah = 11
let ren = 12
let naomi = 13
let tom = 14
let rina = 15
let alexandra = 16
let shinnosuke = 17
let maximilian = 18
let yukiko = 19

// A head-and-shoulders avatar as an inline SVG data URI, so pictures render
// without the network. The seed picks the colours.
let avatarColours = [
  ("#bfdbfe", "#f2c9a8", "#1f2937", "#2563eb"),
  ("#fbcfe8", "#e9b995", "#3b2416", "#db2777"),
  ("#bbf7d0", "#c9936a", "#111827", "#16a34a"),
  ("#fde68a", "#f6d3b8", "#5b3a22", "#d97706"),
  ("#ddd6fe", "#dba27c", "#27272a", "#7c3aed"),
  ("#a5f3fc", "#96603f", "#0a0a0a", "#0891b2"),
]

let avatar = (seed: int) => {
  let (bg, skin, hair, shirt) =
    avatarColours
    ->Array.get(mod(seed, avatarColours->Array.length))
    ->Option.getOr(("#e5e7eb", "#f2c9a8", "#111827", "#475569"))
  let svg =
    `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'>` ++
    `<rect width='80' height='80' fill='${bg}'/>` ++
    `<path d='M10 80c2-17 14-26 30-26s28 9 30 26z' fill='${shirt}'/>` ++
    `<circle cx='40' cy='33' r='15' fill='${skin}'/>` ++
    `<path d='M25 31c0-11 7-17 15-17s15 6 15 17c-4-6-9-8-15-8s-11 2-15 8z' fill='${hair}'/>` ++ `</svg>`
  "data:image/svg+xml;charset=utf-8," ++ Js.Global.encodeURIComponent(svg)
}

// --- Relay mock --------------------------------------------------------------

@genType
type mockUser = {
  id: string,
  lineUsername: string,
  gender: string,
  picture: Js.Null.t<string>,
}
@genType
type mockRating = {id: string, mu: float, sigma: float, ordinal: float}
@genType
type mockRsvp = {id: string, user: mockUser, rating: mockRating}
@genType
type mockEdge = {cursor: string, node: mockRsvp}
@genType
type mockRsvps = {edges: array<mockEdge>}
@genType
type mockEvent = {rsvps: mockRsvps}

/** The story event, one RSVP per roster player: `parameters.relay.mocks: { Query: { event: eventMock } }`. */
@genType
let eventMock: mockEvent = {
  rsvps: {
    edges: roster->Array.mapWithIndex((p, i) => {
      cursor: "cursor-" ++ i->Int.toString,
      node: {
        id: "rsvp-" ++ p.id,
        user: {
          id: p.id,
          lineUsername: p.name,
          gender: switch p.gender {
          | Male => "male"
          | Female => "female"
          },
          picture: p.hasPicture ? Js.Null.return(avatar(i)) : Js.Null.empty,
        },
        rating: {
          id: "rating-" ++ p.id,
          mu: p.mu,
          sigma: p.sigma,
          ordinal: p.mu -. 3. *. p.sigma,
        },
      },
    }),
  },
}

// --- Players -----------------------------------------------------------------

let toPlayer = (p: entry, index: int, data: option<'a>): Rating.Player.t<'a> => {
  let rating = Rating.Rating.make(p.mu, p.sigma)
  {
    data,
    id: p.id,
    intId: index + 1,
    name: p.name,
    rating,
    ratingOrdinal: rating->Rating.Rating.ordinal,
    paid: true,
    gender: p.gender,
    count: p.count,
  }
}

/** The roster with no Relay data, for components that never read a fragment. */
let plainPlayers = (): array<Rating.Player.t<'a>> =>
  roster->Array.mapWithIndex((p, i) => toPlayer(p, i, None))

/** A walk-in added by name at the desk: no account, so no Relay data. */
let guest = (~name, ~gender=Rating.Gender.Male, ~mu=25., ~intId): Rating.Player.t<'a> => {
  let rating = Rating.Rating.make(mu, 25. /. 3.)
  {
    data: None,
    id: "guest-" ++ name,
    intId,
    name,
    rating,
    ratingOrdinal: rating->Rating.Rating.ordinal,
    paid: false,
    gender,
    count: 0,
  }
}

let withData = (nodes: array<'node>, userId: 'node => option<string>) =>
  roster->Array.mapWithIndex((p, i) =>
    toPlayer(p, i, nodes->Array.find(node => userId(node) == Some(p.id)))
  )

/** The roster as the round tools see it: data is an EventManager RSVP node. */
let useManagerPlayers = (): array<Rating.Player.t<Rating.eventManagerRsvpNode>> => {
  let data = Query.use(~variables=())
  let event = RescriptRelay_Fragment.useFragmentOpt(
    ~fRef=data.event->Option.map(event =>
      event.fragmentRefs->EventManager_event_graphql.getFragmentRef
    ),
    ~node=EventManager_event_graphql.node,
    ~convertFragment=EventManager_event_graphql.Internal.convertFragment,
  )
  React.useMemo1(() => {
    let nodes =
      event
      ->Option.map((event: EventManager_event_graphql.Types.fragment) =>
        event.rsvps->EventManager_event_graphql.Utils.getConnectionNodes
      )
      ->Option.getOr([])
    nodes->withData(node => node.user->Option.map(user => user.id))
  }, [event])
}

/** The roster as the queue screens see it: data is an AiTetsu RSVP node. */
let useQueuePlayers = (): array<Rating.Player.t<Rating.rsvpNode>> => {
  let data = Query.use(~variables=())
  let event = RescriptRelay_Fragment.useFragmentOpt(
    ~fRef=data.event->Option.map(event => event.fragmentRefs->AiTetsu_event_graphql.getFragmentRef),
    ~node=AiTetsu_event_graphql.node,
    ~convertFragment=AiTetsu_event_graphql.Internal.convertFragment,
  )
  React.useMemo1(() => {
    let nodes =
      event
      ->Option.map((event: AiTetsu_event_graphql.Types.fragment) =>
        event.rsvps->AiTetsu_event_graphql.Utils.getConnectionNodes
      )
      ->Option.getOr([])
    nodes->withData(node => node.user->Option.map(user => user.id))
  }, [event])
}

/** EventManager's own accessor for a player's user fragment refs. */
let getUserFragmentRefs = (node: Rating.eventManagerRsvpNode) =>
  node.user->Option.map(user => user.fragmentRefs)

// --- Matches and rounds ------------------------------------------------------

let at = (players: array<Rating.Player.t<'a>>, i) => players->Array.getUnsafe(i)

/** A doubles match from roster positions: (a, b) versus (c, d). */
let doubles = (players, (a, b), (c, d)): Rating.Match.t<'a> => (
  [players->at(a), players->at(b)],
  [players->at(c), players->at(d)],
)

let createdAt = Js.Date.fromString("2026-10-15T10:00:00.000Z")

/** A match on the round board. The id is also MatchCard's service key. */
let entity = (~id, ~score=?, match): Rating.completedMatchEntity<'a> => {
  id,
  match,
  score,
  createdAt,
  synced: score->Option.isSome,
}

// Three rounds of a Thursday night: 16 players checked in, three courts, so
// four sit out each round. Round 1 is finished (court 3 was settled by tapping
// the winner, with no score), round 2 is being played (court 1 is in), round 3
// is drawn but not started. Round 3 repeats round 1's court 1 exactly and
// reuses a round-2 pairing (Chris/Haruka), so its history warnings show.
let round1 = players => [
  entity(~id="evt-r1-c1", ~score=(11., 8.), doubles(players, (kenji, mai), (yuki, takumi))),
  entity(~id="evt-r1-c2", ~score=(9., 11.), doubles(players, (chris, sarah), (aiko, daniel))),
  entity(~id="evt-r1-c3", ~score=(1., -1.), doubles(players, (hiroshi, naomi), (emily, sota))),
]

let round2 = players => [
  entity(~id="evt-r2-c1", ~score=(11., 7.), doubles(players, (kenji, rina), (yuki, tom))),
  entity(~id="evt-r2-c2", doubles(players, (chris, haruka), (aiko, ren))),
  entity(~id="evt-r2-c3", doubles(players, (hiroshi, mai), (takumi, emily))),
]

let round3 = players => [
  entity(~id="evt-r3-c1", doubles(players, (kenji, mai), (yuki, takumi))),
  entity(~id="evt-r3-c2", doubles(players, (chris, haruka), (daniel, sarah))),
  entity(~id="evt-r3-c3", doubles(players, (aiko, sota), (naomi, ren))),
]

let rounds = players => [round1(players), round2(players), round3(players)]

/** Everyone checked in tonight: the 16 regulars (not the long-name players). */
let checkedInIds = (players: array<Rating.Player.t<'a>>) =>
  players->Array.slice(~start=0, ~end=16)->Array.map(p => p.id)->Set.fromArray

/** Games played so far tonight, per player, as the session tracks them. */
let session = (players: array<Rating.Player.t<'a>>): Session.t =>
  players
  ->Array.map(p => (p.id, {Session.PlayerState.count: p.count, paid: p.paid}))
  ->Js.Dict.fromArray

let ratingRange = (players: array<Rating.Player.t<'a>>) => {
  let mus = players->Array.map(p => p.rating.mu)
  (
    mus->Array.reduce(100., (acc, mu) => mu < acc ? mu : acc),
    mus->Array.reduce(0., (acc, mu) => mu > acc ? mu : acc),
  )
}

/** "Kenji Tanaka & Mai Yamamoto vs Yuki Sato & Takumi Ito", for action logs. */
let describe = ((team1, team2): Rating.Match.t<'a>) => {
  let names = (team: Rating.Team.t<'a>) => team->Array.map(p => p.name)->Array.join(" & ")
  names(team1) ++ " vs " ++ names(team2)
}
