// Shared fixtures for the event page section stories (batch B): the sticky
// footer, the RSVP sections, the activity feeds, the invite strip and deck,
// court availability and the draws preview. Storybook support only; the app
// never imports this.
//
// Players on the event come from StoryFixturesEvent (the 14-player Tokyo
// roster). This module adds what those stories didn't need: the event's
// activity feed, players the organizer could invite (none of them on the
// roster, so none is already a participant), and clock helpers.
//
// About the clock: the stories otherwise use fixed dates, but a few of these
// components measure against the current time (the footer's cancellation
// countdown and 30-minute grace period, the feed's "12m ago"). Fixed dates
// would drift those stories into other states as the calendar moves on, so
// those builders take an anchor (usually Date.now(), read when the story
// loads) and place everything relative to it.

let minute = 60_000.
let hour = 60. *. minute
let day = 24. *. hour

/** The story event's id, as every batch-B wrapper queries it. */
@genType
let eventId = "evt-story-1"

/** The event's activity-feed topic, as the event page subscribes to it. */
@genType
let topic = eventId ++ ".updated"

/** The instant `minutes` before `anchor` (ms since the epoch), as ISO. */
@genType
let minutesBefore = (anchor: float, minutes: float) =>
  Date.fromTime(anchor -. minutes *. minute)->Date.toISOString

/** 19:00 in Tokyo, `days` days after `anchor`'s Tokyo date, in ms. A
    weeknight session a few days out, whatever day the story is opened. */
@genType
let tokyoEvening = (anchor: float, days: int) => {
  let jst = 9. *. hour
  let tokyoMidnight = Math.floor((anchor +. jst) /. day) *. day -. jst
  tokyoMidnight +. Int.toFloat(days) *. day +. 19. *. hour
}

// ─── Activity feed (Query.messagesByTopic) ──────────────────────────────────

@genType
type messageMock = {id: string, createdAt: string, payload: string, topic: string}

@genType
type messageEdgeMock = {cursor: string, node: messageMock}

@genType
type messageConnectionMock = {edges: array<messageEdgeMock>}

/** One feed row. The payload is the JSON the server writes: who acted, what
    happened and, for messages and edits, the text. */
@genType
let message = (id: string, createdAt: string, actor: string, activityType: string, details: Js.Null.t<string>) => {
  let fields = [
    ("actorUserName", Js.Json.string(actor)),
    ("activityType", Js.Json.string(activityType)),
  ]
  let fields = switch details->Js.Null.toOption {
  | Some(text) => fields->Array.concat([("details", Js.Json.string(text))])
  | None => fields
  }
  {
    id,
    createdAt,
    payload: Js.Dict.fromArray(fields)->Js.Json.object_->Js.Json.stringify,
    topic,
  }
}

/** A Query.messagesByTopic connection, newest first as the server sends it. */
@genType
let messageConnection = (messages: array<messageMock>) => {
  edges: messages->Array.map(node => {cursor: "cursor-" ++ node.id, node}),
}

// The organizer is Kenji W., who owns the story event; everyone else is on
// the StoryFixturesEvent roster. Minutes before the anchor, newest first.
let feed = [
  (12., "Kenji W.", "host_message", Some("Courts 3 and 4 tonight. Indoor shoes only, the gym is strict about it!")),
  (26., "Emily", "comment", Some("Running about 10 minutes late, please start without me.")),
  (41., "Tom", "rsvp_created", None),
  (95., "あおい", "rsvp_promoted", None),
  (180., "Lucas", "rsvp_deleted", None),
  (300., "Kenji W.", "update", Some("Start time moved to 19:00")),
  (420., "さくら", "comment", Some("初めて参加します！よろしくお願いします。")),
  (1210., "Rin", "rsvp_invited", None),
  (1580., "Daniel", "rsvp_added", None),
  (2890., "Yuki", "rsvp_created", None),
]

/** The event's feed: the first `count` rows (up to 10) of a typical evening,
    `anchor` being the newest moment. Player chat is written with
    `commentType`: "comment_added" on the pickleball event page
    (PkEventMessages), "user_message" on the classic one (EventMessages). */
@genType
let conversation = (anchor: float, count: int, commentType: string) =>
  feed
  ->Array.slice(~start=0, ~end=count)
  ->Array.mapWithIndex(((minutes, actor, activityType, details), i) =>
    message(
      "msg-" ++ Int.toString(i + 1),
      minutesBefore(anchor, minutes),
      actor,
      activityType == "comment" ? commentType : activityType,
      details->Js.Null.fromOption,
    )
  )
  ->messageConnection

// ─── Players the organizer could invite ─────────────────────────────────────

@genType
type duprMock = {doubles: float, doublesReliable: bool, doublesReliability: float}

@genType
type eventRatingMock = {id: string, mu: float, sigma: float}

