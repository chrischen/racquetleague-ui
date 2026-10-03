%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// Merged "Invites" strip for the event participants list: invites the host has
// already sent (RSVPs with listType 2 — the server's Invited) alongside
// potential invitees — players
// whose declared availability covers the event's full window. Inline chip
// invites and the Tinder-style swipe deck commit through the same
// duplicate-safe handler, and sent invites land in the shared
// PkRSVPSection_event_rsvps connection so they survive leaving and reopening
// the event.

module InviteMutation = %relay(`
  mutation EventInvitesMutation($connections: [ID!]!, $eventId: ID!, $userId: ID!, $message: String!) {
    inviteToEvent(eventId: $eventId, userId: $userId, message: $message) {
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
      errors {
        message
      }
    }
  }
`)

// clubId is passed through when the event belongs to a club so candidates are
// scoped to people the host can actually invite; null lets the server search
// the activity at large. eventId lets the swipe deck ask for each candidate's
// rating *for this event* — the server picks the pkuru namespace from the
// event's tags — so the deck shows the number the player would be seeded on.
module CandidatesQuery = %relay(`
  query EventInvitesCandidatesQuery($localDate: String!, $activityId: ID!, $clubId: ID, $eventId: ID!) {
    availabilityUsersForDay(
      localDate: $localDate
      scope: { activityId: $activityId, clubId: $clubId }
    ) {
      id
      localDate
      user {
        id
        lineUsername
        picture
        ...PlayerInviteSwipeDeck_user @arguments(eventId: $eventId)
      }
      intervals {
        startHour
        endHour
      }
    }
  }
`)

// Organizer-only, and already filtered server-side of anyone holding an RSVP,
// the viewer, club bans, out-of-range ratings, clashing events and players
// sitting on three unanswered invites. Returned best-first, so the order is
// taken as given rather than re-sorted here.
module RecommendationsQuery = %relay(`
  query EventInvitesRecommendationsQuery($eventId: ID!, $first: Int) {
    inviteRecommendations(eventId: $eventId, first: $first) {
      recommendations {
        availability
        fit
        strong
        rating {
          dupr
          established
        }
        user {
          id
          lineUsername
          picture
          ...PlayerInviteSwipeDeck_user @arguments(eventId: $eventId)
        }
      }
    }
  }
`)

