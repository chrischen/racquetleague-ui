// Shared fixtures for the session and player-management stories (batch E2):
// check-in, seeds, teams, guests, player settings and the history transfer
// modals. Storybook support only; the app never imports this.
//
// Everything builds on the match roster (StoryFixturesMatch): the same Thursday
// night, 20 players with 16 checked in, three courts, and the same RSVP query,
// so avatars and names agree with the match-play stories. This module adds what
// the organiser's side of the evening needs: two walk-ins added at the desk, a
// few players who have not paid, the rating adjustments made over three rounds,
// and an exported history carried over from a second device.
open StoryFixturesMatch

// --- Walk-ins ----------------------------------------------------------------

/** Two walk-ins added at the desk: no account (initials, no avatar), unpaid, default rating.
 EventManager numbers guests from 9000. */
let guests = (): array<Rating.Player.t<'a>> => [
  guest(~name="Kaito Mori", ~intId=9000),
  guest(~name="Lisa Brown", ~gender=Female, ~intId=9001),
]

let kaitoId = "guest-Kaito Mori"
let lisaId = "guest-Lisa Brown"

// --- Paid and checked in -------------------------------------------------------

// Who still owes the ¥1,500 court fee tonight. Walk-ins start unpaid too.
let unpaidIds = ["user-daniel", "user-sarah", "user-tom", "user-rina", "user-yukiko"]

let withPaidMix = (players: array<Rating.Player.t<'a>>) =>
  players->Array.map(p => unpaidIds->Array.includes(p.id) ? {...p, paid: false} : p)

/** The 16 regulars plus any walk-ins (EventManager checks guests in as it adds them). */
let checkedInWithGuests = (players: array<Rating.Player.t<'a>>) => {
  let ids = checkedInIds(players)
  players->Array.forEach(p =>
    if p.data->Option.isNone {
      ids->Set.add(p.id)->ignore
    }
  )
  ids
}

// --- Rating adjustments ------------------------------------------------------

let time = iso => Js.Date.fromString(iso)->Js.Date.getTime

// Tokyo evening: seeds set at 18:55, round 2 adjusted at 19:25, round 3 at 19:50.
let seedTime = time("2026-10-15T09:55:00.000Z")
let round2Time = time("2026-10-15T10:25:00.000Z")
let round3Time = time("2026-10-15T10:50:00.000Z")

let adjust = (playerId, differential, ~round, ~timestamp): Rating.RatingAdjustment.t => {
  playerId,
  differential,
  // A hand-set seed tightens sigma (see RatingAdjustment.sigmaDifferentialFor).
  sigmaDifferential: -1.5,
  appliedAtRound: round,
  timestamp,
}

let idOf = i => (roster->Array.getUnsafe(i)).id

/** The organiser's seeding before round 1 (appliedAtRound -1): three players up, three down. */
let seedAdjustments = [
  adjust(idOf(chris), 1.8, ~round=-1, ~timestamp=seedTime),
  adjust(idOf(daniel), 3.1, ~round=-1, ~timestamp=seedTime),
  adjust(idOf(rina), 0.9, ~round=-1, ~timestamp=seedTime),
  adjust(idOf(emily), -2.4, ~round=-1, ~timestamp=seedTime),
  adjust(idOf(sarah), -1.2, ~round=-1, ~timestamp=seedTime),
  adjust(idOf(tom), -0.6, ~round=-1, ~timestamp=seedTime),
]

/** Adjusted just before round 2: one up, one down. */
let round2Adjustments = [
  adjust(idOf(mai), 1.5, ~round=1, ~timestamp=round2Time),
  adjust(idOf(haruka), -0.9, ~round=1, ~timestamp=round2Time),
]

/** Adjusted just before round 3: a regular and the walk-in who turned out to be strong. */
let round3Adjustments = [
  adjust(idOf(sota), 0.7, ~round=2, ~timestamp=round3Time),
  adjust(kaitoId, 2.2, ~round=2, ~timestamp=round3Time),
]

let allAdjustments = [seedAdjustments, round2Adjustments, round3Adjustments]->Array.flat

// --- History transfer ----------------------------------------------------------

/** When round `round` (0-based) was played: 19:00 Tokyo, a round every 12 minutes. */
let roundTime = (round: int) =>
  Js.Date.fromFloat(time("2026-10-15T10:00:00.000Z") +. Int.toFloat(round) *. 12. *. 60000.)

let scored = (entity: Rating.completedMatchEntity<'a>, score, ~round) => {
  ...entity,
  score: Some(score),
  createdAt: roundTime(round),
  synced: true,
}

/** Rounds 1 and 2 as a second device recorded them: every court scored, and in
 round 2 a fourth court where the two walk-ins played. `players` is the roster
 with the guests appended (positions 20 and 21). */
let recordedRounds = (players: array<Rating.Player.t<'a>>) => {
  let kaito = roster->Array.length
  let lisa = kaito + 1
  let r2 = round2(players)
  [
    round1(players)->Array.map(m => {...m, createdAt: roundTime(0), synced: true}),
    [
      r2->Array.getUnsafe(0)->scored((11., 7.), ~round=1),
      r2->Array.getUnsafe(1)->scored((8., 11.), ~round=1),
      r2->Array.getUnsafe(2)->scored((11., 9.), ~round=1),
      entity(~id="evt-r2-c4", doubles(players, (kaito, sota), (lisa, naomi)))->scored(
        (11., 6.),
        ~round=1,
      ),
    ],
  ]
}

let exportedAt = time("2026-10-15T11:30:00.000Z")

/** The export a second device produced: rounds 1 and 2 (7 scored matches) and all
 ten rating adjustments. Paste it into the import modal. */
@genType
let sampleExport: string = EventStateTransfer.encode(
  ~eventId="evt-story-match",
  ~exportedAt,
  ~rounds=recordedRounds(plainPlayers()->Array.concat(guests())),
  ~adjustments=allAdjustments,
)
