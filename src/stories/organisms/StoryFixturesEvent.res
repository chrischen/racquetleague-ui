// Shared fixtures for the event and RSVP stories (batch A). Storybook
// support only; the app never imports this.
//
// A roster of players at a Tokyo pickleball session, and builders that turn
// them into the mock objects `parameters.relay.mocks` takes (Rsvp, User,
// Rating, Payment), so every RSVP story lists the same people. Pictures are
// inline SVG initials, so nothing is fetched over the network.

// Initials on a coloured disc, as an SVG data URI.
let avatarColors = [
  ("#dbeafe", "#1e40af"),
  ("#fce7f3", "#9d174d"),
  ("#dcfce7", "#166534"),
  ("#fef3c7", "#92400e"),
  ("#ede9fe", "#5b21b6"),
  ("#e0f2fe", "#075985"),
  ("#ffe4e6", "#9f1239"),
  ("#ecfccb", "#3f6212"),
  ("#f1f5f9", "#334155"),
]

@genType
let avatar = (name: string, seed: int) => {
  let (bg, fg) =
    avatarColors
    ->Array.get(mod(seed, avatarColors->Array.length))
    ->Option.getOr(("#e5e7eb", "#374151"))
  // First letter of the first two words; a single CJK name keeps one glyph.
  let initials =
    name
    ->String.split(" ")
    ->Array.filter(w => w != "")
    ->Array.slice(~start=0, ~end=2)
    ->Array.map(w => w->String.charAt(0)->String.toUpperCase)
    ->Array.join("")
  let svg =
    `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'>` ++
    `<rect width='64' height='64' fill='${bg}'/>` ++
    `<text x='32' y='33' dominant-baseline='middle' text-anchor='middle' ` ++
    `font-family='Helvetica, Arial, sans-serif' font-size='24' font-weight='600' fill='${fg}'>${initials}</text>` ++ `</svg>`
  "data:image/svg+xml;charset=utf-8," ++ encodeURIComponent(svg)
}

/** A player in the shared roster. `mu` and `sigma` are the pkuru rating on
    the internal (openskill) scale: mu 25 is about DUPR 3.54 and each point of
    mu about 0.04 DUPR. A player without one falls back to a linked DUPR
    rating, then to their self-rating (CombinedRating). */
