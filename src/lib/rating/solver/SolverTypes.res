// Shared vocabulary for the solver pipeline: what a constraint breach is, and
// what a scored candidate match looks like on its way into the LP.

open Rating

// A rule the produced round breaks. Match-local breaches (`AntiTeam`,
// `PartnerPool`) are attached to the offending match; round-level ones
// (`RequiredPlayerUnseated`, `BackToBackBye`) are reported for the round.
//
// The solver only ever breaks a rule when the alternative is leaving a court
// empty, and it always reports it — unlike the legacy fallback cascade, which
// silently relaxed filters until something matched.
type violation =
  | AntiTeam({groupIndex: int, playerIds: array<string>})
  | PartnerPool({teamPlayerIds: array<string>})
  | RequiredPlayerUnseated({playerId: string})
  | BackToBackBye({playerId: string})
  // A team without a woman in a round the user asked to be mixed doubles.
  | NotGenderMixed({teamPlayerIds: array<string>})

// Plain-English rendering for logs and tests. User-facing copy is localised at
// the component level from the structured payload above.
let describe = (violation: violation, nameOf: string => string): string =>
  switch violation {
  | AntiTeam({playerIds}) =>
    "Placed " ++ playerIds->Array.map(nameOf)->Array.join(" and ") ++ " on the same court despite an avoid rule"
  | PartnerPool({teamPlayerIds}) =>
    "Paired " ++
    teamPlayerIds->Array.map(nameOf)->Array.join(" and ") ++
    " outside their partner group"
  | RequiredPlayerUnseated({playerId}) => nameOf(playerId) ++ " could not be given a court"
  | BackToBackBye({playerId}) => nameOf(playerId) ++ " sits out twice in a row"
  | NotGenderMixed({teamPlayerIds}) =>
    "Teamed " ++
    teamPlayerIds->Array.map(nameOf)->Array.join(" and ") ++ " without a woman in a mixed round"
  }

// JSON codec, for persisting violations alongside the rounds they describe.
// A fallback warning that vanishes on reload is a silent violation — the exact
// failure mode this reporting exists to prevent.

let toJson = (violation: violation): Js.Json.t => {
  let d = Js.Dict.empty()
  switch violation {
  | AntiTeam({groupIndex, playerIds}) => {
      d->Js.Dict.set("kind", "antiTeam"->Js.Json.string)
      d->Js.Dict.set("groupIndex", groupIndex->Int.toFloat->Js.Json.number)
      d->Js.Dict.set("playerIds", playerIds->Array.map(id => id->Js.Json.string)->Js.Json.array)
    }
  | PartnerPool({teamPlayerIds}) => {
      d->Js.Dict.set("kind", "partnerPool"->Js.Json.string)
      d->Js.Dict.set(
        "teamPlayerIds",
        teamPlayerIds->Array.map(id => id->Js.Json.string)->Js.Json.array,
      )
    }
  | RequiredPlayerUnseated({playerId}) => {
      d->Js.Dict.set("kind", "requiredPlayerUnseated"->Js.Json.string)
      d->Js.Dict.set("playerId", playerId->Js.Json.string)
    }
  | BackToBackBye({playerId}) => {
      d->Js.Dict.set("kind", "backToBackBye"->Js.Json.string)
      d->Js.Dict.set("playerId", playerId->Js.Json.string)
    }
  | NotGenderMixed({teamPlayerIds}) => {
      d->Js.Dict.set("kind", "notGenderMixed"->Js.Json.string)
      d->Js.Dict.set(
        "teamPlayerIds",
        teamPlayerIds->Array.map(id => id->Js.Json.string)->Js.Json.array,
      )
    }
  }
  d->Js.Json.object_
}

let fromJson = (json: Js.Json.t): option<violation> =>
  json
  ->Js.Json.decodeObject
  ->Option.flatMap(d => {
    let str = key => d->Js.Dict.get(key)->Option.flatMap(v => v->Js.Json.decodeString)
    let strArray = key =>
      d
      ->Js.Dict.get(key)
      ->Option.flatMap(v => v->Js.Json.decodeArray)
      ->Option.mapOr([], arr => arr->Array.filterMap(v => v->Js.Json.decodeString))
    switch str("kind") {
    | Some("antiTeam") =>
      Some(
        AntiTeam({
          groupIndex: d
          ->Js.Dict.get("groupIndex")
          ->Option.flatMap(v => v->Js.Json.decodeNumber)
          ->Option.mapOr(0, Float.toInt),
          playerIds: strArray("playerIds"),
        }),
      )
    | Some("partnerPool") => Some(PartnerPool({teamPlayerIds: strArray("teamPlayerIds")}))
    | Some("requiredPlayerUnseated") =>
      str("playerId")->Option.map(playerId => RequiredPlayerUnseated({playerId: playerId}))
    | Some("backToBackBye") =>
      str("playerId")->Option.map(playerId => BackToBackBye({playerId: playerId}))
    | Some("notGenderMixed") => Some(NotGenderMixed({teamPlayerIds: strArray("teamPlayerIds")}))
    | _ => None
    }
  })

// A candidate match, priced. `cost` is the regular weighted cost from
// `CostModel` (bounded by `CostModel.maxMatchCost`); `surcharge` carries the
// tiered penalties for any rule this candidate breaks, so a violating candidate
// is only ever chosen when no clean one can fill the court.
type candidate<'a> = {
  match: Match.t<'a>,
  cost: float,
  surcharge: float,
  violations: array<violation>,
}
