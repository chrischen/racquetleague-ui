%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment PkRSVPSection_event on Event {
    id
    title
    startDate
    endDate
    timezone
    maxRsvps
    price
    # Whether the event's payment account can collect: gates the charge actions.
    chargesEnabled
    # A venue's session tracked from booking emails: players are added from
    # their forwarded confirmations or by an admin, never invited.
    shadow
    minRating
    smartRsvpThreshold
    viewerIsAdmin
    tags
    club {
      id
    }
    activity {
      id
      slug
    }
    location {
      id
      name
    }
    owner {
      lineUsername
    }
    rsvps(first: 100) @connection(key: "PkRSVPSection_event_rsvps") {
      edges {
        node {
          id
          listType
          # Feeds the approve-review deck card. The RSVP's own rating is already
          # activity-scoped, so pending players don't need the deck's user
          # fragment (which would need an activitySlug argument this fragment
          # has no variable for).
          message
          ...PkEventRsvp_rsvp
          ...MiniEventRsvp_rsvp
          user {
            id
            lineUsername
            gender
            picture
            biography
            selfRating
            dupr {
              doubles
              doublesReliable
              doublesReliability
            }
          }
          rating {
            ordinal
            mu
            sigma
          }
        }
      }
    }
  }
`)

module UpdateListTypeMutation = %relay(`
  mutation PkRSVPSectionUpdateListTypeMutation($input: UpdateRsvpListTypeInput!) {
    updateRsvpListType(input: $input) {
      rsvp {
        id
        listType
      }
      errors {
        message
      }
    }
  }
`)

// The organizer's run of Smart RSVP's admission pass: for now the only way
// admissions happen, as the scheduled job is not deployed. The promoted RSVPs
// come back with their new list type, which is enough for Relay to move them
// out of the pending list.
module EvaluateSmartRsvpsMutation = %relay(`
  mutation PkRSVPSectionEvaluateSmartRsvpsMutation($eventId: ID!) {
    evaluateSmartRsvps(eventId: $eventId) {
      rsvps {
        id
        listType
        joinTime
      }
      errors {
        message
      }
    }
  }
`)

// Smart Waitlist: on a full event, every eligible pending player is placed on
// the ordinary waitlist in the search's order. The moved RSVPs come back with
// their new list type and join time, which is what Relay needs to redraw them
// on the waitlist.
module SmartWaitlistMutation = %relay(`
  mutation PkRSVPSectionSmartWaitlistMutation($eventId: ID!) {
    smartWaitlist(eventId: $eventId) {
      rsvps {
        id
        listType
        joinTime
      }
      errors {
        message
      }
    }
  }
`)

// What Smart RSVP would admit right now, without admitting anyone. Fetched
// fresh on every click, since the pending list changes under it.
module PreviewSmartRsvpsQuery = %relay(`
  query PkRSVPSectionPreviewSmartRsvpsQuery($eventId: ID!) {
    previewSmartRsvps(eventId: $eventId) {
      rsvps {
        id
      }
      errors {
        message
      }
    }
  }
`)

module PkRSVPSectionAddUserMutation = %relay(`
  mutation PkRSVPSectionAddUserMutation($connections: [ID!]!, $eventId: ID!, $userId: ID!) {
    addRsvpToEvent(eventId: $eventId, userId: $userId) {
      edge @appendEdge(connections: $connections) {
        node {
          id
          listType
          ...PkEventRsvp_rsvp
          ...MiniEventRsvp_rsvp
          user {
            id
            lineUsername
            gender
          }
          rating {
            ordinal
            mu
            sigma
          }
        }
      }
    }
  }
`)

// Charges every card saved for a going-list RSVP. Returns every payment it
// touched — charged, or declined and now status 3 — with one error per
// declined charge.
module PkRSVPSectionCaptureAllPaymentsMutation = %relay(`
  mutation PkRSVPSectionCaptureAllPaymentsMutation($eventId: ID!) {
    captureEventRsvpPayments(eventId: $eventId) {
      payments {
        id
        status
        chargeable
      }
      errors {
        message
      }
    }
  }
`)

module UserFragment = %relay(`
  fragment PkRSVPSection_user on User
  @argumentDefinitions(eventId: { type: "ID!" }) {
    id
    eventRating(eventId: $eventId) {
      id
      ordinal
      mu
      sigma
    }
    dupr {
      doubles
      doublesReliable
      doublesReliability
    }
  }
