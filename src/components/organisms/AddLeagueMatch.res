%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment AddLeagueMatch_event on Event
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 50 }
  )
  @refetchable(queryName: "LeagueEventRsvpsRefetchQuery")
  {
    __id
    activity {
      id
      slug
    }
    rsvps(after: $after, first: $first, before: $before)
    @connection(key: "LeagueEventRsvps_event_rsvps")
    {
      edges {
        node {
          __id
          user {
            id
            ...EventRsvpUser_user
          }
          rating {
            id
            mu
            ordinal
          }
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
      }
		}
  }
`)
module CreateLeagueMatchMutation = %relay(`
 mutation AddLeagueMatchMutation(
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

module PredictMatchOutcome = %relay(`
query AddLeagueMatchPredictMatchOutcomeQuery(
  $input: PredictMatchInput!
) {
  predictMatchOutcome(input: $input) {
     team1
     team2
  }
}
`)

module SortAction = {
  type sortDir = Asc | Desc
  @react.component
  let make = (~sortDir, ~setSortDir) => {
    <a href="#" onClick={e => {setSortDir(dir => dir == Asc ? Desc : Asc)}}>
      {switch sortDir {
      | Asc => <Lucide.ArrowUpNarrowWide />
      | Desc => <Lucide.ArrowDownWideNarrow />
      }}
    </a>
  }
}

module SelectEventPlayersList = {
  @react.component
  let make = (
    ~event,
    ~selected: array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node_user>,
    ~disabled: array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node_user>=?,
    ~onSelectPlayer: option<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node => unit>=?,
    ~minRating=0.,
    ~maxRating=1.,
  ) => {
    let (_isPending, startTransition) = ReactExperimental.useTransition()
    let {data, loadNext, isLoadingNext, hasNext} = Fragment.usePagination(event)
    let players = data.rsvps->Fragment.getConnectionNodes
    let onLoadMore = _ =>
      startTransition(() => {
        loadNext(~count=1)->ignore
      })
    // let viewer = GlobalQuery.useViewer()

    let (sortDir, setSortDir) = React.useState(_ => SortAction.Desc)

    <div className="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5">
      <div className="mt-4 flex w-full flex-none gap-x-4 border-t border-gray-900/5 px-6 py-4">
        <SortAction sortDir setSortDir />
        {<>
          <ul className="w-full">
            <FramerMotion.AnimatePresence>
              {switch players {
              | [] => t`no players yet`
              | players =>
                players
                ->Array.toSorted((a, b) => {
                  let userA =
                    a.rating->Option.flatMap(r => r.mu)->Option.map(r => r)->Option.getOr(0.)
                  let userB =
                    b.rating->Option.flatMap(r => r.mu)->Option.map(r => r)->Option.getOr(0.)
                  userA < userB ? sortDir == Desc ? 1. : -1. : sortDir == Desc ? -1. : 1.
                })
                ->Array.map(edge => {
                  edge.user
                  ->Option.map(user => {
                    let disabled =
                      disabled
                      ->Option.map(
                        disabled => disabled->Array.findIndex(player => player.id == user.id) >= 0,
                      )
                      ->Option.getOr(false)
                    <FramerMotion.Li
                      layout=true
                      className="mt-4 flex w-full flex-none gap-x-4 px-6"
                      style={originX: 0.05, originY: 0.05}
                      key={user.id}
                      initial={opacity: 0., scale: 1.15}
                      animate={opacity: 1., scale: 1.}
                      exit={opacity: 0., scale: 1.15}>
                      <div className="flex-none">
                        <span className="sr-only"> {t`Player`} </span>
                        // <UserCircleIcon className="h-6 w-5 text-gray-400" aria-hidden="true" />
                      </div>
                      <div
                        className={Util.cx([
                          "text-sm w-full font-medium leading-6 text-gray-900",
                          disabled ? "opacity-50" : "",
                        ])}>
                        <a
                          href="#"
                          onClick={e => {
                            e->JsxEventU.Mouse.preventDefault

                            if disabled {
                              ()
                            } else {
                              onSelectPlayer->Option.map(f => f(edge))->ignore
                            }
                            ()
                          }}>
                          <EventRsvpUser
                            user={user.fragmentRefs}
                            highlight={selected->Array.findIndex(
                              player => player.id == user.id,
                            ) >= 0}
                            ratingPercent={edge.rating
                            ->Option.flatMap(
                              rating =>
                                rating.mu->Option.map(
                                  mu => (mu -. minRating) /. (maxRating -. minRating) *. 100.,
                                ),
                            )
                            ->Option.getOr(0.)}
                          />
                        </a>
                      </div>
                    </FramerMotion.Li>
                  })
                  ->Option.getOr(React.null)
                })
                ->React.array
              }}
            </FramerMotion.AnimatePresence>
          </ul>
          <em>
            {isLoadingNext
              ? React.string("...")
              : hasNext
              ? <a onClick={onLoadMore}> {t`load More`} </a>
              : React.null}
          </em>
        </>}
      </div>
    </div>
  }
}

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
module Match = {
  @react.component
  let make = (
    ~team1: array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node>,
    ~team2: array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node>,
    ~minRating,
    ~maxRating,
  ) => {
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
    <div className="grid grid-cols-2 gap-4 col-span-2">
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
    </div>
  }
}

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"
//@genType
//let default = make

@rhf
type inputsMatch = {
  scoreWinner: Zod.number,
  scoreLoser: Zod.number,
}

let schema = Zod.z->Zod.object(
  (
    {
      scoreWinner: Zod.z->Zod.number({})->Zod.Number.gte(0.),
      scoreLoser: Zod.z->Zod.number({})->Zod.Number.gte(0.),
    }: inputsMatch
  ),
)
let rot2 = (players, player) =>
  switch players {
  | [_, p2] => [p2, player]
  | [p1] => [p1, player]
  | [] => [player]
  | _ => [player]
  }
@genType @react.component
let make = (~event) => {
  open Form
  let {__id, activity} = Fragment.use(event)
  let {register, handleSubmit, setValue} = useFormOfInputsMatch(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {},
    },
  )
  let (commitMutationCreateLeagueMatch, _isMutationInFlight) = CreateLeagueMatchMutation.use()

  let (winningPlayers, setWinningPlayers) = React.useState(() => [])
  let (losingPlayers, setLosingPlayers) = React.useState(() => [])
  let (winningNodes, setWinningNodes) = React.useState(() => [])
  let (losingNodes, setLosingNodes) = React.useState(() => [])

  // let onCreateMatch = _ => {
  //   let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
  //     __id,
  //     "LeagueEventMatches_matches",
  //     (),
  //   )
  //   commitMutationCreateLeagueMatch(
  //     ~variables={
  //       matchInput: {
  //         activitySlug: "pickleball",
  //         namespace: "doubles:rec",
  //         doublesMatch: {
  //           winners: [],
  //           losers: [],
  //           score: [],
  //           createdAt: Js.Date.make()->Util.Datetime.fromDate,
  //         },
  //       },
  //       // id: __id->RescriptRelay.dataIdToString,
  //       connections: [connectionId],
  //     },
  //   )->RescriptRelay.Disposable.ignore
  // }

  let onSelectWinningNode = (
    node: AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node,
  ) => {
    switch winningNodes->Array.findIndex((
      node': AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node,
    ) => node'.__id == node.__id) >= 0 {
    | true => ()
    | false =>
      node.user
      ->Option.map(user => {
        setWinningPlayers(players => {
          players->rot2(user)
        })->ignore
      })
      ->ignore
      setWinningNodes(nodes => {
        nodes->rot2(node)
      })
    }
  }

  let onSelectLosingNode = (node: AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node) => {
    switch losingNodes->Array.findIndex((
      node': AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node,
    ) => node'.__id == node.__id) >= 0 {
    | true => ()
    | false =>
      node.user
      ->Option.map(user => {
        setLosingPlayers(players => {
          players->rot2(user)
        })->ignore
      })
      ->ignore
      setLosingNodes(nodes => {
        nodes->rot2(node)
      })
    }
  }

  let onSubmit = (data: inputsMatch) => {
    activity
    ->Option.flatMap(activity =>
      activity.slug->Option.map(slug => {
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
                winners: winningPlayers->Array.map(p => p.id),
                losers: losingPlayers->Array.map(p => p.id),
                score: [data.scoreWinner, data.scoreLoser],
                createdAt: Js.Date.make()->Util.Datetime.fromDate,
              },
            },
            connections: [connectionId],
          },
        )->RescriptRelay.Disposable.ignore
        setValue(ScoreWinner, Value(0.))
        setValue(ScoreLoser, Value(0.))
        ()
      })
    )
    ->ignore
    ()
  }

  let {data} = Fragment.usePagination(event)
  let players = data.rsvps->Fragment.getConnectionNodes
  let maxRating =
    players->Array.reduce(0., (acc, next) =>
      next.rating->Option.flatMap(r => r.mu)->Option.getOr(0.) > acc
        ? next.rating->Option.flatMap(r => r.mu)->Option.getOr(0.)
        : acc
    )
  let minRating =
    players->Array.reduce(maxRating, (acc, next) =>
      next.rating->Option.flatMap(r => r.mu)->Option.getOr(maxRating) < acc
        ? next.rating->Option.flatMap(r => r.mu)->Option.getOr(maxRating)
        : acc
    )

  <Layout.Container>
    <form onSubmit={handleSubmit(onSubmit)}>
      <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-2 md:gap-8">
        <div className="grid grid-cols-1 gap-4">
          <section ariaLabelledby="section-1-title" className="col-span-2">
            <h2 className="sr-only" id="section-1-title"> {"Winners"->React.string} </h2>
            <h2> {t`Select Winners`} </h2>
            <SelectEventPlayersList
              event={event}
              selected={winningPlayers}
              onSelectPlayer=onSelectWinningNode
              minRating
              maxRating
            />
          </section>
          <div className="mx-auto col-span-2">
            <Input
              className="w-11 sm:w-24 md:w-32  flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6"
              label={t`Winner Points`}
              type_="text"
              id="scoreWinner"
              register={register(
                ScoreWinner,
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
          <section ariaLabelledby="section-2-title" className="col-span-2">
            <h2 className="sr-only" id="section-2-title"> {"Losers"->React.string} </h2>
            <h2> {t`Select Losers`} </h2>
            <SelectEventPlayersList
              event={event}
              selected={losingPlayers}
              disabled={winningPlayers}
              onSelectPlayer=onSelectLosingNode
              minRating
              maxRating
            />
          </section>
          <div className="mx-auto col-span-2">
            <Input
              className="w-11 sm:w-24 md:w-32 block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6"
              label={t`Loser Points`}
              type_="text"
              id="scoreLoser"
              register={register(
                ScoreLoser,
                ~options={
                  setValueAs: v => v == "" ? 0. : Float.fromString(v)->Option.getOr(1.),
                },
              )}
            />
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4 md:col-span-2">
          <React.Suspense fallback={<div> {t`Loading`} </div>}>
            <Match team1={winningNodes} team2={losingNodes} minRating maxRating />
          </React.Suspense>
        </div>
        <div className="md:col-span-2 gap-4">
          <input
            type_="submit"
            className="mx-auto block text-3xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded"
            value="Submit"
          />
        </div>
      </div>
    </form>
  </Layout.Container>
}

// let loadMessages = lang => {
//   let messages = switch lang {
//   | "ja" => Lingui.import("../../locales/ja/organisms/EventRsvps.mjs")
//   | _ => Lingui.import("../../locales/en/organisms/EventRsvps.mjs")
//   }->Promise.thenResolve(messages => Lingui.i18n.load(lang, messages["messages"]))
//
//   [messages]->Array.concat(ViewerRsvpStatus.loadMessages(lang))
// }

@genType
let default = make
