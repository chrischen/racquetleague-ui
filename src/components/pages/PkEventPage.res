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
      viewerIsBanned
      deleted
      shadow
      details
      maxRsvps
      cancelDeadline
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
        stripeChargesEnabled
      }
      rsvps(first: 100) @connection(key: "PkRSVPSection_event_rsvps") {
        edges {
          node {
            id
            listType
            joinTime
            user {
              id
            }
            payment {
              id
              status
              currency
            }
          }
        }
      }
      ...PkRSVPSection_event
    }
    ...PkEventMessages_query @arguments(topic: $topic, after: $after, first: $first, before: $before)
  }
`)

module ChargePaymentMutation = %relay(`
  mutation PkEventPageChargePaymentMutation($rsvpId: ID!) {
    chargeRsvpPayment(rsvpId: $rsvpId) {
      clientSecret
      connectedAccountId
      errors { message }
    }
  }
`)

module AuthorizePlatformPaymentMutation = %relay(`
  mutation PkEventPageAuthorizePlatformPaymentMutation($rsvpId: ID!) {
    authorizePlatformRsvpPayment(rsvpId: $rsvpId) {
      clientSecret
      errors { message }
    }
  }
`)

module ConfirmPaymentMutation = %relay(`
  mutation PkEventPageConfirmPaymentMutation($rsvpId: ID!, $paymentIntentId: String!) {
    confirmRsvpPayment(rsvpId: $rsvpId, paymentIntentId: $paymentIntentId) {
      rsvp {
        id
        payment {
          id
          ...PaymentIndicator_payment
        }
        listType
      }
      errors { message }
    }
  }
