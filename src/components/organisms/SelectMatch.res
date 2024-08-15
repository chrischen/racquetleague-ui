%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
open Rating
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
    // ~event,
    ~players: array<player>,
    ~selected: array<Player.t<'a>>,
    ~disabled: option<array<Player.t<'a>>>=?,
    ~onSelectPlayer: option<Player.t<'a> => unit>=?,
    ~minRating=0.,
    ~maxRating=1.,
  ) => {
    let (sortDir, setSortDir) = React.useState(_ => SortAction.Desc)

    <div className="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5">
      <div className="mt-4 gap-x-4 border-t border-gray-900/5 px-6 py-4">
        <SortAction sortDir setSortDir />
        {<>
          <ul className="w-full">
            <FramerMotion.AnimatePresence>
              {switch players {
              | [] => t`no players yet`
              | players =>
                players
                ->Array.toSorted((a, b) => {
                  let userA = a.rating.mu
                  let userB = b.rating.mu
                  userA < userB ? sortDir == Desc ? 1. : -1. : sortDir == Desc ? -1. : 1.
                })
                ->Array.map(player => {
                  let disabled =
                    disabled
                    ->Option.map(disabled => disabled->Array.findIndex(p => player.id == p.id) >= 0)
                    ->Option.getOr(false)

                  let percent = switch maxRating -. minRating {
                  | 0. => 0.
                  | _ => (player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.
                  }

                  <FramerMotion.Li
                    layout=true
                    className="mt-4 flex w-full flex-none gap-x-4"
                    style={originX: 0.05, originY: 0.05}
                    key={player.id}
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
                            onSelectPlayer->Option.map(f => f(player))->ignore
                          }
                          ()
                        }}>
                        {player.data
                        ->Option.flatMap(data => {
                          data.user->Option.map(
                            user => {
                              <EventRsvpUser
                                user={user.fragmentRefs}
                                highlight={selected->Array.findIndex(
                                  player => player.id == user.id,
                                ) >= 0}
                                ratingPercent=percent
                              />
                            },
                          )
                        })
                        ->Option.getOr(
                          <RsvpUser
                            user={makeGuest(player.name)}
                            highlight={selected->Array.findIndex(p => p.id == player.id) >= 0}
                            ratingPercent=percent
                          />,
                        )}
                      </a>
                    </div>
                  </FramerMotion.Li>
                })
                ->React.array
              }}
            </FramerMotion.AnimatePresence>
          </ul>
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
let make = (
  ~players: array<player>,
  ~activity: option<AiTetsu_event_graphql.Types.fragment_activity>,
  ~onMatchQueued,
  ~onMatchCompleted,
) => {
  let (leftNodes: array<Player.t<'a>>, setLeftNodes) = React.useState(() => [])
  let (rightNodes: array<Player.t<'a>>, setRightNodes) = React.useState(() => [])
  let (selectedMatch: option<match>, setSelectedMatch) = React.useState(() => None)
  // let {data} = Fragment.usePagination(event)
  // let players = data.rsvps->Fragment.getConnectionNodes

  let matchSelected = match => {
    switch (
      match: (
        array<player>,
        array<player>,
      )
    ) {
    | ([_, _], [_, _]) as match =>
      // onMatchSelected(match)
      // let match = (
      //   [players->Array.find(p => p.id == p1.id)->Option.getExn, players->Array.find(p => p.id == p2.id)->Option.getExn],
      //   [players->Array.find(p => p.id == p3.id)->Option.getExn, players->Array.find(p => p.id == p4.id)->Option.getExn],
      // )
      setSelectedMatch(_ => Some((match :> (array<player>, array<player>))))
    | _ => ()
    }
  }
  React.useEffect(() => {
    // Reset all selected values when players change, as the state of this
    // component will be outdated
    setLeftNodes(_ => [])
    setRightNodes(_ => [])
    setSelectedMatch(_ => None)
    None
  }, [players])
  let maxRating =
    players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
  let minRating =
    players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)
  let onSelectLeftNode = (node: Player.t<'a>) => {
    switch leftNodes->Array.findIndex((node': Player.t<'a>) => node'.id == node.id) >= 0 {
    | true => ()
    | false =>
      setLeftNodes(nodes => {
        let nodes = nodes->rot2((node :> Player.t<'a>))
        // onSelectLeftNodes(nodes)->ignore
        matchSelected((nodes, rightNodes))
        nodes
      })
    }
  }

  let onSelectRightNode = (node: Player.t<'a>) => {
    switch rightNodes->Array.findIndex((node': Player.t<'a>) => node'.id == node.id) >= 0 {
    | true => ()
    | false =>
      setRightNodes(nodes => {
        let nodes = nodes->rot2((node :> Player.t<'a>))
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
          // event={event}
          players
          selected={leftNodes}
          onSelectPlayer=onSelectLeftNode
          minRating
          maxRating
        />
      </section>
    </div>
    <div className="grid grid-cols-1 gap-4">
      <section ariaLabelledby="section-2-title" className="col-span-2">
        <h2 className="sr-only" id="section-2-title"> {"Losers"->React.string} </h2>
        <h2> {t`right team players`} </h2>
        <SelectEventPlayersList
          players
          selected={rightNodes}
          disabled={leftNodes}
          onSelectPlayer=onSelectRightNode
          minRating
          maxRating
        />
      </section>
    </div>
    <div className="grid grid-cols-1 md:col-span-2">
      {selectedMatch
      ->Option.map(match => <>
        <div className="text-center md:col-span-2">
          <UiAction onClick={() => onMatchQueued(match)}> {t`Queue Match`} </UiAction>
        </div>
        <React.Suspense fallback={<div> {t`Loading`} </div>}>
          {activity
          ->Option.map(activity =>
            <SubmitMatch
              match
              minRating
              maxRating
              activity
              // onSubmitted={() => {
              //   onMatchCompleted(match)
              //   setSelectedMatch(_ => None)
              // }}
              onComplete={match => {
                onMatchCompleted(match)
                setSelectedMatch(_ => None)
              }}
            />
          )
          ->Option.getOr(React.null)}
        </React.Suspense>
      </>)
      ->Option.getOr(React.null)}
    </div>
  </div>
}
