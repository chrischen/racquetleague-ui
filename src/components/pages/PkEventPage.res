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
    ...UseProfileGate_query
    viewer {
      user {
        id
        lineUsername
        email
        eventRating(eventId: $eventId) {
          id
        }
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
      minRating
      cancelDeadline
      price
      activity {
        name
        slug
      }
      club {
        id
        name
        slug
        viewerMembership {
          status
        }
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
        ...LocationMap_location
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
      # Scraped court availability for the venue, rendered only for owners and
      # club admins. Deliberately NOT @defer'd: the deferred payload leaves a
      # window where the fragment reads back partially populated (schema-non-null
      # fields arriving as undefined), and this resolves to a cheap keyed lookup
      # anyway. Gate the cost in the resolver, not with @defer.
      ...EventLocationAvailability_event
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

module AuthorizeConnectedPaymentMutation = %relay(`
  mutation PkEventPageAuthorizeConnectedPaymentMutation($rsvpId: ID!) {
    authorizeRsvpPayment(rsvpId: $rsvpId) {
      clientSecret
      connectedAccountId
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
    ~isAuthorization: bool=?,
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

// Inline edits from edit mode. `updateEvent` replaces the whole event, so the
// input comes from EventLocationAvailability.updateInput, which carries every
// current field through.
module UpdateEventMutation = %relay(`
  mutation PkEventPageUpdateEventMutation($eventId: ID!, $input: CreateEventInput!) {
    updateEvent(eventId: $eventId, input: $input) {
      event {
        id
        details
      }
    }
  }
`)

type loaderData = PkEventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"
type pageParams = {eventId: string}
@module("react-router-dom")
external useParams: unit => pageParams = "useParams"

@val @scope(("navigator", "clipboard"))
external writeToClipboard: string => Js.Promise.t<unit> = "writeText"
@val @scope(("window", "location")) external locationHref: string = "href"

// Every block on the page is one of these cards on the grey page ground.
let cardClass = "mx-3 mt-3 rounded-xl border border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#1e1f23]"

module EventTitleSection = {
  @react.component
  let make = (
    ~event: PkEventPageQuery_graphql.Types.response_event,
    ~secret: bool,
    // Sponsor strip, rendered inside the card under the title block.
    ~sponsor: React.element=React.null,
  ) => {
    let ts = Lingui.UtilString.t
    let td = Lingui.UtilString.dynamic
    let (urlCopied, setUrlCopied) = React.useState(() => false)
    <div className={cardClass ++ " overflow-hidden"}>
      <div className="px-4 py-4">
        /* Hosting club */
        {event.club
        ->Option.flatMap(club =>
          club.slug->Option.map(slug => {
            let name = club.name->Option.getOr(slug)
            <Router.Link
              to={"/clubs/" ++ slug}
              className="mb-3 flex w-full items-center gap-2.5 rounded-md border-b border-gray-100 pb-3 text-left focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:border-[#2a2b30]">
              <span
                className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-md bg-[#bdf25d] text-xs font-bold text-black shadow-sm"
                ariaHidden=true>
                {PkEventMessages.makeInitials(name)->React.string}
              </span>
              <span className="min-w-0 flex-1">
                <span
                  className="block font-mono text-[8px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
                  {t`Hosted by`}
                </span>
                <span
                  className="block truncate text-sm font-semibold text-gray-900 dark:text-gray-100">
                  {name->React.string}
                </span>
              </span>
              <Lucide.ChevronRight
                size=14 className="flex-shrink-0 text-gray-400" \"aria-hidden"="true"
              />
            </Router.Link>
          })
        )
        ->Option.getOr(React.null)}
        {event.deleted
        ->Option.map(_ =>
          <span
            className="inline-flex mb-2 items-center px-2 py-0.5 rounded text-xs font-mono bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400">
            {(ts`CANCELED`)->React.string}
          </span>
        )
        ->Option.getOr(React.null)}
        /* Activity pill, linking to the activity's event list */
        {event.activity
        ->Option.flatMap(a =>
          a.slug->Option.map(slug =>
            <div className="mb-1 flex items-center gap-2">
              <Router.Link
                to={"/e/" ++ slug}
                className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800/40 text-[10px] font-semibold text-green-700 dark:text-green-400 uppercase tracking-wider hover:bg-green-100 dark:hover:bg-green-900/30 transition-colors">
                <span className="w-1.5 h-1.5 rounded-full bg-green-500 dark:bg-green-400" />
                {td(a.name->Option.getOr(slug))->React.string}
              </Router.Link>
            </div>
          )
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
        <p className="mt-1 font-mono text-xs text-gray-600 dark:text-gray-300">
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
        </p>
        <ResponsiveTooltip.Provider>
          <div className="mt-2 flex flex-wrap items-center gap-1.5">
            {event.listed == Some(false) ? <EventTag tag="unlisted" /> : React.null}
            {event.tags->Option.getOr([])->Array.some(t => t->String.toLowerCase == "comp")
              ? <EventTag tag="comp" />
              : React.null}
            {event.tags
            ->Option.getOr([])
            ->Array.filter(t => t->String.toLowerCase != "comp")
            ->Array.mapWithIndex((tag, i) => <EventTag key={Int.toString(i)} tag />)
            ->React.array}
          </div>
        </ResponsiveTooltip.Provider>
      </div>
      sponsor
    </div>
  }
}

module EventLocationSection = {
  @react.component
  let make = (
    ~loc: PkEventPageQuery_graphql.Types.response_event_location,
    // Whether a court at the venue covers the event window. None when the
    // viewer can't see availability (it's an organizer tool), which hides the
    // court badge rather than showing a false "not available".
    ~courtStatus: option<bool>,
    // Court availability for this venue, already gated by the caller.
    ~availability: React.element=React.null,
  ) => {
    let ts = Lingui.UtilString.t
    let (expanded, setExpanded) = React.useState(() => false)
    let (showFullDetails, setShowFullDetails) = React.useState(() => false)
    let name = loc.name->Option.getOr("?")
    let courtLabel = switch courtStatus {
    | Some(true) => (ts`Courts available`) ++ ". "
    | Some(false) => (ts`No courts available`) ++ ". "
    | None => ""
    }
    let toggleLabel = expanded ? ts`Hide location details` : ts`Show location details`
    <div className={cardClass ++ " overflow-hidden"}>
      <button
        type_="button"
        onClick={_ => setExpanded(v => !v)}
        ariaExpanded=expanded
        ariaLabel={name ++ ". " ++ courtLabel ++ toggleLabel}
        className="flex w-full items-center justify-between gap-3 px-4 py-3.5 text-left transition-colors hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[#94c93a] dark:hover:bg-[#242529]">
        <span className="min-w-0">
          <span className="block text-xs font-medium text-gray-500 dark:text-gray-400">
            {t`Location`}
          </span>
          <span className="block truncate text-sm font-semibold text-gray-900 dark:text-gray-100">
            {name->React.string}
          </span>
        </span>
        <span className="flex flex-shrink-0 items-center gap-2">
          {switch courtStatus {
          | Some(available) =>
            let tone = available
              ? "text-emerald-600 dark:text-emerald-400"
              : "text-red-500 dark:text-red-400"
            <>
              <IsometricPickleballCourtIcon className={"h-7 w-8 " ++ tone} />
              <span className={"inline-flex items-center gap-1 " ++ tone} ariaHidden=true>
                {available ? <Lucide.CheckCircle2 size=15 /> : <Lucide.XCircle size=15 />}
              </span>
            </>
          | None => React.null
          }}
          <Lucide.ChevronRight
            size=15
            className={"text-gray-400 transition-transform duration-200 " ++ (
              expanded ? "rotate-90" : ""
            )}
            \"aria-hidden"="true"
          />
        </span>
      </button>
      {expanded
        ? <div className="border-t border-gray-200 px-4 pb-4 pt-3 dark:border-[#2a2b30]">
            {loc.details
            ->Option.map(d => {
              let limit = 100
              let isTruncatable = String.length(d) > limit
              let displayText =
                !showFullDetails && isTruncatable ? String.slice(d, ~start=0, ~end=limit) : d
              <p className="font-mono text-xs text-gray-500 dark:text-gray-400">
                {displayText->React.string}
                {isTruncatable
                  ? <button
                      type_="button"
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
                className="mt-0.5 block font-mono text-xs text-gray-500 dark:text-gray-400 hover:underline">
                {addr->React.string}
              </a>
            })
            ->Option.getOr(React.null)}
            <Router.Link
              to={`/locations/${loc.id}`}
              className="mt-1.5 inline-flex items-center gap-1 font-mono text-xs font-semibold text-[#5f8618] underline-offset-2 hover:underline dark:text-[#bdf25d]">
              {t`View all events at this location`}
              <Lucide.ChevronRight size=12 \"aria-hidden"="true" />
            </Router.Link>
            availability
          </div>
        : React.null}
    </div>
  }
}

// Sponsor + prize strip for competitive pickleball events, linking to the
// league rankings (RPM Playoff Draft campaign). Uses the shared sponsor logo.
// Sits inside the title card, under the title block.
module SponsorBanner = {
  @react.component
  let make = () => {
    <Router.Link
      to="/league/pickleball"
      className="flex items-center justify-between gap-3 border-t border-violet-200 bg-violet-50 px-4 py-3 transition-colors hover:bg-violet-100 dark:border-violet-700/50 dark:bg-violet-900/30 dark:hover:bg-violet-900/50">
      <div className="flex items-center gap-2 min-w-0">
        <span
          className="font-mono text-[10px] font-semibold uppercase tracking-wider text-violet-700 dark:text-violet-300 flex-shrink-0">
          {t`Presented by`}
        </span>
        <TopPlayerAwardsBanner.SponsorLogo className="h-6 w-auto max-w-[140px]" />
      </div>
      <div
        className="flex items-center gap-1.5 flex-shrink-0 px-2 py-0.5 rounded-md bg-amber-100 dark:bg-amber-900/40 border border-amber-300 dark:border-amber-700/60">
        <Lucide.Gift size=12 strokeWidth={2.25} className="text-amber-700 dark:text-amber-400" />
        <span className="font-mono text-[11px] leading-tight">
          <span className="font-bold text-amber-800 dark:text-amber-300">
            {TopPlayerAwardsBanner.prizePool->React.string}
          </span>
          <span className="text-amber-700/80 dark:text-amber-400/80">
            {" · "->React.string}
            {t`Playoff Draft`}
          </span>
        </span>
      </div>
    </Router.Link>
  }
}

// Notes card, editable in place while the page's edit mode is on.
module HostNotesSection = {
  @react.component
  let make = (~notes: string, ~editable: bool, ~onEdited: string => unit) => {
    let ts = Lingui.UtilString.t
    let field = UseEditable.use(~editable, ~value=notes, ~onEdited=draft =>
      onEdited(draft->String.trim)
    )
    let placeholder = ts`Add details participants should know before arriving`
    <EditableSection
      state=field.state
      heading={t`Notes from the host`}
      editLabel={ts`Edit notes from the host`}
      saveLabel={t`Save notes`}
      onStartEditing=field.startEditing
      onCancel=field.cancel
      onCommit=field.commit
      editor={<>
        <label className="sr-only" htmlFor="host-notes-input"> {t`Notes from the host`} </label>
        <textarea
          id="host-notes-input"
          autoFocus=true
          value=field.draft
          rows=3
          onChange={e => {
            let next: string = ReactEvent.Form.target(e)["value"]
            field.setDraft(_ => next)
          }}
          onKeyDown=field.onKeyDown
          placeholder
          className="w-full resize-none rounded-lg border border-gray-200 bg-white px-3 py-2.5 text-sm leading-relaxed text-gray-900 outline-none transition-colors placeholder:text-gray-400 focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-100"
        />
      </>}>
      {notes == ""
        ? <span className="block text-sm leading-relaxed text-gray-400 dark:text-gray-500">
            {placeholder->React.string}
          </span>
        : notes
          ->String.split("\n")
          ->Array.mapWithIndex((line, i) =>
            <span
              key={Int.toString(i)}
              className={"block text-sm leading-relaxed text-gray-700 dark:text-gray-300" ++ (
                i > 0 ? " mt-2" : ""
              )}>
              {line->React.string}
            </span>
          )
          ->React.array}
    </EditableSection>
  }
}

module Inner = {
  @react.component
  let make = (
    ~event: PkEventPageQuery_graphql.Types.response_event,
    ~viewer: option<PkEventPageQuery_graphql.Types.response_viewer>,
    ~queryFragmentRefs: RescriptRelay.fragmentRefs<
      [> #UseProfileGate_query | #PkEventMessages_query],
    >,
    ~onRefresh: option<unit => Js.Promise.t<unit>>=?,
    // Rendered as a route rather than inside the events drawer: the page
    // ground and the sticky footer span the full width, with the cards in a
    // centred column.
    ~asPage: bool=false,
  ) => {
    let viewerUser = viewer->Option.flatMap(v => v.user)
    let ts = Lingui.UtilString.t

    let containerRef: React.ref<Js.Nullable.t<Dom.element>> = React.useRef(Js.Nullable.null)
    let {
      pullDistance,
      isRefreshing,
      isPullRefreshing,
      triggerRefresh,
    } = PullToRefresh.usePullToRefresh(
      containerRef,
      onRefresh->Option.getOr(() => Js.Promise.resolve()),
    )

    let (mounted, setMounted) = React.useState(() => false)
    React.useEffect0(() => {
      setMounted(_ => true)
      None
    })

    let (cancelEvent, canceling) = EventCancelMutation.use()
    let (uncancelEvent, uncanceling) = EventUncancelMutation.use()
    let (chargePayment, charging) = ChargePaymentMutation.use()
    let (authorizePlatformPayment, authorizingPlatform) = AuthorizePlatformPaymentMutation.use()
    let (authorizeConnectedPayment, authorizingConnected) = AuthorizeConnectedPaymentMutation.use()
    let (confirmPayment, _confirming) = ConfirmPaymentMutation.use()
    let (paymentClientSecret, setPaymentClientSecret) = React.useState(() => None)
    let (updateEvent, _updatingEvent) = UpdateEventMutation.use()
    // Edit mode: organizers toggle it from the admin row, and every section
    // built on UseEditable lights up until they're done.
    let (editModeActive, setEditModeActive) = React.useState(() => false)

    // Court availability feeds the badge on the collapsed location card as
    // well as the organizer panel inside it.
    let availabilityData = EventLocationAvailability.Fragment.use(event.fragmentRefs)
    let genericCourtName = event.location->Option.flatMap(l => l.name)->Option.getOr(ts`Courts`)
    let courtStatus = event.viewerIsAdmin
      ? EventLocationAvailability.isAvailableAtEventTime(availabilityData, ~genericCourtName)
      : None

    let canEditInPlace = event.viewerIsAdmin && event.deleted->Option.isNone
    let editable = editModeActive && canEditInPlace
    let saveNotes = notes =>
      EventLocationAvailability.updateInput(
        availabilityData,
        ~details=notes,
      )->Option.forEach(input =>
        updateEvent(~variables={eventId: event.id, input})->RescriptRelay.Disposable.ignore
      )

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
    // listType 2 = invited by the host. The viewer hasn't accepted, so the
    // footer keeps the Join call-to-action (joining converts the invite).
    let isViewerInvited = switch viewerRsvpNode {
    | Some({listType: Some(2)}) => true
    | _ => false
    }
    let isJoined = viewerRsvpNode->Option.isSome && !isViewerInvited
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
    let ownerHasConnectedAccount =
      event.owner->Option.flatMap(o => o.stripeChargesEnabled)->Option.getOr(false)
    let viewerIsClubMember = switch event.club->Option.flatMap(c => c.viewerMembership) {
    | Some({status: Some(Active)}) => true
    | _ => false
    }
    // Platform payments (owner has no connected account) skip the deposit
    // authorization gate for members of the event's club
    let requiresPaymentGate = ownerHasConnectedAccount || !viewerIsClubMember
    let isUnpaid =
      isJoined && isPaidEvent && !viewerIsInGoingList && !viewerHasPayment && requiresPaymentGate
    let viewerJoinTime = viewerRsvpNode->Option.flatMap(n => n.joinTime)
    let isViewerPending = switch viewerRsvpNode {
    | Some({listType}) => listType != None && listType != Some(0) && listType != Some(2)
    | None => false
    }
    let eventCurrency = allRsvpNodes->Array.findMap(n => n.payment->Option.map(p => p.currency))
    let isAuthorization = true

    // Joined viewers get the activity feed in the sticky footer. When the
    // footer isn't rendered (cancelled or shadow events, logged-out viewers)
    // the feed stays in the page so it's never lost.
    let footerShown =
      event.deleted->Option.isNone && viewerUser->Option.isSome && event.shadow != Some(true)
    let chatInFooter = isJoined && footerShown

    let isSponsored =
      event.activity->Option.flatMap(a => a.slug) == Some("pickleball") &&
        event.tags->Option.getOr([])->Array.some(t => t->String.toLowerCase == "comp")

    if event.viewerIsBanned->Option.getOr(false) {
      <div className="p-6 text-center text-gray-500">
        {(ts`Cannot access variable "title"`)->React.string}
      </div>
    } else {
      <div
        className="relative w-full min-h-full bg-gray-50 dark:bg-[#18191c]"
        ref={ReactDOM.Ref.domRef(containerRef)}>
        /* Top bar: date, time and refresh. Deliberately not sticky. */
        <div
          className="bg-white dark:bg-[#1e1f23] border-b border-gray-100 dark:border-[#2a2b30] flex-shrink-0">
          <div className="mx-auto w-full max-w-2xl px-5 py-3 flex items-center justify-between">
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
            {onRefresh
            ->Option.map(_ =>
              <button
                onClick={_ => triggerRefresh()}
                disabled=isRefreshing
                className="text-gray-400 dark:text-gray-500 hover:text-black dark:hover:text-white transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
                title={isRefreshing ? ts`Refreshing…` : ts`Refresh event details`}>
                <Lucide.RefreshCw size=13 className={isRefreshing ? "animate-spin" : ""} />
              </button>
            )
            ->Option.getOr(React.null)}
          </div>
        </div>
        <PullToRefresh.Indicator pullDistance isRefreshing={isPullRefreshing} />
        <div className="mx-auto w-full max-w-2xl pb-24">
          /* Title, with the sponsor + prize strip for competitive pickleball
           events (they feed the Top Player awards) */
          <EventTitleSection event secret sponsor={isSponsored ? <SponsorBanner /> : React.null} />
          /* Admin controls */
          {switch (event.viewerIsAdmin, viewerUser) {
          | (true, Some(_)) =>
            <div className={cardClass ++ " px-4 py-3"}>
              <div className="flex flex-row flex-wrap gap-2">
                <Button.Button
                  href={"/events/update/" ++
                  event.id ++
                  "/" ++
                  event.location->Option.map(l => l.id)->Option.getOr("")}>
                  {t`edit event`}
                </Button.Button>
                {event.location
                ->Option.map(loc =>
                  <Button.Button href={"/events/copy/" ++ event.id ++ "/" ++ loc.id}>
                    {t`copy event`}
                  </Button.Button>
                )
                ->Option.getOr(React.null)}
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
                <Button.Button
                  disabled={!canEditInPlace}
                  className={editModeActive ? "ring-2 ring-[#94c93a]" : ""}
                  onClick={_ => setEditModeActive(v => !v)}>
                  <Lucide.Pencil size=13 \"aria-hidden"="true" />
                  {editModeActive ? t`Done editing` : t`Edit in place`}
                </Button.Button>
              </div>
              {editModeActive
                ? <p className="mt-2 font-mono text-[10px] text-[#547817] dark:text-[#bdf25d]">
                    {t`Editable fields are highlighted below. Click one to edit it.`}
                  </p>
                : React.null}
            </div>
          | _ => React.null
          }}
          /* Location */
          {switch (event.location, secret) {
          | (Some(loc), false) =>
            <EventLocationSection
              loc
              courtStatus
              availability={event.viewerIsAdmin
                ? <EventLocationAvailability event={event.fragmentRefs} genericCourtName />
                : React.null}
            />
          | _ => React.null
          }}
          /* Participants */
          <PkRSVPSection
            event={event.fragmentRefs} user=?{viewerUser->Option.map(u => u.fragmentRefs)}
          />
          /* Notes: organizers always get the card so they can add notes */
          {switch (event.details, canEditInPlace) {
          | (None, false) => React.null
          | (details, _) =>
            <HostNotesSection notes={details->Option.getOr("")} editable onEdited=saveNotes />
          }}
          /* Round-robin draws */
          {switch event.activity {
          | Some(activity) =>
            switch activity.slug {
            | Some(("pickleball" | "badminton") as slug) =>
              let managerHref = "/league/events/" ++ event.id ++ "/" ++ slug ++ "/manager"
              mounted
                ? <React.Suspense fallback=React.null>
                    <RoundRobinDrawsPreview eventId=event.id managerHref className="mx-3 mt-3" />
                  </React.Suspense>
                : React.null
            | _ => React.null
            }
          | None => React.null
          }}
          /* Activity feed, for viewers who haven't joined (joined viewers get
           it in the sticky footer) */
          {chatInFooter
            ? React.null
            : <PkEventMessages queryRef=queryFragmentRefs eventId=event.id isJoined />}
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
          hasComputedRating={viewerUser->Option.flatMap(u => u.eventRating)->Option.isSome}
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
          queryFragmentRefs
          charging={charging || authorizingPlatform || authorizingConnected}
          isAuthorization
          fullWidth=asPage
          chat={chatInFooter
            ? <PkEventMessages.FooterChat queryRef=queryFragmentRefs eventId=event.id />
            : React.null}
          onPayClick={() =>
            viewerRsvpNode->Option.forEach(rsvp =>
              if isAuthorization {
                if ownerHasConnectedAccount {
                  authorizeConnectedPayment(~variables={rsvpId: rsvp.id}, ~onCompleted=(
                    response,
                    _,
                  ) =>
                    switch response.authorizeRsvpPayment.clientSecret {
                    | Some(secret) =>
                      setPaymentClientSecret(
                        _ => Some((
                          secret,
                          response.authorizeRsvpPayment.connectedAccountId->Option.getOr(""),
                        )),
                      )
                    | None => ()
                    }
                  )->RescriptRelay.Disposable.ignore
                } else {
                  authorizePlatformPayment(~variables={rsvpId: rsvp.id}, ~onCompleted=(
                    response,
                    _,
                  ) =>
                    switch response.authorizePlatformRsvpPayment.clientSecret {
                    | Some(secret) => setPaymentClientSecret(_ => Some((secret, "")))
                    | None => ()
                    }
                  )->RescriptRelay.Disposable.ignore
                }
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
            isAuthorization={isAuthorization}
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
    let (fetchKey, setFetchKey) = React.useState(() => 0)
    let fetchPolicy = fetchKey > 0 ? RescriptRelay.StoreAndNetwork : RescriptRelay.StoreOrNetwork
    let {event, viewer, fragmentRefs: queryFragmentRefs} = EventQuery.use(
      ~variables={eventId, topic: eventId ++ ".updated"},
      ~fetchKey=Int.toString(fetchKey),
      ~fetchPolicy,
    )
    let onRefresh = () => {
      setFetchKey(k => k + 1)
      Js.Promise.make((~resolve, ~reject as _) => {
        let _ = Js.Global.setTimeout(() => resolve(), 1500)
      })
    }
    event
    ->Option.map(event => <Inner event viewer queryFragmentRefs onRefresh />)
    ->Option.getOr(<div className="p-6 text-center text-gray-500"> {t`Event not found`} </div>)
  }
}

@genType @react.component
let make = () => {
  let environment = RescriptRelay.useEnvironmentFromContext()
  let {eventId} = useParams()
  let query = useLoaderData()
  let {event, viewer, fragmentRefs: queryFragmentRefs} = EventQuery.usePreloaded(
    ~queryRef=query.data,
  )
  let onRefresh = () => {
    Js.Promise.make((~resolve, ~reject as _) => {
      let _ = EventQuery.fetch(
        ~environment,
        ~variables={eventId, topic: eventId ++ ".updated"},
        ~fetchPolicy=RescriptRelay.NetworkOnly,
        ~onResult=_result => resolve(),
      )
    })
  }
  <WaitForMessages>
    {() =>
      event
      ->Option.map(event => <Inner event viewer queryFragmentRefs onRefresh asPage=true />)
      ->Option.getOr(<div className="p-6 text-center text-gray-500"> {t`Event not found`} </div>)}
  </WaitForMessages>
}