`)

module StripePaymentEmbed = {
  @module("../organisms/StripePaymentEmbed") @react.component
  external make: (
    ~clientSecret: string,
    ~stripeAccountId: string,
    ~onSuccess: string => unit,
    ~onClose: unit => unit,
    ~isDepositOnly: bool=?,
  ) => React.element = "StripePaymentEmbed"
}

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

@val @scope(("navigator", "clipboard")) external writeToClipboard: string => Js.Promise.t<unit> = "writeText"
@val @scope(("window", "location")) external locationHref: string = "href"

module EventTitleSection = {
  @react.component
  let make = (
    ~event: PkEventPageQuery_graphql.Types.response_event,
    ~secret: bool,
    ~tz: string,
  ) => {
    let ts = Lingui.UtilString.t
    let td = Lingui.UtilString.dynamic
    let (urlCopied, setUrlCopied) = React.useState(() => false)
    <div className="px-5 pt-4 pb-3 border-b border-gray-100 dark:border-[#2a2b30]">
      {event.deleted
      ->Option.map(_ =>
        <span
          className="inline-flex mb-2 items-center px-2 py-0.5 rounded text-xs font-mono bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400">
          {(ts`CANCELED`)->React.string}
        </span>
      )
      ->Option.getOr(React.null)}
      <div className="flex items-start justify-between gap-3">
        <h1
          className={Util.cx([
            "text-lg font-semibold leading-tight flex-1 min-w-0",
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
        <button
          onClick={_ => {
            writeToClipboard(locationHref)->ignore
            setUrlCopied(_ => true)
            let _ = Js.Global.setTimeout(() => setUrlCopied(_ => false), 2000)
          }}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-semibold bg-[#bdf25d] hover:bg-[#aee050] text-black border border-[#a3d949] shadow-sm transition-colors flex-shrink-0">
          <Lucide.Share size=13 strokeWidth={2.5} />
          {(urlCopied ? ts`Copied!` : ts`Share`)->React.string}
        </button>
      </div>
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
  }
}

module EventLocationSection = {
  @react.component
  let make = (~loc: PkEventPageQuery_graphql.Types.response_event_location) => {
    let ts = Lingui.UtilString.t
    let (showFullDetails, setShowFullDetails) = React.useState(() => false)
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
  }
}

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
    let locale = React.useContext(LangProvider.LocaleContext.context)

    let (mounted, setMounted) = React.useState(() => false)
    React.useEffect0(() => {
      setMounted(_ => true)
      None
    })

    let (cancelEvent, canceling) = EventCancelMutation.use()
    let (uncancelEvent, uncanceling) = EventUncancelMutation.use()
    let (chargePayment, charging) = ChargePaymentMutation.use()
    let (authorizePlatformPayment, authorizingPlatform) = AuthorizePlatformPaymentMutation.use()
    let (confirmPayment, _confirming) = ConfirmPaymentMutation.use()
    let (paymentClientSecret, setPaymentClientSecret) = React.useState(() => None)

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

    // Find the viewer's own RSVP node (for payment status)
    let viewerRsvpNode =
      viewerUser->Option.flatMap(vu =>
        allRsvpNodes->Array.find(n => n.user->Option.map(u => u.id == vu.id)->Option.getOr(false))
      )

    // Unpaid: viewer is joined, event has a price, viewer is not in Going list, and has no payment
    let isPaidEvent = event.price->Option.map(p => p > 0)->Option.getOr(false)
    let isJoined = viewerRsvpNode->Option.isSome
    let isViewerWaitlisted =
      viewerRsvpNode
      ->Option.map(node => waitlistPlayers->Array.some(wp => wp.id == node.id))
      ->Option.getOr(false)
    let viewerIsInGoingList = switch viewerRsvpNode {
    | Some({listType: None | Some(0)}) => true
    | _ => false
    }
    let viewerHasPayment = switch viewerRsvpNode {
    | Some({payment: Some({status: 0 | 1})}) => true
    | _ => false
    }
    let isUnpaid = isJoined && isPaidEvent && !viewerIsInGoingList && !viewerHasPayment
    let viewerJoinTime = viewerRsvpNode->Option.flatMap(n => n.joinTime)
    let isViewerPending = switch viewerRsvpNode {
    | Some({listType}) => listType != None && listType != Some(0)
    | None => false
    }
    let eventCurrency = allRsvpNodes->Array.findMap(n => n.payment->Option.map(p => p.currency))
    let isPlatformPayment = !(
      event.owner->Option.flatMap(o => o.stripeChargesEnabled)->Option.getOr(false)
    )

    if event.viewerIsBanned->Option.getOr(false) {
      <div className="p-6 text-center text-gray-500">
        {(ts`Cannot access variable "title"`)->React.string}
      </div>
    } else {
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
          <EventTitleSection event secret tz />
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
          | (Some(loc), false) => <EventLocationSection loc />
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
        <EventStickyFooter
          event={{
            __id: event.__id,
            id: event.id,
            price: event.price,
            currency: eventCurrency,
            startDate: event.startDate,
            cancelDeadline: event.cancelDeadline,
            shadow: event.shadow,
            deleted: event.deleted,
          }}
          viewerUser={viewerUser->Option.map(u => {
            EventStickyFooter.id: u.id,
            lineUsername: u.lineUsername,
            email: u.email,
          })}
          isJoined
          isWaitlisted={isViewerWaitlisted}
          isPending={isViewerPending}
          isUnpaid
          viewerJoinTime
          isPaidEvent
          isFull
          confirmedCount={confirmedPlayers->Array.length}
          waitlistCount={waitlistPlayers->Array.length}
          maxRsvps
          tz
          locale
          queryFragmentRefs
          charging={charging || authorizingPlatform}
          isPlatformPayment
          onPayClick={() =>
            viewerRsvpNode->Option.forEach(rsvp =>
              if isPlatformPayment {
                authorizePlatformPayment(~variables={rsvpId: rsvp.id}, ~onCompleted=(response, _) =>
                  switch response.authorizePlatformRsvpPayment.clientSecret {
                  | Some(secret) => setPaymentClientSecret(_ => Some((secret, "")))
                  | None => ()
                  }
                )->RescriptRelay.Disposable.ignore
              } else {
                chargePayment(~variables={rsvpId: rsvp.id}, ~onCompleted=(response, _) =>
                  switch response.chargeRsvpPayment.clientSecret {
                  | Some(secret) =>
                    setPaymentClientSecret(
                      _ => Some((
                        secret,
                        response.chargeRsvpPayment.connectedAccountId->Option.getOr(""),
                      )),
                    )
                  | None => ()
                  }
                )->RescriptRelay.Disposable.ignore
              }
            )}
        />
        {switch paymentClientSecret {
        | Some((secret, accountId)) =>
          <StripePaymentEmbed
            clientSecret=secret
            stripeAccountId=accountId
            isDepositOnly={isPlatformPayment}
            onSuccess={paymentIntentId => {
              setPaymentClientSecret(_ => None)
              viewerRsvpNode->Option.forEach(rsvp =>
                confirmPayment(
                  ~variables={rsvpId: rsvp.id, paymentIntentId},
                )->RescriptRelay.Disposable.ignore
              )
            }}
            onClose={() => setPaymentClientSecret(_ => None)}
          />
        | None => React.null
        }}
      </div>
    }
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
