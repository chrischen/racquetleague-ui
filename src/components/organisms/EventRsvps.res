%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment EventRsvps_event on Event
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 80 }
  )
  @refetchable(queryName: "EventRsvpsRefetchQuery") {
    __id
    maxRsvps
    minRating
    viewerIsAdmin
    activity {
      slug
    }
    rsvps(after: $after, first: $first, before: $before)
      @connection(key: "EventRsvps_event_rsvps") {
      edges {
        node {
          id
          ...EventRsvps_rsvp
          ...RsvpOptions_rsvp
          user {
            id
          }
          rating {
            ordinal
            mu
          }
          listType
          message
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
  @argumentDefinitions(eventId: { type: "ID!" }) {
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
 mutation EventRsvpsJoinMutation($connections: [ID!]!, $id: ID!) {
   joinEvent(eventId: $id) {
     edge @appendEdge(connections: $connections) {
       node {
         id
         user {
           id
           lineUsername
         }
         listType
       }
     }
   }
 }
`)

module EventRsvpsCreateRatingMutation = %relay(`
 mutation EventRsvpsCreateRatingMutation {
   createLeagueRating(
     input: { activitySlug: "pickleball", namespace: "doubles:rec" }
   ) {
     rating {
       id
     }
   }
 }
`)
module EventRsvpsLeaveMutation = %relay(`
 mutation EventRsvpsLeaveMutation($connections: [ID!]!, $id: ID!) {
   leaveEvent(eventId: $id) {
     eventIds @deleteEdge(connections: $connections)
     errors {
       message
     }
   }
 }
`)

module EventRsvpsUpdateMessageMutation = %relay(`
  mutation EventRsvpsUpdateMessageMutation($input: UpdateViewerRsvpMessageInput!) {
    updateViewerRsvpMessage(input: $input) {
      id
      message
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

let isRestrictedRsvp = listType => listType != Some(0) && listType != None

// This component displays the current user's status message and allows the user to edit it if clicked.

module ViewerStatusMessage = {
  @react.component
  let make = (~rsvpId, ~message: option<string>) => {
    let ts = Lingui.UtilString.t
    let (isEditing, setIsEditing) = React.useState(() => false)
    let (editedMessage, setEditedMessage) = React.useState(() => message->Option.getOr(""))
    let (
      commitMutationUpdateMessage,
      _updateMessageInFlight,
    ) = EventRsvpsUpdateMessageMutation.use()

    let handleSave = () => {
      commitMutationUpdateMessage(
        ~variables={input: {rsvpId, message: editedMessage}},
      )->RescriptRelay.Disposable.ignore
      setIsEditing(_ => false)
    }

    let content = switch message {
    | Some("") | None =>
      ts`Type a status message for people to see... such as 'I will arrive at 19:00.'`
    | Some(msg) => msg
    }

    if isEditing {
      <div className="flex items-center gap-x-2 mt-2">
        <div className="flex-grow">
          <input
            value=editedMessage
            onChange={e => setEditedMessage(ReactEvent.Form.target(e)["value"])}
            className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
          />
        </div>
        <button
          onClick={_ => handleSave()}
          className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          {t`Save`}
        </button>
      </div>
    } else {
      <div
        className="flex items-center text-sm text-gray-500 mt-4 group cursor-pointer"
        onClick={_ => setIsEditing(_ => true)}>
        <p className="flex-auto">
          {content->React.string}
          <Lucide.Pencil
            className="inline h-4 w-4 ml-2 text-gray-400 invisible group-hover:visible"
          />
        </p>
      </div>
    }
  }
}
//@genType
//let default = make
@react.component
let make = (~event, ~user) => {
  let (_isPending, startTransition) = ReactExperimental.useTransition()
  let {data, loadNext, isLoadingNext, hasNext} = Fragment.usePagination(event)
  let {__id, maxRsvps, minRating, activity} = Fragment.use(event)
  let viewer = user->Option.map(user => UserFragment.use(user))
  let rsvps = data.rsvps->Fragment.getConnectionNodes

  let isWaitlist = count => {
    maxRsvps->Option.flatMap(max => count >= max ? Some() : None)->Option.isSome
  }
  let mainList = rsvps->Array.filter(edge => edge.listType == None || edge.listType == Some(0))
  let confirmedRsvps =
    mainList
    ->Array.filterWithIndex((_, i) => !isWaitlist(i))
    ->Array.toSorted((a, b) => {
      let userA = a.rating->Option.flatMap(rating => rating.mu)->Option.getOr(0.)
      let userB = b.rating->Option.flatMap(rating => rating.mu)->Option.getOr(0.)
      userA < userB ? 1. : -1.
    })

  let waitlistRsvps = mainList->Array.filterWithIndex((_, i) => isWaitlist(i))
  let restrictedRsvps = rsvps->Array.filter(edge => isRestrictedRsvp(edge.listType))
  // let pageInfo = data.rsvps->Option.map(e => e.pageInfo)
  // let hasPrevious = pageInfo->Option.map(e => e.hasPreviousPage)->Option.getOr(false)
  let onLoadMore = _ =>
    startTransition(() => {
      loadNext(~count=1)->ignore
    })

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
      confirmedRsvps
      ->Array.findIndexOpt(edge =>
        edge.user->Option.map(user => viewer.id == user.id)->Option.getOr(false)
      )
      ->Option.map(_ => true)
    )
    ->Option.getOr(false)

  let viewerCanJoin: option<bool> = minRating->Option.map(minRating => {
    let rating =
      viewer
      ->Option.flatMap(viewer => viewer.eventRating->Option.flatMap(r => r.ordinal))
      ->Option.getOr(Rating.Rating.makeDefault()->Rating.Rating.ordinal)
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
      (max->Int.toFloat -. confirmedRsvps->Array.length->Int.toFloat)->Math.max(0.)->Float.toInt
    )

  let waitlistCount = waitlistRsvps->Array.length

  let maxRating =
    rsvps->Array.reduce(0., (acc, next) =>
      next.rating->Option.flatMap(r => r.mu)->Option.getOr(0.) > acc
        ? next.rating->Option.flatMap(r => r.mu)->Option.getOr(0.)
        : acc
    )
  // let minRsvpRating =
  //   rsvps->Array.reduce(maxRating, (acc, next) =>
  //     next.rating->Option.flatMap(r => r.mu)->Option.getOr(maxRating) < acc
  //       ? next.rating->Option.flatMap(r => r.mu)->Option.getOr(maxRating)
  //       : acc
  //   )

  let viewerLowerRating =
    viewer
    ->Option.flatMap(viewer => viewer.eventRating->Option.flatMap(r => r.ordinal))
    ->Option.getOr(Rating.Rating.makeDefault()->Rating.Rating.ordinal)
  let viewerUpperRating =
    viewer
    ->Option.flatMap(viewer => viewer.eventRating->Option.flatMap(r => r.mu))
    ->Option.getOr(Rating.Rating.makeDefault()->Rating.Rating.ordinal)
  let viewerStatusMessage = viewer->Option.flatMap(viewer =>
    rsvps
    ->Array.find(edge => edge.user->Option.map(user => viewer.id == user.id)->Option.getOr(false))
    ->Option.flatMap(edge => edge.message)
  )
  let viewerRsvpId = viewer->Option.flatMap(viewer =>
    rsvps
    ->Array.find(edge => edge.user->Option.map(user => viewer.id == user.id)->Option.getOr(false))
    ->Option.map(edge => edge.id)
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
          {t`Required rating: ${minRating
          ->Option.getOr(0.)
          ->Float.toFixed(~digits=2)} (DUPR ${minRating
          ->Option.getOr(0.)
          ->Rating.guessDupr
          ->Float.toFixed(~digits=2)})`}
          <br />
          {t`Your rating ${viewerLowerRating->Float.toFixed(
            ~digits=2,
          )} ~ ${viewerUpperRating->Float.toFixed(~digits=2)} (DUPR ${viewerLowerRating
          ->Rating.guessDupr
          ->Float.toFixed(~digits=2)} ~ ${viewerUpperRating
          ->Rating.guessDupr
          ->Float.toFixed(
            ~digits=2,
          )}) is too low. You will be placed in the pending list until the rating limit is lowered. Please join another JPL rated event to boost your rating.`}
        </WarningAlert>
        <button
          onClick=onJoin
          className="mt-2 w-full items-center justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600">
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
    <Button.Button
      onClick=onLeave
      className="inline-flex w-full items-center justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
      {t`leave event`}
    </Button.Button>
  let leaveButtonWithConfirmation =
    <ConfirmButton
      button={<Button.Button type_="button"> {t`leave event`} </Button.Button>}
      // className="inline-flex w-full items-center justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
      title={t`You will lose your spot`}
      description={t`This event is full, so leaving the event will give your spot to someone on the waitlist. If you rejoin, you will join the waitlist. Are you sure you want to leave this event?`}
      // confirmText={t`Leave`}
      // cancelText={t`Cancel`}
      onConfirmed=onLeave
      // Optional: specify confirm button color if default red is not desired
      // confirmButtonColor=#zinc
    />
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
        | 0 =>
          viewerHasRsvp ? viewerIsInEvent ? leaveButtonWithConfirmation : leaveButton : joinButton
        | _ => viewerHasRsvp ? leaveButton : joinButton
        }
      })
      ->Option.getOr({viewerHasRsvp ? leaveButton : joinButton})}
      {viewerRsvpId
      ->Option.map(rsvpId => <ViewerStatusMessage message={viewerStatusMessage} rsvpId={rsvpId} />)
      ->Option.getOr(React.null)}
    </div>
    <dl className="flex flex-wrap">
      <div className="flex-auto pl-6">
        <dt className="text-sm font-semibold leading-6 text-gray-900"> {t`confirmed`} </dt>
        <dd className="mt-1 text-base font-semibold leading-6 text-gray-900">
          {switch maxRsvps {
          | Some(max) =>
            <>
              {(Js.Math.min_int(confirmedRsvps->Array.length, max)->Int.toString ++
              " / " ++
              max->Int.toString ++ " ")->React.string}
              {plural(max, {one: "player", other: "players"})}
            </>
          | None =>
            <>
              {(confirmedRsvps->Array.length->Int.toString ++ " ")->React.string}
              {plural(confirmedRsvps->Array.length, {one: "player", other: "players"})}
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
              {switch confirmedRsvps {
              | [] => t`no players yet`
              | rsvps =>
                rsvps
                ->Array.mapWithIndex((edge, i) => {
                  let adminOptions = <RsvpOptions rsvp=edge.fragmentRefs __id />

                  {
                    data.viewerIsAdmin
                      ? <div
                          key={i->Int.toString}
                          className="flex items-center justify-between w-full gap-2">
                          <div className="flex-auto">
                            <EventRsvp rsvp=edge.fragmentRefs viewer activitySlug maxRating />
                          </div>
                          <div className="flex-none"> {adminOptions} </div>
                        </div>
                      : <EventRsvp
                          key={i->Int.toString} rsvp=edge.fragmentRefs viewer activitySlug maxRating
                        />
                  }
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
      <div className={Util.cx([expanded ? "" : "hidden sm:block", "w-full"])}>
        <div className="mt-4 border-t border-gray-900/5 pl-6 pt-4">
          <div className="flex-auto">
            <dt className="text-sm font-semibold leading-6 text-gray-900"> {t`waitlist`} </dt>
            <dd className="mt-1 text-base font-semibold leading-6 text-gray-900">
              {(waitlistCount->Int.toString ++ " ")->React.string}
              {plural(waitlistCount, {one: "player", other: "players"})}
            </dd>
          </div>
        </div>
        <div className="mt-4 flex w-full flex-col gap-x-4 border-t border-gray-900/5 px-6 py-4">
          {<>
            <ul className="">
              <FramerMotion.AnimatePresence>
                {switch waitlistRsvps {
                | [] => t`no players yet`
                | rsvps =>
                  rsvps
                  ->Array.map(edge => {
                    <EventRsvp rsvp=edge.fragmentRefs viewer activitySlug maxRating />
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
        <div className="mt-4 border-t border-gray-900/5 pl-6 pt-4">
          <div className="flex-auto">
            <dt className="text-sm font-semibold leading-6 text-gray-900"> {t`pending`} </dt>
            <dd className="mt-1 text-base font-semibold leading-6 text-gray-900">
              {(restrictedRsvps->Array.length->Int.toString ++ " ")->React.string}
              {plural(restrictedRsvps->Array.length, {one: "player", other: "players"})}
            </dd>
          </div>
        </div>
        <div className="mt-4 flex w-full flex-col gap-x-4 border-t border-gray-900/5 px-6 py-4">
          {<>
            <ul className="">
              <FramerMotion.AnimatePresence>
                {switch restrictedRsvps {
                | [] => t`no players yet`
                | rsvps =>
                  rsvps
                  ->Array.map(edge => {
                    <EventRsvp rsvp=edge.fragmentRefs viewer activitySlug maxRating />
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
