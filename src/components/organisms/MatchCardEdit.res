%%raw("import { t } from '@lingui/macro'")

// MatchCardEdit Component - Edit mode for MatchCard
//
// This component manages the form state and score inputs for editing a match.
// It handles score validation and submission of completed matches.

open Rating

@rhf
type inputsMatch = {
  scoreLeft: Zod.number,
  scoreRight: Zod.number,
}

let schema = Zod.z->Zod.object(
  (
    {
      scoreLeft: Zod.z->Zod.preprocess(
        a => Float.fromString(a)->Option.getOr(0.),
        Zod.z->Zod.number({invalid_type_error: "Enter a number"})->Zod.Number.gte(0.),
      ),
      scoreRight: Zod.z->Zod.preprocess(
        a => Float.fromString(a)->Option.getOr(0.),
        Zod.z->Zod.number({invalid_type_error: "Enter a number"})->Zod.Number.gte(0.),
      ),
    }: inputsMatch
  ),
)

@react.component
let make = (
  ~match: Match.t<'a>,
  ~courtNumber: int,
  ~score: option<(float, float)>=?,
  ~onDelete: option<unit => unit>=?,
  ~onSave: ((Match.t<'a>, option<(float, float)>)) => unit,
  ~onCancel: unit => unit,
  ~team1Element: React.element,
  ~team2Element: React.element,
) => {
  let ts = Lingui.UtilString.t
  open Form

  let (team1, team2) = match
  let doublesMatch = match->DoublesMatch.fromMatch

  let ratedMatch = doublesMatch->Result.flatMap((((p1, p2), (p3, p4))) =>
    switch (p1.data, p2.data, p3.data, p4.data) {
    | (Some(_), Some(_), Some(_), Some(_)) => Ok()
    | _ => Error(TwoPlayersRequired)
    }
  )

  let (scoreLeft, scoreRight) = score->Option.getOr((0., 0.))

  let {register, watch, _} = useFormOfInputsMatch(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {
        scoreLeft,
        scoreRight,
      },
    },
  )

  // Watch the score fields
  let scoreLeftValue = switch watch(ScoreLeft) {
  | Some(String(s)) => s->Float.fromString->Option.getOr(0.)
  | Some(Number(n)) => n
  | _ => 0.
  }
  let scoreRightValue = switch watch(ScoreRight) {
  | Some(String(s)) => s->Float.fromString->Option.getOr(0.)
  | Some(Number(n)) => n
  | _ => 0.
  }

  let handleSave = () => {
    // Keep the original match order - don't swap teams based on winner
    let match = (team1, team2)
    let scoreData = (scoreLeftValue, scoreRightValue)

    // Only submit a score if:
    // 1. All players are selected (ratedMatch is Ok)
    // 2. There's actually a winner (scores are not both 0 or equal)
    let hasWinner =
      scoreLeftValue != scoreRightValue && (scoreLeftValue != 0. || scoreRightValue != 0.)

    onSave((match, ratedMatch->Result.isOk && hasWinner ? Some(scoreData) : None))
  }

  <div className="bg-white rounded-lg border-2 border-blue-500 shadow-sm overflow-hidden">
    <div
      className="bg-blue-100 px-2 py-1 border-b border-blue-200 flex items-center justify-between">
      <span className="text-xs font-semibold text-blue-900">
        {(ts`Court ${courtNumber->Int.toString} - Editing`)->React.string}
      </span>
      <div className="flex items-center gap-1">
        {onDelete
        ->Option.map(deleteFn =>
          <button
            onClick={_ => deleteFn()}
            className="p-1 text-red-700 hover:bg-red-200 rounded transition-colors"
            ariaLabel={ts`Delete match`}>
            <Lucide.Trash2 className="w-4 h-4" />
          </button>
        )
        ->Option.getOr(React.null)}
        <button
          onClick={_ => {
            handleSave()
            onCancel()
          }}
          className="p-1 text-green-700 hover:bg-green-200 rounded transition-colors"
          ariaLabel={ts`Save`}>
          <Lucide.Check className="w-4 h-4" />
        </button>
      </div>
    </div>
    <div className="flex flex-col">
      // Team 1 - Editing
      <div className="p-2 bg-slate-50 flex-1 border-b border-slate-200">
        <div className="flex items-center justify-between mb-2">
          <div className="text-xs font-semibold text-slate-600"> {(ts`TEAM 1`)->React.string} </div>
          <Input
            id="scoreLeft"
            className="w-16 px-2 py-1 text-sm text-center border border-slate-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder={ts`Score`}
            type_="number"
            pattern="[0-9]*"
            inputMode="numeric"
            register={register(ScoreLeft)}
          />
        </div>
        <div className="space-y-2"> {team1Element} </div>
      </div>
      // VS Divider - Horizontal only in edit mode
      <div className="relative flex items-center justify-center bg-slate-50">
        <div
          className="absolute inset-0 flex items-center justify-center border-b border-slate-200">
          <span className="bg-slate-50 px-2 text-xs font-bold text-slate-400">
            {(ts`VS`)->React.string}
          </span>
        </div>
      </div>
      // Team 2 - Editing
      <div className="p-2 bg-slate-50 flex-1">
        <div className="flex items-center justify-between mb-2">
          <div className="text-xs font-semibold text-slate-600"> {(ts`TEAM 2`)->React.string} </div>
          <Input
            id="scoreRight"
            className="w-16 px-2 py-1 text-sm text-center border border-slate-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder={ts`Score`}
            type_="number"
            pattern="[0-9]*"
            inputMode="numeric"
            register={register(ScoreRight)}
          />
        </div>
        <div className="space-y-2"> {team2Element} </div>
      </div>
    </div>
  </div>
}
