%%raw("import { t } from '@lingui/macro'")

module Fragment = %relay(`
  fragment PkEventRsvp_rsvp on Rsvp {
    id
    user {
      id
      picture
      lineUsername
      gender
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
    message
    paid
    payment {
      id
      ...PaymentIndicator_payment
    }
    ...RsvpOptions_rsvp
  }
`)

@react.component
let make = (
  ~rsvp,
  ~activitySlug: option<string>=?,
  ~maxRating: float,
  ~eventId: string,
  ~isAdmin: bool=false,
  ~chargesEnabled: bool=false,
  ~isHost: bool=false,
  ~waitlistPosition: option<int>=?,
  ~isPending: bool=false,
  ~isInvited: bool=false,
  // The viewer's conversation with this person about the event. On an
  // invited chip it adds a chat segment to the pill and a menu item.
  ~threadPath: option<string>=?,
  ~showRating: bool=true,
  ~connectionKey: string="RSVPSection_event_rsvps",
) => {
  let rsvp = Fragment.use(rsvp)
  let isWaitlisted = waitlistPosition->Option.isSome

  rsvp.user
  ->Option.map(user => {
    // The same rating the Round Robin tool would seed this player at:
    // pkuru, then a linked DUPR rating, then their own estimate.
    let combined = CombinedRating.resolve(
      ~pkuruMu=rsvp.rating->Option.flatMap(r => r.mu),
      ~pkuruSigma=?rsvp.rating->Option.flatMap(r => r.sigma),
      ~duprDoubles=user.dupr->Option.flatMap(d => d.doubles),
      ~duprReliability=?user.dupr->Option.flatMap(d => d.doublesReliability),
      ~duprReliable=user.dupr->Option.map(d => d.doublesReliable)->Option.getOr(false),
      ~selfMu=user.selfRating,
    )
    let mu = combined->Option.map(CombinedRating.mu)->Option.getOr(25.)
    let progress = Int.fromFloat(mu /. maxRating *. 100.)

    let skillStr =
      combined
      ->Option.map(r => CombinedRating.dupr(r)->Js.Float.toFixedWithPrecision(~digits=2))
      ->Option.getOr("—")

    // Payment indicator
    let paymentIndicator = switch rsvp.payment {
    | Some(payment) => <PaymentIndicator payment={payment.fragmentRefs} />
    | None =>
      rsvp.paid->Option.getOr(0) > 0
        ? <span
            title="Paid"
            className="text-[10px] font-semibold text-green-500 dark:text-green-400 leading-none">
            {"✓"->React.string}
          </span>
        : React.null
    }

    if isWaitlisted {
      let pos = waitlistPosition->Option.getOr(0)
      <RsvpOptions
        rsvp={rsvp.fragmentRefs}
        eventId
        eventActivitySlug={activitySlug->Option.getOr("badminton")}
        isAdmin
        chargesEnabled
        connectionKey
        triggerClassName="relative flex items-center gap-2 pl-0.5 pr-2 py-1 rounded-md cursor-pointer hover:bg-gray-50 dark:hover:bg-[#26272b] transition-all text-left w-full">
        <span
          className="font-mono text-[11px] text-gray-400 dark:text-gray-500 w-4 text-right flex-shrink-0">
          {Int.toString(pos)->React.string}
        </span>
        <AvatarWithProgress
          src={user.picture->Option.getOr("")}
          alt={user.lineUsername->Option.getOr("")}
          progress
          size=22
          strokeWidth=1.5
        />
        <span className="text-[11px] text-gray-700 dark:text-gray-400 leading-none flex-1">
          {user.lineUsername->Option.getOr("?")->React.string}
        </span>
        {switch user.gender {
        | Some(Male) =>
          <span className="text-[9px] font-bold leading-none text-blue-400">
            {"♂"->React.string}
          </span>
        | Some(Female) =>
          <span className="text-[9px] font-bold leading-none text-pink-400">
            {"♀"->React.string}
          </span>
        | _ => React.null
        }}
        {showRating
          ? <span className="font-mono text-[11px] text-gray-400 dark:text-gray-500 leading-none">
              {skillStr->React.string}
            </span>
          : React.null}
        {paymentIndicator}
      </RsvpOptions>
    } else {
      let chipContent =
        <>
          <AvatarWithProgress
            src={user.picture->Option.getOr("")}
            alt={user.lineUsername->Option.getOr("")}
            progress
            size=22
            strokeWidth=1.5
          />
          <span
            className={"text-[11px] leading-none " ++ (
              isInvited ? "text-violet-900 dark:text-violet-200" : "text-gray-900 dark:text-gray-100"
            )}>
            {user.lineUsername->Option.getOr("?")->React.string}
          </span>
          {isInvited
            ? <span
                className="font-mono text-[9px] leading-none text-violet-500 dark:text-violet-400">
                {(Lingui.UtilString.t`sent`)->React.string}
              </span>
            : React.null}
          {switch user.gender {
          | Some(Male) =>
            <span className="text-[9px] font-bold leading-none text-blue-400">
              {"♂"->React.string}
            </span>
          | Some(Female) =>
            <span className="text-[9px] font-bold leading-none text-pink-400">
              {"♀"->React.string}
            </span>
          | _ => React.null
          }}
          {showRating
            ? <span className="font-mono text-[11px] text-gray-400 dark:text-gray-500 leading-none">
                {skillStr->React.string}
              </span>
            : React.null}
          {paymentIndicator}
          {isHost
            ? <span className="text-[11px] font-mono text-gray-400 dark:text-gray-500 leading-none">
                {"★"->React.string}
              </span>
            : React.null}
        </>
      let name = user.lineUsername->Option.getOr("?")
      switch (isInvited, threadPath) {
      // A sent invite with a conversation: one pill, its name opening the
      // menu and a chat segment on its right edge opening the thread.
      | (true, Some(path)) =>
        <span
          className="relative inline-flex items-stretch rounded-full border border-violet-200 bg-violet-50 dark:border-violet-800/60 dark:bg-violet-950/20">
          <RsvpOptions
            rsvp={rsvp.fragmentRefs}
            eventId
            eventActivitySlug={activitySlug->Option.getOr("badminton")}
            isAdmin
            chargesEnabled
            connectionKey
            threadPath=path
            triggerClassName="relative inline-flex h-full items-center gap-1.5 rounded-l-full py-0.5 pl-0.5 pr-1.5 cursor-pointer transition-colors hover:bg-violet-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 dark:hover:bg-violet-900/30">
            {chipContent}
          </RsvpOptions>
          <LangProvider.Router.Link
            to=path
            className="inline-flex w-7 items-center justify-center rounded-r-full border-l border-violet-200 text-violet-500 transition-colors hover:bg-violet-100 hover:text-violet-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 dark:border-violet-800/60 dark:text-violet-400 dark:hover:bg-violet-900/30 dark:hover:text-violet-200">
            <Lucide.MessageCircle size=12 \"aria-hidden"="true" />
            <span className="sr-only">
              {(Lingui.UtilString.t`View message thread with ${name}`)->React.string}
            </span>
          </LangProvider.Router.Link>
        </span>
      | _ =>
        <RsvpOptions
          rsvp={rsvp.fragmentRefs}
          eventId
          eventActivitySlug={activitySlug->Option.getOr("badminton")}
          isAdmin
          chargesEnabled
          connectionKey
          ?threadPath
          triggerClassName={"relative inline-flex items-center gap-1.5 pl-0.5 pr-2 py-0.5 rounded-full cursor-pointer transition-colors " ++ if (
            isInvited
          ) {
            "border border-violet-200 dark:border-violet-800/60 bg-violet-50 dark:bg-violet-950/20 hover:bg-violet-100 dark:hover:bg-violet-900/30"
          } else if isPending {
            "border border-dashed border-gray-300 dark:border-[#3a3b40] opacity-50 hover:opacity-70 hover:bg-gray-50 dark:hover:bg-[#26272b]"
          } else {
            "border border-gray-200 dark:border-[#3a3b40] hover:bg-gray-50 dark:hover:bg-[#26272b]"
          }}>
          {chipContent}
        </RsvpOptions>
      }
    }
  })
  ->Option.getOr(React.null)
}
