%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module EventQuery = %relay(`
  query PkEventPageQuery(
    $eventId: ID!
    $topic: String!
    $after: String
    $first: Int
    $before: String
  ) {
    ...ProfileModal_viewer
    viewer {
      user {
        id
        lineUsername
        email
        ...PkRSVPSection_user @arguments(eventId: $eventId)
      }
    }
    event(id: $eventId) {
      __id
      id
      title
      startDate
      endDate
      timezone
      tags
      listed
      viewerIsAdmin
      viewerHasRsvp
      deleted
      shadow
      details
      maxRsvps
      price
      activity {
        name
        slug
      }
      club {
        name
        slug
      }
      location {
        id
        name
        details
        address
        links
        coords {
          lat
          lng
        }
        ...GMap_location
      }
      owner {
        id
        lineUsername
        picture
      }
      rsvps(first: 100) {
        edges {
          node {
            id
            listType
            user {
              id
            }
          }
        }
      }
      ...PkRSVPSection_event
    }
    ...PkEventMessages_query @arguments(topic: $topic, after: $after, first: $first, before: $before)
  }
`)

module JoinEventMutation = %relay(`
  mutation PkEventPageJoinMutation($connections: [ID!]!, $eventId: ID!) {
    joinEvent(eventId: $eventId) {
      edge @appendEdge(connections: $connections) {
        node {
          id
          listType
          user {
            id
            lineUsername
          }
          rating {
            ordinal
            mu
            sigma
          }
        }
      }
      errors { message }
    }
  }
`)

module LeaveEventMutation = %relay(`
  mutation PkEventPageLeaveMutation($connections: [ID!]!, $eventId: ID!) {
    leaveEvent(eventId: $eventId) {
      eventIds @deleteEdge(connections: $connections)
      errors { message }
    }
  }
`)

module EventCancelMutation = %relay(`
  mutation PkEventPageCancelMutation($eventId: ID!) {
    cancelEvent(eventId: $eventId) {
      event {
        id
        listed
        deleted
      }
    }
  }
`)

module EventUncancelMutation = %relay(`
  mutation PkEventPageUncancelMutation($eventId: ID!) {
    uncancelEvent(eventId: $eventId) {
      event {
        id
        listed
        deleted
      }
    }
  }
`)

type loaderData = PkEventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

