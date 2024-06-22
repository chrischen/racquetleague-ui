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
          user {
            id
            ...EventRsvpUser_user
          }
          rating
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
    }
  }
`)

module SelectEventPlayersList = {
  @react.component
  let make = (~event, ~selected: array<string>, ~onSelectPlayer: string => unit=?) => {
    let (_isPending, startTransition) = ReactExperimental.useTransition()
    let {data, loadNext, isLoadingNext, hasNext} = Fragment.usePagination(event)
    let players = data.rsvps->Fragment.getConnectionNodes
    let onLoadMore = _ =>
      startTransition(() => {
        loadNext(~count=1)->ignore
      })
    // let viewer = GlobalQuery.useViewer()

    let maxRating =
      players->Array.reduce(0., (acc, next) =>
        next.rating->Option.getOr(0.) > acc ? next.rating->Option.getOr(0.) : acc
      )
    let minRating =
      players->Array.reduce(maxRating, (acc, next) =>
        next.rating->Option.getOr(maxRating) < acc ? next.rating->Option.getOr(maxRating) : acc
      )
    <div className="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5">
      <div className="mt-4 flex w-full flex-none gap-x-4 border-t border-gray-900/5 px-6 py-4">
        {<>
          <ul className="w-full">
            <FramerMotion.AnimatePresence>
              {switch players {
              | [] => t`no players yet`
              | players =>
                players
                ->Array.toSorted((a, b) => {
                  let userA = a.rating->Option.map(r => r)->Option.getOr(0.)
                  let userB = b.rating->Option.map(r => r)->Option.getOr(0.)
                  userA < userB ? 1. : -1.
                })
                ->Array.mapWithIndex((edge, i) => {
                  edge.user
                  ->Option.map(user => {
                    <FramerMotion.Li
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
                      <div className="text-sm w-full font-medium leading-6 text-gray-900">
                        <a
                          href="#"
                          onClick={e => {
                            e->JsxEventU.Mouse.preventDefault
                            onSelectPlayer->Option.map(f => f(user.id))->ignore
                            ()
                          }}>
                          <EventRsvpUser
                            link=false
                            user={user.fragmentRefs}
                            highlight={selected->Array.findIndex(id => id == user.id) >= 0}
                            ratingPercent={edge.rating
                            ->Option.map(
                              rating => (rating -. minRating) /. (maxRating -. minRating) *. 100.,
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
@genType @react.component
let make = (~event) => {
  open Form
  let {__id, activity} = Fragment.use(event)
  let {register, handleSubmit, formState, getFieldState, setValue, watch} = useFormOfInputsMatch(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {},
    },
  )
  let (commitMutationCreateLeagueMatch, _isMutationInFlight) = CreateLeagueMatchMutation.use()

  let (winningPlayers, setWinningPlayers) = React.useState(() => [])
  let (losingPlayers, setLosingPlayers) = React.useState(() => [])

  let viewer = GlobalQuery.useViewer()

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

  let onSelectWinningPlayer = playerId => {
    setWinningPlayers(players => {
      switch players {
      | [_, p2] => [p2, playerId]
      | [p1] => [p1, playerId]
      | [] => [playerId]
      | _ => [playerId]
      }
    })
  }

  let onSelectLosingPlayer = playerId => {
    setLosingPlayers(players => {
      switch players {
      | [_, p2] => [p2, playerId]
      | [p1] => [p1, playerId]
      | [] => [playerId]
      | _ => [playerId]
      }
    })
  }

  let onSubmit = (data: inputsMatch) => {
    Js.log(data)

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
                winners: winningPlayers,
                losers: losingPlayers,
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

  <Layout.Container>
    <form onSubmit={handleSubmit(onSubmit)}>
      <div className="grid grid-cols-1 items-start gap-4 lg:grid-cols-4 lg:gap-8">
        <div className="grid grid-cols-1 gap-4 lg:col-span-2">
          <section ariaLabelledby="section-1-title" className="col-span-2">
            <h2 className="sr-only" id="section-1-title"> {"Winners"->React.string} </h2>
            <h2> {t`Select Winners`} </h2>
            <SelectEventPlayersList
              event={event} selected={winningPlayers} onSelectPlayer=onSelectWinningPlayer
            />
          </section>
          <div className="mx-auto col-span-2">
            <Input
              className="w-11 sm:w-24 md:w-32  flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6"
              label={t`Winner Points`}
              type_="number"
              id="scoreWinner"
              register={register(
                ScoreWinner,
                ~options={
                  setValueAs: v => {
                    Js.log("Set value as")
                    Js.log(v)
                    v == "" ? 0. : Float.fromString(v)->Option.getOr(1.)
                  },
                },
              )}
            />
          </div>
        </div>
        <div className="grid grid-cols-2 lg:col-span-2 gap-4">
          <section ariaLabelledby="section-2-title" className="col-span-2">
            <h2 className="sr-only" id="section-2-title"> {"Losers"->React.string} </h2>
            <h2> {t`Select Losers`} </h2>
            <SelectEventPlayersList
              event={event} selected={losingPlayers} onSelectPlayer=onSelectLosingPlayer
            />
          </section>
          <div className="mx-auto col-span-2">
            <Input
              className="w-11 sm:w-24 md:w-32 block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6"
              label={t`Loser Points`}
              type_="number"
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
        <div className="lg:col-span-4 gap-4">
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
