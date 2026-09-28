// Shared fixtures for the discovery, availability and planning stories
// (batch C). Storybook support only; the app never imports this.
//
// One Tokyo pickleball fortnight seen from Wednesday 14 October 2026, 09:00:
// a dozen events over six days (open, almost full, full with a waitlist,
// canceled, private, uncapped, a venue booking forwarded by email), the
// players who shared when they can play, the courts left open at six venues,
// and the viewer's own saved windows. The Relay stories take these as mocks;
// the props-only stories build the same courts and players as TimeWindow
// values, so every surface shows the same week.
//
// Players come from StoryFixturesEvent's roster (same ids, names, avatars).

// ─── The clock ────────────────────────────────────────────────────────────────

/** The stories' "now": Wednesday 14 October 2026, 09:00 in Tokyo. */
@genType
let now = "2026-10-14T00:00:00.000Z"

/** The availability window the event pages ask for (EventsListUtils: two weeks). */
@genType
let fromDate = "2026-10-14"
@genType
let toDate = "2026-10-28"

/** A story `beforeEach`: runs the clock from `now` (still ticking, so timers
    and debounces behave), and restores the real clock afterwards. The lists
    bucket events into Today / Tomorrow / weekday by the current date and the
    rows grey out a passed cancel deadline, so without this the same fixtures
    would read differently every day. */
@genType
let shiftClock: unit => unit => unit = %raw(`
  function () {
    var RealDate = globalThis.Date;
    var offset = RealDate.parse("2026-10-14T00:00:00.000Z") - RealDate.now();
    class ShiftedDate extends RealDate {
      constructor(...args) {
        if (args.length === 0) super(RealDate.now() + offset);
        else super(...args);
      }
      static now() {
        return RealDate.now() + offset;
      }
      // Dates made before the shift (a library's module-level constants)
      // are still Dates.
      static [Symbol.hasInstance](value) {
        return value instanceof RealDate;
      }
    }
    globalThis.Date = ShiftedDate;
    return function () {
      globalThis.Date = RealDate;
    };
  }
`)

// Days of the fortnight ("YYYY-MM-DD", Tokyo).
let wed14 = "2026-10-14"
let thu15 = "2026-10-15"
let fri16 = "2026-10-16"
let sat17 = "2026-10-17"
let sun18 = "2026-10-18"
let mon19 = "2026-10-19"
let tue20 = "2026-10-20"
let thu22 = "2026-10-22"
let sat24 = "2026-10-24"
let sun25 = "2026-10-25"

let pad2 = n => n->Int.toString->String.padStart(2, "0")

/** The instant (ISO, UTC) of a Tokyo wall-clock time; hour 19.5 is 19:30. */
let tokyo = (date: string, hour: float) => {
  let h = hour->Js.Math.floor_int
  let m = ((hour -. h->Int.toFloat) *. 60.)->Js.Math.round->Float.toInt
  Js.Date.fromString(`${date}T${pad2(h)}:${pad2(m)}:00+09:00`)->Js.Date.toISOString
}

/** The Tokyo calendar day of an instant, as "YYYY-MM-DD". */
let tokyoDay = (date: Js.Date.t) =>
  Js.Date.fromFloat(date->Js.Date.getTime +. 9. *. 3600000.)
  ->Js.Date.toISOString
  ->String.slice(~start=0, ~end=10)

// ─── Places and clubs ─────────────────────────────────────────────────────────

@genType
type placeMock = {id: string, name: string}

let toyosu = {id: "loc-toyosu", name: "Toyosu Riverside Courts"}
let ginza = {id: "loc-ginza", name: "PickleOne Ginza"}
let shibuya = {id: "loc-shibuya", name: "Shibuya Sports Center"}
let minato = {id: "loc-minato", name: "Minato Sports Center"}
let ota = {id: "loc-ota", name: "Ota City General Gymnasium"}
let setagaya = {id: "loc-setagaya", name: "Setagaya Sogo Undojo"}
let picklrCourt = {id: "loc-picklr", name: "Picklr Tokyo, Toyosu"}

