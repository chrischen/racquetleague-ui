%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment EventRsvps_event on Event
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 80 }
  )
  @refetchable(queryName: "EventRsvpsRefetchQuery")
  {
    __id
    maxRsvps
    minRating
    activity {
      slug
    }
    rsvps(after: $after, first: $first, before: $before)
    @connection(key: "EventRsvps_event_rsvps")
    {
      edges {
        node {
          user {
            id
            ...EventRsvpUser_user
          }
          rating {
            ordinal
            mu
            sigma
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
module UserFragment = %relay(`
  fragment EventRsvps_user on User
  @argumentDefinitions (
    eventId: { type: "ID!" }
  )
  {
    id
    lineUsername
    eventRating(eventId: $eventId) {
      ordinal
      mu
      sigma
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

module EventRsvpsCreateRatingMutation = %relay(`
 mutation EventRsvpsCreateRatingMutation
  {
    createLeagueRating(input: {activitySlug: "pickleball", namespace: "doubles:rec"}) {
      rating {
        id
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
@react.component
let make = (~event, ~user) => {
  let ts = Lingui.UtilString.t
  let (_isPending, startTransition) = ReactExperimental.useTransition()
  let {data, loadNext, isLoadingNext, hasNext} = Fragment.usePagination(event)
  let rsvps = data.rsvps->Fragment.getConnectionNodes

  // let pageInfo = data.rsvps->Option.map(e => e.pageInfo)
  // let hasPrevious = pageInfo->Option.map(e => e.hasPreviousPage)->Option.getOr(false)
  let onLoadMore = _ =>
    startTransition(() => {
      loadNext(~count=1)->ignore
    })

  let {__id, maxRsvps, minRating, activity} = Fragment.use(event)
  let viewer = user->Option.map(user => UserFragment.use(user))
  // let user = viewer->Option.flatMap(viewer => viewer.user)
  let (commitMutationLeave, _isMutationInFlight) = EventRsvpsLeaveMutation.use()
  let (commitMutationJoin, _isMutationInFlight) = EventRsvpsJoinMutation.use()
  let (commitMutationCreateRating, _) = EventRsvpsCreateRatingMutation.use()
  let (expanded, setExpanded) = React.useState(() => false)

  // let viewer = GlobalQuery.useViewer()
  // let viewer = viewer->Option.flatMap(viewer => viewer.user)

  let viewerHasRsvp =
    viewer
    ->Option.flatMap(viewer =>
      rsvps
      ->Array.find(edge => edge.user->Option.map(user => viewer.id == user.id)->Option.getOr(false))
      ->Option.map(_ => true)
    )
    ->Option.getOr(false)

  let viewerIsInEvent =
    viewer
    ->Option.flatMap(viewer =>
      rsvps
      ->Array.findIndexOpt(edge =>
        edge.user->Option.map(user => viewer.id == user.id)->Option.getOr(false)
      )
      ->Option.map(i => maxRsvps->Option.map(max => i < max)->Option.getOr(true))
    )
    ->Option.getOr(false)

  let viewerCanJoin: option<bool> = minRating->Option.map(minRating => {
    let rating =
      viewer
      ->Option.flatMap(viewer => viewer.eventRating->Option.flatMap(r => r.ordinal))
      ->Option.getOr(0.0)
    if rating < minRating {
      false
    } else {
      true
    }
  })

  let onJoin = _ => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      __id,
      "EventRsvps_event_rsvps",
      (),
    )
    commitMutationCreateRating(~variables=())->RescriptRelay.Disposable.ignore
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

  let activitySlug = activity->Option.flatMap(a => a.slug)

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
      next.rating->Option.flatMap(r => r.mu)->Option.getOr(0.) > acc
        ? next.rating->Option.flatMap(r => r.mu)->Option.getOr(0.)
        : acc
    )
  let minRsvpRating =
    rsvps->Array.reduce(maxRating, (acc, next) =>
      next.rating->Option.flatMap(r => r.mu)->Option.getOr(maxRating) < acc
        ? next.rating->Option.flatMap(r => r.mu)->Option.getOr(maxRating)
        : acc
    )

  let joinButton = switch viewer {
  | Some(_) =>
    switch viewerCanJoin {
    | Some(true) | None =>
      <button
        onClick=onJoin
        className="w-full items-center justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600">
        {t`join event`}
      </button>
    | _ =>
      <div className="text-center">
        <WarningAlert cta={""->React.string} ctaClick={() => ()}>
          {t`required rating: ${minRating->Option.getOr(0.0)->Float.toFixed(~digits=2)}`}
          <br />
          {t`your rating ${viewer
          ->Option.flatMap(viewer => viewer.eventRating->Option.flatMap(r => r.ordinal))
          ->Option.getOr(0.0)
          ->Float.toFixed(
            ~digits=2,
          )} is too low. please join a JPL open event to boost your rating. the fastest way is to play and beat Jai a couple of times`}
        </WarningAlert>
        <button
          disabled=true
          className="mt-2 w-full items-center justify-center rounded-md bg-red-200 px-3 py-2 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600">
          {t`join event`}
        </button>
      </div>
    }
  | None =>
    <div className="text-center">
      <p>
        <em> {t`login to join the event`} </em>
      </p>
      <LoginLink className="mt-2 inline-block" />
      <button
        disabled=true
        className="mt-2 w-full items-center justify-center rounded-md bg-red-200 px-3 py-2 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600">
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
  <div className="rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5 flex flex-col">
    <h2 className="sr-only"> {t`attendees`} </h2>
    <div className="flex-auto p-6 pt-4">
      {viewerHasRsvp
        ? viewerIsInEvent
            ? <div className="border-l-4 border-green-400 bg-green-50 p-4 mb-2">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <HeroIcons.ExclamationTriangleIcon
                      \"aria-hidden"="true" className="h-5 w-5 text-green-400"
                    />
                  </div>
                  <div className="ml-3">
                    <p className="text-sm text-green-700"> {t`you're going :)`} </p>
                  </div>
                </div>
              </div>
            : <div className="border-l-4 border-yellow-400 bg-yellow-50 p-4 mb-2">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <HeroIcons.ExclamationTriangleIcon
                      \"aria-hidden"="true" className="h-5 w-5 text-yellow-400"
                    />
                  </div>
                  <div className="ml-3">
                    <p className="text-sm text-yellow-700"> {t`you're waitlisted :(`} </p>
                  </div>
                </div>
              </div>
        : React.null}
      {spotsAvailable
      ->Option.map(count => {
        switch count {
        | 0 => viewerHasRsvp ? leaveButton : joinButton
        | _ => viewerHasRsvp ? leaveButton : joinButton
        }
      })
      ->Option.getOr({viewerHasRsvp ? leaveButton : joinButton})}
    </div>
    <dl className="flex flex-wrap">
      <div className="flex-auto pl-6">
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
      <div className="mt-4 w-full flex flex-col gap-x-4 border-t border-gray-900/5 px-6 pt-4">
        {<>
          <ul className={Util.cx([expanded ? "" : "hidden sm:block"])}>
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
                            link={"/league/" ++
                            activitySlug->Option.getOr("badminton") ++
                            "/p/" ++
                            user.id}
                            user={user.fragmentRefs}
                            rating=?{edge.rating->Option.flatMap(r => r.mu)}
                            sigma=?{edge.rating->Option.flatMap(r => r.sigma)}
                            sigmaPercent={edge.rating
                            ->Option.flatMap(
                              rating =>
                                rating.sigma->Option.map(sigma => 3. *. sigma /. maxRating *. 100.),
                            )
                            ->Option.getOr(0.)}
                            ratingPercent={edge.rating
                            ->Option.flatMap(
                              rating =>
                                rating.mu->Option.flatMap(
                                  mu =>
                                    rating.sigma->Option.map(
                                      sigma => (mu -. sigma *. 3.0) /. maxRating *. 100.,
                                    ),
                                ),
                            )
                            ->Option.getOr(0.)}
                            highlight={viewer
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
            {switch viewerCanJoin {
            | Some(true) | None =>
              <FramerMotion.Li
                className="mt-4 flex w-full flex-none gap-x-4 px-6"
                style={originX: 0.05, originY: 0.05}
                key="viewer"
                initial={opacity: 0., scale: 1.15}
                animate={opacity: 1., scale: 1.}
                exit={opacity: 0., scale: 1.15}>
                <ViewerRsvpStatus onJoin onLeave joined={viewerHasRsvp} />
              </FramerMotion.Li>
            | _ => React.null
            }}
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
      <div className={Util.cx([expanded ? "" : "hidden sm:block"])}>
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
                              link={"/league/" ++
                              activitySlug->Option.getOr("badminton") ++
                              "/p/" ++
                              user.id}
                              user={user.fragmentRefs}
                              rating=?{edge.rating->Option.flatMap(r => r.ordinal)}
                              sigmaPercent={edge.rating
                              ->Option.flatMap(
                                rating =>
                                  rating.sigma->Option.map(
                                    sigma => 3. *. sigma /. maxRating *. 100.,
                                  ),
                              )
                              ->Option.getOr(0.)}
                              ratingPercent={edge.rating
                              ->Option.flatMap(
                                rating =>
                                  rating.mu->Option.flatMap(
                                    mu =>
                                      rating.sigma->Option.map(
                                        sigma => (mu -. sigma *. 3.0) /. maxRating *. 100.,
                                      ),
                                  ),
                              )
                              ->Option.getOr(0.)}
                              highlight={viewer
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
      </div>
    </dl>
    <UiAction
      className="sm:hidden p-3 w-full flex flex-col items-center hover:bg-gray-100"
      onClick={_ => setExpanded(expanded => !expanded)}>
      {expanded ? React.null : <HeroIcons.Users className="inline w-5 h-5" />}
      {expanded
        ? <HeroIcons.ChevronUpIcon className="inline w-5 h-5" />
        : <HeroIcons.ChevronDownIcon className="inline w-5 h-5" />}
    </UiAction>
  </div>
}
