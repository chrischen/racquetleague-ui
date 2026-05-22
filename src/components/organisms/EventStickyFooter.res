%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module JoinEventMutation = %relay(`
  mutation EventStickyFooterJoinMutation($connections: [ID!]!, $eventId: ID!) {
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
  mutation EventStickyFooterLeaveMutation($connections: [ID!]!, $eventId: ID!) {
    leaveEvent(eventId: $eventId) {
      eventIds @deleteEdge(connections: $connections)
      errors { message }
    }
  }
`)

type eventShape = {
  __id: RescriptRelay.dataId,
  id: string,
  price: option<int>,
  currency: option<string>,
  startDate: option<Util.Datetime.t>,
  cancelDeadline: option<int>,
  shadow: option<bool>,
  deleted: option<Util.Datetime.t>,
}

type viewerUserShape = {
  id: string,
  lineUsername: option<string>,
  email: option<string>,
}

@react.component
let make = (
  ~event: eventShape,
  ~viewerUser: option<viewerUserShape>,
  ~isJoined: bool,
  ~isWaitlisted: bool,
  ~isPending: bool,
  ~isUnpaid: bool,
  ~viewerJoinTime: option<float>,
  ~isPaidEvent: bool,
  ~isPlatformPayment: bool,
  ~isFull: bool,
  ~confirmedCount: int,
  ~waitlistCount: int,
  ~maxRsvps: int,
  ~tz: string,
  ~locale: LangProvider.locale,
  ~queryFragmentRefs: RescriptRelay.fragmentRefs<[> #ProfileModal_viewer]>,
  ~charging: bool,
  ~onPayClick: unit => unit,
) => {
  let ts = Lingui.UtilString.t

  let (joinEvent, joining) = JoinEventMutation.use()
  let (leaveEvent, leaving) = LeaveEventMutation.use()

  let (isProfileModalOpen, setIsProfileModalOpen) = React.useState(() => false)
  let (pendingJoinAction, setPendingJoinAction) = React.useState(() => None)
  let (showLeaveConfirm, setShowLeaveConfirm) = React.useState(() => false)

  let hasCompleteProfile = () =>
    switch viewerUser {
    | Some(user) =>
      switch (user.lineUsername, user.email) {
      | (Some(u), Some(e)) => u != "" && e != ""
      | _ => false
      }
    | None => false
    }

  let performLeave = () => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      event.__id,
      "PkRSVPSection_event_rsvps",
      (),
    )
    leaveEvent(~variables={eventId: event.id, connections: [connectionId]})->ignore
  }

  let doLeave = () => {
    if waitlistCount > 0 {
      setShowLeaveConfirm(_ => true)
    } else {
      performLeave()
    }
  }

  let doJoin = () => {
    let proceed = () => {
      let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
        event.__id,
        "PkRSVPSection_event_rsvps",
        (),
      )
      joinEvent(~variables={eventId: event.id, connections: [connectionId]})->ignore
    }
    if hasCompleteProfile() {
      proceed()
    } else {
      setPendingJoinAction(_ => Some(proceed))
      setIsProfileModalOpen(_ => true)
    }
  }

  switch (event.deleted, viewerUser) {
  | (None, Some(_)) =>
    switch event.shadow {
    | Some(true) => React.null
    | _ => {
        let cancelDeadlineDate =
          event.startDate->Option.flatMap(sd =>
            event.cancelDeadline->Option.map(ms =>
              Js.Date.fromFloat(sd->Util.Datetime.toDate->DateFns.getTime -. Int.toFloat(ms))
            )
          )
        let cancelMinutesLeft =
          cancelDeadlineDate->Option.map(d => DateFns.differenceInMinutes(d, Js.Date.make()))
        let deadlinePassed =
          cancelDeadlineDate->Option.isSome &&
            cancelMinutesLeft->Option.map(m => m <= 0.)->Option.getOr(false)
        let isInGracePeriod =
          !isWaitlisted &&
          viewerJoinTime
          ->Option.map(jt =>
            DateFns.differenceInMinutes(Js.Date.make(), Js.Date.fromFloat(jt)) <= 30.
          )
          ->Option.getOr(false)

        <>
          <div
            className="sticky bottom-0 bg-white dark:bg-[#1e1f23] border-t border-gray-200 dark:border-[#2a2b30] flex flex-col flex-shrink-0">
            {if isUnpaid {
              // State 2: Unpaid — payment required to confirm spot
              <>
                <div
                  className="bg-amber-50 dark:bg-amber-900/20 border-b border-amber-200/60 dark:border-amber-800/30 px-5 py-2.5 flex items-center gap-2">
                  <Lucide.CreditCard
                    className="w-3 h-3 text-amber-600 dark:text-amber-400 flex-shrink-0"
                  />
                  <span
                    className="font-mono text-[11px] font-medium text-amber-700 dark:text-amber-300 leading-tight">
                    {isPlatformPayment
                      ? t`Deposit required to confirm your spot`
                      : t`Payment required to confirm your spot`}
                  </span>
                </div>
                {isPlatformPayment
                  ? <div
                      className="bg-amber-50/50 dark:bg-amber-900/10 border-b border-amber-200/40 dark:border-amber-800/20 px-5 py-2">
                      <span
                        className="font-mono text-[10px] text-amber-600 dark:text-amber-400 leading-tight">
                        {t`This is a deposit hold only — payment is due to the organizer at the event. The hold will be released after the event.`}
                      </span>
                    </div>
                  : React.null}
                <div
                  className="bg-white dark:bg-[#1e1f23] px-5 py-3 flex items-center justify-between gap-2">
                  <button
                    disabled={leaving}
                    onClick={_ => doLeave()}
                    className="font-mono text-[11px] text-gray-500 dark:text-gray-400 hover:text-red-500 dark:hover:text-red-400 transition-colors uppercase tracking-wider disabled:opacity-50 disabled:cursor-not-allowed">
                    {(leaving ? ts`Cancelling...` : ts`Cancel RSVP`)->React.string}
                  </button>
                  <button
                    disabled={charging}
                    onClick={_ => onPayClick()}
                    className="px-4 py-2 text-sm font-semibold rounded-md transition-colors flex-shrink-0 bg-amber-500 text-white hover:bg-amber-600 inline-flex items-center justify-center gap-1.5 disabled:opacity-60">
                    <Lucide.CreditCard className="w-3 h-3" />
                    {if charging {
                      (ts`Loading...`)->React.string
                    } else if isPlatformPayment {
                      t`Authorize deposit`
                    } else {
                      let currencyStr =
                        event.currency
                        ->Option.map(PaymentIndicator.getCurrencySymbol)
                        ->Option.getOr("¥")
                      let priceStr =
                        event.price
                        ->Option.map(p => currencyStr ++ Int.toString(p))
                        ->Option.getOr("")
                      (ts`Pay ${priceStr}`)->React.string
                    }}
                  </button>
                </div>
              </>
            } else if isPending {
              // State: Pending admin approval
              <div className="px-5 py-3 flex items-center justify-between">
                <div className="flex items-center gap-2 min-w-0">
                  <div
                    className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0 bg-orange-100 dark:bg-orange-900/30 border border-orange-400 dark:border-orange-500 border-dashed">
                    <svg width="10" height="10" viewBox="0 0 14 14" fill="none">
                      <path d="M7 4V7.5" stroke="#ea580c" strokeWidth="1.5" strokeLinecap="round" />
                      <circle cx="7" cy="10" r="0.75" fill="#ea580c" />
                    </svg>
                  </div>
                  <div className="font-mono text-xs min-w-0">
                    <span
                      className="font-semibold uppercase tracking-wider text-orange-600 dark:text-orange-400">
                      {(ts`Pending approval`)->React.string}
                    </span>
                    <span
                      className="block text-[10px] text-gray-500 dark:text-gray-400 normal-case tracking-normal truncate">
                      {(ts`Your RSVP is awaiting admin approval`)->React.string}
                    </span>
                  </div>
                </div>
                <button
                  className="px-4 py-2 text-sm font-medium rounded-md transition-colors border flex-shrink-0 text-gray-700 dark:text-gray-300 bg-white dark:bg-transparent border-gray-200 dark:border-[#3a3b40] hover:bg-red-50 dark:hover:bg-red-900/20 hover:border-red-200 dark:hover:border-red-800/40 hover:text-red-600 dark:hover:text-red-400"
                  disabled={leaving}
                  onClick={_ => doLeave()}>
                  {(leaving ? ts`Withdrawing...` : ts`Withdraw RSVP`)->React.string}
                </button>
              </div>
            } else if isJoined {
              // State 3: Joined or Waitlisted — show cancellation notice + leave button
              <>
                {cancelDeadlineDate->Option.isSome && !isWaitlisted
                  ? <div
                      className="bg-amber-50 dark:bg-amber-900/20 border-b border-amber-200/60 dark:border-amber-800/30 px-5 py-2.5 flex items-center gap-2">
                      <Lucide.AlertCircle
                        className="w-3 h-3 text-amber-600 dark:text-amber-400 flex-shrink-0"
                      />
                      <span
                        className="font-mono text-[11px] font-medium text-amber-700 dark:text-amber-300">
                        {switch cancelMinutesLeft->Option.filter(m => m > 0.) {
                        | Some(mins) =>
                          <>
                            {(ts`Cancellation deadline`)->React.string}
                            {": "->React.string}
                            <ReactIntl.FormattedRelativeTime
                              value={mins} unit=#minute updateIntervalInSeconds=1.
                            />
                          </>
                        | None =>
                          (
                            ts`Cancellation deadline passed. Contact the organizer on this page to cancel.`
                          )->React.string
                        }}
                      </span>
                    </div>
                  : React.null}
                <div className="px-5 py-3 flex items-center justify-between">
                  <div className="flex items-center gap-2 min-w-0">
                    <div
                      className={Util.cx([
                        "w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0",
                        isWaitlisted
                          ? "bg-amber-100 dark:bg-amber-900/30 border border-amber-400 dark:border-amber-500"
                          : "bg-[#bdf25d]/20 border border-[#bdf25d]",
                      ])}>
                      {isWaitlisted
                        ? <svg width="10" height="10" viewBox="0 0 14 14" fill="none">
                            <circle cx="7" cy="7" r="5" stroke="#d97706" strokeWidth="1.5" />
                            <path
                              d="M7 4.5V7.5L9 9"
                              stroke="#d97706"
                              strokeWidth="1.5"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                          </svg>
                        : <svg width="10" height="10" viewBox="0 0 14 14" fill="none">
                            <path
                              d="M3 7.5L5.5 10L11 4"
                              stroke="#65a30d"
                              strokeWidth="2"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                          </svg>}
                    </div>
                    <div className="font-mono text-xs truncate">
                      <span
                        className={Util.cx([
                          "font-semibold uppercase tracking-wider",
                          isWaitlisted
                            ? "text-amber-600 dark:text-amber-400"
                            : "text-gray-900 dark:text-gray-100",
                        ])}>
                        {(isWaitlisted ? ts`On waitlist` : ts`You're in`)->React.string}
                      </span>
                      <span className="text-gray-400 dark:text-gray-500">
                        {(" \u00B7 " ++ (
                          isWaitlisted
                            ? "#" ++ Int.toString(waitlistCount) ++ " in queue"
                            : Int.toString(confirmedCount) ++ (
                                maxRsvps > 0 ? "/" ++ Int.toString(maxRsvps) : ""
                              )
                        ))->React.string}
                      </span>
                    </div>
                  </div>
                  <button
                    className={Util.cx([
                      "px-4 py-2 text-sm font-medium rounded-md transition-colors border flex-shrink-0",
                      deadlinePassed && !isWaitlisted && !isInGracePeriod
                        ? "text-gray-400 dark:text-gray-600 bg-gray-100 dark:bg-[#2a2b30] border-gray-200 dark:border-[#3a3b40] cursor-not-allowed"
                        : "text-gray-700 dark:text-gray-300 bg-white dark:bg-transparent border-gray-200 dark:border-[#3a3b40] hover:bg-red-50 dark:hover:bg-red-900/20 hover:border-red-200 dark:hover:border-red-800/40 hover:text-red-600 dark:hover:text-red-400",
                    ])}
                    disabled={leaving || (deadlinePassed && !isWaitlisted && !isInGracePeriod)}
                    onClick={_ => doLeave()}>
                    {(
                      leaving ? ts`Leaving...` : isWaitlisted ? ts`Leave waitlist` : ts`Leave event`
                    )->React.string}
                  </button>
                </div>
              </>
            } else {
              // State 1: Unjoined — claim spot
              <>
                {cancelDeadlineDate->Option.isSome
                  ? <div
                      className="bg-amber-50 dark:bg-amber-900/20 border-b border-amber-200/60 dark:border-amber-800/30 px-5 py-2.5 flex items-center gap-2">
                      <Lucide.AlertCircle
                        className="w-3 h-3 text-amber-600 dark:text-amber-400 flex-shrink-0"
                      />
                      <span
                        className="font-mono text-[11px] font-medium text-amber-700 dark:text-amber-300">
                        {switch cancelMinutesLeft->Option.filter(m => m > 0.) {
                        | Some(mins) =>
                          <>
                            {(ts`Cancellation deadline`)->React.string}
                            {": "->React.string}
                            <ReactIntl.FormattedRelativeTime
                              value={mins} unit=#minute updateIntervalInSeconds=1.
                            />
                          </>
                        | None => (ts`Cancellation deadline passed.`)->React.string
                        }}
                      </span>
                    </div>
                  : React.null}
                <div className="px-5 py-3 flex items-center justify-between">
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
                      Int.toString(confirmedCount) ++ (
                        maxRsvps > 0 ? "/" ++ Int.toString(maxRsvps) : ""
                      ))->React.string}
                    </span>
                  </div>
                  <button
                    className={Util.cx([
                      "px-4 py-2 text-sm font-semibold rounded-md transition-colors border",
                      isFull
                        ? "bg-white dark:bg-transparent border-gray-200 dark:border-[#3a3b40] text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#2a2b30]"
                        : "bg-[#bdf25d] text-black hover:bg-[#aee050] border-transparent",
                    ])}
                    disabled={joining}
                    onClick={_ => doJoin()}>
                    {(
                      isFull
                        ? ts`Join waitlist (#${Int.toString(waitlistCount + 1)})`
                        : isPaidEvent
                        ? {
                          let currencyStr =
                            event.currency
                            ->Option.map(PaymentIndicator.getCurrencySymbol)
                            ->Option.getOr("¥")
                          ts`Claim spot · ${event.price
                          ->Option.map(p => currencyStr ++ Int.toString(p))
                          ->Option.getOr("")}`
                        }
                        : ts`Claim spot`
                    )->React.string}
                  </button>
                </div>
              </>
            }}
          </div>
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
            onConfirmed={_ => performLeave()}
          />
        </>
      }
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
            Int.toString(confirmedCount) ++ (maxRsvps > 0 ? "/" ++ Int.toString(maxRsvps) : ""))
              ->React.string}
          </span>
        </div>
        <div className="flex items-center gap-2.5">
          <Router.Link
            to={"oauth-login?return=" ++ I18n.getLangPath(locale.lang) ++ "/events/" ++ event.id}
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
  }
}