type player = {
  id: string,
  lineUsername: string,
  fullName: string,
  gender: [#male | #female],
  hasPicture: bool,
  rating: option<(float, float)>,
  duprDoubles: option<float>,
  selfRating: option<float>,
}

let p = (~id, ~name, ~full, ~gender, ~pic=true, ~rating=?, ~dupr=?, ~self=?) => {
  id,
  lineUsername: name,
  fullName: full,
  gender,
  hasPicture: pic,
  rating,
  duprDoubles: dupr,
  selfRating: self,
}

// Strongest first. LINE display names are what the app shows; full names only
// appear on the guest list.
let roster = [
  p(~id="user-yuki", ~name="Yuki", ~full="Tanaka Yuki", ~gender=#female, ~rating=(38.6, 2.4)),
  p(~id="user-kenji", ~name="Kenji W.", ~full="Watanabe Kenji", ~gender=#male, ~rating=(36.1, 3.0)),
  p(~id="user-emily", ~name="Emily", ~full="Emily Carter", ~gender=#female, ~rating=(33.2, 3.9)),
  p(~id="user-haruto", ~name="はると", ~full="Sato Haruto", ~gender=#male, ~rating=(31.4, 2.9)),
  p(~id="user-daniel", ~name="Daniel", ~full="Daniel Kim", ~gender=#male, ~rating=(29.9, 4.6)),
  p(~id="user-sakura", ~name="さくら", ~full="Ito Sakura", ~gender=#female, ~rating=(28.3, 5.4)),
  p(
    ~id="user-rin",
    ~name="Rin",
    ~full="Suzuki Rin",
    ~gender=#female,
    // No games here yet; an established DUPR rating stands in.
    ~dupr=3.71,
  ),
  p(~id="user-takeshi", ~name="Takeshi", ~full="Kobayashi Takeshi", ~gender=#male, ~rating=(26.4, 6.1)),
  p(~id="user-lucas", ~name="Lucas", ~full="Lucas Moreau", ~gender=#male, ~rating=(24.8, 7.2)),
  p(~id="user-aoi", ~name="あおい", ~full="Yamamoto Aoi", ~gender=#female, ~rating=(23.1, 7.9)),
  p(
    ~id="user-tom",
    ~name="Tom",
    ~full="Tom Becker",
    ~gender=#male,
    ~pic=false,
    // Brand new: only his own estimate.
    ~self=18.0,
  ),
  p(~id="user-mei", ~name="Mei", ~full="Nakamura Mei", ~gender=#female, ~rating=(21.5, 8.1)),
  p(~id="user-shota", ~name="翔太", ~full="Kato Shota", ~gender=#male, ~rating=(20.2, 8.3)),
  p(~id="user-olivia", ~name="Olivia", ~full="Olivia Hughes", ~gender=#female, ~rating=(19.6, 8.3)),
]

@genType
type duprMock = {
  doubles: float,
  doublesReliable: bool,
  doublesReliability: float,
}

@genType
type userMock = {
  id: string,
  lineUsername: Js.Null.t<string>,
  fullName: Js.Null.t<string>,
  picture: Js.Null.t<string>,
  gender: Js.Null.t<[#male | #female]>,
  selfRating: Js.Null.t<float>,
  dupr: Js.Null.t<duprMock>,
}

@genType
type ratingMock = {id: string, mu: float, sigma: float, ordinal: float}

/** Payment.status: 0 legacy hold, 1 charged, 2 refunded, 3 charge failed
    (card still on file), 4 pending, 5 card on file. */
@genType
type paymentMock = {
  id: string,
  status: int,
  chargeable: bool,
  currency: string,
  amount: int,
}

/** Rsvp.listType: 0 (or null) the main list, which the event's maxRsvps
    splits into going and waitlist; 1 pending (awaiting the organizer); 2
    invited by the organizer. */
@genType
type rsvpMock = {
  id: string,
  listType: Js.Null.t<int>,
  paid: Js.Null.t<int>,
  message: Js.Null.t<string>,
  payment: Js.Null.t<paymentMock>,
  rating: Js.Null.t<ratingMock>,
  user: userMock,
}

@genType
type edgeMock = {node: rsvpMock}

@genType
type connectionMock = {edges: array<edgeMock>}

let userOf = (player: player, index) => {
  id: player.id,
  lineUsername: Js.Null.return(player.lineUsername),
  fullName: Js.Null.return(player.fullName),
  picture: player.hasPicture
    ? Js.Null.return(avatar(player.lineUsername, index))
    : Js.Null.empty,
  gender: Js.Null.return(player.gender),
  selfRating: player.selfRating->Js.Null.fromOption,
  dupr: player.duprDoubles
  ->Option.map(doubles => {doubles, doublesReliable: true, doublesReliability: 64.})
  ->Js.Null.fromOption,
}

let rsvpOf = (player: player, index) => {
  id: "rsvp-" ++ player.id->String.replace("user-", ""),
  listType: Js.Null.return(0),
  paid: Js.Null.return(0),
  message: Js.Null.empty,
  payment: Js.Null.empty,
  rating: player.rating
  ->Option.map(((mu, sigma)) => {
    id: "rating-" ++ player.id->String.replace("user-", ""),
    mu,
    sigma,
    ordinal: mu -. 3. *. sigma,
  })
  ->Js.Null.fromOption,
  user: userOf(player, index),
}

/** The number of players in the roster. */
@genType
let rosterSize = roster->Array.length

/** The roster's players as users, strongest first. */
@genType
let users = (count: int) =>
  roster->Array.slice(~start=0, ~end=count)->Array.mapWithIndex((player, i) => userOf(player, i))

/** The first `count` roster players as main-list RSVPs (going, unpaid, no
    message), strongest first. */
@genType
let rsvps = (count: int) =>
  roster->Array.slice(~start=0, ~end=count)->Array.mapWithIndex((player, i) => rsvpOf(player, i))

/** RSVPs for the roster players from `start` (0-based), `count` of them. */
@genType
let rsvpsFrom = (start: int, count: int) =>
  roster
  ->Array.slice(~start, ~end=start + count)
  ->Array.mapWithIndex((player, i) => rsvpOf(player, start + i))

/** A yen payment in the given status on the RSVP with this id. */
@genType
let payment = (rsvpId: string, status: int) => {
  id: "payment-" ++ rsvpId,
  status,
  // What the server would charge or capture: a saved card, a failed charge
  // (the card is still on file), or a legacy hold.
  chargeable: status == 5 || status == 3 || status == 0,
  currency: "jpy",
  amount: 1500,
}

/** An Event.rsvps connection. */
@genType
let connection = (nodes: array<rsvpMock>) => {edges: nodes->Array.map(node => {node: node})}

// Fixed dates: Thursday 15 October 2026, 19:00 to 21:00 in Tokyo.
@genType
let startDate = "2026-10-15T10:00:00.000Z"
@genType
let endDate = "2026-10-15T12:00:00.000Z"
