// Shared fixtures for the navigation, profile, club and rating stories
// (batch D). Storybook support only; the app never imports this.
//
// A roster of players used by the rating list, rating graph, match history
// and member autocomplete stories, and a portrait generator so avatars have a
// picture without fetching anything over the network.

// A simple head-and-shoulders portrait as an inline SVG data URI. Different
// seeds give different background, skin, hair and shirt colours.
let palettes = [
  ("#dbeafe", "#f1c7a5", "#2b1d14", "#1d4ed8"),
  ("#fce7f3", "#e8b894", "#4a2c1a", "#be185d"),
  ("#dcfce7", "#c68e63", "#111827", "#15803d"),
  ("#fef3c7", "#f5d0b5", "#6b4226", "#b45309"),
  ("#ede9fe", "#d9a07a", "#1f2937", "#6d28d9"),
  ("#e0f2fe", "#8d5a3b", "#0b0b0b", "#0369a1"),
  ("#ffe4e6", "#f3c9a8", "#a16207", "#e11d48"),
  ("#ecfccb", "#e2ad86", "#3f2a1d", "#4d7c0f"),
]

@genType
let portrait = (seed: int) => {
  let (bg, skin, hair, shirt) =
    palettes->Array.get(mod(seed, palettes->Array.length))->Option.getOr(("#e5e7eb", "#f1c7a5", "#111827", "#374151"))
  let svg =
    `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 96 96'>` ++
    `<rect width='96' height='96' fill='${bg}'/>` ++
    `<path d='M14 96c3-21 17-31 34-31s31 10 34 31z' fill='${shirt}'/>` ++
    `<rect x='42' y='52' width='12' height='14' rx='5' fill='${skin}'/>` ++
    `<circle cx='48' cy='40' r='17' fill='${skin}'/>` ++
    `<path d='M30 39c0-13 8-20 18-20s18 7 18 20c-4-7-10-10-18-10s-14 3-18 10z' fill='${hair}'/>` ++ `</svg>`
  "data:image/svg+xml;charset=utf-8," ++ encodeURIComponent(svg)
}

/** A player in the shared roster. `mu` and `sigma` are on the internal
    (openskill) scale: mu 25 is about DUPR 3.54, and each point of mu is about
    0.04 DUPR. The rating list's ordinal is mu - 3 * sigma. */
@genType
type player = {
  id: string,
  lineUsername: string,
  fullName: string,
  gender: [#male | #female],
  picture: Js.Null.t<string>,
  mu: float,
  sigma: float,
  daysNumberOne: float,
}

let p = (~id, ~lineUsername, ~fullName, ~gender, ~photo=?, ~mu, ~sigma, ~days=0.) => {
  id,
  lineUsername,
  fullName,
  gender,
  picture: photo->Option.map(portrait)->Js.Null.fromOption,
  mu,
  sigma,
  daysNumberOne: days,
}

/** Twenty-two players, strongest first by ordinal (mu - 3 * sigma), the order
    the server returns rankings in. Twelve men and ten women, some with a
    picture, some with a Japanese display name. */
@genType
let roster: array<player> = [
  p(~id="user-kenji", ~lineUsername="Kenji", ~fullName="Kenji Watanabe", ~gender=#male, ~photo=0, ~mu=41.8, ~sigma=2.1, ~days=46.),
  p(~id="user-aki", ~lineUsername="Aki", ~fullName="Aki Tanaka", ~gender=#female, ~photo=1, ~mu=40.2, ~sigma=2.3, ~days=38.5),
  p(~id="user-dan", ~lineUsername="Dan B.", ~fullName="Daniel Brooks", ~gender=#male, ~photo=2, ~mu=39.6, ~sigma=2.4, ~days=4.),
  p(~id="user-yuki", ~lineUsername="ゆき", ~fullName="Yuki Sato", ~gender=#female, ~mu=38.1, ~sigma=2.2, ~days=12.5),
  p(~id="user-takumi", ~lineUsername="たくみ", ~fullName="Takumi Suzuki", ~gender=#male, ~photo=4, ~mu=37.9, ~sigma=2.6),
  p(~id="user-haruka", ~lineUsername="Haruka", ~fullName="Haruka Ito", ~gender=#female, ~photo=3, ~mu=36.4, ~sigma=2.5),
  p(~id="user-ryo", ~lineUsername="Ryo", ~fullName="Ryo Yamamoto", ~gender=#male, ~mu=35.8, ~sigma=2.4),
  p(~id="user-emily", ~lineUsername="Emily", ~fullName="Emily Carter", ~gender=#female, ~photo=6, ~mu=35.1, ~sigma=2.7),
  p(~id="user-sho", ~lineUsername="Sho", ~fullName="Sho Nakamura", ~gender=#male, ~photo=5, ~mu=34.7, ~sigma=2.7),
  p(~id="user-chris", ~lineUsername="Chris", ~fullName="Chris Chen", ~gender=#male, ~photo=7, ~mu=33.9, ~sigma=2.8),
  p(~id="user-mai", ~lineUsername="Mai", ~fullName="Mai Kobayashi", ~gender=#female, ~mu=33.2, ~sigma=2.6),
  p(~id="user-lucas", ~lineUsername="Lucas", ~fullName="Lucas Moreau", ~gender=#male, ~mu=32.8, ~sigma=3.1),
  p(~id="user-olivia", ~lineUsername="Olivia", ~fullName="Olivia Park", ~gender=#female, ~photo=1, ~mu=31.9, ~sigma=3.0),
  p(~id="user-hiroshi", ~lineUsername="Hiroshi", ~fullName="Hiroshi Kato", ~gender=#male, ~mu=31.5, ~sigma=3.2),
  p(~id="user-sakura", ~lineUsername="さくら", ~fullName="Sakura Hayashi", ~gender=#female, ~photo=6, ~mu=30.4, ~sigma=3.1),
  p(~id="user-kaito", ~lineUsername="Kaito", ~fullName="Kaito Mori", ~gender=#male, ~photo=2, ~mu=29.8, ~sigma=3.3),
  p(~id="user-naomi", ~lineUsername="Naomi", ~fullName="Naomi Fujita", ~gender=#female, ~mu=28.7, ~sigma=3.4),
  p(~id="user-mike", ~lineUsername="Mike", ~fullName="Michael O'Connor", ~gender=#male, ~photo=0, ~mu=28.1, ~sigma=3.6),
  p(~id="user-jess", ~lineUsername="Jess", ~fullName="Jessica Lin", ~gender=#female, ~photo=4, ~mu=27.2, ~sigma=3.8),
  p(~id="user-taro", ~lineUsername="Taro", ~fullName="Taro Yoshida", ~gender=#male, ~mu=26.4, ~sigma=4.1),
  p(~id="user-aoi", ~lineUsername="Aoi", ~fullName="Aoi Shimizu", ~gender=#female, ~photo=3, ~mu=25.3, ~sigma=4.6),
  p(~id="user-ren", ~lineUsername="Ren", ~fullName="Ren Ishikawa", ~gender=#male, ~mu=24.1, ~sigma=5.2),
]
