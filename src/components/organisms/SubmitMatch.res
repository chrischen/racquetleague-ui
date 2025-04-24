%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
// module Fragment = %relay(`
//   fragment MatchRsvp on Rsvp {
//           user {
//             id
//             lineUsername
//           }
//           rating {
//             id
//             mu
//             sigma
//             ordinal
//           }
//   }
// `)
// module PredictMatchOutcome = %relay(`
// query SubmitMatchPredictMatchOutcomeQuery(
//   $input: PredictMatchInput!
// ) {
//   predictMatchOutcome(input: $input) {
//      team1
//      team2
//   }
// }
// `)
open Rating
// module PredictionBar = {
//   @react.component
//   let make = (~match: Match.t<rsvpNode>) => {
//     let team1 = match->fst
//     let team2 = match->snd
//     let outcome = PredictMatchOutcome.use(
//       ~variables={
//         input: {
//           team1RatingIds: team1->Array.map(node =>
//             node.data
//             ->Option.flatMap(node => node.rating->Option.map(rating => rating.id))
//             ->Option.getOr("")
//           ),
//           team2RatingIds: team2->Array.map(node =>
//             node.data
//             ->Option.flatMap(node => node.rating->Option.map(rating => rating.id))
//             ->Option.getOr("")
//           ),
//         },
//       },
//       ~fetchPolicy=NetworkOnly,
//     ).predictMatchOutcome
//
//     {
//       outcome
//       ->Option.map(outcome => {
//         let odds = (outcome.team1->Option.getOr(0.), outcome.team2->Option.getOr(0.))
//         let (leftOdds, rightOdds) = odds
//         let odds = rightOdds -. leftOdds
//         let leftOdds = odds < 0. ? Js.Math.abs_float(odds *. 1000.) : 0.
//         let rightOdds = odds < 0. ? 0. : odds *. 1000.
//         <div className="grid grid-cols-2 gap-0">
//           <div className="col-span-2 text-center">
//             {switch odds < 0. {
//             | true =>
//               <>
//                 <Lucide.MoveLeft color="red" className="inline" />
//                 {t`predicted winner`}
//                 <Lucide.MoveRight color="#929292" className="inline" />
//               </>
//             | false =>
//               <>
//                 <Lucide.MoveLeft color="#929292" className="inline" />
//                 {t`predicted winner`}
//                 <Lucide.MoveRight color="red" className="inline" />
//               </>
//             }}
//           </div>
//           <div
//             className="overflow-hidden rounded-l-full bg-gray-200 mt-1 place-content-end border-r-4 border-black">
//             <FramerMotion.Div
//               className="h-2 rounded-l-full bg-red-400 float-right"
//               initial={width: "0%"}
//               animate={{width: leftOdds->Float.toFixed(~digits=3) ++ "%"}}
//             />
//           </div>
//           <div
//             className="overflow-hidden rounded-r-full bg-gray-200 mt-1 border-l-4 border-black border-l-radius">
//             <FramerMotion.Div
//               className="h-2 rounded-r-full bg-blue-400"
//               initial={width: "0%"}
//               animate={{width: rightOdds->Float.toFixed(~digits=3) ++ "%"}}
//             />
//           </div>
//         </div>
//       })
//       ->Option.getOr(React.null)
//     }
//   }
// }
module PredictionBar = {
  @react.component
  let make = (~match: Match.t<rsvpNode>) => {
    let team1 = match->fst
    let team2 = match->snd
    let outcome = Rating.predictWin([
      team1->Array.map(node => node.rating),
      team2->Array.map(node => node.rating),
    ])

    let odds = (outcome->Array.get(0)->Option.getOr(0.), outcome->Array.get(1)->Option.getOr(0.))
    let (leftOdds, rightOdds) = odds
    let odds = rightOdds -. leftOdds
    let leftOdds = odds < 0. ? Js.Math.abs_float(odds *. 1000.) : 0.
    let rightOdds = odds < 0. ? 0. : odds *. 1000.
    <div className="grid grid-cols-2 gap-0">
      <div className="col-span-2 text-center">
        {switch odds < 0. {
        | true =>
          <>
            <Lucide.MoveLeft color="red" className="inline" />
            {t`predicted winner`}
            <Lucide.MoveRight color="#929292" className="inline" />
          </>
        | false =>
          <>
            <Lucide.MoveLeft color="#929292" className="inline" />
            {t`predicted winner`}
            <Lucide.MoveRight color="red" className="inline" />
          </>
        }}
      </div>
      <div
        className="overflow-hidden rounded-l-full bg-gray-200 mt-1 place-content-end border-r-4 border-black">
        <FramerMotion.Div
          className="h-2 rounded-l-full bg-red-400 float-right"
          initial={width: "0%"}
          animate={{width: leftOdds->Float.toFixed(~digits=3) ++ "%"}}
        />
      </div>
      <div
        className="overflow-hidden rounded-r-full bg-gray-200 mt-1 border-l-4 border-black border-l-radius">
        <FramerMotion.Div
          className="h-2 rounded-r-full bg-blue-400"
          initial={width: "0%"}
          animate={{width: rightOdds->Float.toFixed(~digits=3) ++ "%"}}
        />
      </div>
    </div>
  }
}
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

