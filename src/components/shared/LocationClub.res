%%raw("import { t } from '@lingui/macro'")

// Clubs that are a physical venue rather than a group of people: every event
// is open play at the club's home court, with a fixed player cap. Today that
// is only Picklr, matched by slug; this config is what a future "location
// club" flag on Club would carry, so callers ask `ofSlug` and never compare
// slugs themselves.
type t = {
  slug: string,
  // The home court's production id; the dev database carries a stub under it.
  homeLocationId: string,
  // The player cap every open play starts with.
  maxPlayers: int,
}

let all = [
  {slug: "picklr", homeLocationId: "Location_8a23aff0-b167-11f1-aa11-5f94af570e5c", maxPlayers: 6},
]

let ofSlug = (slug: option<string>): option<t> =>
  slug->Option.flatMap(s => all->Array.find(c => c.slug == s))

// Translated, so resolved during a component's render rather than held in a
// constant.
let useOpenPlayTitle = () => Lingui.UtilString.t`Open Play`

// Prefill for a location club's create-event links: home court, title and
// player cap. Empty for every other club.
let useCreatePrefillParams = (~slug: option<string>): array<(string, string)> => {
  let title = useOpenPlayTitle()
  switch ofSlug(slug) {
  | Some(club) => [
      ("locationId", club.homeLocationId),
      ("title", title),
      ("maxRsvps", club.maxPlayers->Int.toString),
    ]
  | None => []
  }
}
