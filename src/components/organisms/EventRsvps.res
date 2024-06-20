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
    maxRsvps->Option.flatMap(max => count >= max ? Some() : None)->Option.isSome
  }

  let waitlistCount =
    (rsvps->Array.length->Int.toFloat -.
      maxRsvps->Option.map(Int.toFloat)->Option.getOr(rsvps->Array.length->Int.toFloat))
    ->Math.max(0.)
    ->Float.toInt

  let maxRating =
    rsvps->Array.reduce(0., (acc, next) =>
      next.rating->Option.getOr(0.) > acc ? next.rating->Option.getOr(0.) : acc
    )
  let minRating =
    rsvps->Array.reduce(maxRating, (acc, next) =>
      next.rating->Option.getOr(maxRating) < acc ? next.rating->Option.getOr(maxRating) : acc
    )

  let joinButton = switch viewer.user {
  | Some(_) =>
    <button
      onClick=onJoin
      className="inline-flex w-full items-center justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600">
      {t`join event`}
    </button>
  | None =>
    <div className="text-center">
      <p><em> {t`login to join the event`} </em></p>
      <LoginLink className="mt-2 inline-block" />
      <button
        disabled=true
        className="mt-2 inline-flex w-full items-center justify-center rounded-md bg-red-200 px-3 py-2 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600">
        {t`join event`}
      </button>
    </div>
  }
  let leaveButton =
    <button
      onClick=onLeave
      className="inline-flex w-full items-center justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
      {t`leave event`}
    </button>
  <div className="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5">
    <dl className="flex flex-wrap">
      <div className="flex-auto pl-6 pt-4">
        <dt className="text-sm font-semibold leading-6 text-gray-900"> {t`confirmed`} </dt>
        <dd className="mt-1 text-base font-semibold leading-6 text-gray-900">
          {switch maxRsvps {
          | Some(max) =>
            <>
              {(Js.Math.min_int(rsvps->Array.length, max)->Int.toString ++
              " / " ++
              max->Int.toString ++ " ")->React.string}
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
              {t`waitlist`}
            </dd>
          | _ =>
            <dd
              className="rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-600 ring-1 ring-inset ring-green-600/20">
              {t`spots available`}
            </dd>
          }
        })
        ->Option.getOr(
          <dd
            className="rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-600 ring-1 ring-inset ring-green-600/20">
            {t`spots available`}
          </dd>,
        )}
      </div>
      <div className="mt-4 w-full flex-none gap-x-4 border-t border-gray-900/5 px-6 pt-4">
        {<>
          {spotsAvailable
          ->Option.map(count => {
            switch count {
            | 0 => viewerHasRsvp ? leaveButton : joinButton
            | _ => viewerHasRsvp ? leaveButton : joinButton
            }
          })
          ->Option.getOr({viewerHasRsvp ? leaveButton : joinButton})}
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
                        className="mt-4 flex w-full flex-none"
                        style={originX: 0.05, originY: 0.05}
                        key={user.id}
                        initial={opacity: 0., scale: 1.15}
                        animate={opacity: 1., scale: 1.}
                        exit={opacity: 0., scale: 1.15}>
                        <div className="flex-none">
                          <span className="sr-only"> {t`Player`} </span>
                          // <UserCircleIcon className="h-6 w-5 text-gray-400" aria-hidden="true" />
                        </div>
                        <div className="w-full text-sm font-medium leading-6 text-gray-900">
                          <EventRsvpUser
                            user={user.fragmentRefs}
                            rating=?edge.rating
                            ratingPercent={edge.rating
                            ->Option.map(
                              rating => (rating -. minRating) /. (maxRating -. minRating) *. 100.,
                            )
                            ->Option.getOr(0.)}
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
