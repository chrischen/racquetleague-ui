%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment PkRSVPSection_event on Event {
    id
    maxRsvps
    price
    minRating
    viewerIsAdmin
    club {
      id
    }
    activity {
      slug
    }
    owner {
      lineUsername
    }
    rsvps(first: 100) @connection(key: "PkRSVPSection_event_rsvps") {
      edges {
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
  let (commitMutationAddUser, _addUserInFlight) = PkRSVPSectionAddUserMutation.use()

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
  let maxRsvps = eventData.maxRsvps->Option.getOr(0)
  let minRating = eventData.minRating
  let activitySlug = eventData.activity->Option.flatMap(a => a.slug)

  let isWaitlist = count => maxRsvps > 0 && count >= maxRsvps

  let mainList = rsvps->Array.filter(n => n.listType == None || n.listType == Some(0))
  let pendingRsvps = rsvps->Array.filter(n => n.listType != None && n.listType != Some(0))
  let confirmedRsvps =
    mainList
    ->Array.filterWithIndex((_, i) => !isWaitlist(i))
    ->Array.toSorted((a, b) => {
      let muA = a.rating->Option.flatMap(r => r.mu)->Option.getOr(25.)
      let muB = b.rating->Option.flatMap(r => r.mu)->Option.getOr(25.)
      compare(muB, muA)->Int.toFloat
    })
  let waitlistRsvps = mainList->Array.filterWithIndex((_, i) => isWaitlist(i))
  let waitlistCount = waitlistRsvps->Array.length
  let pendingCount = pendingRsvps->Array.length

  let mus = confirmedRsvps->Array.map(n => n.rating->Option.flatMap(r => r.mu)->Option.getOr(25.))
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
    node.user
    ->Option.flatMap(u => u.gender)
    ->Option.flatMap(g => g == Male ? node.rating->Option.flatMap(r => r.mu) : None)
  )
  let femaleMus = confirmedRsvps->Array.filterMap(node =>
    node.user
    ->Option.flatMap(u => u.gender)
    ->Option.flatMap(g => g == Female ? node.rating->Option.flatMap(r => r.mu) : None)
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

  // Viewer rating check against minRating
  let viewerRating = viewerUser->Option.flatMap(v => v.eventRating)
  let viewerRatingVal = {
    let d = Rating.Rating.makeDefault()
    switch viewerRating {
    | Some(r) => Rating.Rating.make(r.mu->Option.getOr(d.mu), r.sigma->Option.getOr(d.sigma))
    | None => d
    }
  }
  let viewerOrdinal2 = Rating.ordinal2(viewerRatingVal)
  let viewerCanJoin = minRating->Option.map(min => viewerOrdinal2 >= min)

  let ratingWarning = switch minRating {
  | Some(min) =>
    let minDuprStr = min->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=2)
    switch (viewerUser, viewerCanJoin) {
    | (Some(_), Some(false)) =>
      let viewerOrdinal2Str = viewerOrdinal2->Float.toFixed(~digits=2)
      let viewerMuStr = viewerRatingVal.mu->Float.toFixed(~digits=2)
      let viewerDuprLo = viewerOrdinal2->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=2)
      let viewerDuprHi = viewerRatingVal.mu->Rating.guessDupr->Js.Float.toFixedWithPrecision(~digits=2)
      <div
        className="mb-3 p-3 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-700/40">
        <div
          className="font-mono text-[11px] tracking-wider text-amber-700 dark:text-amber-400 uppercase mb-1">
          {"LEVEL RESTRICTION"->React.string}
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
          {"LEVEL RESTRICTION"->React.string}
        </div>
        <div className="text-xs text-gray-700 dark:text-gray-300">
          {t`Requires DUPR ${minDuprStr}+ to join`}
        </div>
      </div>
    }
  | None => React.null
  }

  <div className="px-5 py-4 border-b border-gray-100 dark:border-[#2a2b30]">
    {ratingWarning}
    /* Header */
    <div className="flex items-center justify-between mb-3">
      <h2
        className="font-mono text-xs tracking-wider text-gray-400 dark:text-gray-500 uppercase flex items-center gap-2">
        {(ts`Participants`)->React.string}
        {eventData.viewerIsAdmin && eventData.club->Option.isSome
          ? <button
              onClick={_ => setIsAddingPlayer(_ => true)}
              className="p-1 rounded-md hover:bg-gray-100 dark:hover:bg-[#3a3b40] text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors"
              title="Add player">
              <Lucide.UserPlus className="w-3 h-3" />
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
    /* Stats grid */
    <div
      className="grid grid-cols-2 sm:grid-cols-4 border border-gray-200 dark:border-[#3a3b40] rounded-lg overflow-hidden mb-4">
      <div
        className="px-3 py-2.5 border-r border-b sm:border-b-0 border-gray-200 dark:border-[#3a3b40]">
        <div className="font-mono text-[11px] tracking-wider text-gray-400 dark:text-gray-500">
          {t`TOP 6 AVG`}
        </div>
        <div className="font-mono text-xl text-gray-900 dark:text-gray-100 mt-0.5">
          {top6AvgDuprStr->React.string}
        </div>
        <div className="font-mono text-[11px] text-gray-400 mt-0.5"> {t`DUPR`} </div>
      </div>
      <div
        className="px-3 py-2.5 border-b sm:border-r sm:border-b-0 border-gray-200 dark:border-[#3a3b40]">
        <div className="font-mono text-[11px] tracking-wider text-gray-400 dark:text-gray-500">
          {t`MEDIAN`}
        </div>
        <div className="font-mono text-xl text-gray-900 dark:text-gray-100 mt-0.5">
          {overallMedianDuprStr->React.string}
        </div>
        <div className="font-mono text-[11px] text-gray-400 mt-0.5"> {t`DUPR`} </div>
      </div>
      <div className="px-3 py-2.5 border-r border-gray-200 dark:border-[#3a3b40]">
        <div className="font-mono text-[11px] tracking-wider text-gray-400 dark:text-gray-500">
          {t`♂/♀ SKILL`}
        </div>
        <div
          className="font-mono text-xl text-gray-900 dark:text-gray-100 mt-0.5 flex items-baseline gap-0.5">
          <span className="text-blue-400"> {maleMedianDuprStr->React.string} </span>
          <span className="text-gray-300 dark:text-gray-600 text-sm"> {"/"->React.string} </span>
          <span className="text-pink-400"> {femaleMedianDuprStr->React.string} </span>
        </div>
        <div className="flex items-center gap-1.5 mt-1">
          <div
            className="flex-1 h-1 rounded-full bg-pink-300/40 dark:bg-pink-400/20 overflow-hidden">
            <div
              className="h-full rounded-full bg-blue-400"
              style={ReactDOM.Style.make(~width=Int.toString(malePct) ++ "%", ())}
            />
          </div>
          <span className="font-mono text-[9px] text-gray-400"> {genderGapStr->React.string} </span>
        </div>
      </div>
      <div className="px-3 py-2.5">
        <div className="font-mono text-[11px] tracking-wider text-gray-400 dark:text-gray-500">
          {t`SPREAD`}
        </div>
        <div className="font-mono text-xl text-gray-900 dark:text-gray-100 mt-0.5">
          {spreadStr->React.string}
        </div>
        <div className={"font-mono text-[11px] mt-0.5 " ++ spreadQualifierClass}>
          {spreadQualifier->React.string}
        </div>
      </div>
    </div>
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
                isHost
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
                waitlistPosition={i + 1}
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
          <div className="flex items-center gap-2 mb-2">
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
          </div>
          <div className="flex flex-wrap gap-1.5">
            {pendingRsvps
            ->Array.map(edge =>
              <PkEventRsvp
                key=edge.id
                eventId=eventData.id
                rsvp={edge.fragmentRefs}
                ?activitySlug
                maxRating
                isAdmin=eventData.viewerIsAdmin
                isPending=true
                connectionKey="PkRSVPSection_event_rsvps"
              />
            )
            ->React.array}
          </div>
        </div>
      : React.null}
  </div>
}
