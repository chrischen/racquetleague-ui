%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

// No need for simple rsvp type - we'll use GraphQL fragments directly

module Fragment = %relay(`
  fragment RSVPSection_event on Event
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 80 }
  )
  @refetchable(queryName: "RSVPSectionRefetchQuery") {
    __id
    id
    maxRsvps
    minRating
    viewerIsAdmin
    activity {
      slug
    }
    rsvps(after: $after, first: $first, before: $before)
      @connection(key: "RSVPSection_event_rsvps") {
      edges {
        node {
          id
          ...EventRsvp_rsvp
          ...RsvpOptions_rsvp
          user {
            id
            picture
            lineUsername
          }
          rating {
            ordinal
            mu
            sigma
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
  fragment RSVPSection_user on User
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

module RSVPSectionJoinMutation = %relay(`
 mutation RSVPSectionJoinMutation($connections: [ID!]!, $id: ID!) {
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

module RSVPSectionCreateRatingMutation = %relay(`
 mutation RSVPSectionCreateRatingMutation {
   createLeagueRating(
     input: { activitySlug: "pickleball", namespace: "doubles:rec" }
   ) {
     rating {
       id
     }
   }
 }
`)

module RSVPSectionLeaveMutation = %relay(`
 mutation RSVPSectionLeaveMutation($connections: [ID!]!, $id: ID!) {
   leaveEvent(eventId: $id) {
     eventIds @deleteEdge(connections: $connections)
     errors {
       message
     }
   }
 }
`)

module RSVPSectionUpdateMessageMutation = %relay(`
  mutation RSVPSectionUpdateMessageMutation($connections: [ID!]!, $input: UpdateViewerRsvpMessageInput!) {
    updateViewerRsvpMessage(input: $input) {
      rsvp {
        id
        message
      }
      edge @prependEdge(connections: $connections) {
        node {
          id
          payload
          createdAt
          topic
        }
      }
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

let isRestrictedRsvp = listType => listType != Some(0) && listType != None

// This component displays the current user's status message and allows the user to edit it if clicked.
module ViewerStatusMessage = {
  @react.component
  let make = (~eventId, ~message: option<string>) => {
    let ts = Lingui.UtilString.t
    let (isEditing, setIsEditing) = React.useState(() => false)
    let (editedMessage, setEditedMessage) = React.useState(() => message->Option.getOr(""))
    let (
      commitMutationUpdateMessage,
      _updateMessageInFlight,
    ) = RSVPSectionUpdateMessageMutation.use()

    let handleSave = () => {
      let trimmedMessage = editedMessage->String.trim

      // Only save if the message is not empty
      if trimmedMessage != "" {
        let connectionId =
          "client:root"
          ->RescriptRelay.makeDataId
          ->EventMessages.Fragment.Operation.makeConnectionId(~topic=eventId ++ ".updated")

        commitMutationUpdateMessage(
          ~variables={connections: [connectionId], input: {eventId, message: trimmedMessage}},
        )->RescriptRelay.Disposable.ignore
      }
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

@react.component
let make = (~event, ~user) => {
  let (_isPending, startTransition) = ReactExperimental.useTransition()
  let {data, loadNext, isLoadingNext, hasNext} = Fragment.usePagination(event)
  let {__id, maxRsvps, minRating, activity} = Fragment.use(event)
  let viewer = user->Option.map(user => UserFragment.use(user))
  let rsvps = data.rsvps->Fragment.getConnectionNodes

  // Mutation hooks
  let (commitMutationJoin, _joinInFlight) = RSVPSectionJoinMutation.use()
  let (commitMutationLeave, _leaveInFlight) = RSVPSectionLeaveMutation.use()
  let (commitMutationCreateRating, _createRatingInFlight) = RSVPSectionCreateRatingMutation.use()

  let onLoadMore = _ =>
    startTransition(() => {
      loadNext(~count=80)->RescriptRelay.Disposable.ignore
    })

  // Data processing - separate RSVPs by list type
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
      userB > userA ? 1. : userB < userA ? -1. : 0.
    })
  let waitlistRsvps = mainList->Array.filterWithIndex((_, i) => isWaitlist(i))
  let restrictedRsvps = rsvps->Array.filter(edge => isRestrictedRsvp(edge.listType))

  // Viewer state calculations
  let viewerRsvp =
    viewer->Option.flatMap(viewer =>
      rsvps->Array.find(edge =>
        edge.user->Option.map(user => viewer.id == user.id)->Option.getOr(false)
      )
    )

  let viewerHasRsvp = viewerRsvp->Option.isSome

  // Determine if viewer is in waitlist, confirmed, or pending list
  let (viewerInWaitlist, viewerInPending) =
    viewerRsvp
    ->Option.map(rsvp => {
      // Check if viewer is in restricted/pending list
      if isRestrictedRsvp(rsvp.listType) {
        (false, true)
      } else {
        // Check if viewer is in waitlist vs confirmed
        let viewerIndex = mainList->Array.findIndex(edge => edge.id == rsvp.id)
        if viewerIndex >= 0 {
          (isWaitlist(viewerIndex), false)
        } else {
          (false, false)
        }
      }
    })
    ->Option.getOr((false, false))

  // Rating validation logic
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

  // Rating warning alert
  let ratingWarning = switch viewer {
  | Some(_) =>
    switch viewerCanJoin {
    | Some(false) =>
      <div className="mb-3">
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
      </div>
    | _ => React.null
    }
  | None => React.null
  }

  // Action handlers
  let onJoin = _ => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      __id,
      "RSVPSection_event_rsvps",
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
      "RSVPSection_event_rsvps",
      (),
    )
    commitMutationLeave(
      ~variables={
        id: __id->RescriptRelay.dataIdToString,
        connections: [connectionId],
      },
    )->RescriptRelay.Disposable.ignore
  }

  let onRsvp = (status: string) => {
    switch status {
    | "going" =>
      if !viewerHasRsvp {
        onJoin()
      } else {
        // If already going, leave the event
        onLeave()
      }
    | _ => ()
    }
  }

  // Calculate maximum rating for display purposes
  let maxRating = rsvps->Array.reduce(0., (max, edge) => {
    let currentRating = edge.rating->Option.flatMap(rating => rating.mu)->Option.getOr(0.)
    currentRating > max ? currentRating : max
  })

  // Use GraphQL edges directly instead of converting to simple records
  let goingRsvps = confirmedRsvps

  // Determine button text and style
  let (buttonText, buttonStyle) = if viewerHasRsvp {
    if viewerInPending {
      (t`Pending`, "bg-red-600 text-white") // Red for pending/restricted
    } else if viewerInWaitlist {
      (t`You're Waitlisted`, "bg-yellow-500 text-white") // Yellow for waitlisted
    } else {
      (t`You're Going`, "bg-green-600 text-white") // Green for confirmed going
    }
  } else {
    (t`Join`, "bg-green-100 text-green-800 hover:bg-green-200") // Default join state
  }

  // UI state
  let (expanded, setExpanded) = React.useState(() => false)
  let initialDisplayCount = 3
  let displayedGoingRsvps = expanded
    ? goingRsvps
    : goingRsvps->Array.slice(~start=0, ~end=initialDisplayCount)

  <div
    className="fixed bottom-0 left-0 right-0 bg-white shadow-lg border-t md:border-t-0 md:relative md:rounded-lg md:shadow-sm md:mt-4 z-10 max-h-[75vh] md:max-h-none flex flex-col">
    <div className="p-4 md:p-6 flex-shrink-0">
      <h2 className="text-lg font-semibold mb-4"> {t`RSVP`} </h2>
      {ratingWarning}
      // RSVP Button
      <div className="flex mb-6">
        <button
          onClick={_ => onRsvp("going")}
          className={"w-full py-2 px-4 rounded-md flex items-center justify-center space-x-1 " ++
          buttonStyle}>
          <HeroIcons.CheckIcon className="w-4 h-4" />
          <span> {buttonText} </span>
        </button>
      </div>
      <div className="mb-5">
        {viewerHasRsvp
          ? <ViewerStatusMessage message={viewerStatusMessage} eventId={data.id} />
          : React.null}
      </div>
    </div>
    <div className="flex-1 overflow-y-auto p-4 md:p-6 pt-0 md:pt-0">
      // Going Section
      <div className="mb-5">
        <div className="flex justify-between items-center mb-3">
          <h3 className="font-medium text-gray-900">
            {t`Going`}
            {" ("->React.string}
            {goingRsvps->Array.length->Int.toString->React.string}
            {")"->React.string}
          </h3>
          {goingRsvps->Array.length > initialDisplayCount ||
          waitlistRsvps->Array.length > 0 ||
          restrictedRsvps->Array.length > 0 ||
          restrictedRsvps->Array.length > 0
            ? <button
                onClick={_ => setExpanded(prev => !prev)}
                className="text-sm text-blue-600 hover:text-blue-800 flex items-center">
                {expanded
                  ? <>
                      <span> {t`Show less`} </span>
                      <HeroIcons.ChevronUpIcon className="w-4 h-4 ml-1" />
                    </>
                  : <>
                      <span> {t`Show all`} </span>
                      <HeroIcons.ChevronDownIcon className="w-4 h-4 ml-1" />
                    </>}
              </button>
            : React.null}
        </div>
        <div className="flex flex-wrap gap-3">
          {displayedGoingRsvps
          ->Array.mapWithIndex((edge, _) =>
            <EventRsvp
              key={edge.id}
              rsvp={edge.fragmentRefs}
              viewer
              activitySlug={activity->Option.flatMap(a => a.slug)}
              maxRating={maxRating}
            />
          )
          ->React.array}
          {!expanded && goingRsvps->Array.length > initialDisplayCount
            ? <div
                className="flex items-center cursor-pointer text-blue-600 hover:text-blue-800"
                onClick={_ => setExpanded(_ => true)}>
                <span className="text-sm">
                  {t`+${(goingRsvps->Array.length - initialDisplayCount)->Int.toString} more`}
                </span>
              </div>
            : React.null}
        </div>
      </div>
      // Maybe Section - Only show when expanded (using waitlist data)
      {expanded && waitlistRsvps->Array.length > 0
        ? <div>
            <h3 className="font-medium text-gray-900 mb-3">
              {t`Waitlist`}
              {" ("->React.string}
              {waitlistRsvps->Array.length->Int.toString->React.string}
              {")"->React.string}
            </h3>
            <div className="space-y-2">
              {waitlistRsvps
              ->Array.mapWithIndex((edge, i) =>
                <div key={edge.id} className="flex items-center space-x-3">
                  <span
                    className="flex-shrink-0 w-6 h-6 bg-gray-100 rounded-full flex items-center justify-center text-xs font-medium text-gray-600">
                    {(i + 1)->Int.toString->React.string}
                  </span>
                  <EventRsvp
                    rsvp={edge.fragmentRefs}
                    viewer
                    activitySlug={activity->Option.flatMap(a => a.slug)}
                    maxRating={maxRating}
                  />
                </div>
              )
              ->React.array}
            </div>
          </div>
        : React.null}
      // Pending Section - Only show when expanded and has pending users
      {expanded && restrictedRsvps->Array.length > 0
        ? <div className="mt-5">
            <h3 className="font-medium text-gray-900 mb-3">
              {t`Pending`}
              {" ("->React.string}
              {restrictedRsvps->Array.length->Int.toString->React.string}
              {")"->React.string}
            </h3>
            <div className="flex flex-wrap gap-3">
              {restrictedRsvps
              ->Array.mapWithIndex((edge, _) =>
                <EventRsvp
                  key={edge.id}
                  rsvp={edge.fragmentRefs}
                  viewer
                  activitySlug={activity->Option.flatMap(a => a.slug)}
                  maxRating={maxRating}
                />
              )
              ->React.array}
            </div>
          </div>
        : React.null}
      // Load more if available
      {hasNext || isLoadingNext
        ? <div className="mt-4 text-center">
            {isLoadingNext
              ? <span className="text-sm text-gray-500"> {t`Loading...`} </span>
              : <button
                  className="text-sm font-medium text-blue-600 hover:underline"
                  onClick={_ => onLoadMore()}>
                  {t`Load more`}
                </button>}
          </div>
        : React.null}
    </div>
  </div>
}
