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
    club {
      id
    }
    ...RsvpWaitlist_event @arguments(after: $after, first: $first, before: $before)
    ...GoingRsvps_event @arguments(after: $after, first: $first, before: $before)
    ...PendingRsvps_event @arguments(after: $after, first: $first, before: $before)
    rsvps(after: $after, first: $first, before: $before)
      @connection(key: "RSVPSection_event_rsvps") {
      edges {
        node {
          id
          ...EventRsvp_rsvp
          ...MiniEventRsvp_rsvp
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

module RSVPSectionAddUserMutation = %relay(`
 mutation RSVPSectionAddUserMutation($connections: [ID!]!, $eventId: ID!, $userId: ID!) {
   addRsvpToEvent(eventId: $eventId, userId: $userId) {
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

    let onSubmit = e => {
      ReactEvent.Form.preventDefault(e)
      handleSave()
    }

    let content = switch message {
    | Some("") | None =>
      ts`Type a status message for people to see... such as 'I will arrive at 19:00.'`
    | Some(msg) => msg
    }

    if isEditing {
      <form onSubmit={onSubmit} className="flex items-center gap-x-2 mt-2">
        <div className="flex-grow">
          <input
            value=editedMessage
            onChange={e => setEditedMessage(ReactEvent.Form.target(e)["value"])}
            className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
          />
        </div>
        <button
          type_="submit"
          className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          {t`Save`}
        </button>
      </form>
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
  let {__id, maxRsvps, minRating, activity, viewerIsAdmin, club} = Fragment.use(event)
  let viewer = user->Option.map(user => UserFragment.use(user))
  let rsvps = data.rsvps->Fragment.getConnectionNodes

  // Mutation hooks
  let (commitMutationJoin, _joinInFlight) = RSVPSectionJoinMutation.use()
  let (commitMutationLeave, _leaveInFlight) = RSVPSectionLeaveMutation.use()
  let (commitMutationCreateRating, _createRatingInFlight) = RSVPSectionCreateRatingMutation.use()
  let (commitMutationAddUser, _addUserInFlight) = RSVPSectionAddUserMutation.use()

  let onLoadMore = _ =>
    startTransition(() => {
      loadNext(~count=80)->RescriptRelay.Disposable.ignore
    })

  // Handler to add a user to the event
  let handleAddUser = (user: AutocompleteUser.user) => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      __id,
      "RSVPSection_event_rsvps",
      None,
    )
    commitMutationAddUser(
      ~variables={
        connections: [connectionId],
        eventId: data.id,
        userId: user.id,
      },
      ~onCompleted=(_, _) => {
        Js.log2("Successfully added user to event:", user)
      },
      ~onError=error => {
        Js.log2("Error adding user to event:", error)
      },
    )->RescriptRelay.Disposable.ignore
  }

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

  // Check if event is full (confirmed RSVPs >= max capacity)
  let eventIsFull =
    maxRsvps->Option.map(max => confirmedRsvps->Array.length >= max)->Option.getOr(false)

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

  // UI state
  let (mobileExpanded, setMobileExpanded) = React.useState(() => false)

  let rsvpButtonStatus: EventSignupButton.status = switch viewer {
  | None => NotJoined(Login)
  | Some(_) =>
    if viewerInPending {
      Joined(Pending)
    } else if viewerHasRsvp {
      if viewerInWaitlist {
        Joined(Waitlisted)
      } else {
        Joined(Going)
      }
    } else if eventIsFull {
      NotJoined(JoinWaitlist)
    } else {
      NotJoined(Join)
    }
  }

  // Centralized confirmation logic for leave button
  let requireConfirmation =
    eventIsFull &&
    rsvps
    ->Array.filter(edge =>
      mainList
      ->Array.findIndex(e => e.id == edge.id)
      ->(i => isWaitlist(i))
    )
    ->Array.length > 0 &&
    switch rsvpButtonStatus {
    | Joined(Going) | Joined(Waitlisted) => true
    | _ => false
    }

  // Toggle mobile expanded state
  let toggleMobileExpanded = () => {
    let newMobileExpanded = !mobileExpanded
    setMobileExpanded(_ => newMobileExpanded)
  }

  <>
    <div
      className="fixed bottom-0 left-0 right-0 bg-white shadow-lg border-t md:border-t-0 md:rounded-lg md:shadow-sm md:p-6 md:mt-4 md:sticky md:top-4 z-10">
      // Mobile view
      <div className="md:hidden">
        <div className="p-4">
          {!mobileExpanded
            ? <div className="flex justify-between items-center">
                <div>
                  <EventSignupButton
                    onClick={_ => onRsvp("going")}
                    status=rsvpButtonStatus
                    className="py-2 px-4 rounded-md flex items-center justify-center space-x-1 text-base"
                    requireConfirmation
                  />
                </div>
                <div
                  className="flex items-center space-x-3 cursor-pointer"
                  onClick={_ => toggleMobileExpanded()}>
                  <h2 className="text-lg font-semibold"> {t`RSVP`} </h2>
                  <div className="flex -space-x-2">
                    {goingRsvps
                    ->Array.slice(~start=0, ~end=3)
                    ->Array.map(edge =>
                      <div key={edge.id} className="inline-block">
                        <MiniEventRsvp rsvp={edge.fragmentRefs} maxRating />
                      </div>
                    )
                    ->React.array}
                    {goingRsvps->Array.length > 3
                      ? <div
                          className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-gray-200 text-xs font-medium text-gray-800 cursor-pointer hover:bg-gray-300">
                          <div className="flex items-center">
                            {`+${(goingRsvps->Array.length - 3)->Int.toString}`->React.string}
                          </div>
                        </div>
                      : React.null}
                  </div>
                  <Lucide.ChevronUp
                    size=20
                    className={`text-gray-500 transition-transform ${mobileExpanded
                        ? "rotate-180"
                        : ""}`}
                  />
                </div>
              </div>
            : <div>
                <div
                  className="flex justify-between items-center cursor-pointer"
                  onClick={_ => toggleMobileExpanded()}>
                  <h2 className="text-lg font-semibold"> {t`RSVP`} </h2>
                  <Lucide.ChevronUp
                    size=20
                    className={`text-gray-500 transition-transform ${mobileExpanded
                        ? "rotate-180"
                        : ""}`}
                  />
                </div>
                <EventSignupButton
                  onClick={_ => onRsvp("going")}
                  status=rsvpButtonStatus
                  className="w-full py-2 px-4 rounded-md flex items-center justify-center space-x-1 mt-3"
                  requireConfirmation
                />
              </div>}
        </div>
        {mobileExpanded
          ? <div className="p-4 pt-0">
              {ratingWarning}
              {viewerHasRsvp
                ? <div className="mb-5">
                    <ViewerStatusMessage message={viewerStatusMessage} eventId={data.id} />
                  </div>
                : React.null}
              <div className="max-h-[60vh] overflow-y-auto">
                <GoingRsvps
                  event={data.fragmentRefs}
                  ?viewer
                  activitySlug=?{activity->Option.flatMap(a => a.slug)}
                  maxRating
                  className=?Some("mb-5")
                />
                <RsvpWaitlist
                  event={data.fragmentRefs}
                  ?viewer
                  activitySlug=?{activity->Option.flatMap(a => a.slug)}
                  maxRating
                />
                <PendingRsvps
                  event={data.fragmentRefs}
                  ?viewer
                  activitySlug=?{activity->Option.flatMap(a => a.slug)}
                  maxRating
                />
                {viewerIsAdmin
                  ? club
                    ->Option.map(c =>
                      <div className="mt-5">
                        <h3 className="text-sm font-medium text-gray-700 mb-2"> {t`Add Member`} </h3>
                        <AutocompleteUser clubId={c.id} onSelected={handleAddUser} />
                      </div>
                    )
                    ->Option.getOr(React.null)
                  : React.null}
              </div>
              <button
                onClick={_ => toggleMobileExpanded()}
                className="w-full py-3 mt-4 flex items-center justify-center text-blue-600 border-t border-gray-200">
                <span className="font-medium"> {t`Collapse`} </span>
                <Lucide.ChevronUp size=20 className="ml-1" />
              </button>
            </div>
          : React.null}
      </div>
      // Desktop View
      <div className="hidden md:block">
        <h2 className="text-lg font-semibold mb-4"> {t`RSVP`} </h2>
        {ratingWarning}
        <div className="mb-6">
          <EventSignupButton
            onClick={_ => onRsvp("going")}
            status=rsvpButtonStatus
            className="w-full py-2 px-4 rounded-md flex items-center justify-center space-x-1"
            requireConfirmation
          />
        </div>
        {viewerHasRsvp
          ? <div className="mb-5">
              <ViewerStatusMessage message={viewerStatusMessage} eventId={data.id} />
            </div>
          : React.null}
        <GoingRsvps
          event={data.fragmentRefs}
          ?viewer
          activitySlug=?{activity->Option.flatMap(a => a.slug)}
          maxRating
          className=?Some("mb-5")
        />
        <RsvpWaitlist
          event={data.fragmentRefs}
          ?viewer
          activitySlug=?{activity->Option.flatMap(a => a.slug)}
          maxRating
          className=?Some("mb-5")
        />
        <PendingRsvps
          event={data.fragmentRefs}
          ?viewer
          activitySlug=?{activity->Option.flatMap(a => a.slug)}
          maxRating
          className=?Some("mb-5")
        />
        {viewerIsAdmin
          ? club
            ->Option.map(c =>
              <div className="mb-5">
                <h3 className="text-sm font-medium text-gray-700 mb-2"> {t`Add Member`} </h3>
                <AutocompleteUser clubId={c.id} onSelected={handleAddUser} />
              </div>
            )
            ->Option.getOr(React.null)
          : React.null}
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
  </>
}