// type team = array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node>
// type match = (team, team)
external alert: string => unit = "alert"

// let nullFormEvent: JsxEvent.Form.t = %raw("null")
type winners = Left | Right
type view = Default | SubmitMatch

module PlayerView = {
  @react.component
  let make = (~player: player, ~minRating, ~maxRating) =>
    switch player.data {
    | Some(data) =>
      data.user
      ->Option.map(user => {
        <EventMatchRsvpUser
          compact=true
          key={user.id}
          user={user.fragmentRefs}
          ratingPercent={(player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.}
        />
      })
      ->Option.getOr(React.null)
    | None =>
      <MatchRsvpUser
        compact=true
        key={player.id}
        user={makeGuest(player.name)}
        ratingPercent={(player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.}
      />
    }
}

@react.component
let make = (
  ~defaultView: view=Default,
  ~match: Match.t<rsvpNode>,
  ~score: option<(float, float)>=?,
  // ~activity: AiTetsu_event_graphql.Types.fragment_activity,
  ~minRating,
  ~maxRating,
  ~onDelete: option<unit => unit>=?,
  ~onComplete: option<CompletedMatch.t<rsvpNode> => Js.Promise.t<unit>>=?,
) => {
  // ~onSubmitted: option<unit => unit>=?,
  // ~onSubmit: option<CompletedMatch.t<rsvpNode> => unit>=?,

  let ts = Lingui.UtilString.t
  open Form
  let (view, setView) = React.useState(() => defaultView)
  let {register, handleSubmit, setValue } = useFormOfInputsMatch(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {
        // scoreLeft: score->Option.map(fst)->Option.getOr(0.),
        // scoreRight: score->Option.map(snd)->Option.getOr(0.),
      },
    },
  )

  let team1 = match->fst
  let team2 = match->snd
  let doublesMatch = match->DoublesMatch.fromMatch

  let (submitting, setSubmitting) = React.useState(() => false)
  React.useEffect2(() => {
    // Set the value to the provided score if it exists
    score
    ->Option.map(score => {
      setValue(ScoreLeft, Value(score->fst))
      setValue(ScoreRight, Value(score->snd))
    })
    ->ignore
    None
  }, (view, match))

  let handleWinner = (winningSide: winners) => {
    onComplete
    ->Option.map(f => {
      let match = (winningSide == Left ? team1 : team2, winningSide == Left ? team2 : team1)
      f((match, None))
    })
    ->ignore
  }

  let onSubmit = (data: inputsMatch) => {
    setSubmitting(_ => true)
    switch data.scoreLeft == data.scoreRight {
    | true => alert("No ties allowed")
    | false =>
      onComplete
      ->Option.map(f => {
        let winningSide = switch data.scoreLeft > data.scoreRight {
        | true => Left
        | false => Right
        }
        let score =
          winningSide == Left
            ? (data.scoreLeft, data.scoreRight)
            : (data.scoreRight, data.scoreLeft)
        let match = (winningSide == Left ? team1 : team2, winningSide == Left ? team2 : team1)
        let x = f((match, Some(score)))
        x->Promise.then(_ => {
          setValue(ScoreLeft, Value(0.))
          setValue(ScoreRight, Value(0.))
          Promise.resolve(setSubmitting(_ => false))
        })
      })
      ->ignore
    }
  }

  let defaultView =
    <div
      onClick={_ => setView(_ => SubmitMatch)}
      className="grid grid-cols-1 gap-2 p-0 border bg-white border-gray-200 rounded-lg shadow-sm">
      <div
        className="grid grid-cols-1 gap-0 p-0 bg-white rounded-tl-lg rounded-tr-lg shadow truncate">
        {team1
        ->Array.map(player => <PlayerView key=player.id player minRating maxRating />)
        ->React.array}
      </div>
      <div className="grid grid-cols-1 gap-0 p-0 bg-white shadow truncate">
        {team2
        ->Array.map(player => <PlayerView key=player.id player minRating maxRating />)
        ->React.array}
      </div>
      <div className="flex md:top-3 md:mt-0 justify-center">
        {onDelete
        ->Option.map(onDelete =>
          <UiAction
            className="ml-3 inline-flex items-center text-3xl bg-red-500 hover:bg-red-400 text-white font-bold py-2 px-4 border-b-4 border-red-700 hover:border-red-500 rounded"
            onClick={e => {
              e->JsxEventU.Mouse.stopPropagation
              onDelete()
            }}>
            {t`Cancel`}
          </UiAction>
        )
        ->Option.getOr(React.null)}
      </div>
    </div>

  let unratedMatch = doublesMatch->Result.flatMap((((p1, p2), (p3, p4))) =>
    switch (p1.data, p2.data, p3.data, p4.data) {
    | (Some(_), Some(_), Some(_), Some(_)) => Ok()
    | _ => Error(TwoPlayersRequired)
    }
  )

  let submitMatch =
    <div className="grid col-span-1 items-start gap-2 md:gap-4">
      {<>
        <div
          className="grid col-span-1 items-start gap-2 p-0 border bg-white border-gray-200 rounded-lg shadow-sm">
          <div
            onClick={_ => setView(_ => Default)}
            className="flex relative p-0 justify-between rounded-tl-lg rounded-tr-lg bg-white shadow truncate">
            <div className="grid grid-cols-1 gap-0">
              {team1
              ->Array.map(player => <PlayerView key=player.id player minRating maxRating />)
              ->React.array}
            </div>
            <div className="flex bg-white z-10">
              {unratedMatch
              ->Result.map(_ =>
                <Input
                  className="w-24 sm:w-32 md:w-48 flex-1 border-0 bg-transparent py-3.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-4xl sm:leading-6"
                  placeholder={ts`Points`}
                  onClick={e => {
                    e->JsxEventU.Mouse.stopPropagation
                    e->JsxEventU.Mouse.preventDefault
                  }}
                  type_="text"
                  id="scoreLeft"
                  register={register(
                    ScoreLeft,
                    // ~options={
                    //   setValueAs: v => {
                    //     v == "" ? 0. : Float.fromString(v)->Option.getOr(1.)
                    //   },
                    // },
                  )}
                />
              )
              ->Result.getOr(
                <UiAction
                  onClick={e => {
                    e->JsxEventU.Mouse.stopPropagation
                    e->JsxEventU.Mouse.preventDefault
                    handleWinner(Left)
                  }}
                  className="ml-3 inline-flex items-center text-3xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded">
                  {t`Winner`}
                </UiAction>,
              )}
            </div>
          </div>
          <div
            onClick={_ => setView(_ => Default)}
            className="flex relative p-0 justify-between bg-white shadow truncate">
            <div className="grid grid-cols-1 gap-0 truncate">
              {team2
              ->Array.map(player => <PlayerView key=player.id player minRating maxRating />)
              ->React.array}
            </div>
            <div className="flex bg-white z-10">
              {unratedMatch
              ->Result.map(_ =>
                <Input
                  className="w-24 sm:w-32 md:w-48 flex-1 border-0 bg-transparent py-3.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-4xl sm:leading-6"
                  placeholder={ts`Points`}
                  onClick={e => {
                    e->JsxEventU.Mouse.stopPropagation
                    e->JsxEventU.Mouse.preventDefault
                  }}
                  type_="text"
                  id="scoreRight"
                  register={register(
                    ScoreRight,
                    // ~options={
                    //   setValueAs: v => v == "" ? 0. : Float.fromString(v)->Option.getOr(1.),
                    // },
                  )}
                />
              )
              ->Result.getOr(
                <UiAction
                  onClick={e => {
                    e->JsxEventU.Mouse.stopPropagation
                    e->JsxEventU.Mouse.preventDefault
                    handleWinner(Right)
                  }}
                  className="ml-3 inline-flex items-center text-3xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded">
                  {t`Winner`}
                </UiAction>,
              )}
            </div>
          </div>
          <div className="mt-3 flex md:top-3 md:mt-0 justify-center">
            <UiAction
              className="inline-flex items-center text-2xl bg-red-500 hover:bg-red-400 text-white font-bold py-2 px-4 border-b-4 border-red-700 hover:border-red-500 rounded"
              onClick={_ => setView(_ => Default)}>
              {t`Go Back`}
            </UiAction>
            {unratedMatch
            ->Result.map(_ =>
              <input
                type_="submit"
                disabled={submitting}
                className="ml-3 inline-flex items-center text-2xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded"
                value={ts`Submit Rated`}
              />
            )
            ->Result.getOr(React.null)}
          </div>
          <div className="grid gap-0 col-span-1">
            <React.Suspense fallback={<div> {t`Loading`} </div>}>
              <PredictionBar match />
            </React.Suspense>
          </div>
        </div>
      </>}
    </div>

  <form onSubmit={handleSubmit(onSubmit)}>
    <div className="grid grid-cols-1">
      {switch view {
      | Default => defaultView
      | SubmitMatch => submitMatch
      }}
    </div>
  </form>
}