module Inner = {
  @react.component
  let make = (
    ~event: PkEventPageQuery_graphql.Types.response_event,
    ~viewer: option<PkEventPageQuery_graphql.Types.response_viewer>,
    ~queryFragmentRefs: RescriptRelay.fragmentRefs<
      [> #ProfileModal_viewer | #PkEventMessages_query],
    >,
  ) => {
    let viewerUser = viewer->Option.flatMap(v => v.user)
    let ts = Lingui.UtilString.t
    let td = Lingui.UtilString.dynamic
    let locale = React.useContext(LangProvider.LocaleContext.context)

    let (mounted, setMounted) = React.useState(() => false)
    React.useEffect0(() => {
      setMounted(_ => true)
      None
    })

    let (isProfileModalOpen, setIsProfileModalOpen) = React.useState(() => false)
    let (pendingJoinAction, setPendingJoinAction) = React.useState(() => None)
    let (localRsvpState, setLocalRsvpState) = React.useState(() => None)

    let (showFullDetails, setShowFullDetails) = React.useState(() => false)
    let (showLeaveConfirm, setShowLeaveConfirm) = React.useState(() => false)
    let (cancelEvent, canceling) = EventCancelMutation.use()
    let (uncancelEvent, uncanceling) = EventUncancelMutation.use()
    let (joinEvent, joining) = JoinEventMutation.use()
    let (leaveEvent, leaving) = LeaveEventMutation.use()

    let hasCompleteProfile = () =>
      switch viewerUser {
      | Some(user) =>
        switch (user.lineUsername, user.email) {
        | (Some(u), Some(e)) => u != "" && e != ""
        | _ => false
        }
      | None => false
      }

    let secret = event.shadow->Option.getOr(false)
    let tz = event.timezone->Option.getOr("Asia/Tokyo")
    let maxRsvps = event.maxRsvps->Option.getOr(0)

    let durationStr = event.startDate->Option.flatMap(startDate =>
      event.endDate->Option.map(endDate => {
        let mins =
          endDate
          ->Util.Datetime.toDate
          ->DateFns.differenceInMinutes(startDate->Util.Datetime.toDate)
        let hours = Js.Math.floor_float(mins /. 60.)
        let minutes = mod(mins->Float.toInt, 60)
        if hours > 0. && minutes > 0 {
          Float.toString(hours) ++ "h " ++ Int.toString(minutes) ++ "m"
        } else if hours > 0. {
          Float.toString(hours) ++ "h"
        } else {
          Int.toString(minutes) ++ "m"
        }
      })
    )

    let allRsvpNodes =
      event.rsvps
      ->Option.map(r =>
        r.edges->Option.getOr([])->Array.filterMap(e => e)->Array.filterMap(e => e.node)
      )
      ->Option.getOr([])
    let confirmedPlayers =
      allRsvpNodes->Array.filter(p => p.listType == Some(0) || p.listType == None)
    let waitlistPlayers =
      maxRsvps > 0
        ? confirmedPlayers->Array.slice(~start=maxRsvps, ~end=confirmedPlayers->Array.length)
        : []
    let isFull = maxRsvps > 0 && confirmedPlayers->Array.length >= maxRsvps
    let isJoined = switch localRsvpState {
    | Some(v) => v
    | None => event.viewerHasRsvp->Option.getOr(false)
    }

    /* Top Bar */
    <div className="relative w-full max-w-2xl mx-auto bg-white dark:bg-[#1e1f23]">
      <div
        className="bg-white dark:bg-[#1e1f23] border-b border-gray-100 dark:border-[#2a2b30] px-5 py-3 flex items-center justify-between flex-shrink-0">
        <div
          className="font-mono text-[11px] text-gray-500 dark:text-gray-400 flex items-center gap-1">
          {event.startDate
          ->Option.map(sd =>
            <ReactIntl.FormattedDate
              weekday=#short
              day=#"2-digit"
              month=#short
              value={sd->Util.Datetime.toDate}
              timeZone=tz
            />
          )
          ->Option.getOr(React.null)}
          {" "->React.string}
          {event.startDate
          ->Option.map(sd =>
            <ReactIntl.FormattedTime value={sd->Util.Datetime.toDate} timeZone=tz />
          )
          ->Option.getOr(React.null)}
          {event.endDate
          ->Option.map(ed => <>
            {" - "->React.string}
            <ReactIntl.FormattedTime value={ed->Util.Datetime.toDate} timeZone=tz />
          </>)
          ->Option.getOr(React.null)}
          {durationStr->Option.map(d => (" · " ++ d)->React.string)->Option.getOr(React.null)}
        </div>
      </div>
      <div className="flex-1 overflow-y-auto pb-24">
        /* Title */
        <div className="px-5 pt-4 pb-3 border-b border-gray-100 dark:border-[#2a2b30]">
          {event.deleted
          ->Option.map(_ =>
            <span
              className="inline-flex mb-2 items-center px-2 py-0.5 rounded text-xs font-mono bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400">
              {(ts`CANCELED`)->React.string}
            </span>
          )
          ->Option.getOr(React.null)}
          <h1
            className={Util.cx([
              "text-lg font-semibold leading-tight",
              event.deleted->Option.isSome
                ? "line-through text-gray-400 dark:text-gray-500"
                : "text-gray-900 dark:text-gray-100",
            ])}>
            {event.activity
            ->Option.flatMap(a =>
              a.slug->Option.map(slug => <>
                <Router.Link
                  to={"/e/" ++ slug}
                  className="text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 font-normal">
                  {td(a.name->Option.getOr(slug))->React.string}
                </Router.Link>
                <span className="text-gray-300 dark:text-gray-600 mx-1.5 font-normal">
                  {"/"->React.string}
                </span>
              </>)
            )
            ->Option.getOr(React.null)}
            {(secret ? "---" : event.title->Option.getOr("Event"))->React.string}
          </h1>
          {event.club
          ->Option.flatMap(club =>
            club.slug->Option.map(slug =>
              <Router.Link
                to={"/clubs/" ++ slug}
                className="text-xs text-gray-600 dark:text-gray-300 mt-1 block hover:underline">
                {club.name->Option.getOr(slug)->React.string}
              </Router.Link>
            )
          )
          ->Option.getOr(React.null)}
          <ResponsiveTooltip.Provider>
            <div className="flex flex-wrap items-center gap-1.5 mt-2">
              {event.listed == Some(false) ? <EventTag tag="unlisted" /> : React.null}
              {event.tags->Option.getOr([])->Array.some(t => t->String.toLowerCase == "comp")
                ? <EventTag tag="comp" />
                : React.null}
              {event.tags
              ->Option.getOr([])
              ->Array.filter(t => t->String.toLowerCase != "comp")
              ->Array.mapWithIndex((tag, i) => <EventTag key={Int.toString(i)} tag />)
              ->React.array}
              <span className="font-mono text-xs font-medium text-gray-700 dark:text-gray-300">
                {event.price
                ->Option.map(p =>
                  if p == 0 {
                    ts`Free`
                  } else {
                    Int.toString(p) ++ "円"
                  }
                )
                ->Option.getOr("???円")
                ->React.string}
              </span>
            </div>
          </ResponsiveTooltip.Provider>
        </div>
        /* Admin controls */
        {switch (event.viewerIsAdmin, viewerUser) {
        | (true, Some(_)) =>
          <div className="px-5 py-3 border-b border-gray-100 dark:border-[#2a2b30]">
            <div className="flex flex-row gap-2">
              <Button.Button
                href={"/events/update/" ++
                event.id ++
                "/" ++
                event.location->Option.map(l => l.id)->Option.getOr("")}>
                {t`edit event`}
              </Button.Button>
              {switch event.deleted {
              | Some(_) =>
                <Button.Button
                  onClick={_ =>
                    !uncanceling ? uncancelEvent(~variables={eventId: event.id})->ignore : ()}>
                  {t`uncancel event`}
                </Button.Button>
              | None =>
                <Button.Button
                  onClick={_ =>
                    !canceling ? cancelEvent(~variables={eventId: event.id})->ignore : ()}>
                  {t`cancel event`}
                </Button.Button>
              }}
            </div>
          </div>
        | _ => React.null
        }}
        /* Location */
        {switch (event.location, secret) {
        | (Some(loc), false) =>
          <div className="px-5 py-4 border-b border-gray-100 dark:border-[#2a2b30]">
            <h2
              className="font-mono text-xs tracking-wider text-gray-400 dark:text-gray-500 uppercase mb-3">
              {(ts`Location`)->React.string}
            </h2>
            <div
              className="h-24 rounded-lg border border-gray-200 dark:border-[#3a3b40] mb-3 overflow-hidden">
              <GMap location={loc.fragmentRefs} />
            </div>
            <p className="font-mono text-sm font-medium text-gray-900 dark:text-gray-100">
              <Router.Link to={`/locations/${loc.id}`} className="hover:underline">
                {loc.name->Option.getOr("?")->React.string}
              </Router.Link>
            </p>
            {loc.details
            ->Option.map(d => {
              let limit = 100
              let isTruncatable = String.length(d) > limit
              let displayText =
                !showFullDetails && isTruncatable ? String.slice(d, ~start=0, ~end=limit) : d
              <p className="font-mono text-xs text-gray-500 dark:text-gray-400 mt-1">
                {displayText->React.string}
                {isTruncatable
                  ? <button
                      onClick={_ => setShowFullDetails(v => !v)}
                      className="ml-1 text-blue-500 hover:underline font-mono text-xs">
                      {(showFullDetails ? ts`less` : ts`...more`)->React.string}
                    </button>
                  : React.null}
              </p>
            })
            ->Option.getOr(React.null)}
            {loc.address
            ->Option.map(addr => {
              let defaultLink = loc.links->Option.flatMap(links => links->Array.get(0))
              let mapsUrl =
                defaultLink
                ->Option.orElse(
                  loc.coords->Option.map(c =>
                    `https://maps.google.com/?q=${Float.toString(c.lat)},${Float.toString(c.lng)}`
                  ),
                )
                ->Option.getOr(`https://maps.google.com/?q=${addr}`)
              <a
                href=mapsUrl
                target="_blank"
                rel="noopener noreferrer"
                className="font-mono text-xs text-gray-500 dark:text-gray-400 mt-1 block hover:underline">
                {addr->React.string}
              </a>
            })
            ->Option.getOr(React.null)}
          </div>
        | _ => React.null
        }}
        /* Participants */
        <PkRSVPSection
          event={event.fragmentRefs} user=?{viewerUser->Option.map(u => u.fragmentRefs)}
        />
        /* Host */
        // {event.owner
        // ->Option.map(owner =>
        //   <div className="px-5 py-4 border-b border-gray-100 dark:border-[#2a2b30]">
        //     <h2
        //       className="font-mono text-[10px] tracking-wider text-gray-400 dark:text-gray-500 uppercase mb-3">
        //       {(ts`Host`)->React.string}
        //     </h2>
        //     <div className="flex items-center gap-2.5">
        //       <div
        //         className="w-9 h-9 rounded-full overflow-hidden bg-gray-100 dark:bg-[#2a2b30] flex items-center justify-center text-xs font-medium text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-[#3a3b40] flex-shrink-0">
        //         {switch owner.picture {
        //         | Some(url) =>
        //           <img
        //             src=url
        //             alt={owner.lineUsername->Option.getOr("?")}
        //             className="w-full h-full object-cover"
        //           />
        //         | None =>
        //           owner.lineUsername->Option.map(makeInitials)->Option.getOr("?")->React.string
        //         }}
        //       </div>
        //       <div className="text-sm font-medium text-gray-900 dark:text-gray-100">
        //         {owner.lineUsername->Option.getOr("?")->React.string}
        //       </div>
        //     </div>
        //   </div>
        // )
        // ->Option.getOr(React.null)}
        /* Notes */
        {event.details
        ->Option.map(details =>
          <div className="px-5 py-4 border-b border-gray-100 dark:border-[#2a2b30]">
            <h2
              className="font-mono text-xs tracking-wider text-gray-400 dark:text-gray-500 uppercase mb-3">
              {(ts`Notes from the host`)->React.string}
            </h2>
            <div className="space-y-2">
              {details
              ->String.split("\n")
              ->Array.mapWithIndex((line, i) =>
                <p
                  key={Int.toString(i)}
                  className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
                  {line->React.string}
                </p>
              )
              ->React.array}
            </div>
          </div>
        )
        ->Option.getOr(React.null)}
        /* Round-robin draws */
        {switch event.activity {
        | Some(activity) =>
          switch activity.slug {
          | Some(("pickleball" | "badminton") as slug) =>
            let managerHref = "/league/events/" ++ event.id ++ "/" ++ slug ++ "/manager"
            mounted
              ? <React.Suspense fallback=React.null>
                  <RoundRobinDrawsPreview eventId=event.id managerHref />
                </React.Suspense>
              : React.null
          | _ => React.null
          }
        | None => React.null
        }}
        /* Activity feed */
        <PkEventMessages queryRef=queryFragmentRefs eventId=event.id isJoined />
      </div>
      /* Sticky footer */
      {switch (event.deleted, viewerUser) {
      | (None, Some(_)) =>
        switch event.shadow {
        | Some(true) => React.null
        | _ =>
          <div
            className="sticky bottom-0 bg-white dark:bg-[#1e1f23] border-t border-gray-200 dark:border-[#2a2b30] px-5 py-3 flex items-center justify-between flex-shrink-0">
            <div
              className="font-mono text-[11px] font-medium text-gray-600 dark:text-gray-400 uppercase tracking-wider flex items-center gap-1">
              {event.startDate
              ->Option.map(sd =>
                <ReactIntl.FormattedDate
                  weekday=#short
                  day=#"2-digit"
                  month=#short
                  value={sd->Util.Datetime.toDate}
                  timeZone=tz
                />
              )
              ->Option.getOr(React.null)}
              {" "->React.string}
              {event.startDate
              ->Option.map(sd =>
                <ReactIntl.FormattedTime value={sd->Util.Datetime.toDate} timeZone=tz />
              )
              ->Option.getOr(React.null)}
              <span className="text-gray-400 dark:text-gray-500 font-normal normal-case">
                {(" \u00B7 " ++
                Int.toString(confirmedPlayers->Array.length) ++ (
                  maxRsvps > 0 ? "/" ++ Int.toString(maxRsvps) : ""
                ))->React.string}
              </span>
            </div>
            <div className="flex items-center gap-2.5">
              {isJoined
                ? <button
                    className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-transparent border border-gray-200 dark:border-[#3a3b40] rounded-md hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors"
                    disabled={leaving}
                    onClick={_ => {
                      if waitlistPlayers->Array.length > 0 {
                        setShowLeaveConfirm(_ => true)
                      } else {
                        let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
                          event.__id,
                          "PkRSVPSection_event_rsvps",
                          (),
                        )
                        leaveEvent(
                          ~variables={eventId: event.id, connections: [connectionId]},
                        )->ignore
                        setLocalRsvpState(_ => Some(false))
                      }
                    }}>
                    {(ts`Leave`)->React.string}
                  </button>
                : <button
                    className={Util.cx([
                      "px-4 py-2 text-sm font-semibold rounded-md transition-colors border",
                      isFull
                        ? "bg-white dark:bg-transparent border-gray-200 dark:border-[#3a3b40] text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#2a2b30]"
                        : "bg-[#bdf25d] text-black hover:bg-[#aee050] border-transparent",
                    ])}
                    disabled={joining}
                    onClick={_ => {
                      let proceed = () => {
                        let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
                          event.__id,
                          "PkRSVPSection_event_rsvps",
                          (),
                        )
                        joinEvent(
                          ~variables={eventId: event.id, connections: [connectionId]},
                        )->ignore
                        setLocalRsvpState(_ => Some(true))
                      }
                      if hasCompleteProfile() {
                        proceed()
                      } else {
                        setPendingJoinAction(_ => Some(proceed))
                        setIsProfileModalOpen(_ => true)
                      }
                    }}>
                    {(
                      isFull
                        ? ts`Join waitlist (#${Int.toString(waitlistPlayers->Array.length + 1)})`
                        : ts`Claim spot`
                    )->React.string}
                  </button>}
            </div>
          </div>
        }
      | (None, None) =>
        switch event.shadow {
        | Some(true) => React.null
        | _ =>
          <div
            className="sticky bottom-0 bg-white dark:bg-[#1e1f23] border-t border-gray-200 dark:border-[#2a2b30] px-5 py-3 flex items-center justify-between flex-shrink-0">
            <div
              className="font-mono text-[11px] font-medium text-gray-600 dark:text-gray-400 uppercase tracking-wider flex items-center gap-1">
              {event.startDate
              ->Option.map(sd =>
                <ReactIntl.FormattedDate
                  weekday=#short
                  day=#"2-digit"
                  month=#short
                  value={sd->Util.Datetime.toDate}
                  timeZone=tz
                />
              )
              ->Option.getOr(React.null)}
              {" "->React.string}
              {event.startDate
              ->Option.map(sd =>
                <ReactIntl.FormattedTime value={sd->Util.Datetime.toDate} timeZone=tz />
              )
              ->Option.getOr(React.null)}
              <span className="text-gray-400 dark:text-gray-500 font-normal normal-case">
                {(" \u00B7 " ++
                Int.toString(confirmedPlayers->Array.length) ++ (
                  maxRsvps > 0 ? "/" ++ Int.toString(maxRsvps) : ""
                ))->React.string}
              </span>
            </div>
            <div className="flex items-center gap-2.5">
              <Router.Link
                to={"/oauth-login?return=" ++
                I18n.getLangPath(locale.lang) ++
                "/events/" ++
                event.id}
                className={Util.cx([
                  "px-4 py-2 text-sm font-semibold rounded-md transition-colors border",
                  isFull
                    ? "bg-white dark:bg-transparent border-gray-200 dark:border-[#3a3b40] text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#2a2b30]"
                    : "bg-[#bdf25d] text-black hover:bg-[#aee050] border-transparent",
                ])}>
                {(isFull ? ts`Join waitlist` : ts`Claim spot`)->React.string}
              </Router.Link>
            </div>
          </div>
        }
      | _ => React.null
      }}
      <ProfileModal
        isOpen=isProfileModalOpen
        onClose={_ => {
          setIsProfileModalOpen(_ => false)
          setPendingJoinAction(_ => None)
        }}
        onProfileComplete={() => {
          pendingJoinAction->Option.forEach(action => action())
          setPendingJoinAction(_ => None)
        }}
        query=queryFragmentRefs
      />
      <ConfirmDialog
        title={t`Leave event`}
        description={t`There are players on the waitlist. If you leave, your spot will be given to the next person. Are you sure?`}
        setIsOpen={setShowLeaveConfirm}
        isOpen={showLeaveConfirm}
        onConfirmed={_ => {
          let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
            event.__id,
            "PkRSVPSection_event_rsvps",
            (),
          )
          leaveEvent(~variables={eventId: event.id, connections: [connectionId]})->ignore
          setLocalRsvpState(_ => Some(false))
        }}
      />
    </div>
  }
}

module Lazy = {
  @react.component
  let make = (~eventId: string) => {
    let {event, viewer, fragmentRefs: queryFragmentRefs} = EventQuery.use(
      ~variables={eventId, topic: eventId ++ ".updated"},
    )
    event
    ->Option.map(event => <Inner event viewer queryFragmentRefs />)
    ->Option.getOr(<div className="p-6 text-center text-gray-500"> {t`Event not found`} </div>)
  }
}

@genType @react.component
let make = () => {
  let query = useLoaderData()
  let {event, viewer, fragmentRefs: queryFragmentRefs} = EventQuery.usePreloaded(
    ~queryRef=query.data,
  )
  <WaitForMessages>
    {() =>
      event
      ->Option.map(event => <Inner event viewer queryFragmentRefs />)
      ->Option.getOr(<div className="p-6 text-center text-gray-500"> {t`Event not found`} </div>)}
  </WaitForMessages>
}
