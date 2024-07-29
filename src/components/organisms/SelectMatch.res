%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
module Fragment = %relay(`
  fragment SelectMatch_event on Event
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 50 }
  )
  @refetchable(queryName: "SelectMatchRsvpsRefetchQuery")
  {
    __id
    rsvps(after: $after, first: $first, before: $before)
    @connection(key: "SelectMatchRsvps_event_rsvps")
    {
      edges {
        node {
          __id
          user {
            id
            lineUsername
            ...EventRsvpUser_user
          }
          rating {
            id
            mu
            sigma
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
module SortAction = {
  type sortDir = Asc | Desc
  @react.component
  let make = (~sortDir, ~setSortDir) => {
    <UiAction onClick={() => {setSortDir(dir => dir == Asc ? Desc : Asc)}}>
      {switch sortDir {
      | Asc => <Lucide.ArrowUpNarrowWide />
      | Desc => <Lucide.ArrowDownWideNarrow />
      }}
    </UiAction>
  }
}
module SelectEventPlayersList = {
  @react.component
  let make = (
    ~event,
    ~selected: array<SelectMatch_event_graphql.Types.fragment_rsvps_edges_node_user>,
    ~disabled: option<array<SelectMatch_event_graphql.Types.fragment_rsvps_edges_node_user>>=?,
    ~onSelectPlayer: option<SelectMatch_event_graphql.Types.fragment_rsvps_edges_node => unit>=?,
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
let rot2 = (players, player) =>
  switch players {
  | [_, p2] => [p2, player]
  | [p1] => [p1, player]
  | [] => [player]
  | _ => [player]
  }

@react.component
let make = (~event, ~onMatchSelected) => {
  let (
    leftNodes: array<SelectMatch_event_graphql.Types.fragment_rsvps_edges_node>,
    setLeftNodes,
  ) = React.useState(() => [])
  let (
    rightNodes: array<SelectMatch_event_graphql.Types.fragment_rsvps_edges_node>,
    setRightNodes,
  ) = React.useState(() => [])
  let {data} = Fragment.usePagination(event)
  let players = data.rsvps->Fragment.getConnectionNodes

  let matchSelected = (match) => {
    switch match {
      | ([_, _], [_, _]) as match => onMatchSelected(match)
      | _ => ()
    }
  }
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
  let onSelectLeftNode = (node: SelectMatch_event_graphql.Types.fragment_rsvps_edges_node) => {
    switch leftNodes->Array.findIndex((
      node': SelectMatch_event_graphql.Types.fragment_rsvps_edges_node,
    ) => node'.__id == node.__id) >= 0 {
    | true => ()
    | false =>
      setLeftNodes(nodes => {
        let nodes = nodes->rot2((node :> SelectMatch_event_graphql.Types.fragment_rsvps_edges_node))
        // onSelectLeftNodes(nodes)->ignore
        matchSelected((nodes, rightNodes))
        nodes
      })
    }
  }

  let onSelectRightNode = (node: SelectMatch_event_graphql.Types.fragment_rsvps_edges_node) => {
    switch rightNodes->Array.findIndex((
      node': SelectMatch_event_graphql.Types.fragment_rsvps_edges_node,
    ) => node'.__id == node.__id) >= 0 {
    | true => ()
    | false =>
      setRightNodes(nodes => {
        let nodes = nodes->rot2((node :> SelectMatch_event_graphql.Types.fragment_rsvps_edges_node))
        // onSelectRightNodes(nodes)->ignore
        matchSelected((leftNodes, nodes))
        nodes
      })
    }
  }
  <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-2 md:gap-8">
    <div className="grid grid-cols-1 gap-4">
      <section ariaLabelledby="section-1-title" className="col-span-2">
        <h2 className="sr-only" id="section-1-title"> {"Winners"->React.string} </h2>
        <h2> {t`left team players`} </h2>
        <SelectEventPlayersList
          event={event}
          selected={leftNodes->Array.filterMap(n => n.user)}
          onSelectPlayer=onSelectLeftNode
          minRating
          maxRating
        />
      </section>
      <div className="mx-auto col-span-2" />
    </div>
    <div className="grid grid-cols-1 gap-4">
      <section ariaLabelledby="section-2-title" className="col-span-2">
        <h2 className="sr-only" id="section-2-title"> {"Losers"->React.string} </h2>
        <h2> {t`right team players`} </h2>
        <SelectEventPlayersList
          event={event}
          selected={rightNodes->Array.filterMap(n => n.user)}
          disabled={leftNodes->Array.filterMap(n => n.user)}
          onSelectPlayer=onSelectRightNode
          minRating
          maxRating
        />
      </section>
      <div className="mx-auto col-span-2" />
    </div>
  </div>
}
