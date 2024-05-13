%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment EventRsvps_event on Event
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
  )
  @refetchable(queryName: "EventRsvpsRefetchQuery")
  {
    __id
    maxRsvps
    rsvps(after: $after, first: $first, before: $before)
    @connection(key: "EventRsvps_event_rsvps")
    {
      edges {
        node {
          user {
            id
            ...EventRsvpUser_user
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
module EventRsvpsJoinMutation = %relay(`
 mutation EventRsvpsJoinMutation(
    $connections: [ID!]!
    $id: ID!
  ) {
    joinEvent(eventId: $id) {
      edge @appendEdge(connections: $connections) {
        node {
          id
          user {
            id
            lineUsername
          }
        }
      }
    }
  }
`)
module EventRsvpsLeaveMutation = %relay(`
 mutation EventRsvpsLeaveMutation(
    $connections: [ID!]!
    $id: ID!
  ) {
    leaveEvent(eventId: $id) {
      eventIds @deleteEdge(connections: $connections)
      errors {
        message
      }
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"
//@genType
//let default = make
@genType @react.component
let make = (~event) => {
  let (_isPending, startTransition) = ReactExperimental.useTransition()
  let {data, loadNext, isLoadingNext, hasNext} = Fragment.usePagination(event)
  let rsvps = data.rsvps->Fragment.getConnectionNodes

  // let pageInfo = data.rsvps->Option.map(e => e.pageInfo)
  // let hasPrevious = pageInfo->Option.map(e => e.hasPreviousPage)->Option.getOr(false)
  let onLoadMore = _ =>
    startTransition(() => {
      loadNext(~count=1)->ignore
    })

  let {__id, maxRsvps} = Fragment.use(event)
  let (commitMutationLeave, _isMutationInFlight) = EventRsvpsLeaveMutation.use()
  let (commitMutationJoin, _isMutationInFlight) = EventRsvpsJoinMutation.use()

  let viewer = GlobalQuery.useViewer()

  let viewerHasRsvp =
    viewer.user
    ->Option.flatMap(viewer =>
      rsvps
      ->Array.find(edge => edge.user->Option.map(user => viewer.id == user.id)->Option.getOr(false))
      ->Option.map(_ => true)
    )
    ->Option.getOr(false)

  let onJoin = _ => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      __id,
      "EventRsvps_event_rsvps",
      (),
    )
    commitMutationJoin(
      ~variables={
        id: __id->RescriptRelay.dataIdToString,
        connections: [connectionId],
      },
    )->RescriptRelay.Disposable.ignore
  }
  let onLeave = _ => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      __id,
      "EventRsvps_event_rsvps",
      (),
    )
    commitMutationLeave(
      ~variables={
        id: __id->RescriptRelay.dataIdToString,
        connections: [connectionId],
      },
    )->RescriptRelay.Disposable.ignore
  }

  let spotsAvailable =
    maxRsvps->Option.map(max =>
      (max->Int.toFloat -. rsvps->Array.length->Int.toFloat)->Math.max(0.)->Float.toInt
    )

  let isWaitlist = count => {
    maxRsvps->Option.flatMap(max => count > max ? Some() : None)->Option.isSome
  }

  let waitlistCount =
    (rsvps->Array.length->Int.toFloat -.
      maxRsvps->Option.map(Int.toFloat)->Option.getOr(rsvps->Array.length->Int.toFloat))
    ->Math.max(0.)
    ->Float.toInt

  <div className="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5">
    <dl className="flex flex-wrap">
      <div className="flex-auto pl-6 pt-4">
        <dt className="text-sm font-semibold leading-6 text-gray-900"> {t`confirmed`} </dt>
        <dd className="mt-1 text-base font-semibold leading-6 text-gray-900">
          {switch maxRsvps {
          | Some(max) =>
            <>
              {(rsvps->Array.length->Int.toString ++ " / " ++ max->Int.toString ++ " ")->React.string}
              {plural(max, {one: "player", other: "players"})}
            </>
          | None =>
            <>
              {(rsvps->Array.length->Int.toString ++ " ")->React.string}
              {plural(rsvps->Array.length, {one: "player", other: "players"})}
            </>
          }}
        </dd>
      </div>
      <div className="flex-none self-end px-6 pt-4">
        <dt className="sr-only"> {"Status"->React.string} </dt>
        {spotsAvailable
        ->Option.map(count => {
          switch count {
          | 0 =>
            <dd
              className="rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-600 ring-1 ring-inset ring-yellow-600/20">
              {viewerHasRsvp ? <button onClick=onLeave>{t`leave event`}</button> : <button onClick=onJoin>{t`join waitlist`}</button>}
            </dd>
          | _ =>
            <dd
              className="rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-600 ring-1 ring-inset ring-green-600/20">
              {viewerHasRsvp ? <button onClick=onLeave>{t`leave event`}</button> : <button onClick=onJoin>{t`join event`}</button>}
            </dd>
          }
        })
        ->Option.getOr(
          <dd
            className="rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-600 ring-1 ring-inset ring-green-600/20">
              {viewerHasRsvp ? <button onClick=onLeave>{t`leave event`}</button> : <button onClick=onJoin>{t`join event`}</button>}
          </dd>,
        )}
      </div>
      <div className="mt-4 flex w-full flex-none gap-x-4 border-t border-gray-900/5 px-6 pt-4">
        {<>
          <ul className="">
            <FramerMotion.AnimatePresence>
              {switch rsvps {
              | [] => t`no players yet`
              | rsvps =>
                rsvps
                ->Array.mapWithIndex((edge, i) => {
                  edge.user
                  ->Option.map(user => {
                    switch isWaitlist(i) {
                    | false =>
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
                        <div className="text-sm font-medium leading-6 text-gray-900">
                          <EventRsvpUser
                            user={user.fragmentRefs}
                            highlight={viewer.user
                            ->Option.map(viewer => viewer.id == user.id)
                            ->Option.getOr(false)}
                          />
                        </div>
                      </FramerMotion.Li>
                    | true => React.null
                    }
                  })
                  ->Option.getOr(React.null)
                })
                ->React.array
              }}
            </FramerMotion.AnimatePresence>
            <FramerMotion.Li
              className="mt-4 flex w-full flex-none gap-x-4 px-6"
              style={originX: 0.05, originY: 0.05}
              key="viewer"
              initial={opacity: 0., scale: 1.15}
              animate={opacity: 1., scale: 1.}
              exit={opacity: 0., scale: 1.15}>
              <ViewerRsvpStatus onJoin onLeave joined={viewerHasRsvp} />
            </FramerMotion.Li>
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
      <div className="mt-4 border-t border-gray-900/5 pl-6 pt-4">
        <div className="flex-auto">
          <dt className="text-sm font-semibold leading-6 text-gray-900"> {t`waitlist`} </dt>
          <dd className="mt-1 text-base font-semibold leading-6 text-gray-900">
            {(waitlistCount->Int.toString ++ " ")->React.string}
            {plural(waitlistCount, {one: "player", other: "players"})}
          </dd>
        </div>
      </div>
      <div className="mt-4 flex w-full flex-none gap-x-4 border-t border-gray-900/5 px-6 py-4">
        {<>
          <ul className="">
            <FramerMotion.AnimatePresence>
              {switch rsvps {
              | [] => t`no players yet`
              | rsvps =>
                rsvps
                ->Array.mapWithIndex((edge, i) => {
                  edge.user
                  ->Option.map(user => {
                    switch isWaitlist(i) {
                    | true =>
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
                        <div className="text-sm font-medium leading-6 text-gray-900">
                          <EventRsvpUser
                            user={user.fragmentRefs}
                            highlight={viewer.user
                            ->Option.map(viewer => viewer.id == user.id)
                            ->Option.getOr(false)}
                          />
                        </div>
                      </FramerMotion.Li>
                    | false => React.null
                    }
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
    </dl>
  </div>
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
