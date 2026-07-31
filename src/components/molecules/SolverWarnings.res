%%raw("import { t } from '@lingui/macro'")

open Rating

// Renders what the optimizer had to compromise on for a round.
//
// The solver only breaks a rule when the alternative is leaving a court empty,
// and when it does it always reports it — unlike the legacy fallback cascade,
// which relaxed filters silently. This is where that reporting surfaces.

let nameOf = (playersCache: PlayersCache.t<'a>, id: string): string =>
  playersCache->PlayersCache.get(id)->Option.mapOr(id, p => p.name)

let joinNames = (playersCache, ids: array<string>): string =>
  ids->Array.map(id => nameOf(playersCache, id))->Array.join(" & ")

@react.component
let make = (
  ~matches: array<completedMatchEntity<'a>>,
  ~matchViolations: Js.Dict.t<array<SolverTypes.violation>>,
  ~roundViolations: array<SolverTypes.violation>,
  ~playersCache: PlayersCache.t<'a>,
) => {
  let ts = Lingui.UtilString.t

  // Court numbers are 1-based and follow the order matches were generated in.
  let fallbackMatches =
    matches->Array.mapWithIndex((entity, index) => (
      index + 1,
      matchViolations->Js.Dict.get(entity.id)->Option.getOr([]),
    ))->Array.filter(((_, reasons)) => reasons->Array.length > 0)

  if fallbackMatches->Array.length == 0 && roundViolations->Array.length == 0 {
    React.null
  } else {
    let describeMatch = (reason: SolverTypes.violation) =>
      switch reason {
      | AntiTeam({playerIds}) =>
        ts`Fallback: ${joinNames(playersCache, playerIds)} share a court despite an avoid rule`
      | PartnerPool({teamPlayerIds}) =>
        ts`Fallback: ${joinNames(playersCache, teamPlayerIds)} are paired outside their group`
      | RequiredPlayerUnseated({playerId}) =>
        ts`${nameOf(playersCache, playerId)} could not be given a court`
      | BackToBackBye({playerId}) => ts`${nameOf(playersCache, playerId)} sits out again`
      | NotGenderMixed({teamPlayerIds}) =>
        ts`Fallback: ${joinNames(playersCache, teamPlayerIds)} team up without a woman in a mixed round`
      }

    let describeRound = (reason: SolverTypes.violation) =>
      switch reason {
      | RequiredPlayerUnseated({playerId}) =>
        ts`${nameOf(playersCache, playerId)} was marked as required but there was no seat`
      | BackToBackBye({playerId}) =>
        ts`${nameOf(playersCache, playerId)} sits out two rounds running — there are more players than seats`
      | AntiTeam(_) | PartnerPool(_) | NotGenderMixed(_) => describeMatch(reason)
      }

    <div
      className="mb-3 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
      <div className="flex items-center gap-2 font-semibold">
        <Lucide.AlertTriangle className="w-4 h-4" />
        {(ts`Some rules had to be bent to fill the courts`)->React.string}
      </div>
      <ul className="mt-2 space-y-1 text-xs">
        {roundViolations
        ->Array.mapWithIndex((reason, index) =>
          <li key={"round-" ++ index->Int.toString}> {describeRound(reason)->React.string} </li>
        )
        ->React.array}
        {fallbackMatches
        ->Array.flatMap(((courtNumber, reasons)) =>
          reasons->Array.mapWithIndex((reason, index) =>
            <li key={"m" ++ courtNumber->Int.toString ++ "-" ++ index->Int.toString}>
              {(ts`Court ${courtNumber->Int.toString}` ++ " — " ++ describeMatch(reason))
                ->React.string}
            </li>
          )
        )
        ->React.array}
      </ul>
    </div>
  }
}
