%%raw("import { t, plural } from '@lingui/macro'")

open Lingui.Util

module MediaQuery = {
  type t = {matches: bool}
  @val external matchMedia: string => t = "window.matchMedia"
}

module ItemFragment = %relay(`
  fragment PkEventRow_event on Event {
    __id
    id
    title
    location { id name }
    club { name }
    maxRsvps
    rsvps(first: 100) @connection(key: "PkEventRow_event_rsvps")
    { edges { node { id user { id } listType rating { mu } } } }
    startDate
    endDate
    timezone
    shadow
    listed
    deleted
    tags
  }
`)

module UserFragment = %relay(`
  fragment PkEventRow_user on User
  {
    id
    lineUsername
    email
  }
`)

module JoinEventMutation = %relay(`
  mutation PkEventRowJoinEventMutation($connections: [ID!]!, $id: ID!) {
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

module LeaveEventMutation = %relay(`
  mutation PkEventRowLeaveEventMutation($connections: [ID!]!, $id: ID!) {
    leaveEvent(eventId: $id) {
      eventIds @deleteEdge(connections: $connections)
      errors { message }
    }
  }
`)

module QueryFragment = %relay(`
  fragment PkEventRow_query on Query {
    ...ProfileModal_viewer
  }
`)

let ts = Lingui.UtilString.t

type viewerRsvpStatus = Confirmed | Waitlist | Pending

module ProgressBar = {
  @react.component
  let make = (~filled: int, ~total: option<int>, ~status: string, ~overflow: option<int>=?) => {
    switch total {
    | None =>
      <span className="font-mono text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap">
        {(Int.toString(filled) ++
        " " ++
        Lingui.UtilString.plural(filled, {one: ts`player`, other: ts`players`}))->React.string}
      </span>
    | Some(total) =>
      let pct = Js.Math.min_int(
        100,
        Js.Math.round(Float.fromInt(filled) /. Float.fromInt(total) *. 100.)->Float.toInt,
      )
      let colorClass = switch status {
      | "red" => "bg-[#ef4444]"
      | "orange" => "bg-[#ffb042]"
      | _ => "bg-[#4ade80]"
      }
      <div className="flex items-center gap-3 w-32">
        <div className="h-0.5 w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
          <div
            className={"h-full " ++ colorClass}
            style={ReactDOM.Style.make(~width=Int.toString(pct) ++ "%", ())}
          />
        </div>
        <span className="font-mono text-xs text-gray-500 dark:text-gray-400 whitespace-nowrap">
          {(Int.toString(filled) ++ "/" ++ Int.toString(total))->React.string}
        </span>
      </div>
    }
  }
}

module CapacityCount = {
  @react.component
  let make = (~filled: int, ~total: option<int>, ~status: string, ~overflow: option<int>=?) => {
    let textColor = switch status {
    | "red" => "text-red-500"
    | "orange" => "text-[#e09030]"
    | _ => "text-emerald-500 dark:text-emerald-400"
    }
    let label = switch total {
    | None =>
      Int.toString(filled) ++
      " " ++
      Lingui.UtilString.plural(filled, {one: ts`player`, other: ts`players`})
    | Some(total) => Int.toString(filled) ++ "/" ++ Int.toString(total)
    }
    <span className={"font-mono text-sm font-medium whitespace-nowrap " ++ textColor}>
      {label->React.string}
    </span>
  }
}

module StatusBadge = {
  @react.component
  let make = (~status: viewerRsvpStatus, ~position: option<int>=?) => {
    switch status {
    | Confirmed =>
      <div
        className="flex items-center gap-1 px-2 py-0.5 rounded border border-[#bdf25d] bg-[#bdf25d]/10 text-xs font-medium text-gray-900 dark:text-gray-100 whitespace-nowrap">
        <svg
          width="10"
          height="10"
          viewBox="0 0 14 14"
          fill="none"
          className="text-[#65a30d] dark:text-[#bdf25d]">
          <path
            d="M3 7.5L5.5 10L11 4"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
        <span> {(ts`Joined`)->React.string} </span>
      </div>
    | Waitlist =>
      <div
        className="flex items-center gap-1 px-2 py-0.5 rounded border border-[#ffb042] bg-[#ffb042]/10 text-xs font-medium text-gray-900 dark:text-[#ffb042] whitespace-nowrap">
        <svg width="10" height="10" viewBox="0 0 14 14" fill="none" className="text-[#ffb042]">
          <circle cx="7" cy="7" r="5" stroke="currentColor" strokeWidth="1.5" />
          <path
            d="M7 4.5V7.5L9 9"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
        <span> {(ts`Waitlisted`)->React.string} </span>
      </div>
    | Pending =>
      <div
        className="flex items-center gap-1 px-2 py-0.5 rounded border border-[#ffb042] bg-[#ffb042]/10 text-xs font-medium text-gray-900 dark:text-[#ffb042] whitespace-nowrap">
        {(ts`Pending`)->React.string}
      </div>
    }
  }
}

module DuprBadge = {
  @react.component
  let make = (~value: float, ~size: [#sm | #md]=#sm) => {
    let textClass = switch size {
    | #sm => "text-[11px]"
    | #md => "text-xs font-medium"
    }
    let iconSize = switch size {
    | #sm => 13
    | #md => 14
    }
    let valueStr = value->Js.Float.toFixedWithPrecision(~digits=1)
    if value >= 4.5 {
      <span
        className={"font-mono " ++
        textClass ++ " text-orange-500 dark:text-orange-400 whitespace-nowrap inline-flex items-center gap-0.5"}>
        <Lucide.ChevronsUp size=iconSize strokeWidth={2.5} />
        {valueStr->React.string}
      </span>
    } else if value >= 4.0 {
      <span
        className={"font-mono " ++
        textClass ++ " text-amber-500 dark:text-amber-400 whitespace-nowrap inline-flex items-center gap-0.5"}>
        <Lucide.ChevronUp size=iconSize strokeWidth={2.5} />
        {valueStr->React.string}
      </span>
    } else {
      <span
        className={"font-mono " ++
        textClass ++ " text-gray-400 dark:text-gray-500 whitespace-nowrap"}>
        {valueStr->React.string}
      </span>
    }
  }
}

@react.component
let make = (
  ~event,
  ~user,
  ~isLastInGroup: bool=false,
  ~onEventClick: option<string => unit>=?,
  ~onHoverLocation: option<option<string> => unit>=?,
  ~dimmed: bool=false,
  ~waitlistCount: int=0,
  ~query: RescriptRelay.fragmentRefs<[> #PkEventRow_query]>,
) => {
  let queryData = QueryFragment.use(query)
  let {
    __id,
    id,
    title,
    location,
    club,
    startDate,
    rsvps,
    maxRsvps,
    endDate,
    timezone,
    shadow,
    listed,
    deleted,
    tags,
  } = ItemFragment.use(event)

  let secret = shadow->Option.getOr(false)
  let isUnlisted = switch listed {
  | Some(false) => true
  | _ => false
  }

  let playersCount =
    rsvps
    ->Option.flatMap(rsvps =>
      rsvps.edges->Option.map(edges =>
        edges
        ->Array.filter(
          edge => {
            edge
            ->Option.flatMap(
              edge =>
                edge.node->Option.map(node => node.listType == Some(0) || node.listType == None),
            )
            ->Option.getOr(true)
          },
        )
        ->Array.length
      )
    )
    ->Option.getOr(0)

  let viewer = user->Option.map(user => UserFragment.use(user))

  let viewerRsvpStatus: option<viewerRsvpStatus> = viewer->Option.flatMap(viewer => {
    let viewerId = viewer.id
    let edges =
      rsvps
      ->Option.flatMap(r => r.edges)
      ->Option.getOr([])

    let viewerEdge = edges->Array.find(edge =>
      edge
      ->Option.flatMap(
        e => e.node->Option.flatMap(node => node.user->Option.map(u => u.id == viewerId)),
      )
      ->Option.getOr(false)
    )

    viewerEdge->Option.flatMap(edge =>
      edge->Option.flatMap(
        e =>
          e.node->Option.flatMap(
            node => {
              switch node.listType {
              | Some(lt) if lt != 0 => Some(Pending)
              | _ => {
                  let mainList = edges->Belt.Array.keepMap(
                    edge =>
                      edge->Option.flatMap(
                        e =>
                          e.node->Option.flatMap(
                            node =>
                              switch node.listType {
                              | Some(0) | None => Some(node)
                              | _ => None
                              },
                          ),
                      ),
                  )
                  let viewerIndexOpt =
                    mainList->Array.findIndexOpt(
                      n => n.user->Option.map(u => u.id == viewerId)->Option.getOr(false),
                    )
                  viewerIndexOpt->Option.map(
                    idx =>
                      maxRsvps
                      ->Option.map(max => idx < max ? Confirmed : Waitlist)
                      ->Option.getOr(Confirmed),
                  )
                }
              }
            },
          ),
      )
    )
  })

  let duration = startDate->Option.flatMap(startDate =>
    endDate->Option.map(endDate =>
      endDate
      ->Util.Datetime.toDate
      ->DateFns.differenceInMinutes(startDate->Util.Datetime.toDate)
    )
  )

  let durationStr = duration->Option.map(duration => {
    let hours = Js.Math.floor_float(duration /. 60.)
    let minutes = mod(duration->Float.toInt, 60)
    if hours > 0. && minutes > 0 {
      Float.toString(hours) ++ "h " ++ Int.toString(minutes) ++ "m"
    } else if hours > 0. {
      Float.toString(hours) ++ "h"
    } else {
      Int.toString(minutes) ++ "m"
    }
  })

  let navigate = LangProvider.Router.useNavigate()
  let locale = React.useContext(LangProvider.LocaleContext.context)
  let (hovered, setHovered) = React.useState(() => false)
  let (isTouchDevice, setIsTouchDevice) = React.useState(() => false)
  React.useEffect(() => {
    setIsTouchDevice(_ => MediaQuery.matchMedia("(pointer: coarse)").matches)
    None
  }, [])
  let eventPath = "/events/" ++ id
  let loginHref = "/oauth-login?return=" ++ I18n.getLangPath(locale.lang) ++ eventPath

  let (commitJoin, _) = JoinEventMutation.use()
  let (commitLeave, _) = LeaveEventMutation.use()
  let (showLeaveConfirm, setShowLeaveConfirm) = React.useState(() => false)
  let (isProfileModalOpen, setIsProfileModalOpen) = React.useState(() => false)
  let (pendingJoinAction, setPendingJoinAction) = React.useState((): option<unit => unit> => None)

  let getConnectionId = () =>
    RescriptRelay.ConnectionHandler.getConnectionID(__id, "PkEventRow_event_rsvps", ())

  let proceed = () => {
    commitJoin(
      ~variables={
        id: __id->RescriptRelay.dataIdToString,
        connections: [getConnectionId()],
      },
    )->RescriptRelay.Disposable.ignore
  }

  let onJoin = _ => proceed()

  let onLeave = _ => {
    commitLeave(
      ~variables={
        id: __id->RescriptRelay.dataIdToString,
        connections: [getConnectionId()],
      },
    )->RescriptRelay.Disposable.ignore
  }

  let hasCompleteProfile = () =>
    switch viewer {
    | Some(v) =>
      switch (v.lineUsername, v.email) {
      | (Some(u), Some(e)) => u != "" && e != ""
      | _ => false
      }
    | None => false
    }

  let doJoinWithProfileCheck = () => {
    if hasCompleteProfile() {
      proceed()
    } else {
      setPendingJoinAction(_ => Some(proceed))
      setIsProfileModalOpen(_ => true)
    }
  }

  let confirmedRsvpNodes =
    rsvps
    ->Option.flatMap(r => r.edges)
    ->Option.getOr([])
    ->Array.filterMap(e => e)
    ->Array.filterMap(e => e.node)
    ->Array.filter(n => n.listType == None || n.listType == Some(0))

  let avgDupr: option<float> = {
    let mus =
      confirmedRsvpNodes
      ->Array.map(n => n.rating->Option.flatMap(r => r.mu)->Option.getOr(25.0))
      ->Array.toSorted((a, b) => b -. a)
      ->Array.slice(~start=0, ~end=6)
    if mus->Array.length == 0 {
      None
    } else {
      let avg = mus->Array.reduce(0., (a, b) => a +. b) /. Float.fromInt(mus->Array.length)
      Some(avg->Rating.guessDupr)
    }
  }

  let isFull = maxRsvps->Option.map(max => playersCount >= max)->Option.getOr(false)
  let isAlmostFull =
    maxRsvps->Option.map(max => max - playersCount <= 2 && !isFull)->Option.getOr(false)
  let isCanceled = deleted->Option.isSome

  let status = if isFull {
    "red"
  } else if isAlmostFull {
    "orange"
  } else {
    "green"
  }

  let _overflow = if isFull {
    let over = playersCount - maxRsvps->Option.getOr(playersCount)
    if over > 0 {
      Some(over)
    } else {
      None
    }
  } else {
    None
  }

  let handleActionClick = _ => {
    switch viewerRsvpStatus {
    | Some(Confirmed) | Some(Waitlist) | Some(Pending) =>
      if waitlistCount > 0 {
        setShowLeaveConfirm(_ => true)
      } else {
        onLeave()
      }
    | None =>
      switch viewer {
      | None => navigate(loginHref, None)
      | Some(_) => doJoinWithProfileCheck()
      }
    }
  }

  let isInEvent = switch viewerRsvpStatus {
  | Some(Confirmed) | Some(Waitlist) | Some(Pending) => true
  | None => false
  }

  let actionBg = if isInEvent {
    "bg-[#e8907e]"
  } else if isFull {
    "bg-gray-200 dark:bg-[#3a3b40]"
  } else {
    "bg-[#bdf25d]"
  }

  let actionTextColor = if isInEvent {
    "text-white"
  } else if isFull {
    "text-gray-600 dark:text-gray-300"
  } else {
    "text-black"
  }

  let actionLabel = if isInEvent {
    ts`Leave`
  } else if isFull {
    ts`Waitlist`
  } else {
    ts`Join`
  }

  let actionButton = isCanceled
    ? React.null
    : <button
        onClick=handleActionClick
        className={"flex items-center gap-1.5 font-semibold text-sm px-4 py-2 h-full " ++
        actionTextColor ++
        " " ++
        actionBg}>
        {actionLabel->React.string}
      </button>

  <div
    className={Util.cx([
      isLastInGroup
        ? "relative overflow-hidden"
        : "relative overflow-hidden border-b border-gray-100 dark:border-[#2a2b30]",
      dimmed ? "opacity-30" : "",
      isCanceled ? "opacity-60" : "",
    ])}
    onMouseEnter={_ => {
      if !isTouchDevice {
        setHovered(_ => true)
        onHoverLocation->Option.forEach(cb => cb(location->Option.map(l => l.id)))
      }
    }}
    onMouseLeave={_ => {
      if !isTouchDevice {
        setHovered(_ => false)
        onHoverLocation->Option.forEach(cb => cb(None))
      }
    }}>
    <SwipeAction
      rightActions={isTouchDevice ? actionButton : React.null}
      disableDrag={!isTouchDevice}
      onFullSwipeLeft={isTouchDevice
        ? () => {
            switch viewerRsvpStatus {
            | Some(Confirmed) | Some(Waitlist) | Some(Pending) =>
              if waitlistCount > 0 {
                setShowLeaveConfirm(_ => true)
              } else {
                onLeave()
              }
            | None =>
              switch viewer {
              | None => navigate(loginHref, None)
              | Some(_) => doJoinWithProfileCheck()
              }
            }
          }
        : () => ()}
      onTapped={() =>
        switch onEventClick {
        | Some(cb) => cb(id)
        | None => navigate(eventPath, None)
        }}
      className="bg-white dark:bg-[#222326]">
      <div className="px-4 md:px-6 py-3 flex items-start gap-3 md:gap-6 cursor-pointer">
        <div className="w-12 md:w-16 flex-shrink-0 flex flex-col items-start pt-0.5">
          <span className="font-mono font-bold text-base dark:text-gray-100">
            {startDate
            ->Option.map(startDate =>
              timezone
              ->Option.map(tz =>
                <ReactIntl.FormattedTime value={startDate->Util.Datetime.toDate} timeZone={tz} />
              )
              ->Option.getOr(<ReactIntl.FormattedTime value={startDate->Util.Datetime.toDate} />)
            )
            ->Option.getOr(React.null)}
          </span>
          <span className="font-mono text-[10px] text-gray-400 mt-1">
            {durationStr->Option.getOr("")->React.string}
          </span>
        </div>
        <div className="flex-1 min-w-0">
          <h4
            className={"font-medium truncate " ++ (
              isCanceled
                ? "line-through text-gray-400 dark:text-gray-500"
                : "text-gray-900 dark:text-gray-100"
            )}>
            {title->Option.getOr(ts`[missing title]`)->React.string}
          </h4>
          <div
            className="flex items-center flex-wrap gap-x-1.5 gap-y-1 text-xs text-gray-600 dark:text-gray-400 mt-1">
            {club
            ->Option.flatMap(c => c.name)
            ->Option.map(name => <>
              <span className="font-medium text-gray-800 dark:text-gray-300">
                {name->React.string}
              </span>
              <span> {"·"->React.string} </span>
            </>)
            ->Option.getOr(React.null)}
            {secret
              ? React.null
              : <span className="truncate">
                  {location
                  ->Option.flatMap(l => l.name->Option.map(name => name->React.string))
                  ->Option.getOr(React.null)}
                </span>}
          </div>
          {
            let tagsArr = tags->Option.getOr([])
            let hasComp = tagsArr->Array.some(t => t->String.toLowerCase == "comp")
            let otherTags = tagsArr->Array.filter(t => t->String.toLowerCase != "comp")
            <ResponsiveTooltip.Provider>
              <div className="flex flex-wrap gap-1.5 mt-0.5">
                {isUnlisted ? <EventTag tag="unlisted" responsive=true /> : React.null}
                {hasComp ? <EventTag tag="comp" responsive=true /> : React.null}
                {otherTags
                ->Array.mapWithIndex((tag, i) =>
                  <EventTag key={Int.toString(i)} tag responsive=true />
                )
                ->React.array}
              </div>
            </ResponsiveTooltip.Provider>
          }
        </div>
        <div className="w-20 md:w-44 flex-shrink-0 flex flex-col items-end gap-1.5 pt-1">
          {isCanceled
            ? <span
                className="text-xs font-medium px-2 py-0.5 rounded bg-red-100 dark:bg-red-900/20 text-red-500 dark:text-red-400">
                {(ts`Canceled`)->React.string}
              </span>
            : <>
                {viewerRsvpStatus
                ->Option.map(s =>
                  <div className="hidden md:block">
                    <StatusBadge status=s />
                  </div>
                )
                ->Option.getOr(React.null)}
                <div className="md:hidden flex flex-col items-end gap-1">
                  {viewerRsvpStatus
                  ->Option.map(s => {
                    let isJoined = s == Confirmed
                    let dotBg = isJoined
                      ? "bg-[#bdf25d]/20 border border-[#bdf25d]"
                      : "bg-[#ffb042]/20 border border-[#ffb042]"
                    <div
                      className={"w-5 h-5 rounded-full flex items-center justify-center " ++ dotBg}>
                      {isJoined
                        ? <svg width="10" height="10" viewBox="0 0 14 14" fill="none">
                            <path
                              d="M3 7.5L5.5 10L11 4"
                              stroke="#65a30d"
                              strokeWidth="2"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                          </svg>
                        : <svg width="10" height="10" viewBox="0 0 14 14" fill="none">
                            <circle cx="7" cy="7" r="5" stroke="#ffb042" strokeWidth="1.5" />
                            <path
                              d="M7 4.5V7.5L9 9"
                              stroke="#ffb042"
                              strokeWidth="1.5"
                              strokeLinecap="round"
                              strokeLinejoin="round"
                            />
                          </svg>}
                    </div>
                  })
                  ->Option.getOr(React.null)}
                  <CapacityCount filled=playersCount total=maxRsvps status />
                  {avgDupr
                  ->Option.map(v => <DuprBadge value=v size=#sm />)
                  ->Option.getOr(React.null)}
                </div>
                <div className="hidden md:flex items-center gap-3">
                  {avgDupr
                  ->Option.map(v => <DuprBadge value=v size=#md />)
                  ->Option.getOr(React.null)}
                  <ProgressBar filled=playersCount total=maxRsvps status />
                </div>
              </>}
        </div>
      </div>
    </SwipeAction>
    {isCanceled || isTouchDevice
      ? React.null
      : <FramerMotion.Div
          className={"absolute right-0 top-0 bottom-0 w-[120px] flex items-center justify-center z-20 " ++
          actionBg}
          initial={x: 120.}
          animate={{FramerMotion.x: hovered ? 0. : 120.}}
          transition={{type_: "spring", stiffness: 900, damping: 35, mass: 0.4}}>
          <button
            onClick={e => {
              ReactEvent.Mouse.stopPropagation(e)
              handleActionClick(e)
              setHovered(_ => false)
            }}
            className={"flex items-center gap-1.5 font-semibold text-sm " ++ actionTextColor}>
            {actionLabel->React.string}
            <Lucide.ChevronLeft size=16 />
          </button>
        </FramerMotion.Div>}
    <ConfirmDialog
      title={t`Leave event`}
      description={t`There are players on the waitlist. If you leave, your spot will be given to the next person. Are you sure?`}
      setIsOpen={setShowLeaveConfirm}
      isOpen={showLeaveConfirm}
      onConfirmed={_ => onLeave()}
    />
    <ProfileModal
      isOpen=isProfileModalOpen
      onClose={() => {
        setIsProfileModalOpen(_ => false)
        setPendingJoinAction(_ => None)
      }}
      onProfileComplete={() => {
        pendingJoinAction->Option.forEach(action => action())
        setPendingJoinAction(_ => None)
      }}
      query=queryData.fragmentRefs
    />
  </div>
}
