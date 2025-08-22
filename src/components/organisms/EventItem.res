%%raw("import { t, plural } from '@lingui/macro'")

module ItemFragment = %relay(`
  fragment EventItem_event on Event {
    __id
    id
    title
    activity { name }
    location { id name }
    club { name }
    maxRsvps
    rsvps(first: 100) @connection(key: "EventRsvps_event_rsvps")
    { edges { node { id user { id } listType } } }
    startDate
    endDate
    timezone
    shadow
    deleted
    tags
  }
`)

open Lingui.Util
module JoinEventMutation = %relay(`
  mutation EventItemJoinEventMutation($connections: [ID!]!, $id: ID!) {
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
module UserFragment = %relay(`
  fragment EventItem_user on User
  {
    id
    lineUsername
  }
`)
module LeaveEventMutation = %relay(`
  mutation EventItemLeaveEventMutation($connections: [ID!]!, $id: ID!) {
    leaveEvent(eventId: $id) {
      eventIds @deleteEdge(connections: $connections)
      errors { message }
    }
  }
`)
let td = Lingui.UtilString.dynamic
let ts = Lingui.UtilString.t

type viewerRsvpStatus = Confirmed | Waitlist | Pending
@react.component
let make = (~event, ~user, ~highlightedLocation: bool=false) => {
  let {
    __id,
    id,
    title,
    activity,
    location,
    club,
    startDate,
    rsvps,
    maxRsvps,
    endDate,
    timezone,
    shadow,
    deleted,
    tags,
  } = ItemFragment.use(event)
  let secret = shadow->Option.getOr(false)
  let isCompetitive = tags->Option.getOr([])->Array.includes("comp")
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

  /* Determine viewer RSVP status
     Some(Confirmed) if viewer in main list (listType 0/None) and index < maxRsvps
     Some(Pending) if viewer's listType not 0 (i.e. restricted/pending)
     Some(Waitlist) if viewer in main list but index >= maxRsvps
     None if viewer not in any RSVP edge */
  let viewerRsvpStatus: option<viewerRsvpStatus> = viewer->Option.flatMap(viewer => {
    let viewerId = viewer.id
    // Collect all edges
    let edges: array<option<EventItem_event_graphql.Types.fragment_rsvps_edges>> =
      rsvps
      ->Option.flatMap(r => r.edges)
      ->Option.getOr([])

    // Find the edge (any listType) for this viewer
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
              // Pending if listType not 0 (and not None)
              switch node.listType {
              | Some(lt) if lt != 0 => Some(Pending)
              | _ => {
                  // Build main list (only listType 0 / None)
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
                      ->Option.getOr(Confirmed), // no max => always confirmed
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
  let duration = duration->Option.map(duration => {
    let hours = Js.Math.floor_float(duration /. 60.)
    let minutes = mod(duration->Float.toInt, 60)
    if minutes == 0 {
      plural(
        hours->Float.toInt,
        {one: ts`${hours->Float.toString} hour`, other: ts`${hours->Float.toString} hours`},
      )
    } else {
      <>
        {plural(
          hours->Float.toInt,
          {one: ts`${hours->Float.toString} hour`, other: ts`${hours->Float.toString} hours`},
        )}
        {" "->React.string}
        {plural(
          minutes,
          {one: ts`${minutes->Int.toString} minute`, other: ts`${minutes->Int.toString} minutes`},
        )}
      </>
    }
  })
  let eventPath = "/events/" ++ id
  let navigate = LangProvider.Router.useNavigate()
  // SwipeAction handles open state internally; legacy showActions removed
  // Reuse join/leave mutations from EventRsvps component
  let (commitJoin, _joinInFlight) = JoinEventMutation.use()
  let (commitLeave, _leaveInFlight) = LeaveEventMutation.use()
  let onJoin = _ => {
    let eventPageConnectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      __id,
      "EventRsvps_event_rsvps",
      (),
    )
    // let eventListConnectionId = RescriptRelay.ConnectionHandler.getConnectionID(
    //   __id,
    //   "EventItem_event_rsvps",
    //   (),
    // )
    commitJoin(
      ~variables={
        id: __id->RescriptRelay.dataIdToString,
        connections: [eventPageConnectionId],
      },
    )->RescriptRelay.Disposable.ignore
    ()
  }
  let onLeave = _ => {
    let eventPageConnectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      __id,
      "EventRsvps_event_rsvps",
      (),
    )
    // let eventListConnectionId = RescriptRelay.ConnectionHandler.getConnectionID(
    //   __id,
    //   "EventItem_event_rsvps",
    //   (),
    // )
    commitLeave(
      ~variables={
        id: __id->RescriptRelay.dataIdToString,
        connections: [eventPageConnectionId],
      },
    )->RescriptRelay.Disposable.ignore
    ()
  }
  <SwipeAction
    className="cursor-pointer"
    onFullSwipeLeft={() => {
      switch viewerRsvpStatus {
      | Some(Confirmed)
      | Some(Waitlist)
      | Some(Pending) =>
        onLeave()
      | None => onJoin()
      }
    }}
    onTapped={() => navigate(eventPath, None)}
    rightActions={secret
      ? React.null
      : switch viewerRsvpStatus {
        | Some(Confirmed)
        | Some(Waitlist)
        | Some(Pending) =>
          <Button.Button
            color=#dark
            onClick={ev => {
              onLeave(ev)
            }}>
            {t`leave event`}
          </Button.Button>
        | None =>
          <Button.Button
            color=#red
            onClick={ev => {
              onJoin(ev)
            }}>
            {t`join event`}
          </Button.Button>
        }}
    partialThreshold=120
    fullThreshold=260
    hoverPartialSide="right">
    <div
      role="link"
      tabIndex=0
      onKeyDown={ev =>
        if ReactEvent.Keyboard.key(ev) == "Enter" {
          navigate(eventPath, None)
        }}>
      <Layout.Container
        className={Util.cx(["relative flex items-center space-x-4 py-4 select-none"])}>
        <div className="min-w-0 flex-auto">
          <div className="flex items-center gap-x-3">
            {isCompetitive
              ? <div className="flex-none text-yellow-500">
                  <Lucide.Trophy className="h-5 w-5" />
                </div>
              : <div
                  className={Util.cx([
                    "text-green-400 bg-green-400/10",
                    "flex-none rounded-full p-1",
                  ])}>
                  <div className="h-2 w-2 rounded-full bg-current" />
                </div>}
            <h2 className="min-w-0 text-sm font-semibold leading-6 text-black w-full">
              <div className="flex gap-x-2">
                <span
                  className={Util.cx(["truncate", deleted->Option.isSome ? "line-through" : ""])}>
                  {activity
                  ->Option.flatMap(a => a.name->Option.map(name => td(name)->React.string))
                  ->Option.getOr(React.null)}
                  {" / "->React.string}
                  {title->Option.getOr(ts`[missing title]`)->React.string}
                </span>
              </div>
            </h2>
          </div>
          <div className="mt-3 flex items-center gap-x-2.5 text-xs leading-5 text-gray-600">
            <p className="whitespace-nowrap">
              {startDate
              ->Option.map(startDate =>
                timezone
                ->Option.map(timezone =>
                  <ReactIntl.FormattedTime
                    value={startDate->Util.Datetime.toDate} timeZone={timezone}
                  />
                )
                ->Option.getOr(<ReactIntl.FormattedTime value={startDate->Util.Datetime.toDate} />)
              )
              ->Option.getOr(React.null)}
              {" -> "->React.string}
              {endDate
              ->Option.map(endDate =>
                timezone
                ->Option.map(timezone =>
                  <ReactIntl.FormattedTime
                    value={endDate->Util.Datetime.toDate} timeZone={timezone}
                  />
                )
                ->Option.getOr(<ReactIntl.FormattedTime value={endDate->Util.Datetime.toDate} />)
              )
              ->Option.getOr(React.null)}
              {duration
              ->Option.map(duration => <>
                {" ("->React.string}
                {duration}
                {") "->React.string}
              </>)
              ->Option.getOr(React.null)}
            </p>
          </div>
          <div className="mt-3 flex items-center gap-x-2.5 text-xs leading-5 text-gray-600">
            <span className="whitespace-nowrap">
              <p className={Util.cx(["truncate", highlightedLocation ? "font-bold" : ""])}>
                {secret
                  ? React.null
                  : location
                    ->Option.flatMap(l => l.name->Option.map(name => name->React.string))
                    ->Option.getOr(t`[location missing]`)}
              </p>
              {club
              ->Option.flatMap(c =>
                c.name->Option.map(name =>
                  <p className="text-xs text-gray-500 truncate"> {name->React.string} </p>
                )
              )
              ->Option.getOr(React.null)}
            </span>
          </div>
        </div>
        {switch viewerRsvpStatus {
        | Some(Confirmed) =>
          <div
            className={Util.cx([
              "text-green-600 bg-green-400/10 ring-green-400/30",
              "rounded-full flex-none py-1 px-2 text-xs font-medium ring-1 ring-inset",
            ])}>
            {t`joined`}
          </div>
        | Some(Waitlist) =>
          <div
            className={Util.cx([
              "text-yellow-600 bg-yellow-400/10 ring-yellow-400/30",
              "rounded-full flex-none py-1 px-2 text-xs font-medium ring-1 ring-inset",
            ])}>
            {t`waitlist`}
          </div>
        | Some(Pending) =>
          <div
            className={Util.cx([
              "text-yellow-600 bg-yellow-400/10 ring-yellow-400/30",
              "rounded-full flex-none py-1 px-2 text-xs font-medium ring-1 ring-inset",
            ])}>
            {t`pending`}
          </div>
        | None => React.null
        }}
        <div
          className={Util.cx([
            "text-indigo-400 bg-indigo-400/10 ring-indigo-400/30",
            "rounded-full flex-none py-1 px-2 text-xs font-medium ring-1 ring-inset",
          ])}>
          {switch shadow {
          | None
          | Some(false) =>
            maxRsvps
            ->Option.map(maxRsvps =>
              (playersCount->Int.toString ++ "/" ++ maxRsvps->Int.toString ++ " " ++ (ts`players`))
                ->React.string
            )
            ->Option.getOr(<>
              {(playersCount->Int.toString ++ " ")->React.string}
              {plural(playersCount, {one: "player", other: "players"})}
            </>)
          | _ => <HeroIcons.LockClosed className="-ml-0.5 h-3 w-3" />
          }}
        </div>
      </Layout.Container>
    </div>
  </SwipeAction>
}