/** A User as PlayerInviteSwipeDeck_user selects it. */
@genType
type inviteeMock = {
  id: string,
  lineUsername: string,
  picture: Js.Null.t<string>,
  gender: Js.Null.t<[#male | #female]>,
  biography: Js.Null.t<string>,
  selfRating: Js.Null.t<float>,
  dupr: Js.Null.t<duprMock>,
  eventRating: Js.Null.t<eventRatingMock>,
}

type invitee = {
  user: inviteeMock,
  // What the ranking pass says about them (Query.inviteRecommendations).
  availability: [#available | #unknown | #unavailable],
  resolvedDupr: float,
  established: bool,
}

let invitee = (
  ~id,
  ~name,
  ~gender,
  ~seed,
  ~pic=true,
  ~bio=?,
  ~self=?,
  ~dupr=?,
  ~rating=?,
  ~availability,
  ~resolvedDupr,
  ~established,
) => {
  user: {
    id,
    lineUsername: name,
    picture: pic ? Js.Null.return(StoryFixturesEvent.avatar(name, seed)) : Js.Null.empty,
    gender: Js.Null.return(gender),
    biography: bio->Js.Null.fromOption,
    selfRating: self->Js.Null.fromOption,
    dupr: dupr
    ->Option.map(((doubles, reliability)) => {
      doubles,
      doublesReliable: reliability >= 20.,
      doublesReliability: reliability,
    })
    ->Js.Null.fromOption,
    eventRating: rating
    ->Option.map(((mu, sigma)) => {id: "rating-evt-" ++ id, mu, sigma})
    ->Js.Null.fromOption,
  },
  availability,
  resolvedDupr,
  established,
}

// Ranked best first, as the server returns recommendations. `self` and
// `rating` are on the internal scale (mu 25 is about DUPR 3.54).
let invitees = [
  invitee(
    ~id="user-ryo",
    ~name="Ryo",
    ~gender=#male,
    ~seed=0,
    ~bio="Ex-tennis player, three years of pickleball. Happy to play any side, weeknights in Minato and Shibuya.",
    ~self=31.,
    ~dupr=(3.86, 48.),
    ~rating=(33.5, 3.1),
    ~availability=#available,
    ~resolvedDupr=3.87,
    ~established=true,
  ),
  invitee(
    ~id="user-haruka",
    ~name="はるか",
    ~gender=#female,
    ~seed=1,
    ~bio="週2回、有明で練習しています。ミックスダブルス歓迎です！",
    ~rating=(30.2, 4.4),
    ~availability=#available,
    ~resolvedDupr=3.74,
    ~established=true,
  ),
  invitee(
    ~id="user-marco",
    ~name="Marco",
    ~gender=#male,
    ~seed=2,
    ~bio="Visiting from Milan until December. Looking for competitive doubles.",
    ~dupr=(4.12, 12.),
    ~availability=#unknown,
    ~resolvedDupr=4.12,
    ~established=false,
  ),
  invitee(
    ~id="user-nana",
    ~name="Nana",
    ~gender=#female,
    ~seed=3,
    ~self=24.,
    ~rating=(27.1, 5.9),
    ~availability=#unavailable,
    ~resolvedDupr=3.62,
    ~established=false,
  ),
  invitee(
    ~id="user-sho",
    ~name="翔",
    ~gender=#male,
    ~seed=4,
    ~pic=false,
    ~self=20.,
    ~availability=#available,
    ~resolvedDupr=3.25,
    ~established=false,
  ),
  invitee(
    ~id="user-grace",
    ~name="Grace",
    ~gender=#female,
    ~seed=5,
    ~bio="Beginner-intermediate, working on my third-shot drop.",
    ~rating=(22.4, 6.8),
    ~availability=#available,
    ~resolvedDupr=3.44,
    ~established=false,
  ),
  invitee(
    ~id="user-kaito",
    ~name="Kaito",
    ~gender=#male,
    ~seed=6,
    ~rating=(29.3, 3.6),
    ~availability=#available,
    ~resolvedDupr=3.71,
    ~established=true,
  ),
  invitee(
    ~id="user-mio",
    ~name="Mio",
    ~gender=#female,
    ~seed=7,
    ~self=22.,
    ~availability=#available,
    ~resolvedDupr=3.44,
    ~established=false,
  ),
]

@genType
type resolvedRatingMock = {dupr: float, established: bool}

@genType
type recommendationMock = {
  availability: [#available | #unknown | #unavailable],
  fit: [#balanced | #unbalanced | #unknown],
  strong: bool,
  rating: resolvedRatingMock,
  user: inviteeMock,
}

@genType
type recommendationsMock = {recommendations: array<recommendationMock>}

/** Query.inviteRecommendations: the first `count` invitees (up to 5), ranked. */
@genType
let recommendations = (count: int) => {
  recommendations: invitees
  ->Array.slice(~start=0, ~end=Math.Int.min(count, 5))
  ->Array.map(i => {
    availability: i.availability,
    fit: i.availability == #unavailable ? #unbalanced : #balanced,
    strong: i.resolvedDupr >= 3.8,
    rating: {dupr: i.resolvedDupr, established: i.established},
    user: i.user,
  }),
}

@genType
type intervalMock = {startHour: int, endHour: int}

@genType
type availabilityDayMock = {
  id: string,
  localDate: string,
  user: inviteeMock,
  intervals: array<intervalMock>,
}

/** Query.availabilityUsersForDay on `localDate`: every invitee who stored
    availability that day. Those past the ranked five cover 18:00-22:00; the
    others overlap with the recommendations or miss the event's hours. */
@genType
let availabilityDays = (localDate: string) =>
  invitees
  ->Array.filter(i => i.availability != #unknown)
  ->Array.map(i => {
    id: "avail-" ++ i.user.id,
    localDate,
    user: i.user,
    intervals: i.availability == #unavailable
      ? [{startHour: 9, endHour: 13}]
      : [{startHour: 18, endHour: 22}],
  })