`)

@react.component
let make = (
  ~event: RescriptRelay.fragmentRefs<[> #PkRSVPSection_event]>,
  ~user: option<RescriptRelay.fragmentRefs<[> #PkRSVPSection_user]>>=?,
) => {
  let ts = Lingui.UtilString.t
  let eventData = Fragment.use(event)
  let viewerUser = user->Option.map(u => UserFragment.use(u))

  let (isAddingPlayer, setIsAddingPlayer) = React.useState(() => false)
  let (pendingSwipeOpen, setPendingSwipeOpen) = React.useState(() => false)
  // The level curve is always up; the number grid sits behind "View more".
  let (showSkillDetail, setShowSkillDetail) = React.useState(() => false)
  let (commitUpdateListType, _updateListTypeInFlight) = UpdateListTypeMutation.use()
  let (commitEvaluateSmartRsvps, isEvaluateSmartRsvpsInFlight) =
    EvaluateSmartRsvpsMutation.use()
  let (commitSmartWaitlist, isSmartWaitlistInFlight) = SmartWaitlistMutation.use()
  let environment = RescriptRelay.useEnvironmentFromContext()
  // The pending RSVP ids the last Smart RSVP preview would admit, if any.
  let (smartRsvpPreview, setSmartRsvpPreview) = React.useState(() => None)
  let (isPreviewingSmartRsvps, setIsPreviewingSmartRsvps) = React.useState(() => false)
  let (commitMutationAddUser, _addUserInFlight) = PkRSVPSectionAddUserMutation.use()
  let (commitCaptureAll, isCaptureAllInFlight) = PkRSVPSectionCaptureAllPaymentsMutation.use()
  // What the last "charge all" could not collect, one line per declined card.
  let (chargeErrors, setChargeErrors) = React.useState(() => [])
  let onChargeAll = () => {
    setChargeErrors(_ => [])
    commitCaptureAll(
      ~variables={eventId: eventData.id},
      ~onCompleted=(response, _) =>
        setChargeErrors(_ =>
          response.captureEventRsvpPayments.errors
          ->Option.getOr([])
          ->Array.map(e => e.message)
        ),
    )->RescriptRelay.Disposable.ignore
  }

  let handleAddUser = (user: AutocompleteUser.user) => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      eventData.id->RescriptRelay.makeDataId,
      "PkRSVPSection_event_rsvps",
      None,
    )
    commitMutationAddUser(
      ~variables={
        connections: [connectionId],
        eventId: eventData.id,
        userId: user.id,
      },
    )->RescriptRelay.Disposable.ignore
  }

  let rsvps = eventData.rsvps->Fragment.getConnectionNodes
  Js.log(rsvps)
  let maxRsvps = eventData.maxRsvps->Option.getOr(0)
  let minRating = eventData.minRating
  let activitySlug = eventData.activity->Option.flatMap(a => a.slug)

  // Check if event is competitive (has "comp" tag)
  let isCompetitive =
    eventData.tags
    ->Option.getOr([])
    ->Array.some(t => t->String.toLowerCase == "comp")

  let isWaitlist = count => maxRsvps > 0 && count >= maxRsvps

  let mainList = rsvps->Array.filter(n => n.listType == None || n.listType == Some(0))
  // listType 2 = invited by the host; not a join request, so kept out of Pending
  let invitedRsvps = rsvps->Array.filter(n => n.listType == Some(2))
  let pendingRsvps =
    rsvps->Array.filter(n => n.listType != None && n.listType != Some(0) && n.listType != Some(2))
  // The rating this section reasons with, for the order of the list and
  // every stat: the same CombinedRating each row displays and the Round
  // Robin tool seeds from — pkuru or DUPR by confidence, then the player's
  // own estimate. A player with no signal at all has no rating here, rather
  // than a stand-in value that would pull the stats toward the default.
  let seedRating = (node: PkRSVPSection_event_graphql.Types.fragment_rsvps_edges_node) =>
    CombinedRating.resolve(
      ~pkuruMu=node.rating->Option.flatMap(r => r.mu),
      ~pkuruSigma=?node.rating->Option.flatMap(r => r.sigma),
      ~duprDoubles=node.user->Option.flatMap(u => u.dupr)->Option.flatMap(d => d.doubles),
      ~duprReliability=?node.user
      ->Option.flatMap(u => u.dupr)
      ->Option.flatMap(d => d.doublesReliability),
      ~duprReliable=node.user
      ->Option.flatMap(u => u.dupr)
      ->Option.map(d => d.doublesReliable)
      ->Option.getOr(false),
      ~selfMu=node.user->Option.flatMap(u => u.selfRating),
    )
  let seedMu = node => seedRating(node)->Option.map(CombinedRating.mu)
  /* Sorts an unrated player after everyone with a rating. */
  let unratedSortKey = -1.

  let confirmedRsvps =
    mainList
    ->Array.filterWithIndex((_, i) => !isWaitlist(i))
    ->Array.toSorted((a, b) => {
      let muA = seedMu(a)->Option.getOr(unratedSortKey)
      let muB = seedMu(b)->Option.getOr(unratedSortKey)
      compare(muB, muA)->Int.toFloat
    })
  let waitlistRsvps = mainList->Array.filterWithIndex((_, i) => isWaitlist(i))
  let waitlistCount = waitlistRsvps->Array.length
  let pendingCount = pendingRsvps->Array.length

  // Pending requests as review cards. The deck acts on the RSVP id, since
  // approving updates the RSVP's list type rather than the user.
  let pendingReviewPlayers = pendingRsvps->Array.filterMap(n =>
    n.user->Option.map(u => {
      let name = u.lineUsername->Option.getOr("?")
      {
        PlayerInviteSwipeDeck.id: n.id,
        name,
        source: PlayerInviteSwipeDeck.FromProfile({
          displayName: name,
          picture: u.picture,
          gender: u.gender,
          biography: u.biography,
          selfDupr: u.selfRating->Option.map(Rating.guessDupr),
          duprDoubles: u.dupr->Option.flatMap(d => d.doubles),
          duprReliable: u.dupr->Option.map(d => d.doublesReliable)->Option.getOr(false),
          duprReliability: u.dupr->Option.flatMap(d => d.doublesReliability),
          computedDupr: n.rating->Option.flatMap(r => r.mu)->Option.map(Rating.guessDupr),
          computedSigma: n.rating->Option.flatMap(r => r.sigma),
          note: n.message,
        }),
      }
    })
  )

  // What the next run would admit, marked in the pending list with nobody
  // moved. A run clears it: the list it previewed no longer exists.
  let handlePreviewSmartRsvps = () => {
    setIsPreviewingSmartRsvps(_ => true)
    let _ = PreviewSmartRsvpsQuery.fetch(
      ~environment,
      ~variables={eventId: eventData.id},
      ~onResult=result => {
        setIsPreviewingSmartRsvps(_ => false)
        setSmartRsvpPreview(_ =>
          switch result {
          | Ok(data) =>
            Some(data.previewSmartRsvps.rsvps->Option.getOr([])->Array.map(r => r.id))
          | Error(_) => None
          }
        )
      },
    )
  }
  // Admits what the preview showed, then clears it: the list it described no
  // longer exists, so the button offers a fresh preview again.
  let handleEvaluateSmartRsvps = () =>
    commitEvaluateSmartRsvps(
      ~variables={eventId: eventData.id},
      ~onCompleted=(_, _) => setSmartRsvpPreview(_ => None),
    )->RescriptRelay.Disposable.ignore
  // On a full event: the pending list, ranked by the search, onto the waitlist.
  let handleSmartWaitlist = () =>
    commitSmartWaitlist(
      ~variables={eventId: eventData.id},
      ~onCompleted=(_, _) => setSmartRsvpPreview(_ => None),
    )->RescriptRelay.Disposable.ignore
  let smartRsvpBusy =
    isEvaluateSmartRsvpsInFlight || isPreviewingSmartRsvps || isSmartWaitlistInFlight

  // Right swipe approves onto the confirmed list; a left swipe leaves the RSVP
  // pending, so there is nothing to commit for it.
  let handleApprove = (rsvpId: string) =>
    commitUpdateListType(
      ~variables={input: {rsvpId, listType: 0}},
    )->RescriptRelay.Disposable.ignore

  let mus = confirmedRsvps->Array.filterMap(seedMu)
  let maxRating = mus->Array.reduce(0., (acc, mu) => mu > acc ? mu : acc)
  let maxRating = maxRating == 0. ? 1. : maxRating

  let (spreadStr, spreadQualifier, spreadQualifierClass) = if mus->Array.length >= 2 {
    let duprVals = mus->Array.map(Rating.guessDupr)
    let n = Float.fromInt(duprVals->Array.length)
    let mean = duprVals->Array.reduce(0., (a, b) => a +. b) /. n
    let variance = duprVals->Array.reduce(0., (acc, v) => acc +. (v -. mean) *. (v -. mean)) /. n
    let stdDev = Math.sqrt(variance)
    let (label, cls) = if stdDev < 0.3 {
      (ts`even`, "text-emerald-500 dark:text-emerald-400")
    } else if stdDev < 0.6 {
      (ts`balanced`, "text-gray-400 dark:text-gray-500")
    } else {
      (ts`mixed`, "text-amber-500 dark:text-amber-400")
    }
    ("±" ++ stdDev->Js.Float.toFixedWithPrecision(~digits=2), label, cls)
  } else {
    ("—", "", "text-gray-400 dark:text-gray-500")
  }

  let top6AvgDuprStr = if mus->Array.length > 0 {
    let top6 =
      mus
      ->Array.toSorted((a, b) => b -. a)
      ->Array.slice(~start=0, ~end=6)
    let avg = top6->Array.reduce(0., (a, b) => a +. b) /. Float.fromInt(top6->Array.length)
    avg->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=2)
  } else {
    "—"
  }

  let medianMu = arr => {
    let sorted = arr->Array.toSorted((a, b) => a -. b)
    let n = sorted->Array.length
    if n == 0 {
      None
    } else if mod(n, 2) == 1 {
      Some(sorted->Array.getUnsafe(n / 2))
    } else {
      Some((sorted->Array.getUnsafe(n / 2 - 1) +. sorted->Array.getUnsafe(n / 2)) /. 2.)
    }
  }

  let overallMedianDuprStr =
    medianMu(mus)
    ->Option.map(mu => mu->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=2))
    ->Option.getOr("—")

  let isFull = maxRsvps > 0 && confirmedRsvps->Array.length >= maxRsvps
  let openSpots = maxRsvps > 0 ? Js.Math.max_int(0, maxRsvps - confirmedRsvps->Array.length) : 0
  let percentage =
    maxRsvps > 0
      ? Js.Math.min_float(
          Float.fromInt(confirmedRsvps->Array.length) /. Float.fromInt(maxRsvps) *. 100.,
          100.,
        )
      : 0.
  let colorClass = isFull ? "bg-[#ef4444]" : percentage >= 75. ? "bg-[#ffb042]" : "bg-[#4ade80]"

  let maleMus = confirmedRsvps->Array.filterMap(node =>
    node.user->Option.flatMap(u => u.gender)->Option.flatMap(g => g == Male ? seedMu(node) : None)
  )
  let femaleMus = confirmedRsvps->Array.filterMap(node =>
    node.user->Option.flatMap(u => u.gender)->Option.flatMap(g => g == Female ? seedMu(node) : None)
  )

  let maleMedianMu = medianMu(maleMus)
  let femaleMedianMu = medianMu(femaleMus)
  let maleMedianDuprStr =
    maleMedianMu
    ->Option.map(mu => mu->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=1))
    ->Option.getOr("—")
  let femaleMedianDuprStr =
    femaleMedianMu
    ->Option.map(mu => mu->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=1))
    ->Option.getOr("—")
  let totalWithGender = maleMus->Array.length + femaleMus->Array.length
  let malePct =
    totalWithGender > 0
      ? Js.Math.round(
          Float.fromInt(maleMus->Array.length) /. Float.fromInt(totalWithGender) *. 100.,
        )->Float.toInt
      : 50
  let genderGapStr = switch (maleMedianMu, femaleMedianMu) {
  | (Some(m), Some(f)) =>
    let gap = Js.Math.abs_float(m -. f)->Rating.guessDupr
    if gap < 0.1 {
      "even"
    } else {
      "Δ" ++ gap->Js.Float.toFixedWithPrecision(~digits=1)
    }
  | _ => "—"
  }

  // Viewer rating check against minRating, resolved the way the server's
  // gate resolves it: pkuru or DUPR by confidence, never the self-rating.
  let viewerRating = viewerUser->Option.flatMap(v => v.eventRating)
  let viewerEffective = viewerUser->Option.flatMap(v =>
    CombinedRating.resolve(
      ~pkuruMu=v.eventRating->Option.flatMap(r => r.mu),
      ~pkuruSigma=?v.eventRating->Option.flatMap(r => r.sigma),
      ~duprDoubles=v.dupr->Option.flatMap(d => d.doubles),
      ~duprReliability=?v.dupr->Option.flatMap(d => d.doublesReliability),
      ~duprReliable=v.dupr->Option.map(d => d.doublesReliable)->Option.getOr(false),
      ~selfMu=None,
    )
  )
  let viewerRatingVal = {
    let d = Rating.Rating.makeDefault()
    switch (viewerEffective, viewerRating) {
    | (Some(r), Some(pk)) if CombinedRating.source(r) == Pkuru =>
      Rating.Rating.make(pk.mu->Option.getOr(d.mu), pk.sigma->Option.getOr(d.sigma))
    | (Some(r), _) => Rating.Rating.make(CombinedRating.mu(r), d.sigma)
    | (None, _) => d
    }
  }
  // A pkuru rating carries its uncertainty into the comparison; a DUPR rating
  // is compared as it stands, which is how the server gates it.
  let viewerOrdinal2 = switch viewerEffective {
  | Some(r) if CombinedRating.source(r) == Dupr => CombinedRating.mu(r)
  | _ => Rating.ordinal2(viewerRatingVal)
  }
  let viewerCanJoin = minRating->Option.map(min => viewerOrdinal2 >= min)

  // Smart RSVP holds every join for automatic review, so the level restriction
  // is no longer the thing that decides who gets in: the notice below stands in
  // for it. Anyone who already has an RSVP has seen it.
  let viewerHasRsvp =
    viewerUser
    ->Option.map(v =>
      rsvps->Array.some(n => n.user->Option.map(u => u.id == v.id)->Option.getOr(false))
    )
    ->Option.getOr(false)

  let ratingWarning = switch (eventData.smartRsvpThreshold, viewerUser) {
  | (Some(_), Some(_)) =>
    viewerHasRsvp
      ? React.null
      : <div
          className="mb-3 p-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700/40">
          <div
            className="font-mono text-[11px] tracking-wider text-blue-700 dark:text-blue-400 uppercase mb-1">
            {t`SMART RSVP`}
          </div>
          <div className="text-xs text-blue-800 dark:text-blue-300">
            {t`This event admits players by level rather than by the time of RSVP. Your request will be reviewed and you will be notified once a spot is confirmed.`}
          </div>
        </div>
  | _ =>
    switch minRating {
    | Some(min) =>
      let minDuprStr = min->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=2)
      switch (viewerUser, viewerCanJoin) {
      | (Some(_), Some(false)) =>
        let viewerOrdinal2Str = viewerOrdinal2->Float.toFixed(~digits=2)
        let viewerMuStr = viewerRatingVal.mu->Float.toFixed(~digits=2)
        let viewerDuprLo = viewerOrdinal2->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=2)
        let viewerDuprHi =
          viewerRatingVal.mu->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=2)
        <div
          className="mb-3 p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-700/40">
          <div
            className="font-mono text-[11px] tracking-wider text-amber-700 dark:text-amber-400 uppercase mb-1">
            {t`LEVEL RESTRICTION`}
          </div>
          <div className="text-xs text-amber-800 dark:text-amber-300">
            {t`Required: DUPR ${minDuprStr}+`}
          </div>
          <div className="text-xs text-amber-700/80 dark:text-amber-400/80 mt-0.5">
            {t`Your rating ${viewerOrdinal2Str} ~ ${viewerMuStr} (DUPR ${viewerDuprLo} ~ ${viewerDuprHi}) is below the minimum. You will be placed in the pending list.`}
          </div>
        </div>
      | _ =>
        <div
          className="mb-3 p-3 rounded-lg bg-gray-50 dark:bg-[#2a2b30] border border-gray-200 dark:border-[#3a3b40]">
          <div
            className="font-mono text-[11px] tracking-wider text-gray-500 dark:text-gray-400 uppercase mb-1">
            {t`LEVEL RESTRICTION`}
          </div>
          <div className="text-xs text-gray-700 dark:text-gray-300">
            {t`Requires DUPR ${minDuprStr}+ to join`}
          </div>
        </div>
      }
    | None => React.null
    }
  }

  <div
    className="mx-3 mt-3 rounded-xl border border-gray-200 bg-white px-4 py-4 dark:border-[#2a2b30] dark:bg-[#1e1f23]">
    {ratingWarning}
    /* Header */
    <div className="flex items-center justify-between mb-3">
      <h2
        className="flex items-center gap-2 text-base font-semibold text-gray-900 dark:text-gray-100">
        {(ts`Participants`)->React.string}
        {eventData.viewerIsAdmin && eventData.club->Option.isSome
          ? <button
              onClick={_ => setIsAddingPlayer(_ => true)}
              className="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-[#3a3b40] text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors"
              title="Add player">
              <Lucide.UserPlus className="w-3 h-3" />
            </button>
          : React.null}
        {eventData.viewerIsAdmin && eventData.chargesEnabled
          ? <button
              onClick={_ => onChargeAll()}
              disabled={isCaptureAllInFlight}
              className="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-[#3a3b40] text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors disabled:opacity-40"
              title="Charge all payments">
              <Lucide.CreditCard className="w-3 h-3" />
            </button>
          : React.null}
      </h2>
      <span className="font-mono text-xs text-gray-600 dark:text-gray-400">
        {((
          ts`${Int.toString(confirmedRsvps->Array.length) ++ (
            maxRsvps > 0 ? "/" ++ Int.toString(maxRsvps) : ""
          )} joined`
        ) ++
        (waitlistCount > 0 ? ts` · +${Int.toString(waitlistCount)} waitlist` : "") ++ (
          pendingCount > 0 ? ts` · ${Int.toString(pendingCount)} pending` : ""
        ))->React.string}
      </span>
    </div>
    {chargeErrors->Array.length > 0
      ? <div className="mb-3 space-y-0.5">
          {chargeErrors
          ->Array.mapWithIndex((message, i) =>
            <p
              key={Int.toString(i)}
              className="font-mono text-[11px] text-red-500 dark:text-red-400 leading-tight">
              {message->React.string}
            </p>
          )
          ->React.array}
        </div>
      : React.null}
    /* Add player autocomplete */
    <FramerMotion.AnimatePresence>
      {isAddingPlayer
        ? {
            switch eventData.club->Option.flatMap(c => Some(c.id)) {
            | Some(clubId) =>
              <FramerMotion.Div
                key="add-player"
                className="mb-3"
                initial={FramerMotion.opacity: 0., y: -4.}
                animate={FramerMotion.opacity: 1., y: 0.}
                exit={FramerMotion.opacity: 0., y: -4.}>
                <React.Suspense fallback={React.null}>
                  <AutocompleteUser
                    clubId onSelected={handleAddUser} onClose={_ => setIsAddingPlayer(_ => false)}
                  />
                </React.Suspense>
              </FramerMotion.Div>
            | None => React.null
            }
          }
        : React.null}
    </FramerMotion.AnimatePresence>
    /* Progress bar */
    <div className="mb-1">
      <div className="h-1 w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
        <div
          className={"h-full rounded-full " ++ colorClass}
          style={ReactDOM.Style.make(~width=Js.Float.toString(percentage) ++ "%", ())}
        />
      </div>
    </div>
    /* Skill summary: the level curve up front, the number grid behind a toggle */
    {mus->Array.length > 0
      ? <div className="mb-4 mt-3">
          <SkillDistributionChart
            duprs={mus->Array.map(Rating.guessDupr)} topCourtDupr=top6AvgDuprStr
          />
          <div className="mt-2 flex items-center justify-between gap-3">
            <p className="text-sm text-gray-600 dark:text-gray-300">
              {t`Top court DUPR`}
              {" "->React.string}
              <span className="font-semibold text-gray-900 dark:text-gray-100">
                {top6AvgDuprStr->React.string}
              </span>
            </p>
            <button
              type_="button"
              onClick={_ => setShowSkillDetail(v => !v)}
              ariaExpanded=showSkillDetail
              className="flex flex-shrink-0 items-center gap-1 text-xs font-semibold text-[#5f8618] underline-offset-2 transition-colors hover:text-[#476412] hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-[#bdf25d] dark:hover:text-[#d3ff85]">
              {showSkillDetail ? t`View less` : t`View more`}
              <Lucide.ChevronRight
                size=13
                className={"transition-transform duration-200 " ++ (
                  showSkillDetail ? "rotate-90" : ""
                )}
                \"aria-hidden"="true"
              />
            </button>
          </div>
          {showSkillDetail
            ? <div
                className="mt-2 grid grid-cols-2 sm:grid-cols-4 overflow-hidden rounded-md border border-gray-200 dark:border-[#3a3b40]">
                <div
                  className="border-r border-b sm:border-b-0 border-gray-200 px-3 py-2.5 dark:border-[#3a3b40]">
                  <p
                    className="text-[11px] font-medium uppercase tracking-wide text-gray-500 dark:text-gray-400">
                    {t`TOP 6 AVG`}
                  </p>
                  <p className="mt-0.5 text-lg font-semibold text-gray-900 dark:text-gray-100">
                    {top6AvgDuprStr->React.string}
                  </p>
                  <p className="text-[11px] text-gray-400"> {t`DUPR`} </p>
                </div>
                <div
                  className="border-b sm:border-r sm:border-b-0 border-gray-200 px-3 py-2.5 dark:border-[#3a3b40]">
                  <p
                    className="text-[11px] font-medium uppercase tracking-wide text-gray-500 dark:text-gray-400">
                    {t`MEDIAN`}
                  </p>
                  <p className="mt-0.5 text-lg font-semibold text-gray-900 dark:text-gray-100">
                    {overallMedianDuprStr->React.string}
                  </p>
                  <p className="text-[11px] text-gray-400"> {t`DUPR`} </p>
                </div>
                <div className="border-r border-gray-200 px-3 py-2.5 dark:border-[#3a3b40]">
                  <p
                    className="text-[11px] font-medium uppercase tracking-wide text-gray-500 dark:text-gray-400">
                    {t`♂/♀ SKILL`}
                  </p>
                  <p className="mt-0.5 flex items-baseline gap-1 text-lg font-semibold">
                    <span className="text-blue-500 dark:text-blue-400">
                      {maleMedianDuprStr->React.string}
                    </span>
                    <span className="text-sm text-gray-300 dark:text-gray-600">
                      {"/"->React.string}
                    </span>
                    <span className="text-pink-500 dark:text-pink-400">
                      {femaleMedianDuprStr->React.string}
                    </span>
                  </p>
                  <div className="mt-1 flex items-center gap-1.5">
                    <div
                      className="h-1 flex-1 overflow-hidden rounded-full bg-pink-300/40 dark:bg-pink-400/20">
                      <div
                        className="h-full rounded-full bg-blue-400"
                        style={ReactDOM.Style.make(~width=Int.toString(malePct) ++ "%", ())}
                      />
                    </div>
                    <span className="text-[10px] text-gray-400"> {genderGapStr->React.string} </span>
                  </div>
                </div>
                <div className="px-3 py-2.5">
                  <p
                    className="text-[11px] font-medium uppercase tracking-wide text-gray-500 dark:text-gray-400">
                    {t`SPREAD`}
                  </p>
                  <p className="mt-0.5 text-lg font-semibold text-gray-900 dark:text-gray-100">
                    {spreadStr->React.string}
                  </p>
                  <p className={"text-[11px] " ++ spreadQualifierClass}>
                    {spreadQualifier->React.string}
                  </p>
                </div>
              </div>
            : React.null}
        </div>
      : React.null}
    /* Confirmed section */
    {confirmedRsvps->Array.length > 0
      ? <>
          <div className="flex items-center gap-2 mb-2">
            <div className="h-px flex-1 bg-gray-200 dark:bg-[#3a3b40]" />
            <span
              className="font-mono text-[11px] tracking-wider text-emerald-600 dark:text-emerald-400 uppercase flex items-center gap-1">
              <svg
                width="10"
                height="10"
                viewBox="0 0 14 14"
                fill="none"
                className="text-emerald-500 dark:text-emerald-400">
                <path
                  d="M3 7.5L5.5 10L11 4"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
              {(ts`Confirmed · ${Int.toString(confirmedRsvps->Array.length)}`)->React.string}
            </span>
            <div className="h-px flex-1 bg-gray-200 dark:bg-[#3a3b40]" />
          </div>
          <div className="flex flex-wrap gap-1.5">
            {confirmedRsvps
            ->Array.map(edge => {
              let isHost =
                eventData.owner
                ->Option.flatMap(o => o.lineUsername)
                ->Option.map(ownerName =>
                  edge.user->Option.flatMap(u => u.lineUsername)->Option.getOr("") == ownerName
                )
                ->Option.getOr(false)
              <PkEventRsvp
                key=edge.id
                eventId=eventData.id
                rsvp={edge.fragmentRefs}
                ?activitySlug
                maxRating
                isAdmin=eventData.viewerIsAdmin
                chargesEnabled=eventData.chargesEnabled
                isHost
                showRating=isCompetitive
                connectionKey="PkRSVPSection_event_rsvps"
              />
            })
            ->React.array}
          </div>
        </>
      : React.null}
    /* Waitlist section */
    {waitlistRsvps->Array.length > 0
      ? <div className="mt-2.5">
          <div className="flex items-center gap-2 mb-2">
            <div className="h-px flex-1 bg-gray-200 dark:bg-[#3a3b40]" />
            <span
              className="font-mono text-[11px] tracking-wider text-gray-400 dark:text-gray-500 uppercase flex items-center gap-1">
              <svg
                width="10"
                height="10"
                viewBox="0 0 14 14"
                fill="none"
                className="text-gray-400 dark:text-gray-500">
                <circle cx="7" cy="7" r="5" stroke="currentColor" strokeWidth="1.5" />
                <path
                  d="M7 4.5V7.5L9 9"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
              {(ts`Waitlist · ${Int.toString(waitlistRsvps->Array.length)}`)->React.string}
            </span>
            <div className="h-px flex-1 bg-gray-200 dark:bg-[#3a3b40]" />
          </div>
          <div className="flex flex-col gap-0.5">
            {waitlistRsvps
            ->Array.mapWithIndex((edge, i) =>
              <PkEventRsvp
                key=edge.id
                eventId=eventData.id
                rsvp={edge.fragmentRefs}
                ?activitySlug
                maxRating
                isAdmin=eventData.viewerIsAdmin
                chargesEnabled=eventData.chargesEnabled
                waitlistPosition={i + 1}
                showRating=isCompetitive
                connectionKey="PkRSVPSection_event_rsvps"
              />
            )
            ->React.array}
          </div>
        </div>
      : React.null}
    /* Pending section */
    {pendingRsvps->Array.length > 0
      ? <div className="mt-2.5">
          <div className="relative flex items-center gap-2 mb-2">
            <div className="h-px flex-1 bg-gray-200 dark:bg-[#3a3b40]" />
            <span
              className="font-mono text-[11px] tracking-wider text-amber-500 dark:text-amber-400 uppercase flex items-center gap-1">
              <svg
                width="10"
                height="10"
                viewBox="0 0 14 14"
                fill="none"
                className="text-amber-500 dark:text-amber-400">
                <circle cx="7" cy="7" r="5" stroke="currentColor" strokeWidth="1.5" />
                <path d="M7 5V8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
                <circle cx="7" cy="9.75" r="0.75" fill="currentColor" />
              </svg>
              {(ts`Pending · ${Int.toString(pendingRsvps->Array.length)}`)->React.string}
            </span>
            <div className="h-px flex-1 bg-gray-200 dark:bg-[#3a3b40]" />
            {eventData.viewerIsAdmin && pendingReviewPlayers->Array.length > 0
              ? <button
                  type_="button"
                  onClick={_ => setPendingSwipeOpen(_ => true)}
                  className="absolute right-0 top-1/2 inline-flex -translate-y-1/2 items-center gap-1 rounded-md bg-amber-500 px-2 py-1 text-[9px] font-semibold text-white transition-colors hover:bg-amber-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-amber-500 focus-visible:ring-offset-2 dark:bg-amber-500 dark:hover:bg-amber-400 dark:hover:text-amber-950"
                  ariaLabel={ts`Review ${Int.toString(
                      pendingReviewPlayers->Array.length,
                    )} pending requests with swipe cards`}>
                  <Lucide.Layers size=10 strokeWidth=2.5 \"aria-hidden"="true" />
                  {(ts`Swipe review`)->React.string}
                </button>
              : React.null}
          </div>
          {eventData.viewerIsAdmin && eventData.smartRsvpThreshold->Option.isSome
            ? <div className="mb-2">
                <div className="flex flex-wrap gap-2">
                  // One button, two steps: an admission is always previewed
                  // first, and the button offers the step that matches what is
                  // on screen. A run clears the preview and it starts over.
                  {switch smartRsvpPreview {
                  | None =>
                    <button
                      type_="button"
                      disabled={smartRsvpBusy}
                      onClick={_ => handlePreviewSmartRsvps()}
                      className="inline-flex items-center gap-1 rounded-md border border-emerald-600 px-2 py-1 text-[10px] font-semibold text-emerald-700 transition-colors hover:bg-emerald-50 disabled:cursor-wait disabled:opacity-60 focus:outline-none focus-visible:ring-2 focus-visible:ring-emerald-500 focus-visible:ring-offset-2 dark:text-emerald-300 dark:hover:bg-emerald-900/30">
                      {(isPreviewingSmartRsvps ? ts`Previewing…` : ts`Preview Smart RSVP`)->React.string}
                    </button>
                  | Some(_) =>
                    <button
                      type_="button"
                      disabled={smartRsvpBusy}
                      onClick={_ => handleEvaluateSmartRsvps()}
                      className="inline-flex items-center gap-1 rounded-md bg-blue-600 px-2 py-1 text-[10px] font-semibold text-white transition-colors hover:bg-blue-700 disabled:cursor-wait disabled:opacity-60 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2">
                      {(
                        isEvaluateSmartRsvpsInFlight
                          ? ts`Evaluating pending requests…`
                          : ts`Run Smart RSVP now`
                      )->React.string}
                    </button>
                  }}
                  {isFull
                    ? <button
                        type_="button"
                        disabled={smartRsvpBusy}
                        onClick={_ => handleSmartWaitlist()}
                        className="inline-flex items-center gap-1 rounded-md bg-amber-500 px-2 py-1 text-[10px] font-semibold text-white transition-colors hover:bg-amber-600 disabled:cursor-wait disabled:opacity-60 focus:outline-none focus-visible:ring-2 focus-visible:ring-amber-500 focus-visible:ring-offset-2 dark:hover:bg-amber-400 dark:hover:text-amber-950">
                        {(isSmartWaitlistInFlight ? ts`Placing on the waitlist…` : ts`Smart Waitlist`)->React.string}
                      </button>
                    : React.null}
                </div>
                {switch smartRsvpPreview {
                | Some(ids) =>
                  <p className="mt-1.5 text-[11px] text-gray-600 dark:text-gray-300">
                    {t`Smart RSVP would admit ${ids->Array.length->Int.toString} of ${pendingCount->Int.toString} pending requests: they are marked below.`}
                    <button
                      type_="button"
                      onClick={_ => setSmartRsvpPreview(_ => None)}
                      className="ml-1.5 font-semibold text-emerald-700 underline dark:text-emerald-300">
                      {t`Clear preview`}
                    </button>
                  </p>
                | None => React.null
                }}
              </div>
            : React.null}
          <div className="flex flex-wrap gap-1.5">
            {pendingRsvps
            ->Array.map(edge => {
              let chip =
                <PkEventRsvp
                  key=edge.id
                  eventId=eventData.id
                  rsvp={edge.fragmentRefs}
                  ?activitySlug
                  maxRating
                  isAdmin=eventData.viewerIsAdmin
                chargesEnabled=eventData.chargesEnabled
                  isPending=true
                  showRating=isCompetitive
                  connectionKey="PkRSVPSection_event_rsvps"
                />
              let wouldBeAdmitted =
                smartRsvpPreview->Option.map(ids => ids->Array.includes(edge.id))->Option.getOr(false)
              // A preview mark: the next run would admit this request.
              wouldBeAdmitted
                ? <span
                    key=edge.id
                    title={ts`Would be admitted`}
                    className="relative inline-flex rounded-full ring-2 ring-emerald-500 ring-offset-1 dark:ring-offset-[#1e1f23]">
                    chip
                    <span
                      className="absolute -right-1 -top-1 z-10 h-3 w-3 rounded-full bg-emerald-500 ring-2 ring-white dark:ring-[#1e1f23]"
                      ariaHidden=true
                    />
                  </span>
                : chip
            })
            ->React.array}
          </div>
        </div>
      : React.null}
    /* Approve-review deck. Rendered outside the pending section so approving
       the last request doesn't unmount the deck before its summary card. */
    {pendingSwipeOpen
      ? <PlayerInviteSwipeDeck
          players=pendingReviewPlayers
          eventTitle={eventData.title->Option.getOr("")}
          mode=PlayerInviteSwipeDeck.Approve
          onAccept=handleApprove
          onClose={() => setPendingSwipeOpen(_ => false)}
        />
      : React.null}
    /* Sent and potential invites */
    <EventInvites
      eventId=eventData.id
      canInvite={eventData.viewerIsAdmin && eventData.shadow != Some(true)}
      activityId={eventData.activity->Option.map(a => a.id)}
      activitySlug
      clubId={eventData.club->Option.map(c => c.id)}
      eventTitle={eventData.title->Option.getOr("")}
      venueName={eventData.location
      ->Option.flatMap(l => l.name)
      ->Option.getOr(Lingui.UtilString.t`Court`)}
      startDate=eventData.startDate
      endDate=eventData.endDate
      timezone={eventData.timezone->Option.getOr("Asia/Tokyo")}
      participantUserIds={Belt.Array.concat(
        rsvps->Array.filterMap(n => n.user->Option.map(u => u.id)),
        viewerUser->Option.map(v => [v.id])->Option.getOr([]),
      )}
      invitedCount={invitedRsvps->Array.length}
      invitedChips={invitedRsvps
      ->Array.map(edge =>
        <li key=edge.id className="relative">
          <PkEventRsvp
            eventId=eventData.id
            rsvp={edge.fragmentRefs}
            ?activitySlug
            maxRating
            isAdmin=eventData.viewerIsAdmin
                chargesEnabled=eventData.chargesEnabled
            isInvited=true
            showRating=isCompetitive
            connectionKey="PkRSVPSection_event_rsvps"
          />
        </li>
      )
      ->React.array}
    />
  </div>
}