@genType
type clubMock = {id: string, name: string, slug: string}

/** The viewer's club. */
@genType
let tokyoClub = {id: "club-tpc", name: "Tokyo Pickleball Club", slug: "tokyo-pickleball"}
let shibuyaClub = {id: "club-spc", name: "Shibuya Pickleball Club", slug: "shibuya-pickleball"}
/** A location club (LocationClub): every event is open play at its home court. */
@genType
let picklrClub = {id: "club-picklr", name: "Picklr Tokyo", slug: "picklr"}

@genType
type coordsMock = {lat: float, lng: float}
@genType
type resolvedLocationMock = {coords: coordsMock, region: Js.Null.t<string>}

/** Query.resolvedLocation for a list scoped to the Tokyo default. */
@genType
let resolvedTokyo = {coords: {lat: 35.6812, lng: 139.7671}, region: Js.Null.return("tokyo")}

// ─── The viewer ───────────────────────────────────────────────────────────────

/** The signed-in player, with a complete profile so joining and sharing
    availability are not gated. Give it as both viewer.user and
    viewer.profile (one User record). */
@genType
type viewerUserMock = {
  id: string,
  lineUsername: string,
  fullName: string,
  email: string,
  biography: string,
  selfRating: float,
  picture: string,
  gender: string,
  locale: string,
}

@genType
let viewerUser = {
  id: "user-1",
  lineUsername: "Chris",
  fullName: "Chris Chen",
  email: "player@example.com",
  biography: "Weeknight doubles, mostly in Minato.",
  // Internal scale; about DUPR 3.25.
  selfRating: 17.4,
  picture: StoryFixturesEvent.avatar("Chris", 4),
  gender: "male",
  locale: "en",
}