type candidate = {
  id: string,
  name: string,
  picture: option<string>,
  user: RescriptRelay.fragmentRefs<[#PlayerInviteSwipeDeck_user]>,
  // Set only for server-ranked recommendations. Availability-sourced
  // candidates are, by construction, available for the whole event.
  recommended: bool,
  availability: PlayerInviteSwipeDeck.inviteAvailability,
  // The rating the player would be seeded at, on the DUPR scale.
  dupr: option<float>,
  // Below the server's confidence bar for its source: show it as an estimate.
  duprProvisional: bool,
}

// Data-only child: the lazy availability query has to live in a component that
// mounts conditionally (viewer can invite, event has a resolvable window), so
// it loads under Suspense and lifts the filtered candidates to the parent.
module CandidatesLoader = {
  @react.component
  let make = (
    ~localDate: string,
    ~activityId: string,
    ~clubId: option<string>,
    ~eventId: string,
    ~evStart: float,
    ~evEnd: float,
    ~onLoaded: array<candidate> => unit,
  ) => {
    let data = CandidatesQuery.use(
      ~variables={localDate, activityId, ?clubId, eventId},
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    )
    React.useEffect1(() => {
      let candidates =
        data.availabilityUsersForDay
        ->Array.filter(day =>
          day.intervals->Array.some(iv =>
            Float.fromInt(iv.startHour) <= evStart && Float.fromInt(iv.endHour) >= evEnd
          )
        )
        ->Array.filterMap(day =>
          day.user->Option.map(u => {
            id: u.id,
            name: u.lineUsername->Option.getOr("?"),
            picture: u.picture,
            user: u.fragmentRefs,
            recommended: false,
            availability: PlayerInviteSwipeDeck.AvailabilityCovers,
            dupr: None,
            duprProvisional: false,
          })
        )
      onLoaded(candidates)
      None
    }, [data])
    React.null
  }
}

// The people the viewer has a private conversation with about this event:
// the invitees they sent a note to, and anyone who wrote to them about it.
// An invited chip links into that conversation only when one exists (a chat
// segment and a menu item, see PkEventRsvp), so a host who didn't send a
// given invite isn't sent to an empty thread.
module ThreadsLoader = {
  module Query = %relay(`
    query EventInvitesThreadsQuery {
      viewer {
        directMessages {
          edges {
            node {
              id
              topic
              payload
              createdAt
            }
          }
        }
      }
    }
  `)

  @react.component
  let make = (~eventId: string, ~onLoaded: Belt.Set.String.t => unit) => {
    // Refresh on each visit: the conversations change outside this page.
    let data = Query.use(~variables=(), ~fetchPolicy=RescriptRelay.StoreAndNetwork)
    React.useEffect1(() => {
      data.viewer
      ->Option.flatMap(v => v.directMessages)
      ->Option.flatMap(c => c.edges)
      ->Option.getOr([])
      ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
      ->Array.filterMap(n =>
        DirectMessage.decode(~id=n.id, ~topic=n.topic, ~payload=n.payload, ~createdAt=n.createdAt)
      )
      ->Array.filter(m => m.eventId == Some(eventId))
      ->Array.map(m => fst(DirectMessage.counterpart(m)))
      ->Belt.Set.String.fromArray
      ->onLoaded
      None
    }, [data])
    React.null
  }
}

// Same shape from the ranked source. Kept in its own component (and its own
// Suspense boundary) so a slow ranking pass doesn't hold up the availability
// candidates, or vice versa.
module RecommendationsLoader = {
  @react.component
  let make = (~eventId: string, ~first: int, ~onLoaded: array<candidate> => unit) => {
    let data = RecommendationsQuery.use(
      ~variables={eventId, first},
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    )
    React.useEffect1(() => {
      let recommended =
        data.inviteRecommendations.recommendations
        ->Option.getOr([])
        ->Array.map((r): candidate => {
          id: r.user.id,
          name: r.user.lineUsername->Option.getOr("?"),
          picture: r.user.picture,
          user: r.user.fragmentRefs,
          recommended: true,
          availability: switch r.availability {
          | Available => PlayerInviteSwipeDeck.AvailabilityCovers
          | Unavailable => PlayerInviteSwipeDeck.AvailabilityConflicts
          | _ => PlayerInviteSwipeDeck.AvailabilityUnknown
          },
          dupr: Some(r.rating.dupr),
          duprProvisional: !r.rating.established,
        })
      onLoaded(recommended)
      None
    }, [data])
    React.null
  }
}

@react.component
let make = (
  ~eventId: string,
  ~canInvite: bool,
  ~activityId: option<string>,
  ~activitySlug: option<string>,
  ~clubId: option<string>,
  ~eventTitle: string,
  ~venueName: string,
  ~startDate: option<Util.Datetime.t>,
  ~endDate: option<Util.Datetime.t>,
  ~timezone: string,
  ~participantUserIds: array<string>,
  ~invitedCount: int,
  // The sent invites as chips, given who the viewer has a conversation with
  // about this event (PkEventRsvp's threadPath links a chip to it).
  ~invitedChips: Belt.Set.String.t => React.element,
) => {
  let ts = Lingui.UtilString.t
  let intl = ReactIntl.useIntl()
  let nav = LangProvider.Router.useNavigate()
  let (commitInvite, _inviteInFlight) = InviteMutation.use()

  let (candidates, setCandidates) = React.useState(() => [])
  let (recommendations, setRecommendations) = React.useState(() => [])
  // Users invited from this session, inline or via the deck. Guards double
  // sends until the appended edge lands in the connection (at which point
  // participantUserIds takes over).
  let (sentIds, setSentIds) = React.useState(() => Belt.Set.String.empty)
  // People with a conversation with the viewer about this event. An invite
  // sent from this page counts at once (its note is that conversation),
  // before the next load would show it.
  let (loadedThreadIds, setLoadedThreadIds) = React.useState(() => Belt.Set.String.empty)
  let threadUserIds = Belt.Set.String.union(loadedThreadIds, sentIds)
  // The note sent with the latest invite. The next invite may not reuse it, so
  // each person gets a note written for them (InviteNote). Page state only:
  // it is a nudge, not something the server checks.
  let (lastMessage, setLastMessage) = React.useState((): option<string> => None)
  let (activeMenuId, setActiveMenuId) = React.useState(() => None)
  // The chip the organizer is writing a note for: (userId, displayName).
  let (composeFor, setComposeFor) = React.useState(() => None)
  let (swipeOpen, setSwipeOpen) = React.useState(() => false)
  let (mounted, setMounted) = React.useState(() => false)
  React.useEffect0(() => {
    setMounted(_ => true)
    None
  })

  // The event's window projected into its own timezone: the availability
  // calendar is keyed by venue-local date and hour, so candidates are matched
  // against local hours, not viewer-local ones. Overnight events only require
  // availability up to midnight of the start day.
  let window = switch (startDate, endDate) {
  | (Some(s), Some(e)) => {
      let startD = s->Util.Datetime.toDate
      let endD = e->Util.Datetime.toDate
      let evStart = TimeWindow.hourInTimeZone(startD, timezone)
      let evEndRaw = TimeWindow.hourInTimeZone(endD, timezone)
      let evEnd = evEndRaw <= evStart ? 24. : evEndRaw
      let opts = ReactIntl.dateTimeFormatOptions(
        ~year=#numeric,
        ~month=#"2-digit",
        ~day=#"2-digit",
        ~timeZone=timezone,
        (),
      )
      let parts = intl->ReactIntl.Intl.formatDateWithOptionsToParts(startD, opts)
      let getVal = t =>
        parts
        ->Array.find(p => p.ReactIntl.type_ === t)
        ->Option.map(p => p.ReactIntl.value)
        ->Option.getOr("0")
      let localDate = getVal("year") ++ "-" ++ getVal("month") ++ "-" ++ getVal("day")
      let fmtTime = d =>
        intl->ReactIntl.Intl.formatTimeWithOptions(
          d,
          ReactIntl.dateTimeFormatOptions(~timeZone=timezone, ()),
        )
      Some((localDate, evStart, evEnd, fmtTime(startD) ++ "–" ++ fmtTime(endD)))
    }
  | _ => None
  }

  // Ranked recommendations lead (the server returns them best-first), then any
  // available player it didn't already surface. The server excludes anyone
  // holding an RSVP, but its result is cached, so invites sent this session
  // still have to be filtered out here.
  let visibleCandidates = {
    let seen = Belt.MutableSet.String.make()
    Belt.Array.concat(recommendations, candidates)->Array.filter(c =>
      if (
        participantUserIds->Array.includes(c.id) ||
        sentIds->Belt.Set.String.has(c.id) ||
        seen->Belt.MutableSet.String.has(c.id)
      ) {
        false
      } else {
        seen->Belt.MutableSet.String.add(c.id)
        true
      }
    )
  }

  // Every invite carries the organizer's note: the server rejects a blank one.
  // It reaches the invitee as a private message they can reply to, and the
  // invite email quotes it.
  let handleInvite = (userId: string, message: string) => {
    let alreadyInvited =
      participantUserIds->Array.includes(userId) || sentIds->Belt.Set.String.has(userId)
    let note = message->String.trim
    if !alreadyInvited && note != "" {
      setSentIds(s => s->Belt.Set.String.add(userId))
      // The next composer refuses this note; a failed send gives it back.
      let previous = lastMessage
      setLastMessage(_ => Some(note))
      let restoreLastMessage = () =>
        setLastMessage(current => current == Some(note) ? previous : current)
      let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
        eventId->RescriptRelay.makeDataId,
        "PkRSVPSection_event_rsvps",
        None,
      )
      commitInvite(
        ~variables={connections: [connectionId], eventId, userId, message: note},
        ~onCompleted=(response, _) =>
          switch response.inviteToEvent.errors {
          | Some(errors) if errors->Array.length > 0 =>
            setSentIds(s => s->Belt.Set.String.remove(userId))
            restoreLastMessage()
          | _ => ()
          },
        ~onError=_ => {
          setSentIds(s => s->Belt.Set.String.remove(userId))
          restoreLastMessage()
        },
      )->RescriptRelay.Disposable.ignore
    }
  }

  let inviteableCount = visibleCandidates->Array.length
  let totalCount = invitedCount + inviteableCount

  <>
    {canInvite && mounted
      ? switch (window, activityId) {
        | (Some((localDate, evStart, evEnd, _)), Some(activityId)) =>
          <React.Suspense fallback=React.null>
            <CandidatesLoader
              localDate
              activityId
              clubId
              eventId
              evStart
              evEnd
              onLoaded={c => setCandidates(_ => c)}
            />
          </React.Suspense>
        | _ => React.null
        }
      : React.null}
    {mounted && invitedCount > 0
      ? <React.Suspense fallback=React.null>
          <ThreadsLoader eventId onLoaded={ids => setLoadedThreadIds(_ => ids)} />
        </React.Suspense>
      : React.null}
    {canInvite && mounted
      ? <React.Suspense fallback=React.null>
          <RecommendationsLoader
            eventId first=12 onLoaded={r => setRecommendations(_ => r)}
          />
        </React.Suspense>
      : React.null}
    {totalCount == 0
      ? React.null
      : <section className="mt-2.5" ariaLabelledby="invites-heading">
          <div className="relative flex items-center gap-2 mb-2">
            <div className="h-px flex-1 bg-violet-200 dark:bg-violet-800/50" />
            <span
              id="invites-heading"
              className="font-mono text-[11px] tracking-wider text-violet-600 dark:text-violet-400 uppercase inline-flex items-center gap-1">
              <Lucide.Mail size=10 \"aria-hidden"="true" />
              {(ts`Invites · ${Int.toString(totalCount)}`)->React.string}
            </span>
            <div className="h-px flex-1 bg-violet-200 dark:bg-violet-800/50" />
            {inviteableCount > 0
              ? <button
                  type_="button"
                  onClick={_ => setSwipeOpen(_ => true)}
                  className="absolute right-0 top-1/2 inline-flex -translate-y-1/2 items-center gap-1 rounded-md bg-violet-600 px-2 py-1 text-[9px] font-semibold text-white transition-colors hover:bg-violet-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 focus-visible:ring-offset-2 dark:bg-violet-500 dark:hover:bg-violet-400 dark:hover:text-violet-950"
                  ariaLabel={ts`Review ${Int.toString(
                      inviteableCount,
                    )} potential players with swipe cards`}>
                  <Lucide.Layers size=10 strokeWidth=2.5 \"aria-hidden"="true" />
                  {(ts`Swipe invites`)->React.string}
                </button>
              : React.null}
          </div>
          <ul
            className="flex flex-wrap gap-1.5 list-none p-0 m-0"
            ariaLabel={ts`Invited and potential players`}>
            {invitedChips(threadUserIds)}
            {visibleCandidates
            ->Array.map(c => {
              let menuOpen = activeMenuId == Some(c.id)
              <li
                key=c.id
                className="relative"
                onKeyDown={e => ReactEvent.Keyboard.key(e) == "Escape"
                  ? setActiveMenuId(_ => None)
                  : ()}>
                <button
                  type_="button"
                  onClick={_ => setActiveMenuId(cur => cur == Some(c.id) ? None : Some(c.id))}
                  className="relative inline-flex items-center gap-1.5 rounded-full border border-violet-200 dark:border-violet-800/60 bg-violet-50 dark:bg-violet-950/20 py-0.5 pl-0.5 pr-2 opacity-50 transition-[opacity,background-color] hover:bg-violet-100 dark:hover:bg-violet-900/30 hover:opacity-100 focus:outline-none focus-visible:opacity-100 focus-visible:ring-2 focus-visible:ring-violet-500 focus-visible:ring-offset-2"
                  ariaHaspopup=#menu
                  ariaExpanded=menuOpen
                  ariaLabel={ts`Open invite actions for ${c.name}`}>
                  <AvatarWithProgress
                    src={c.picture->Option.getOr("")} alt=c.name progress=0 size=22 strokeWidth=1.5
                  />
                  {c.recommended
                    ? <Lucide.Sparkles
                        size=10
                        className="text-violet-500 dark:text-violet-400 flex-shrink-0"
                        \"aria-hidden"="true"
                      />
                    : React.null}
                  <span className="text-[11px] leading-none text-violet-900 dark:text-violet-200">
                    {c.name->React.string}
                  </span>
                  {switch c.dupr {
                  | Some(dupr) =>
                    <span
                      className="font-mono text-[9px] leading-none text-violet-500 dark:text-violet-400">
                      {((c.duprProvisional ? "~" : "") ++
                      dupr->Js.Float.toFixedWithPrecision(~digits=2))->React.string}
                    </span>
                  | None =>
                    <span
                      className="font-mono text-[9px] leading-none text-violet-500 dark:text-violet-400">
                      {(ts`invite`)->React.string}
                    </span>
                  }}
                </button>
                {menuOpen
                  ? <>
                      <div className="fixed inset-0 z-40" onClick={_ => setActiveMenuId(_ => None)} />
                      <div
                        role="menu"
                        className="absolute left-0 top-full z-50 mt-1 w-36 overflow-hidden rounded-lg border border-gray-200 dark:border-[#3a3b40] bg-white dark:bg-[#2a2b30] py-1 shadow-lg">
                        <button
                          type_="button"
                          role="menuitem"
                          onClick={_ => {
                            setActiveMenuId(_ => None)
                            nav(
                              "/league/" ++
                              activitySlug->Option.getOr("pickleball") ++
                              "/p/" ++
                              c.id,
                              None,
                            )
                          }}
                          className="flex w-full items-center gap-2 px-3 py-2 text-left text-xs text-gray-700 dark:text-gray-300 transition-colors hover:bg-gray-50 dark:hover:bg-[#353640] focus:bg-gray-50 dark:focus:bg-[#353640] focus:outline-none">
                          <Lucide.User className="w-3 h-3" />
                          {t`View Profile`}
                        </button>
                        <button
                          type_="button"
                          role="menuitem"
                          onClick={_ => {
                            setActiveMenuId(_ => None)
                            setComposeFor(_ => Some((c.id, c.name)))
                          }}
                          className="flex w-full items-center gap-2 px-3 py-2 text-left text-xs font-medium text-violet-700 dark:text-violet-300 transition-colors hover:bg-violet-50 dark:hover:bg-violet-950/30 focus:bg-violet-50 dark:focus:bg-violet-950/30 focus:outline-none">
                          <Lucide.Send className="w-3 h-3" />
                          {t`Send invite`}
                        </button>
                      </div>
                    </>
                  : React.null}
              </li>
            })
            ->React.array}
          </ul>
          {switch (swipeOpen, window) {
          | (true, Some((_, _, _, timeLabel))) =>
            <PlayerInviteSwipeDeck
              players={visibleCandidates->Array.map(c => {
                PlayerInviteSwipeDeck.id: c.id,
                name: c.name,
                source: FromFragment(c.user),
                availability: Some(c.availability),
              })}
              eventTitle
              eventVenue=venueName
              eventTimeLabel=timeLabel
              mode=PlayerInviteSwipeDeck.Invite
              onAccept={(userId, message) =>
                handleInvite(userId, message->Option.getOr(""))}
              onClose={() => setSwipeOpen(_ => false)}
              previousMessage=?lastMessage
            />
          | _ => React.null
          }}
          {switch composeFor {
          | Some((userId, name)) =>
            <InviteMessageComposer
              playerName=name
              eventTitle
              previousMessage=?lastMessage
              onSubmit={message => {
                handleInvite(userId, message)
                setComposeFor(_ => None)
              }}
              onCancel={() => setComposeFor(_ => None)}
            />
          | None => React.null
          }}
        </section>}
  </>
}
