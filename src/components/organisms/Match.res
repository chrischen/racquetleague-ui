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
module PredictMatchOutcome = %relay(`
query MatchPredictMatchOutcomeQuery(
  $input: PredictMatchInput!
) {
  predictMatchOutcome(input: $input) {
     team1
     team2
  }
}
`)
module CreateLeagueMatchMutation = %relay(`
 mutation MatchMutation(
    $connections: [ID!]!
    $matchInput: LeagueMatchInput!
  ) {
    createMatch(match: $matchInput) {
      match @prependNode(connections: $connections, edgeTypeName: "MatchEdge") {
        id
        winners {
          lineUsername
        }
        losers {
          lineUsername
        }
        score
        createdAt
      }
      ratings {
        id
        mu
        sigma
        ordinal
      }
    }
  }
`)
module PredictionBar = {
  @react.component
  let make = (~odds: (float, float)) => {
    let (leftOdds, rightOdds) = odds
    let odds = rightOdds -. leftOdds
    let leftOdds = odds < 0. ? Js.Math.abs_float(odds *. 100.) : 0.
    let rightOdds = odds < 0. ? 0. : odds *. 100.

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
      scoreLeft: Zod.z->Zod.number({})->Zod.Number.gte(0.),
      scoreRight: Zod.z->Zod.number({})->Zod.Number.gte(0.),
    }: inputsMatch
  ),
)

type team = array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node>
type match = (team, team)

type winners = Left | Right
@react.component
let make = (
  ~match: match,
  ~activity: AddLeagueMatch_event_graphql.Types.fragment_activity,
  ~minRating,
  ~maxRating,
  ~onDelete: option<unit => unit>=?,
) => {
  open Form
  let (commitMutationCreateLeagueMatch, _isMutationInFlight) = CreateLeagueMatchMutation.use()

  let team1 = match->fst;
  let team2 = match->snd;
  let outcome = PredictMatchOutcome.use(
    ~variables={
      input: {
        team1RatingIds: team1->Array.map(node =>
          node.rating->Option.map(rating => rating.id)->Option.getOr("")
        ),
        team2RatingIds: team2->Array.map(node =>
          node.rating->Option.map(rating => rating.id)->Option.getOr("")
        ),
      },
    },
  ).predictMatchOutcome
  let {register, handleSubmit, setValue} = useFormOfInputsMatch(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {},
    },
  )

  let onSubmit = (data: inputsMatch) => {
    let winningSide = switch data.scoreLeft > data.scoreRight {
    | true => Left
    | false => Right
    }
    let winners =
      (winningSide == Left ? team1 : team2)->Array.filterMap(n => n.user)->Array.map(p => p.id)
    let losers =
      (winningSide == Left ? team2 : team1)->Array.filterMap(n => n.user)->Array.map(p => p.id)
    let score =
      winningSide == Left ? [data.scoreLeft, data.scoreRight] : [data.scoreRight, data.scoreLeft]
    activity.slug
    ->Option.map(slug => {
      let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
        // __id,
        "root"->RescriptRelay.makeDataId,
        "MatchListFragment_matches",
        {
          LeagueEventPageQuery_graphql.Types.activitySlug: Some(slug),
          namespace: Some("doubles:rec"),
          after: None,
          before: None,
          eventId: None,
          first: None,
        },
      )
      commitMutationCreateLeagueMatch(
        ~variables={
          matchInput: {
            activitySlug: slug,
            namespace: "doubles:rec",
            doublesMatch: {
              winners,
              losers,
              score,
              createdAt: Js.Date.make()->Util.Datetime.fromDate,
            },
          },
          connections: [connectionId],
        },
      )->RescriptRelay.Disposable.ignore
      setValue(ScoreLeft, Value(0.))
      setValue(ScoreRight, Value(0.))
      ()
    })
    ->ignore
    ()
  }
  <form onSubmit={handleSubmit(onSubmit)}>
    <div className="grid grid-cols-2 gap-4 col-span-2">
    <div className="col-span-2">{onDelete->Option.map(onDelete => <UiAction onClick=onDelete>{t`delete`}</UiAction>)->Option.getOr(React.null)}
    </div>
      <div className="grid gap-4">
        {team1
        ->Array.map(playerRsvp =>
          playerRsvp.user
          ->Option.map(user => {
            <EventRsvpUser
              user={user.fragmentRefs}
              ratingPercent={playerRsvp.rating
              ->Option.flatMap(
                rating =>
                  rating.mu->Option.map(
                    mu => (mu -. minRating) /. (maxRating -. minRating) *. 100.,
                  ),
              )
              ->Option.getOr(0.)}
            />
          })
          ->Option.getOr(React.null)
        )
        ->React.array}
      </div>
      <div className="grid gap-4">
        {team2
        ->Array.map(playerRsvp =>
          playerRsvp.user
          ->Option.map(user => {
            <EventRsvpUser
              user={user.fragmentRefs}
              ratingPercent={playerRsvp.rating
              ->Option.flatMap(
                rating =>
                  rating.mu->Option.map(
                    mu => (mu -. minRating) /. (maxRating -. minRating) *. 100.,
                  ),
              )
              ->Option.getOr(0.)}
            />
          })
          ->Option.getOr(React.null)
        )
        ->React.array}
      </div>
      <div className="grid gap-0 col-span-2">
        {outcome
        ->Option.map(outcome =>
          <PredictionBar
            odds={(outcome.team1->Option.getOr(0.), outcome.team2->Option.getOr(0.))}
          />
        )
        ->Option.getOr(React.null)}
      </div>
      <div className="grid grid-cols-2 col-span-2 items-start gap-4 md:grid-cols-2 md:gap-8">
        <div className="grid grid-cols-1 gap-4">
          <div className="mx-auto col-span-1">
            <Input
              className="w-24 sm:w-32 md:w-48  flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6"
              label={t`points`}
              type_="text"
              id="scoreLeft"
              register={register(
                ScoreLeft,
                ~options={
                  setValueAs: v => {
                    v == "" ? 0. : Float.fromString(v)->Option.getOr(1.)
                  },
                },
              )}
            />
          </div>
        </div>
        <div className="grid grid-cols-1 gap-4">
          <div className="mx-auto col-span-1">
            <Input
              className="w-24 sm:w-32 md:w-48 block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6"
              label={t`points`}
              type_="text"
              id="scoreRight"
              register={register(
                ScoreRight,
                ~options={
                  setValueAs: v => v == "" ? 0. : Float.fromString(v)->Option.getOr(1.),
                },
              )}
            />
          </div>
        </div>
        <div className="col-span-2 md:col-span-2 gap-4">
          <input
            type_="submit"
            className="mx-auto block text-3xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded"
            value="Submit"
          />
        </div>
      </div>
    </div>
  </form>
}