let viewerAsUser: StoryFixturesEvent.userMock = {
  id: viewerUser.id,
  lineUsername: Js.Null.return(viewerUser.lineUsername),
  fullName: Js.Null.return(viewerUser.fullName),
  picture: Js.Null.return(viewerUser.picture),
  gender: Js.Null.return(#male),
  selfRating: Js.Null.return(viewerUser.selfRating),
  dupr: Js.Null.empty,
}

// ─── Events ───────────────────────────────────────────────────────────────────

@genType
type eventMock = {
  id: string,
  title: string,
  startDate: string,
  endDate: string,
  timezone: string,
  location: placeMock,
  club: Js.Null.t<clubMock>,
  maxRsvps: Js.Null.t<int>,
  rsvps: StoryFixturesEvent.connectionMock,
  shadow: bool,
  listed: bool,
  deleted: Js.Null.t<string>,
  tags: array<string>,
  cancelDeadline: Js.Null.t<int>,
}

// Who is on an event, in join order: a roster player by index, or the viewer.
type joiner = P(int) | Viewer | ViewerPending

let players = (indices: array<int>) => indices->Array.map(i => P(i))

let shortId = (id: string) => id->String.replace("user-", "")

let event = (
  ~id,
  ~title,
  ~date,
  ~start,
  ~hours,
  ~venue,
  ~club=?,
  ~max=?,
  ~joiners: array<joiner>,
  // Added to every player's rating mu, so a strong session reads as one on
  // the row's average-DUPR badge (4.0 is about mu 37, 4.5 about mu 50).
  ~boost=0.,
  ~tags=[],
  ~shadow=false,
  ~listed=true,
  ~deleted=?,
  ~cancelHours=?,
) => {
  let short = id->String.replace("evt-", "")
  let rsvp = joiner =>
    switch joiner {
    | P(i) =>
      let player = StoryFixturesEvent.roster->Array.getUnsafe(i)
      let base = StoryFixturesEvent.rsvpOf(player, i)
      let rsvpId = `rsvp-${short}-${player.id->shortId}`
      {
        ...base,
        id: rsvpId,
        // Per event, so the boosted value never merges with another event's.
        rating: base.rating
        ->Js.Null.toOption
        ->Option.map(r => {
          ...r,
          id: rsvpId ++ "-rating",
          mu: r.mu +. boost,
          ordinal: r.mu +. boost -. 3. *. r.sigma,
        })
        ->Js.Null.fromOption,
      }
    | Viewer | ViewerPending => {
        id: `rsvp-${short}-viewer`,
        listType: Js.Null.return(joiner == ViewerPending ? 1 : 0),
        paid: Js.Null.return(0),
        message: Js.Null.empty,
        payment: Js.Null.empty,
        rating: Js.Null.empty,
        user: viewerAsUser,
      }
    }
  {
    id,
    title,
    startDate: tokyo(date, start),
    endDate: tokyo(date, start +. hours),
    timezone: "Asia/Tokyo",
    location: venue,
    club: club->Js.Null.fromOption,
    maxRsvps: max->Js.Null.fromOption,
    rsvps: StoryFixturesEvent.connection(joiners->Array.map(rsvp)),
    shadow,
    listed,
    deleted: deleted->Js.Null.fromOption,
    tags,
    cancelDeadline: cancelHours->Option.map(h => h * 3600000)->Js.Null.fromOption,
  }
}

// Roster indices (StoryFixturesEvent, strongest first): 0 Yuki, 1 Kenji W.,
// 2 Emily, 3 はると, 4 Daniel, 5 さくら, 6 Rin, 7 Takeshi, 8 Lucas, 9 あおい,
// 10 Tom, 11 Mei, 12 翔太, 13 Olivia.

let morningOpen = event(
  ~id="evt-morning-open",
  ~title="Morning Open Play",
  ~date=wed14,
  ~start=10.,
  ~hours=2.,
  ~venue=toyosu,
  ~club=tokyoClub,
  ~max=12,
  ~joiners=players([4, 5, 7, 8, 9, 11, 12]),
  ~tags=["all level"],
)

// A court booking forwarded by email: tracked, not joinable here.
let ginzaBooking = event(
  ~id="evt-ginza-booking",
  ~title="Court booking · PickleOne Ginza, Court 2",
  ~date=wed14,
  ~start=18.,
  ~hours=2.,
  ~venue=ginza,
  ~max=4,
  ~joiners=players([0, 1, 2, 3]),
  ~shadow=true,
  ~listed=false,
)

// Full; the viewer joined ninth, so waitlisted, and the 24-hour cancel
// deadline has passed.
let wednesdayDoubles = event(
  ~id="evt-wed-doubles",
  ~title="Wednesday Night Doubles",
  ~date=wed14,
  ~start=19.,
  ~hours=2.,
  ~venue=shibuya,
  ~club=shibuyaClub,
  ~max=8,
  ~joiners=[...players([0, 1, 2, 3, 4, 5, 6, 7]), Viewer, P(8)],
  ~tags=["3.5+", "comp"],
  ~cancelHours=24,
)

// Two spots left; the viewer is in.
let thursdayDoubles = event(
  ~id="evt-thu-doubles",
  ~title="Thursday Doubles",
  ~date=thu15,
  ~start=19.,
  ~hours=2.,
  ~venue=minato,
  ~club=tokyoClub,
  ~max=12,
  ~joiners=[...players([2, 3, 4]), Viewer, ...players([5, 6, 7, 8, 9, 10])],
  ~tags=["3.0+"],
  ~cancelHours=24,
)

let earlyDrills = event(
  ~id="evt-early-drills",
  ~title="朝活ドリル · Early Bird Drills",
  ~date=thu15,
  ~start=7.,
  ~hours=1.5,
  ~venue=ota,
  ~max=8,
  ~joiners=players([9, 10, 13]),
  ~tags=["drill"],
)

let advancedInvitational = event(
  ~id="evt-advanced",
  ~title="Advanced Invitational",
  ~date=fri16,
  ~start=7.,
  ~hours=2.,
  ~venue=minato,
  ~max=8,
  ~joiners=players([0, 1, 2, 3, 4, 5]),
  ~boost=19.,
  ~tags=["4.5+", "comp", "dupr"],
)

let lunchRally = event(
  ~id="evt-lunch-rally",
  ~title="Friday Lunch Rally",
  ~date=fri16,
  ~start=12.,
  ~hours=2.,
  ~venue=toyosu,
  ~club=tokyoClub,
  ~max=8,
  ~joiners=players([5, 8, 11, 13, 12]),
  ~tags=["rec"],
  ~deleted="2026-10-12T03:00:00.000Z",
)

// Full, two on the waitlist.
let fridayRated = event(
  ~id="evt-fri-rated",
  ~title="Friday Rated Session",
  ~date=fri16,
  ~start=19.5,
  ~hours=2.5,
  ~venue=minato,
  ~club=tokyoClub,
  ~max=12,
  ~joiners=players([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]),
  ~boost=6.,
  ~tags=["4.0+", "comp"],
  ~cancelHours=48,
)

// Private (unlisted); the viewer is in.
let weekendRoundRobin = event(
  ~id="evt-weekend-rr",
  ~title="Weekend Round Robin — all levels welcome, paddles available to borrow",
  ~date=sat17,
  ~start=9.,
  ~hours=3.,
  ~venue=setagaya,
  ~club=tokyoClub,
  ~max=24,
  ~joiners=[...players([0, 1, 2, 3, 4]), Viewer, ...players([5, 6, 7, 8, 9, 10, 11, 12])],
  ~tags=["all level"],
  ~listed=false,
)

// No cap: a player count instead of a bar.
let beginnersClinic = event(
  ~id="evt-beginners",
  ~title="Beginners Clinic",
  ~date=sat17,
  ~start=13.,
  ~hours=3.,
  ~venue=ota,
  ~joiners=players([10, 12, 13, 11, 9, 8]),
  ~tags=["rec"],
)

// The viewer asked to join; the organizer hasn't answered.
let sundaySocial = event(
  ~id="evt-sunday-social",
  ~title="Sunday Social",
  ~date=sun18,
  ~start=10.,
  ~hours=2.,
  ~venue=toyosu,
  ~club=shibuyaClub,
  ~max=16,
  ~joiners=[...players([1, 5, 6, 9, 11, 13]), ViewerPending],
  ~tags=["rec"],
)

let ladiesNight = event(
  ~id="evt-ladies-night",
  ~title="Ladies' Night Doubles",
  ~date=tue20,
  ~start=19.,
  ~hours=2.,
  ~venue=shibuya,
  ~max=8,
  ~joiners=players([0, 2, 5, 9]),
  ~tags=["3.0+"],
)

let clubLadder = event(
  ~id="evt-club-ladder",
  ~title="Club Ladder Night",
  ~date=thu22,
  ~start=19.,
  ~hours=2.5,
  ~venue=minato,
  ~club=tokyoClub,
  ~max=16,
  ~joiners=players([1, 3, 4, 7, 8, 12]),
  ~tags=["3.5+", "comp"],
)

/** The Discover feed, in start order: six days, twelve events. */
@genType
let discoverEvents = [
  morningOpen,
  ginzaBooking,
  wednesdayDoubles,
  earlyDrills,
  thursdayDoubles,
  advancedInvitational,
  lunchRally,
  fridayRated,
  weekendRoundRobin,
  beginnersClinic,
  sundaySocial,
  ladiesNight,
]

/** The events the viewer is on (joined, waitlisted or pending). */
@genType
let viewerEvents = [wednesdayDoubles, thursdayDoubles, weekendRoundRobin, sundaySocial]

/** Tokyo Pickleball Club's schedule. */
@genType
let clubEvents = [
  morningOpen,
  thursdayDoubles,
  lunchRally,
  fridayRated,
  weekendRoundRobin,
  clubLadder,
]

let openPlay = (~id, ~date, ~start, ~joiners, ~tags) =>
  event(
    ~id,
    ~title="Open Play",
    ~date,
    ~start,
    ~hours=2.,
    ~venue=picklrCourt,
    ~club=picklrClub,
    ~max=6,
    ~joiners,
    ~tags,
    ~listed=false,
    ~cancelHours=24,
  )

/** A location club's week: open play at its home court, six players each. */
@genType
let picklrEvents = [
  openPlay(
    ~id="evt-picklr-wed",
    ~date=wed14,
    ~start=18.,
    ~joiners=players([2, 4, 7, 8]),
    ~tags=["all level"],
  ),
  openPlay(
    ~id="evt-picklr-thu",
    ~date=thu15,
    ~start=20.,
    ~joiners=players([0, 1, 3, 5, 6, 7]),
    ~tags=["3.5+"],
  ),
  openPlay(
    ~id="evt-picklr-sat",
    ~date=sat17,
    ~start=10.,
    ~joiners=[P(9), Viewer, P(12)],
    ~tags=["all level"],
  ),
  openPlay(~id="evt-picklr-sun", ~date=sun18, ~start=16., ~joiners=[], ~tags=["3.0+"]),
]

/** Events by id, for picking single rows. */
@genType
let eventById = (id: string) =>
  [...discoverEvents, clubLadder]->Array.find(e => e.id == id)->Js.Null.fromOption

@genType
type eventEdgeMock = {node: eventMock}
@genType
type pageInfoMock = {
  hasNextPage: bool,
  hasPreviousPage: bool,
  startCursor: Js.Null.t<string>,
  endCursor: Js.Null.t<string>,
}
@genType
type eventConnectionMock = {edges: array<eventEdgeMock>, pageInfo: pageInfoMock}

/** An EventConnection over `events`; `more` says there are pages on both sides. */
@genType
let eventsConnection = (events: array<eventMock>, more: bool) => {
  edges: events->Array.map(node => {node: node}),
  pageInfo: {
    hasNextPage: more,
    hasPreviousPage: more,
    startCursor: more ? Js.Null.return("cursor-start") : Js.Null.empty,
    endCursor: more ? Js.Null.return("cursor-end") : Js.Null.empty,
  },
}

// ─── Availability ─────────────────────────────────────────────────────────────

@genType
type intervalMock = {startHour: int, endHour: int}

/** An AvailabilityDay: a player's windows for one day. */
@genType
type availabilityDayMock = {
  id: string,
  localDate: string,
  user: Js.Null.t<StoryFixturesEvent.userMock>,
  intervals: array<intervalMock>,
}

let windows = spans => spans->Array.map(((startHour, endHour)) => {startHour, endHour})

// The viewer's saved windows.
let viewerWindows = [
  (wed14, [(18, 22)]),
  (sat17, [(9, 13)]),
  (mon19, [(19, 22)]),
  (thu22, [(18, 21)]),
]

/** viewer.availability. */
@genType
let viewerAvailability = viewerWindows->Array.map(((date, spans)) => {
  id: "avail-viewer-" ++ date,
  localDate: date,
  user: Js.Null.empty,
  intervals: windows(spans),
})

// Other players' windows: (day, roster index, spans).
let playerWindows = [
  (wed14, 0, [(18, 22)]),
  (wed14, 1, [(7, 9), (19, 22)]),
  (wed14, 2, [(17, 21)]),
  (wed14, 3, [(12, 15)]),
  (wed14, 5, [(19, 23)]),
  (wed14, 7, [(18, 21)]),
  (thu15, 4, [(18, 21)]),
  (thu15, 6, [(7, 9)]),
  (thu15, 9, [(19, 22)]),
  (fri16, 8, [(19, 22)]),
  (fri16, 11, [(12, 14)]),
  (sat17, 0, [(9, 12)]),
  (sat17, 2, [(8, 11)]),
  (sat17, 4, [(9, 13)]),
  (sat17, 5, [(10, 14)]),
  (sat17, 7, [(13, 17)]),
  (sat17, 10, [(9, 12)]),
  (sat17, 12, [(14, 18)]),
  (sat17, 13, [(9, 11)]),
  (sun18, 1, [(10, 13)]),
  (sun18, 9, [(10, 12)]),
  (sun18, 11, [(9, 12)]),
  (sun18, 13, [(12, 15)]),
  (mon19, 2, [(19, 22)]),
  (mon19, 8, [(18, 21)]),
  (tue20, 0, [(19, 21)]),
  (thu22, 1, [(18, 21)]),
  (thu22, 10, [(19, 22)]),
  (sat24, 3, [(9, 12)]),
  (sat24, 4, [(10, 13)]),
  (sat24, 6, [(9, 11)]),
  (sat24, 11, [(13, 16)]),
  (sat24, 13, [(9, 12)]),
  (sun25, 5, [(10, 12)]),
  (sun25, 7, [(9, 12)]),
  (sun25, 12, [(13, 15)]),
]

/** Query.availabilityUsersForDateRange: everyone else's windows. */
@genType
let playerAvailability = playerWindows->Array.map(((date, i, spans)) => {
  let player = StoryFixturesEvent.roster->Array.getUnsafe(i)
  {
    id: `avail-${player.id->shortId}-${date}`,
    localDate: date,
    user: Js.Null.return(StoryFixturesEvent.userOf(player, i)),
    intervals: windows(spans),
  }
})

// ─── Courts ───────────────────────────────────────────────────────────────────

// A venue's openings on one day, as hourly blocks: (from, to, indoor courts,
// outdoor courts). Adjacent blocks read as one opening; a gap splits it.
type opening = {
  venue: placeMock,
  link: option<string>,
  date: string,
  blocks: array<(int, int, int, int)>,
  price: (int, int),
}

let toyosuLink = Some("https://reserva.be/toyosuriverside")
let ginzaLink = Some("https://reserva.be/pboneginza")
let minatoLink = Some("https://www.minatoku-sports.com/reserve")
let shibuyaLink = Some("https://shibuya-sports.jp/yoyaku")
let otaLink = Some("https://www.ota-sports.jp/reserve")
let setagayaLink = Some("https://setagaya-sports.jp/yoyaku")

let openings = [
  {venue: ota, link: otaLink, date: wed14, blocks: [(7, 9, 2, 0)], price: (1200, 1200)},
  {
    venue: toyosu,
    link: toyosuLink,
    date: wed14,
    blocks: [(13, 15, 0, 2), (15, 17, 0, 1)],
    price: (2200, 2800),
  },
  {
    venue: ginza,
    link: ginzaLink,
    date: wed14,
    blocks: [(15, 18, 1, 0), (20, 22, 1, 0)],
    price: (4400, 5500),
  },
  {
    venue: minato,
    link: minatoLink,
    date: wed14,
    blocks: [(18, 19, 3, 0), (19, 21, 2, 0)],
    price: (1800, 2400),
  },
  {venue: toyosu, link: toyosuLink, date: thu15, blocks: [(7, 10, 0, 2)], price: (2200, 2200)},
  {
    venue: shibuya,
    link: shibuyaLink,
    date: thu15,
    blocks: [(17, 19, 2, 0), (19, 22, 1, 0)],
    price: (1600, 2000),
  },
  {venue: toyosu, link: toyosuLink, date: sat17, blocks: [(8, 12, 0, 3)], price: (2800, 3300)},
  {venue: ginza, link: ginzaLink, date: sat17, blocks: [(9, 11, 1, 0)], price: (5500, 5500)},
  {
    venue: setagaya,
    link: setagayaLink,
    date: sat17,
    blocks: [(13, 16, 4, 0), (16, 18, 2, 0)],
    price: (1500, 1900),
  },
  {venue: toyosu, link: toyosuLink, date: sun18, blocks: [(9, 15, 0, 2)], price: (2800, 3300)},
  {venue: minato, link: minatoLink, date: sun18, blocks: [(12, 17, 3, 0)], price: (1800, 2400)},
  {venue: minato, link: minatoLink, date: mon19, blocks: [(18, 22, 2, 0)], price: (1800, 2400)},
  {venue: shibuya, link: shibuyaLink, date: tue20, blocks: [(19, 22, 1, 0)], price: (1600, 1600)},
  {venue: minato, link: minatoLink, date: thu22, blocks: [(18, 21, 2, 0)], price: (1800, 2400)},
  {venue: toyosu, link: toyosuLink, date: sat24, blocks: [(8, 12, 0, 3)], price: (2800, 3300)},
  {
    venue: setagaya,
    link: setagayaLink,
    date: sat24,
    blocks: [(13, 18, 3, 0)],
    price: (1500, 1900),
  },
  {venue: toyosu, link: toyosuLink, date: sun25, blocks: [(9, 13, 0, 2)], price: (2800, 3300)},
]

// Contiguous blocks merged into openings.
let spansOf = (blocks: array<(int, int, int, int)>) =>
  blocks->Array.reduce([], (acc: array<(int, int)>, (from, to, _, _)) =>
    switch acc->Array.at(-1) {
    | Some((s, e)) if e == from =>
      [...acc->Array.slice(~start=0, ~end=acc->Array.length - 1), (s, to)]
    | _ => [...acc, (from, to)]
    }
  )

@genType
type hourlyMock = {
  hour: int,
  indoorCount: int,
  outdoorCount: int,
  priceMin: Js.Null.t<int>,
  priceMax: Js.Null.t<int>,
}

/** A LocationAvailabilityDay: one venue's open courts for a day. */
@genType
type courtDayMock = {
  id: string,
  localDate: string,
  link: Js.Null.t<string>,
  location: Js.Null.t<placeMock>,
  intervals: array<intervalMock>,
  hourly: array<hourlyMock>,
}

let courtDayOf = (o: opening): courtDayMock => {
  let (low, high) = o.price
  {
    id: `court-${o.venue.id->String.replace("loc-", "")}-${o.date}`,
    localDate: o.date,
    link: o.link->Js.Null.fromOption,
    location: Js.Null.return(o.venue),
    intervals: windows(spansOf(o.blocks)),
    hourly: o.blocks->Array.flatMap(((from, to, indoor, outdoor)) =>
      Belt.Array.range(from, to - 1)->Array.map(hour => {
        hour,
        indoorCount: indoor,
        outdoorCount: outdoor,
        priceMin: Js.Null.return(low),
        priceMax: Js.Null.return(high),
      })
    ),
  }
}

/** Query.locationsAvailability: every venue's open courts over the fortnight. */
@genType
let courtDays = openings->Array.map(courtDayOf)

// ─── The same, as the props the grids and pseudo-event rows take ──────────────

let courtRows = (days: array<courtDayMock>): array<PkEventsAvailabilityDay.courtRow> =>
  days->Array.map((d): PkEventsAvailabilityDay.courtRow => {
    id: d.id,
    localDate: d.localDate,
    link: d.link->Js.Null.toOption,
    locationId: d.location->Js.Null.toOption->Option.map(l => l.id),
    locationName: d.location->Js.Null.toOption->Option.map(l => l.name),
    intervals: d.intervals->Array.map(iv => (iv.startHour, iv.endHour)),
    hourlyStats: d.hourly->Array.map((h): TimeWindow.hourStat => {
      hour: h.hour,
      indoorCount: h.indoorCount,
      outdoorCount: h.outdoorCount,
      priceMin: h.priceMin->Js.Null.toOption,
      priceMax: h.priceMax->Js.Null.toOption,
    }),
  })

/** A day's courts, as PkEventsAvailabilityDay hands them to the pickers. */
let courtsOn = (date: string): array<TimeWindow.courtAvailability> =>
  PkEventsAvailabilityDay.courtAvailabilityForDate(
    courtRows(courtDays),
    ~localDate=date,
    ~genericCourtName="Court",
  )

/** A day's court openings grouped for the Discover feed (PkEventsDayFeed). */
let courtGroupsOn = (date: string): array<TimeWindow.courtPseudoEventGroup> =>
  courtsOn(date)
  ->TimeWindow.groupCourtAvailabilityIntoPseudoEventBands
  ->TimeWindow.groupContiguousPseudoEventBands

let intentsOf = (intervals: array<intervalMock>) =>
  intervals->Array.mapWithIndex((iv, i): TimeWindow.playIntent => {
    id: i,
    start: iv.startHour->Int.toFloat,
    end: iv.endHour->Int.toFloat,
  })

/** The viewer's saved windows on a day. */
let viewerIntentsOn = (date: string) =>
  viewerAvailability
  ->Array.find(d => d.localDate == date)
  ->Option.map(d => intentsOf(d.intervals))
  ->Option.getOr([])

/** Other players' windows on a day, as the pseudo-event rows list them. */
let slotPlayersOn = (date: string): array<CourtPseudoEventRow.slotPlayer> =>
  playerAvailability
  ->Array.filter(d => d.localDate == date)
  ->Array.map((d): CourtPseudoEventRow.slotPlayer => {
    let name =
      d.user
      ->Js.Null.toOption
      ->Option.flatMap(u => u.lineUsername->Js.Null.toOption)
      ->Option.getOr("?")
    {
      id: d.id,
      name,
      initials: name->String.slice(~start=0, ~end=2)->String.toUpperCase,
      intents: intentsOf(d.intervals),
    }
  })

/** Other players' windows on a day, as the grids' demand heatmap takes them. */
let demandOn = (date: string): array<TimeWindowPicker.playerDemand> =>
  playerAvailability
  ->Array.filter(d => d.localDate == date)
  ->Array.mapWithIndex((d, i): TimeWindowPicker.playerDemand => {
    id: i,
    intents: intentsOf(d.intervals),
  })

/** The viewer's events on a day, as the grids draw them (hours in Tokyo). */
let existingEventsOn = (date: string): array<TimeWindowPicker.existingEvent> =>
  viewerEvents
  ->Array.filter(e => e.startDate->Js.Date.fromString->tokyoDay == date)
  ->Array.map((e): TimeWindowPicker.existingEvent => {
    id: e.id,
    title: e.title,
    startHour: e.startDate->Js.Date.fromString->TimeWindow.hourInTimeZone("Asia/Tokyo"),
    endHour: e.endDate->Js.Date.fromString->TimeWindow.hourInTimeZone("Asia/Tokyo"),
  })

/** `count` consecutive days from `start` ("YYYY-MM-DD"), as ISO dates. */
let daysFrom = (start: string, count: int) =>
  Belt.Array.makeBy(count, i =>
    Js.Date.fromFloat(
      Js.Date.fromString(start ++ "T12:00:00+09:00")->Js.Date.getTime +.
        Float.fromInt(i) *. 86400000.,
    )->tokyoDay
  )

/** A dictionary from each of `dates` to what `f` gives for it. */
let byDate = (dates: array<string>, f: string => array<'a>): Js.Dict.t<array<'a>> =>
  dates->Array.map(date => (date, f(date)))->Js.Dict.fromArray

// ─── Other root fields ────────────────────────────────────────────────────────

@genType
type hourCountMock = {hour: int, count: int}

/** Query.availabilityHourlyCounts for one day: the picker's demand heatmap. */
@genType
let hourlyCounts = [
  {hour: 7, count: 1},
  {hour: 8, count: 1},
  {hour: 12, count: 1},
  {hour: 13, count: 1},
  {hour: 14, count: 1},
  {hour: 17, count: 1},
  {hour: 18, count: 3},
  {hour: 19, count: 5},
  {hour: 20, count: 5},
  {hour: 21, count: 3},
  {hour: 22, count: 1},
]
