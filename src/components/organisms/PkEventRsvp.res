module Fragment = %relay(`
  fragment PkEventRsvp_rsvp on Rsvp {
    user {
      id
      picture
      lineUsername
      gender
    }
    rating {
      ordinal
      mu
      sigma
    }
    message
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
  ~isHost: bool=false,
  ~waitlistPosition: option<int>=?,
  ~isPending: bool=false,
  ~connectionKey: string="RSVPSection_event_rsvps",
) => {
  let rsvp = Fragment.use(rsvp)
  let isWaitlisted = waitlistPosition->Option.isSome

  rsvp.user
  ->Option.map(user => {
    let mu = rsvp.rating->Option.flatMap(r => r.mu)->Option.getOr(25.)
    let progress = Int.fromFloat(mu /. maxRating *. 100.)

    let skillStr =
      rsvp.rating
      ->Option.flatMap(r => r.mu)
      ->Option.map(mu => Rating.guessDupr(mu)->Js.Float.toFixedWithPrecision(~digits=1))
      ->Option.getOr("—")

    if isWaitlisted {
      let pos = waitlistPosition->Option.getOr(0)
      <RsvpOptions
        rsvp={rsvp.fragmentRefs}
        eventId
        eventActivitySlug={activitySlug->Option.getOr("badminton")}
        isAdmin
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
        <span className="font-mono text-[11px] text-gray-400 dark:text-gray-500 leading-none">
          {skillStr->React.string}
        </span>
      </RsvpOptions>
    } else {
      <RsvpOptions
        rsvp={rsvp.fragmentRefs}
        eventId
        eventActivitySlug={activitySlug->Option.getOr("badminton")}
        isAdmin
        connectionKey
        triggerClassName={"relative inline-flex items-center gap-1.5 pl-0.5 pr-2 py-0.5 rounded-full cursor-pointer hover:bg-gray-50 dark:hover:bg-[#26272b] transition-colors " ++ (
          isPending
            ? "border border-dashed border-gray-300 dark:border-[#3a3b40] opacity-50 hover:opacity-70"
            : "border border-gray-200 dark:border-[#3a3b40]"
        )}>
        <AvatarWithProgress
          src={user.picture->Option.getOr("")}
          alt={user.lineUsername->Option.getOr("")}
          progress
          size=22
          strokeWidth=1.5
        />
        <span className="text-[11px] text-gray-900 dark:text-gray-100 leading-none">
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
        <span className="font-mono text-[11px] text-gray-400 dark:text-gray-500 leading-none">
          {skillStr->React.string}
        </span>
        {isHost
          ? <span className="text-[11px] font-mono text-gray-400 dark:text-gray-500 leading-none">
              {"★"->React.string}
            </span>
          : React.null}
      </RsvpOptions>
    }
  })
  ->Option.getOr(React.null)
}
