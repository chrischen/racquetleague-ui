%%raw("import { t, plural } from '@lingui/macro'")
open LangProvider.Router

open Util

// EventManager Component - Simplified Sports Event Manager
//
// This component manages sports events with two types of matches:
// 1. Completed matches (with scores and round information)
// 2. Scheduled matches (awaiting results)
//
// Unlike AiTetsu, this uses a simpler state model:
// - All match-related data is derived from completed/scheduled match states
// - No complex play count tracking (derived from completed matches)
// - Round state persisted in TinyBase
//
// Usage Example:
// ```rescript
// <EventManager
//   event
//   eventId="event-123"
// />
// ```

open Rating

@send
external scrollIntoView: (Dom.element, {"behavior": string, "block": string}) => unit =
  "scrollIntoView"

module CreateLeagueMatchMutation = %relay(`
 mutation EventManagerSubmitMatchMutation(
   $matchInput: LeagueMatchInput!
 ) {
   createMatch(match: $matchInput) {
     match {
       id
       winners {
         id
         lineUsername
       }
       losers {
         id
         lineUsername
       }
       score
       createdAt
     }
     errors {
       message
     }
     ratings {
       id
       mu
       sigma
       ordinal
     }
   }
 }
`)

module Fragment = %relay(`
  fragment EventManager_event on Event
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 100 }
  )
  @refetchable(queryName: "EventManagerRsvpsRefetchQuery") {
    __id
    id
    tags
    startDate
    maxRsvps
    activity {
      id
      slug
    }
    club {
      id
      name
    }
    rsvps(after: $after, first: $first, before: $before)
      @connection(key: "EventManager_event_rsvps") {
      edges {
        node {
          __id
          listType
          user {
            id
            lineUsername
            gender
            ...EventRsvpUserBar_user
            ...EventMatchRsvpUser_user
            ...PlayerCheckin_user
            ...MatchCard_user
            ...PlayerReplaceModal_user
            ...PlayerRow_user
            ...SeedAdjustmentTimeline_user
            ...PlayerAvatar_user
          }
          rating {
            id
            mu
            sigma
            ordinal
          }
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
      }
    }
  }
`)

// Type alias for the rsvpNode used in this component
type rsvpNode = EventManager_event_graphql.Types.fragment_rsvps_edges_node

// Storage estimate bindings
type storageEstimate = {usage: float, quota: float}

@scope("navigator.storage") @val
external estimate: unit => promise<storageEstimate> = "estimate"

// Component to display storage usage in debug mode.
//
// Leads with this tool's own footprint, because that is the only figure a reset
// controls. navigator.storage.estimate() covers the entire origin — service
// worker caches, localStorage, every other database — and Safari reports it as
// one aggregate with no usageDetails breakdown, so on a real install it can read
// hundreds of MB while our data is a few hundred KB. Judging a reset by that
// number makes a working reset look broken.
module StorageUsageDebug = {
  @react.component
  let make = () => {
    let (estimate_data, setEstimate) = React.useState(() => None)
    let (ownBytes, setOwnBytes) = React.useState(() => EventManagerPersistence.storedBytes())

    // Poll rather than read once: both figures move on their own — ours as the
    // event is played, the origin's as IndexedDB compacts in the background — so
    // a single reading at mount goes stale and reads as though a clear did
    // nothing (or made things worse).
    React.useEffect0(() => {
      let refresh = () => {
        setOwnBytes(_ => EventManagerPersistence.storedBytes())
        estimate()
        ->Promise.then(est => {
          setEstimate(_ => Some(est))
          Promise.resolve()
        })
        ->Promise.catch(_ => Promise.resolve())
        ->ignore
      }
      refresh()
      let intervalId = setInterval(refresh, 3000)
      Some(() => clearInterval(intervalId))
    })

    let ownLabel = {
      let kb = ownBytes->Int.toFloat /. 1024.0
      kb < 1024.0
        ? `${kb->Float.toFixed(~digits=0)} KB`
        : `${(kb /. 1024.0)->Float.toFixed(~digits=1)} MB`
    }

    <div className="flex items-center gap-2 px-3 py-1 rounded bg-slate-700">
      <span className="text-xs font-medium text-slate-200 whitespace-nowrap">
        {React.string(`events ${ownLabel}`)}
      </span>
      {switch estimate_data {
      | None => React.null
      | Some({usage, quota}) => {
          let usageMB = usage /. (1024.0 *. 1024.0)
          let quotaMB = quota /. (1024.0 *. 1024.0)
          let percentage = quota > 0.0 ? usage /. quota *. 100.0 : 0.0

          let barColor = if percentage > 90.0 {
            "bg-red-500"
          } else if percentage > 70.0 {
            "bg-amber-500"
          } else {
            "bg-blue-500"
          }

          <>
            <span className="text-xs text-slate-500"> {React.string("|")} </span>
            <span
              className="text-xs text-slate-400 whitespace-nowrap"
              title="Whole-origin usage reported by the browser. Includes caches and other storage this reset cannot clear.">
              {React.string(
                `site ${usageMB->Float.toFixed(~digits=1)}/${quotaMB->Float.toFixed(
                    ~digits=0,
                  )} MB`,
              )}
            </span>
            <div className="w-16 bg-slate-600 rounded-full h-2 overflow-hidden">
              <div
                className={`${barColor} h-2 rounded-full transition-all duration-300`}
                style={ReactDOM.Style.make(~width=`${percentage->Float.toFixed(~digits=1)}%`, ())}
              />
            </div>
            <span className="text-xs text-slate-400 whitespace-nowrap">
              {React.string(`${percentage->Float.toFixed(~digits=1)}%`)}
            </span>
          </>
        }
      }}
    </div>
  }
}

// Popup warning when local storage usage is critically high
module StorageLowWarning = {
  @react.component
  let make = (~onClearData: unit => unit) => {
    open Lingui.Util
    let (storageInfo, setStorageInfo) = React.useState(() => None)
    let (dismissed, setDismissed) = React.useState(() => false)

    React.useEffect0(() => {
      let _ =
        estimate()
        ->Promise.then(est => {
          setStorageInfo(_ => Some(est))
          Promise.resolve()
        })
        ->Promise.catch(_ => Promise.resolve())
      None
    })

    let shouldShow = switch storageInfo {
    | Some({usage, quota}) if quota > 0.0 => usage /. quota *. 100.0 > 90.0
    | _ => false
    }

    if !shouldShow || dismissed {
      React.null
    } else {
      let percentage = switch storageInfo {
      | Some({usage, quota}) if quota > 0.0 => usage /. quota *. 100.0
      | _ => 0.0
      }

      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div className="bg-white rounded-xl shadow-2xl max-w-md w-full mx-4 p-6">
          <div className="flex items-center gap-3 mb-4">
            <div
              className="flex-shrink-0 w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
              <Lucide.AlertTriangle className="w-5 h-5 text-red-600" />
            </div>
            <h2 className="text-lg font-bold text-slate-900"> {t`Storage Almost Full`} </h2>
          </div>
          <p className="text-sm text-slate-600 mb-4">
            {t`Your browser storage is ${percentage->Float.toFixed(
                ~digits=1,
              )}% full. The app may lose data if storage runs out. Freeing space clears saved data for every event on this device — you'll get a chance to review what that removes.`}
          </p>
          <div className="w-full bg-slate-200 rounded-full h-3 overflow-hidden mb-5">
            <div
              className="bg-red-500 h-3 rounded-full"
              style={ReactDOM.Style.make(~width=`${percentage->Float.toFixed(~digits=1)}%`, ())}
            />
          </div>
          <div className="flex justify-end gap-3">
            <button
              onClick={_ => setDismissed(_ => true)}
              className="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors">
              {t`Dismiss`}
            </button>
            <button
              onClick={_ => {
                onClearData()
                setDismissed(_ => true)
              }}
              className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors">
              {t`Free Up Space`}
            </button>
          </div>
        </div>
      </div>
    }
  }
}

// Header chip reporting whether event data is actually reaching IndexedDB.
// Always visible: a silent "saved" state is the whole point — organisers need to
// be able to glance up mid-event and know their scores are safe.
module PersistenceChip = {
  @react.component
  let make = (~health: EventManagerPersistence.health, ~onShowError: unit => unit) => {
    open Lingui.Util

    let (className, icon, label) = switch health {
    | {failure: Some(_)} => (
        "bg-red-600 hover:bg-red-700 text-white cursor-pointer",
        <Lucide.AlertTriangle className="w-4 h-4" />,
        t`Not saved`,
      )
    | {ready: false} => (
        "bg-slate-700 text-slate-300",
        <Lucide.Loader2 className="w-4 h-4 animate-spin" />,
        t`Connecting…`,
      )
    // Only #saving is worth showing. autoLoad polls IndexedDB once a second, so
    // surfacing #loading here would flicker the chip forever on a healthy page.
    | {activity: #saving} => (
        "bg-slate-700 text-slate-300",
        <Lucide.Loader2 className="w-4 h-4 animate-spin" />,
        t`Saving…`,
      )
    | _ => (
        "bg-slate-700 text-emerald-400",
        <Lucide.Check className="w-4 h-4" />,
        t`Saved`,
      )
    }

    let isFailed = switch health.failure {
    | Some(_) => true
    | None => false
    }

    <button
      onClick={_ => if isFailed { onShowError() }}
      disabled={!isFailed}
      className={`flex items-center gap-2 px-3 py-2 rounded-lg transition-colors ${className}`}>
      icon <span className="text-sm font-medium"> label </span>
    </button>
  }
}

// The single confirmation in front of every clear this tool offers. Clearing is
// always device-wide, so this has to name what is about to be lost: unsynced
// scores in this event can still be pushed from the screen behind the modal,
// but the other events have to be opened one by one to save theirs.
module ClearAllStorageModal = {
  @react.component
  let make = (~currentEventId: string, ~onConfirm: unit => unit, ~onCancel: unit => unit) => {
    open Lingui.Util

    // Snapshot on open so the numbers can't shift while the organiser reads them.
    let (summary, _) = React.useState(() =>
      EventManagerPersistence.summarizeStoredData(currentEventId)
    )

    let atRisk = summary.currentUnsyncedMatchCount + summary.otherUnsyncedMatchCount
    let countClass = count =>
      count > 0 ? "font-semibold text-red-600" : "font-semibold text-slate-900"

    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-white rounded-xl shadow-2xl max-w-md w-full mx-4 p-6">
        <div className="flex items-center gap-3 mb-4">
          <div
            className="flex-shrink-0 w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
            <Lucide.AlertTriangle className="w-5 h-5 text-red-600" />
          </div>
          <h2 className="text-lg font-bold text-slate-900">
            {t`Delete all saved event data?`}
          </h2>
        </div>
        <p className="text-sm text-slate-600 mb-4">
          {t`This deletes the saved data for every event on this device, including this one. Events already synced to the server can be reopened; anything unsynced cannot be recovered.`}
        </p>
        <div className="rounded-lg border border-slate-200 bg-slate-50 p-3 mb-4 text-sm">
          <div className="flex items-center justify-between">
            <span className="text-slate-600"> {t`Unsynced scores in this event`} </span>
            <span className={countClass(summary.currentUnsyncedMatchCount)}>
              {React.string(summary.currentUnsyncedMatchCount->Int.toString)}
            </span>
          </div>
          <div className="flex items-center justify-between mt-2">
            <span className="text-slate-600"> {t`Other events on this device`} </span>
            <span className="font-semibold text-slate-900">
              {React.string(summary.otherEventCount->Int.toString)}
            </span>
          </div>
          <div className="flex items-center justify-between mt-2">
            <span className="text-slate-600"> {t`Unsynced scores in those events`} </span>
            <span className={countClass(summary.otherUnsyncedMatchCount)}>
              {React.string(summary.otherUnsyncedMatchCount->Int.toString)}
            </span>
          </div>
        </div>
        {atRisk > 0
          ? <p className="text-sm font-medium text-red-700 mb-5">
              {summary.otherUnsyncedMatchCount > 0
                ? t`Those scores have not reached the server. Sync this event, and open each other event and sync it, before deleting — otherwise they are lost.`
                : t`Those scores have not reached the server. Sync this event before deleting, or they will be lost.`}
            </p>
          : <p className="text-sm text-slate-600 mb-5">
              {t`Everything stored on this device is already synced to the server.`}
            </p>}
        <div className="flex justify-end gap-3">
          <button
            onClick={_ => onCancel()}
            className="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors">
            {t`Cancel`}
          </button>
          <button
            onClick={_ => onConfirm()}
            className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors">
            {t`Delete all data`}
          </button>
        </div>
      </div>
    </div>
  }
}

// Banner spelling out what broke and what the organiser can do about it.
module PersistenceErrorBanner = {
  @react.component
  let make = (
    ~failure: (EventManagerPersistence.failureKind, string),
    ~onRetry: unit => unit,
    ~onFreeUpSpace: unit => unit,
    ~onDismiss: unit => unit,
  ) => {
    open Lingui.Util
    let (kind, detail) = failure

    let explanation = switch kind {
    | EventManagerPersistence.StorageUnavailable =>
      t`Your browser is blocking storage for this site. If you're in a private window, switch to a normal one; otherwise allow site data and reload.`
    | EventManagerPersistence.QuotaExceeded =>
      t`Your browser is out of storage space. Clear old event data to free up space, then retry.`
    | EventManagerPersistence.UnknownFailure =>
      t`Your browser refused to save this event. Reload the page or retry — if it keeps failing, avoid refreshing until scores are synced.`
    }

    <div className="mx-6 mt-4 p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
      <Lucide.AlertTriangle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-red-900">
          {t`Changes aren't being saved`}
        </p>
        <p className="mt-1 text-sm text-red-800"> explanation </p>
        <p className="mt-1 text-xs text-red-600 break-words"> {React.string(detail)} </p>
        <div className="mt-3 flex flex-wrap gap-3">
          // Only the quota case has a fix the organiser can apply from here.
          {kind == EventManagerPersistence.QuotaExceeded
            ? <button
                onClick={_ => onFreeUpSpace()}
                className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors">
                <Lucide.Trash2 className="w-4 h-4" /> {t`Free up space`}
              </button>
            : React.null}
          <button
            onClick={_ => onRetry()}
            className={kind == EventManagerPersistence.QuotaExceeded
              ? "flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-red-700 bg-red-100 hover:bg-red-200 rounded-lg transition-colors"
              : "flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg transition-colors"}>
            <Lucide.RefreshCw className="w-4 h-4" /> {t`Retry`}
          </button>
          <button
            onClick={_ => onDismiss()}
            className="px-3 py-1.5 text-sm font-medium text-red-700 bg-red-100 hover:bg-red-200 rounded-lg transition-colors">
            {t`Dismiss`}
          </button>
        </div>
      </div>
    </div>
  }
}

// Component to display overall average quality across all rounds
module OverallAverageQualityDebug = {
  @react.component
  let make = (~rounds: array<array<completedMatchEntity<'a>>>) => {
    // Calculate total matches and total quality across all rounds
    // Also track court 1 matches separately
    let (totalMatches, totalQuality, court1Matches, court1Quality) = rounds->Array.reduce(
      (0, 0., 0, 0.),
      ((matchAcc, qualityAcc, court1Acc, court1QualityAcc), roundMatches) => {
        let (roundTotal, court1Total) = roundMatches->Array.reduceWithIndex(
          (qualityAcc, court1QualityAcc),
          ((acc, court1Acc), {match}, index) => {
            let (team1, team2) = match
            let quality = Rating.predictDraw([
              team1->Array.map(p => p.rating),
              team2->Array.map(p => p.rating),
            ])
            let newCourt1Acc = if index == 0 {
              // First match in round is court 1
              court1Acc +. quality
            } else {
              court1Acc
            }
            (acc +. quality, newCourt1Acc)
          },
        )
        let court1Count = if roundMatches->Array.length > 0 {
          court1Acc + 1
        } else {
          court1Acc
        }
        (matchAcc + roundMatches->Array.length, roundTotal, court1Count, court1Total)
      },
    )

    let averageQuality = if totalMatches > 0 {
      totalQuality /. Float.fromInt(totalMatches)
    } else {
      0.0
    }

    let court1AverageQuality = if court1Matches > 0 {
      court1Quality /. Float.fromInt(court1Matches)
    } else {
      0.0
    }

    let qualityPercent = averageQuality *. 100.0
    let court1QualityPercent = court1AverageQuality *. 100.0

    <div className="mb-4 p-4 bg-blue-50 border border-blue-200 rounded-lg">
      <div className="text-sm font-semibold text-blue-900">
        {React.string("Overall Match Quality Across All Rounds")}
      </div>
      <div className="text-lg font-bold text-blue-700 mt-1">
        {React.string(qualityPercent->Float.toFixed(~digits=1) ++ "%")}
      </div>
      <div className="text-xs text-blue-600 mt-1">
        {React.string(
          `${totalMatches->Int.toString} total matches across ${rounds
            ->Array.length
            ->Int.toString} rounds`,
        )}
      </div>
      <div className="mt-3 pt-3 border-t border-blue-200">
        <div className="text-sm font-semibold text-blue-900">
          {React.string("Court 1 Average Quality")}
        </div>
        <div className="text-lg font-bold text-blue-700 mt-1">
          {React.string(court1QualityPercent->Float.toFixed(~digits=1) ++ "%")}
        </div>
        <div className="text-xs text-blue-600 mt-1">
          {React.string(`${court1Matches->Int.toString} matches on court 1`)}
        </div>
      </div>
    </div>
  }
}

// Club-scoped ratings are only ever recorded in the competitive namespace, so
// this is fixed rather than following the event's own namespace: a rec event
// asking for its own namespace would find nothing and start everyone from the
// default rating.
let clubRatingNamespace = "doubles:comp"

// Asks for each RSVP'd user's rating inside the club. Going through the event's
// rsvps rather than the club-wide `ratings` list keeps this to exactly the
// people in the room, however large the club is. It has to be a second query:
// the club id only becomes known once the event itself has loaded, so it cannot
// be a variable on the query that fetches it.
module ClubRatingsQuery = %relay(`
  query EventManagerClubRatingsQuery(
    $eventId: ID!
    $activitySlug: String!
    $namespace: String!
    $clubId: ID!
  ) {
    event(id: $eventId) {
      id
      rsvps(first: 100) {
        edges {
          node {
            user {
              id
              rating(activitySlug: $activitySlug, clubId: $clubId, namespace: $namespace) {
                id
                mu
                sigma
              }
            }
          }
        }
      }
    }
  }
`)

// Renders nothing: it exists to suspend on the query and hand the ratings up so
// they can become the base players are built from. Mounted only while the club
// source is selected, so the default path costs nothing.
module ClubRatingsLoader = {
  @react.component
  let make = (
    ~eventId: string,
    ~clubId: string,
    ~activitySlug: string,
    ~onLoaded: array<(string, (float, float))> => unit,
  ) => {
    let data = ClubRatingsQuery.use(
      ~variables={eventId, activitySlug, namespace: clubRatingNamespace, clubId},
    )

    React.useEffect0(() => {
      let ratings =
        data.event
        ->Option.flatMap(event => event.rsvps)
        ->Option.flatMap(rsvps => rsvps.edges)
        ->Option.getOr([])
        ->Array.filterMap(edge =>
          edge
          ->Option.flatMap(edge => edge.node)
          ->Option.flatMap(node => node.user)
          ->Option.flatMap(user =>
            user.rating->Option.flatMap(
              rating =>
                rating.mu->Option.map(mu => (user.id, (mu, rating.sigma->Option.getOr(8.333)))),
            )
          )
        )
      onLoaded(ratings)
      None
    })

    React.null
  }
}

type syncState = Idle | Syncing | Success | Error

@react.component
let make = (
  ~event: RescriptRelay.fragmentRefs<[> #EventManager_event]>,
  ~eventId: string,
  ~debug: bool=false,
) => {
  let data = Fragment.use(event)
  open Lingui.Util
  let ts = Lingui.UtilString.t

  // Mutation hook for submitting matches
  let (commitMutationCreateLeagueMatch, _isMutationInFlight) = CreateLeagueMatchMutation.use()

  // Determine namespace from event tags: if "comp" tag exists => doubles:comp, else doubles:rec
  let eventTags: array<string> = data.tags->Option.getOr([])
  let eventNamespace = eventTags->Array.includes("comp") ? "doubles:comp" : "doubles:rec"

  // Players normally start on their global rating. A club event can instead
  // start them on the rating they earned inside that club — which has to be
  // their *base* rating, not an adjustment on top, or every change shown during
  // the event would really be the gap between the two scales. Needs a club and
  // an activity, so a clubless event gets None and the option stays hidden.
  let clubRatingSource = switch (data.club, data.activity->Option.flatMap(a => a.slug)) {
  | (Some(club), Some(activitySlug)) =>
    Some((club.id, club.name->Option.getOr(ts`this club`), activitySlug))
  | _ => None
  }

  let (seedSource, setSeedSource) = React.useState(() => EventManagerPersistence.GlobalRatings)
  // None until the club query resolves; players fall back to global ratings in
  // the meantime rather than blocking the whole manager on a secondary fetch.
  let (clubRatings, setClubRatings) = React.useState(() => None)

  // Get event start time for staggering match creation timestamps
  let eventStartTime =
    data.startDate->Option.map(Util.Datetime.toDate)->Option.getOr(Js.Date.make())

  // Submit match function (simplified - no connection updates)
  let submitMatch = (
    match: Match.t<'a>,
    score,
    activitySlug,
    matchId: string,
    createdAt: Js.Date.t,
  ): Promise.t<unit> => {
    let namespace = eventNamespace

    // Get winners and losers with their scores
    let (winnerIds, winnerScore) = match->Match.getWinners(score)
    let (loserIds, loserScore) = match->Match.getLosers(score)

    Promise.make((resolve, reject) => {
      commitMutationCreateLeagueMatch(
        ~variables={
          matchInput: {
            activitySlug,
            eventId: ?Some(eventId),
            namespace,
            doublesMatch: {
              winners: winnerIds,
              losers: loserIds,
              score: [winnerScore, loserScore],
              createdAt: createdAt->Util.Datetime.fromDate,
            },
            syncId: matchId,
          },
        },
        ~onCompleted=(_, errs) => {
          switch errs {
          | Some(errs) => Js.log(errs)
          | None => resolve()
          }
        },
        ~onError=e => {
          reject(e)
        },
      )->RescriptRelay.Disposable.ignore
    })
  }

  // Debug mode state
  let (debugMode, setDebugMode) = React.useState(() => debug)

  // Sync state
  let (syncState, setSyncState) = React.useState(() => Idle)
  let (syncProgress, setSyncProgress) = React.useState(() => 0)

  // Local persistence health, so a blocked or full IndexedDB is visible rather
  // than silently discarding the event.
  let persistenceHealth = EventManagerPersistence.Health.use()

  // Dismissal is keyed on the failure detail, so a *new* failure re-arms the banner.
  let (dismissedFailure, setDismissedFailure) = React.useState(() => None)

  // Confirmation for the destructive "free up space" reset offered on quota errors.
  let (showClearAllStorage, setShowClearAllStorage) = React.useState(() => false)

  let visibleFailure = switch persistenceHealth.failure {
  | Some((kind, detail)) if dismissedFailure != Some(detail) => Some((kind, detail))
  | _ => None
  }

  // Reset sync state after success/error
  React.useEffect1(() => {
    switch syncState {
    | Success | Error => {
        let timeoutId = setTimeout(() => {
          setSyncState(_ => Idle)
          setSyncProgress(_ => 0)
        }, 2000)
        Some(() => clearTimeout(timeoutId))
      }
    | _ => None
    }
  }, [syncState])

  // === STATE MANAGEMENT ===

  // Guest players state - separate from RSVP players
  let (guestPlayers: array<Player.t<rsvpNode>>, setGuestPlayers) = React.useState(() => [])

  // Next guest player ID (starting at 9000)
  let (nextGuestId, setNextGuestId) = React.useState(() => 9000)

  // Modal state for adding guest players
  let (showAddGuestsModal, setShowAddGuestsModal) = React.useState(() => false)

  // Load player overrides once and store in state
  let (
    playerOverrides: Js.Dict.t<EventManagerPersistence.playerOverride>,
    setPlayerOverrides,
  ) = React.useState(() => Js.Dict.empty())

  // Resolves a player's starting rating from whichever pool is selected. On the
  // club source a player with no club rating starts from the default rather
  // than their global one: leaving the global value would silently mix two
  // scales in one list, ranking an outsider's form elsewhere against club form.
  let baseRatingFor = (userId: string, rsvpRating: option<(float, float, float)>) => {
    let defaultRating = Rating.makeDefault()
    switch (seedSource, clubRatings) {
    | (EventManagerPersistence.ClubRatings, Some(byUserId)) =>
      switch byUserId->Js.Dict.get(userId) {
      | Some((mu, sigma)) => (mu, sigma, 0.0)
      | None => (defaultRating.mu, defaultRating.sigma, 0.0)
      }
    | _ =>
      switch rsvpRating {
      | Some(rating) => rating
      | None => (defaultRating.mu, defaultRating.sigma, 0.0)
      }
    }
  }

  // Extract players from RSVPs and merge with guest players - memoized to prevent unnecessary recalculations
  let players: array<Player.t<rsvpNode>> = React.useMemo(() => {
    (data.rsvps
    ->Option.flatMap(rsvps => rsvps.edges)
    ->Option.getOr([])
    ->Array.filterMap(edge => {
      edge
      ->Option.flatMap(edge => edge.node)
      ->Option.flatMap(
        rsvp => {
          switch rsvp.user {
          | Some(user) => {
              // Get override data for this player if it exists
              let override = playerOverrides->Js.Dict.get(user.id)

              // Extract override values (using bind since o.name/gender/paid are already options)
              let overrideName = override->Option.flatMap(o => o.name)
              let overrideGender = override->Option.flatMap(o => o.gender)
              let overridePaid = override->Option.flatMap(o => o.paid)

              // Starting rating, from whichever pool the organiser selected
              let (mu, sigma, ordinal) = baseRatingFor(
                user.id,
                rsvp.rating->Option.map(
                  rating => (
                    rating.mu->Option.getOr(25.0),
                    rating.sigma->Option.getOr(8.333),
                    rating.ordinal->Option.getOr(0.0),
                  ),
                ),
              )

              Some({
                Player.data: Some(rsvp),
                id: user.id,
                intId: 0, // Will be set based on array index
                name: overrideName->Option.getOr(user.lineUsername->Option.getOr("Unknown")),
                rating: {
                  Rating.mu,
                  sigma,
                },
                ratingOrdinal: ordinal,
                paid: overridePaid->Option.getOr(false),
                gender: overrideGender->Option.getOr(
                  switch user.gender {
                  | Some(Male) => Gender.Male
                  | Some(Female) => Gender.Female
                  | _ => Gender.Male
                  },
                ),
                count: 0,
              })
            }
          | None => None
          }
        },
      )
    })
    ->Array.concat(guestPlayers)
    ->Array.toSorted((a, b) => {
      // Sort by rating (mu) descending, then by ID for stable ordering
      let ratingDiff = b.rating.mu -. a.rating.mu
      if ratingDiff != 0. {
        ratingDiff
      } else {
        String.compare(a.id, b.id)
      }
    })
    ->Array.mapWithIndex((player, i) => {...player, intId: i + 1}) :> array<Player.t<rsvpNode>>)
  }, (data.rsvps, guestPlayers, playerOverrides, nextGuestId, seedSource, clubRatings))

  // All matches organized by rounds: array<array<completedMatchEntity>>
  // Each element is a round containing matches (completed or not)
  let (rounds, setRounds): (
    array<array<completedMatchEntity<'a>>>,
    (array<array<completedMatchEntity<'a>>> => array<array<completedMatchEntity<'a>>>) => unit,
  ) = React.useState(() => [])

  // Track if matches have been modified (scores updated) in current or previous rounds
  // This prevents unnecessary recalculations when only viewing future rounds
  let (isDirty, setIsDirty) = React.useState(() => false)

  // Checked-in players (by ID)
  // Will be loaded from TinyBase in useEffect
  let (checkedInPlayerIds, setCheckedInPlayerIds) = React.useState(() => Set.make())

  // Current round number (0 = setup/pre-round view, 1+ = round views)
  // Will be loaded from TinyBase in useEffect
  let (currentRoundInt, setCurrentRoundInt) = React.useState(() => 0)

  // Ref for current round section to enable smooth scrolling
  let currentRoundRef = React.useRef(Nullable.null)

  // Court count - initially suggested based on Going list player count (excludes waitlist)
  // Will be loaded from TinyBase in useEffect if previously saved
  let goingPlayerCount = {
    let allGoingOrPending =
      data.rsvps
      ->Option.flatMap(rsvps => rsvps.edges)
      ->Option.getOr([])
      ->Array.filter(edge =>
        edge
        ->Option.flatMap(e => e.node)
        ->Option.map(rsvp => rsvp.listType == Some(0) || rsvp.listType == None)
        ->Option.getOr(false)
      )
      ->Array.length
    switch data.maxRsvps {
    | Some(max) => Math.Int.min(allGoingOrPending, max)
    | None => allGoingOrPending
    }
  }
  let (courtCount, setCourtCount) = React.useState(() => suggestedCourtCount(goingPlayerCount))

  // With the legacy options gone from the picker, a stored or default legacy
  // strategy would leave nothing selected. Upgrade legacy choices to their
  // solver successors (the mapping mirrors each mode's own description);
  // downgrade the other way on runtimes without WebAssembly, where the picker
  // falls back to the legacy set. Generation itself accepts either — the
  // greedy engine remains the solver's fallback path.
  let modernizeStrategy = (s: strategy): strategy =>
    if HighsBindings.isAvailable() {
      switch s {
      | CompetitivePlus | Competitive | DUPR => SolverCompetitivePlus
      | Mixed | Random => SolverRandomBalanced
      | RoundRobin | NoveltyRoundRobin => SolverRoundRobin
      | SolverRoundRobin | SolverRandomBalanced | SolverCompetitivePlus | SolverAuto => s
      }
    } else {
      switch s {
      | SolverCompetitivePlus | SolverAuto => CompetitivePlus
      | SolverRandomBalanced => Mixed
      | SolverRoundRobin => NoveltyRoundRobin
      | _ => s
      }
    }

  // Match generation strategy
  let (strategy, setStrategy) = React.useState(() => modernizeStrategy(CompetitivePlus))

  // The event's draw seed. Solver generation is a pure function of (players,
  // history, strategy, weights, courts, seed), so with a fixed seed "reset"
  // restores the canonical round for the current state — idempotent until
  // something real changes. The dice button mints a new seed for a fresh deal.
  let (drawSeed, setDrawSeed) = React.useState(() => 1)

  // Every solver path derives from this one string (plus the absolute round
  // index, added per round inside SolverRounds). Deliberately free of
  // startRoundIndex: a block generating rounds 0-9 and a later reset of round
  // 3 must feed the identical PRNG stream for round 3, or reset could never
  // reproduce what generation produced.
  let generationSeed = data.id ++ ":" ++ drawSeed->Int.toString

  // Mint a new seed. Applying it goes through the usual settings flow: the
  // "Update Rounds Below" button highlights and rebuilds the future rounds.
  let handleNewSeed = () => {
    let next = Js.Math.random_int(1, 100000)
    setDrawSeed(_ => next)
    EventManagerPersistence.saveDrawSeed(data.id, next)
    setIsDirty(_ => true)
  }

  // Solver weight configuration for the beta strategies. `None` = use the
  // strategy's preset; `Some` = the user has adjusted it for this event.
  let (weightConfig: option<CostModel.uiWeightConfig>, setWeightConfig) = React.useState(() => None)

  // Draw generation is asynchronous on the solver path (the wasm loads lazily
  // on first use), so the generate controls need a pending state.
  let (isGenerating, setIsGenerating) = React.useState(() => false)

  // Bumped whenever *recorded history* changes — a score entered, a match
  // deleted, a seed adjusted — i.e. anything that moves player ratings and so
  // makes the future rounds stale.
  //
  // Deliberately separate from `isDirty`, which also fires on settings changes
  // (strategy, court count, weights). Auto-regenerating on those made a newly
  // picked preset apply itself before the user pressed "Update Rounds Below",
  // leaving the button with nothing to do. A counter rather than a flag, so two
  // scores in a row both trigger.
  let (historyRevision, setHistoryRevision) = React.useState(() => 0)
  let bumpHistoryRevision = () => setHistoryRevision(prev => prev + 1)

  // Only the newest generation request may write to `rounds`. Without this a
  // slow first solve — the one that also waits on the ~3 MB wasm download — can
  // land after a later request and overwrite it with a stale draw.
  let generationRequestRef = React.useRef(0)
  let beginGeneration = () => {
    generationRequestRef.current = generationRequestRef.current + 1
    generationRequestRef.current
  }
  let isLatestGeneration = (token: int) => generationRequestRef.current == token

  // Structured warnings from the last solver run: match id -> reasons the match
  // had to break a rule, plus per-round violations and a one-off notice when
  // the optimizer was unavailable.
  let (
    solverMatchViolations: Js.Dict.t<array<SolverTypes.violation>>,
    setSolverMatchViolations,
  ) = React.useState(() => Js.Dict.empty())
  let (solverRoundViolations: Js.Dict.t<array<SolverTypes.violation>>, setSolverRoundViolations) =
    React.useState(() => Js.Dict.empty())

  // Write-through setters: fallback warnings describe the stored rounds, so
  // every update also lands in TinyBase and survives a reload. (The plain
  // setters are reserved for restoring loaded state on mount.)
  let setAndSaveSolverMatchViolations = updater =>
    setSolverMatchViolations(prev => {
      let next = updater(prev)
      EventManagerPersistence.saveSolverMatchViolations(data.id, next)
      next
    })
  let setAndSaveSolverRoundViolations = updater =>
    setSolverRoundViolations(prev => {
      let next = updater(prev)
      EventManagerPersistence.saveSolverRoundViolations(data.id, next)
      next
    })
  let (solverNoticeDismissed, setSolverNoticeDismissed) = React.useState(() => true)

  // Rating adjustment history (chronological list of adjustments with round metadata)
  let (ratingAdjustmentHistory, setRatingAdjustmentHistory) = React.useState(() => [])

  // Team constraints for matchmaking
  let (teams: NonEmptyArray.t<array<Player.t<rsvpNode>>>, setTeams) = React.useState(() =>
    NonEmptyArray.empty
  )
  let (antiTeams: NonEmptyArray.t<array<Player.t<rsvpNode>>>, setAntiTeams) = React.useState(() =>
    NonEmptyArray.empty
  )

  // Team management modal state
  let (teamManagementOpen, setTeamManagementOpen) = React.useState(() => false)

  // Player settings modal state
  let (playerSettingsOpen, setPlayerSettingsOpen) = React.useState(() => None)

  // Fullscreen round view state
  let (showFullScreenRound, setShowFullScreenRound) = React.useState(() => false)

  // Printable draws view state
  let (showPrintableDraws, setShowPrintableDraws) = React.useState(() => false)

  // Convert teams to team constraints for match generation
  let teamConstraints = React.useMemo(() => {
    let teamsArray = teams->NonEmptyArray.toArray
    if teamsArray->Array.length > 0 {
      Some(teamsArray->Array.map(Team.toSet))
    } else {
      None
    }
  }, [teams])

  // Convert anti-teams to avoidAllPlayers for match generation
  let avoidAllPlayers = React.useMemo(() => {
    antiTeams->NonEmptyArray.toArray
  }, [antiTeams])

  // Check if any future rounds have scores recorded
  // If so, we should NOT auto-regenerate to avoid overwriting entered scores
  let futureRoundsHaveScores = React.useMemo2(() => {
    rounds->Array.someWithIndex((round, index) => {
      index >= currentRoundInt && round->Array.some(match => match.score->Option.isSome)
    })
  }, (rounds, currentRoundInt))

  // === DERIVED DATA ===

  // Load matches from TinyBase on initial mount
  React.useEffect1(() => {
    // Load court count from TinyBase (if previously saved)
    switch EventManagerPersistence.loadCourtCount(data.id) {
    | Some(stored) => setCourtCount(_ => stored)
    | None => ()
    }

    // Load match generation strategy from TinyBase
    let rawStoredStrategy = EventManagerPersistence.loadStrategy(data.id)
    let storedStrategy = modernizeStrategy(rawStoredStrategy)
    setStrategy(_ => storedStrategy)
    // Persist the upgrade so the stored value matches what the picker shows
    // (same pattern as the strategy-string alias migration).
    if storedStrategy != rawStoredStrategy {
      EventManagerPersistence.saveStrategy(data.id, storedStrategy)
    }

    // Which rating pool players start on. Mounting the loader below is what
    // actually fetches the club ratings when this is ClubRatings.
    setSeedSource(_ => EventManagerPersistence.loadSeedSource(data.id))

    // Draw seed (see the dice button in the generation controls)
    setDrawSeed(_ => EventManagerPersistence.loadDrawSeed(data.id))

    // Restore fallback warnings for the rounds already on disk; they are keyed
    // by persisted match ids / round indices, so they reattach cleanly.
    setSolverMatchViolations(_ => EventManagerPersistence.loadSolverMatchViolations(data.id))
    setSolverRoundViolations(_ => EventManagerPersistence.loadSolverRoundViolations(data.id))

    // Solver weight overrides, if the user has adjusted them for this event.
    // The codec's version gate discards configs written before the advanced
    // panel spoke the full weight vocabulary (and, with them, the old
    // nominal-slider auto-stores), so anything that loads here is a real
    // customisation in the current vocabulary.
    setWeightConfig(_ => EventManagerPersistence.loadWeightConfig(data.id))

    // Load checked-in player IDs from TinyBase
    let storedCheckedInIds = EventManagerPersistence.loadCheckedInPlayerIds(data.id)
    if storedCheckedInIds->Array.length > 0 {
      setCheckedInPlayerIds(_ => storedCheckedInIds->Set.fromArray)
    }

    // Load current round from TinyBase
    let storedCurrentRound = EventManagerPersistence.loadCurrentRound(data.id)
    setCurrentRoundInt(_ => storedCurrentRound)

    // Load rating adjustment history from TinyBase
    let storedHistory = EventManagerPersistence.loadRatingAdjustmentHistory(data.id)
    setRatingAdjustmentHistory(_ => storedHistory)

    // Load teams from TinyBase
    let storedTeams = EventManagerPersistence.loadTeams(data.id)
    if storedTeams->Array.length > 0 {
      setTeams(_ => storedTeams->NonEmptyArray.fromArray)
    }

    // Load anti-teams from TinyBase
    let storedAntiTeams = EventManagerPersistence.loadAntiTeams(data.id)
    if storedAntiTeams->Array.length > 0 {
      setAntiTeams(_ => storedAntiTeams->NonEmptyArray.fromArray)
    }

    // Load player overrides from TinyBase
    let storedPlayerOverrides = EventManagerPersistence.loadPlayerOverrides(data.id)
    setPlayerOverrides(_ => storedPlayerOverrides)

    // Load guest players from TinyBase
    let storedGuestPlayers = EventManagerPersistence.loadGuestPlayers(data.id)
    if storedGuestPlayers->Array.length > 0 {
      setGuestPlayers(_ => storedGuestPlayers)
      // Set next guest ID based on existing guest players
      let maxGuestId = storedGuestPlayers->Array.reduce(8999, (max, player) => {
        let playerId = player.id->Int.fromString->Option.getOr(0)
        playerId > max ? playerId : max
      })
      setNextGuestId(_ => maxGuestId + 1)
    }

    // Create a map of userId -> rsvp for fast lookup
    let rsvpMap =
      data.rsvps
      ->Fragment.getConnectionNodes
      ->Array.filterMap(rsvp =>
        rsvp.user
        ->Option.map(u => u.id)
        ->Option.map(userId => (userId, rsvp))
      )
      ->Js.Dict.fromArray

    let rawMatches = EventManagerPersistence.loadMatchesFromDb(data.id, rsvpMap)

    // Group raw matches by round index
    let roundsMap = Map.make()
    rawMatches->Array.forEach(((
      matchId,
      team1Players,
      team2Players,
      roundIndex,
      score,
      createdAt,
      synced,
    )) => {
      let roundMatches = roundsMap->Map.get(roundIndex)->Option.getOr([])
      roundsMap->Map.set(
        roundIndex,
        roundMatches->Array.concat([
          (matchId, team1Players, team2Players, score, createdAt, synced),
        ]),
      )
    })

    // Convert to array of rounds (players already loaded with their ratings)
    let maxRound =
      rawMatches->Array.reduce(0, (max, (_, _, _, roundIndex, _, _, _)) =>
        roundIndex > max ? roundIndex : max
      )

    let loadedRounds = []
    for i in 0 to maxRound {
      let roundData = roundsMap->Map.get(i)->Option.getOr([])

      let round = roundData->Array.filterMap(((
        matchId,
        team1Players,
        team2Players,
        score,
        createdAt,
        synced,
      )) => {
        // Only include match if both teams have players
        if team1Players->Array.length > 0 && team2Players->Array.length > 0 {
          let entity: completedMatchEntity<'a> = {
            id: matchId,
            match: (team1Players, team2Players),
            score,
            createdAt,
            synced,
          }
          Some(entity)
        } else {
          None
        }
      })
      loadedRounds->Array.push(round)
    }

    if (
      loadedRounds->Array.length > 0 && loadedRounds->Array.some(round => round->Array.length > 0)
    ) {
      setRounds(_ => loadedRounds)

      // Correct current round if it's in an invalid state
      // Valid range: 0 to loadedRounds.length (inclusive)
      if currentRoundInt < 0 || currentRoundInt > loadedRounds->Array.length {
        let newRoundInt = loadedRounds->Array.length
        setCurrentRoundInt(_ => newRoundInt)
        EventManagerPersistence.saveCurrentRound(data.id, newRoundInt)
      }
    }

    None
  }, [data.id])

  // Wrapper for setRounds that persists to TinyBase
  let updateRounds = (
    updater: array<array<completedMatchEntity<'a>>> => array<array<completedMatchEntity<'a>>>,
  ) => {
    setRounds(currentRounds => {
      let newRounds = updater(currentRounds)
      // Sync to TinyBase
      EventManagerPersistence.syncRoundsToDb(data.id, newRounds)
      newRounds
    })
  }

  // Get checked-in players - memoized to prevent flashing on regeneration
  // Get players with updated state (counts and ratings) up to AND INCLUDING current round
  // Applies rating adjustments chronologically between rounds
  let playersWithCounts = React.useMemo(() => {
    // Always use toPlayerStateWithAdjustments to ensure round 0 adjustments (appliedAtRound = -1) are applied
    // Even on round 0, there may be rating adjustments that need to be applied
    // currentRoundInt is 1-indexed (round 1, 2, 3...)
    // When viewing round N, we want to include round N in the counts
    // Round N corresponds to rounds[N-1] (array index N-1)
    // So we need to process rounds [0, 1, ..., N-1]
    // Include adjustments up to current round (appliedAtRound < currentRoundInt)
    let adjustmentsUpToCurrent =
      ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound < currentRoundInt)
    rounds
    ->Array.slice(~start=0, ~end=currentRoundInt)
    ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrent)
  }, (rounds, currentRoundInt, ratingAdjustmentHistory, players))

  // Filter to only checked-in players with their updated ratings
  let checkedInPlayers = React.useMemo2(() => {
    playersWithCounts->Array.filter(p => checkedInPlayerIds->Set.has(p.id))
  }, (playersWithCounts, checkedInPlayerIds))

  // Build players cache for quick lookup using playersWithCounts (with updated counts)
  let playersCache = React.useMemo1(() => {
    playersWithCounts->Array.map(p => (p.id, p))->Js.Dict.fromArray
  }, [playersWithCounts])

  // === EVENT HANDLERS ===

  // Handle resetting a round - regenerates matches for specified round
  let handleResetRound = (roundIndex: int, ~genderMixed: bool=false) => {
    // Get player state from matches BEFORE the round being reset (previous rounds only)
    // BUT include rating adjustments FOR the current round (these are applied before the round starts)
    // Example: resetting round 2 (roundIndex=1) uses:
    //   - Match history from rounds 0 only (before round 1)
    //   - Rating adjustments with appliedAtRound <= 1 (seed adjustments + adjustments for round 1)
    let adjustmentsUpToCurrentRound =
      ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound <= roundIndex)
    let playersForReset =
      rounds
      ->Array.slice(~start=0, ~end=roundIndex)
      ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrentRound)
      ->Array.filter(p => checkedInPlayerIds->Set.has(p.id))

    // Solver-aware: dispatches to the ILP for the beta presets and to the
    // greedy engine for everything else (and as a fallback). Async, so show
    // the same pending state as generation; the token keeps a stale full
    // generation from clobbering the reset (and vice versa).
    let token = beginGeneration()
    setIsGenerating(_ => true)
    SolverRounds.generateSingleRound(
      ~roundIndex,
      ~rounds,
      ~availablePlayers=playersForReset,
      ~strategy,
      ~courtCount,
      ~startTime=eventStartTime,
      ~weightConfig?,
      ~teamConstraints?,
      ~avoidAllPlayers,
      ~genderMixed,
      // Reset restores the canonical round for the current seed, strategy and
      // state: idempotent until a score, roster change or edit moves the
      // inputs. A different deal is the dice button's job.
      ~seed=generationSeed,
      (),
    )
    ->Promise.thenResolve(outcome =>
      if isLatestGeneration(token) {
        outcome->Option.forEach(outcome => {
          setAndSaveSolverMatchViolations(prev => {
            let merged = Js.Dict.fromArray(prev->Js.Dict.entries)
            outcome.matchViolations
            ->Js.Dict.entries
            ->Array.forEach(((id, reasons)) => merged->Js.Dict.set(id, reasons))
            merged
          })
          setAndSaveSolverRoundViolations(prev => {
            let merged = Js.Dict.fromArray(prev->Js.Dict.entries)
            merged->Js.Dict.set(roundIndex->Int.toString, outcome.roundViolations)
            merged
          })
          updateRounds(rounds =>
            rounds->Array.mapWithIndex((round, idx) => idx == roundIndex ? outcome.matches : round)
          )
        })
      }
    )
    ->Promise.catch(err => {
      Js.Console.error2("[EventManager] round reset failed:", err)
      Promise.resolve()
    })
    ->Promise.finally(() =>
      if isLatestGeneration(token) {
        setIsGenerating(_ => false)
      }
    )
    ->ignore
  }

  // Function to save adjusted player seeds
  // Takes an array of (playerId, adjustedMu) tuples from SeedAdjustModal
  // Creates new adjustment entries with current round and timestamp, overwrites existing adjustments for same player at same round
  let adjustPlayerSeeds = (sortedPlayers: array<(string, float)>) => {
    setRatingAdjustmentHistory(prevHistory => {
      // Build a map of original mu values for all players
      let originalMuMap =
        checkedInPlayers
        ->Array.map(p => (p.id, p.rating.mu))
        ->Js.Dict.fromArray

      let targetRound = currentRoundInt - 1 // Convert to 0-indexed roundIndex (-1 when on round 0)

      // Create new adjustment entries for players with changed ratings
      let timestamp = Js.Date.now()
      let newAdjustments = []
      let adjustedPlayerIds = Set.make()

      sortedPlayers->Array.forEach(((playerId, adjustedMu)) => {
        originalMuMap
        ->Js.Dict.get(playerId)
        ->Option.forEach(
          originalMu => {
            let differential = adjustedMu -. originalMu
            if differential != 0.0 {
              adjustedPlayerIds->Set.add(playerId)->ignore
              newAdjustments
              ->Array.push({
                RatingAdjustment.playerId,
                differential,
                appliedAtRound: targetRound,
                timestamp,
              })
              ->ignore
            }
          },
        )
      })

      // Remove any existing adjustments for the same players at the same round
      // Keep all other adjustments (different rounds or different players)
      let filteredHistory =
        prevHistory->Array.filter(adj =>
          !(adj.appliedAtRound == targetRound && adjustedPlayerIds->Set.has(adj.playerId))
        )

      // Append new adjustments to filtered history
      let updatedHistory = Array.concat(filteredHistory, newAdjustments)

      // Persist to TinyBase
      EventManagerPersistence.saveRatingAdjustmentHistory(data.id, updatedHistory)

      // Mark as dirty to trigger regeneration prompt
      setIsDirty(_ => true)
      bumpHistoryRevision()

      updatedHistory
    })
  }

  // Handle match completion - update the match with score in current round
  let handleMatchCompleted = (matchId: string, completedMatch: CompletedMatch.t<'a>) => {
    let (match, score) = completedMatch

    // A recorded score moves ratings, so the future rounds are now stale.
    // Whether that triggers a rebuild is the effect's call, not ours.
    if score->Option.isSome {
      bumpHistoryRevision()
      switch strategy {
      | CompetitivePlus | Competitive | Mixed => setIsDirty(_ => true)
      | _ => ()
      }
    }

    updateRounds(rounds => {
      let updated = rounds->Array.map(round => {
        // Check if this round contains the match
        let hasMatch = round->Array.some(m => m.id == matchId)
        if hasMatch {
          // Update match with score
          round->Array.map(
            m => {
              if m.id == matchId {
                // If score is being set for the first time (was None, now Some), update createdAt
                let shouldUpdateCreatedAt = m.score->Option.isNone && score->Option.isSome
                let updatedCreatedAt = shouldUpdateCreatedAt ? Js.Date.make() : m.createdAt
                Js.log("Setting createdAt")
                Js.log(updatedCreatedAt)
                {...m, match, score, createdAt: updatedCreatedAt, synced: false}
              } else {
                m
              }
            },
          )
        } else {
          round
        }
      })
      updated
    })
  }

  // Handle match cancellation - remove from any round
  let handleMatchCanceled = (matchId: string) => {
    updateRounds(rounds => {
      rounds->Array.mapWithIndex((round, _) => {
        // Check if this round contains the match to delete
        let hasMatch = round->Array.some(m => m.id == matchId)
        if hasMatch {
          // Only mark as dirty if deleting from current or previous rounds
          // (not future rounds, as those don't affect player states yet)
          setIsDirty(_ => true)
          bumpHistoryRevision()
          round->Array.filter(m => m.id != matchId)
        } else {
          round
        }
      })
    })
  }

  // Toggle player check-in
  let handleToggleCheckin = (playerId: string) => {
    setIsDirty(_ => true)
    setCheckedInPlayerIds(prev => {
      let newSet = Set.fromArray(prev->Set.values->Array.fromIterator)
      if prev->Set.has(playerId) {
        newSet->Set.delete(playerId)->ignore
      } else {
        newSet->Set.add(playerId)->ignore
      }
      // Persist to TinyBase
      let playerIdsArray = newSet->Set.values->Array.fromIterator
      EventManagerPersistence.saveCheckedInPlayerIds(data.id, playerIdsArray)
      newSet
    })
  }

  // Handle rebalancing a specific round with its current players
  let handleRebalanceRound = (roundIndex: int) => {
    // Get player IDs from the current round only
    let currentRoundPlayerIds: Set.t<string> =
      rounds
      ->Array.get(roundIndex)
      ->Option.map(roundMatches =>
        roundMatches
        ->Array.flatMap(({match: m}) => Match.players(m))
        ->Array.map(p => p.id)
        ->Set.fromArray
      )
      ->Option.getOr(Set.make())

    // Get player state up to (but not including) this round in terms of play counts
    // But include rating adjustments for this round
    let adjustmentsUpToCurrentRound =
      ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound <= roundIndex)
    let playersBeforeRound =
      rounds
      ->Array.slice(~start=0, ~end=roundIndex)
      ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrentRound)

    // Filter to only the players who were in this round
    let currentRoundPlayers =
      playersBeforeRound->Array.filter(p => currentRoundPlayerIds->Set.has(p.id))

    // Re-draw the same participants with the *selected* strategy (this used to
    // hardcode CompetitivePlus). A rebalance is a deliberate "deal me a
    // different arrangement", so the seed varies per press rather than
    // reproducing the round that was just rejected.
    SolverRounds.generateSingleRound(
      ~roundIndex,
      ~rounds,
      ~availablePlayers=currentRoundPlayers,
      ~strategy,
      ~courtCount,
      ~startTime=eventStartTime,
      ~weightConfig?,
      ~teamConstraints?,
      ~avoidAllPlayers,
      ~seed=data.id ++
      ":rebalance:" ++
      roundIndex->Int.toString ++
      ":" ++
      Js.Date.now()->Float.toString,
      (),
    )
    ->Promise.thenResolve(outcome =>
      outcome->Option.forEach(outcome => {
        setAndSaveSolverMatchViolations(prev => {
          let merged = Js.Dict.fromArray(prev->Js.Dict.entries)
          outcome.matchViolations
          ->Js.Dict.entries
          ->Array.forEach(((id, reasons)) => merged->Js.Dict.set(id, reasons))
          merged
        })
        setAndSaveSolverRoundViolations(prev => {
          let merged = Js.Dict.fromArray(prev->Js.Dict.entries)
          merged->Js.Dict.set(roundIndex->Int.toString, outcome.roundViolations)
          merged
        })
        updateRounds(rounds =>
          rounds->Array.mapWithIndex((round, idx) => idx == roundIndex ? outcome.matches : round)
        )
      })
    )
    ->Promise.catch(err => {
      Js.Console.error2("[EventManager] round rebalance failed:", err)
      Promise.resolve()
    })
    ->ignore
  }

  let handleRebalanceMatch = (roundIndex: int, matchId: string) => {
    // Get the specific match to rebalance
    rounds
    ->Array.get(roundIndex)
    ->Option.flatMap(roundMatches => roundMatches->Array.find(({id}) => id == matchId))
    ->Option.forEach(({match}) => {
      // Get players from this match only
      let matchPlayers = Match.players(match)
      let matchPlayerIds = matchPlayers->Array.map(p => p.id)->Set.fromArray

      // Get player state up to (but not including) this round
      let adjustmentsUpToCurrentRound =
        ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound <= roundIndex)
      let playersBeforeRound =
        rounds
        ->Array.slice(~start=0, ~end=roundIndex)
        ->toPlayerStateWithAdjustments(~players, ~adjustments=adjustmentsUpToCurrentRound)

      // Filter to only the players in this match
      let matchPlayersWithState =
        playersBeforeRound->Array.filter(p => matchPlayerIds->Set.has(p.id))

      // Re-pair just these four players with the selected strategy. A 4-player
      // "round" on one court has exactly three pairings; the solver picks the
      // best under the current weights, with a fresh seed per press.
      SolverRounds.generateSingleRound(
        ~roundIndex,
        ~rounds,
        ~availablePlayers=matchPlayersWithState,
        ~strategy,
        ~courtCount=1, // Only one match
        ~startTime=eventStartTime,
        ~weightConfig?,
        ~teamConstraints?,
        ~avoidAllPlayers=[],
        ~seed=data.id ++ ":rebalance:" ++ matchId ++ ":" ++ Js.Date.now()->Float.toString,
        (),
      )
      ->Promise.thenResolve(outcome =>
        outcome
        ->Option.flatMap(outcome => outcome.matches->Array.get(0)->Option.map(m => (outcome, m)))
        ->Option.forEach(((outcome, newMatchEntity)) => {
          // The entity id is retained (scores and UI state hang off it), so any
          // violation reported under the freshly generated id is re-keyed.
          setAndSaveSolverMatchViolations(prev => {
            let merged =
              prev
              ->Js.Dict.entries
              ->Array.filter(((id, _)) => id != matchId)
              ->Js.Dict.fromArray
            switch outcome.matchViolations->Js.Dict.get(newMatchEntity.id) {
            | Some(reasons) => merged->Js.Dict.set(matchId, reasons)
            | None => ()
            }
            merged
          })
          updateRounds(
            rounds => {
              rounds->Array.mapWithIndex(
                (round, idx) => {
                  if idx == roundIndex {
                    round->Array.map(
                      matchEntity => {
                        if matchEntity.id == matchId {
                          // Keep the same ID and score, just update the match
                          {...matchEntity, match: newMatchEntity.match, synced: false}
                        } else {
                          matchEntity
                        }
                      },
                    )
                  } else {
                    round
                  }
                },
              )
            },
          )
        })
      )
      ->Promise.catch(err => {
        Js.Console.error2("[EventManager] match rebalance failed:", err)
        Promise.resolve()
      })
      ->ignore
    })
  }

  // Generate a block of rounds. Async because the solver strategies lazy-load
  // their wasm; the legacy strategies resolve immediately inside
  // `SolverRounds.generateRounds`, which delegates straight to the greedy
  // engine for them.
  let generateRoundBlock = async (
    ~startRoundIndex: int,
    ~completedRounds: array<array<completedMatchEntity<'a>>>,
    ~numberOfRounds: int,
  ) => {
    let result = await SolverRounds.generateRounds(
      ~numberOfRounds,
      ~availablePlayers=checkedInPlayers,
      ~completedRounds,
      ~strategy,
      ~courtCount,
      ~startTime=eventStartTime,
      ~weightConfig?,
      ~teamConstraints?,
      ~avoidAllPlayers,
      ~startRoundIndex,
      ~seed=generationSeed,
      (),
    )

    // Replace, rather than merge: violations describe the rounds that exist now.
    setAndSaveSolverMatchViolations(_ => SolverRounds.mergeViolations(result))
    setAndSaveSolverRoundViolations(_ => {
      let byRound = Js.Dict.empty()
      result.rounds->Array.forEachWithIndex((round, index) =>
        if round.roundViolations->Array.length > 0 {
          byRound->Js.Dict.set((startRoundIndex + index)->Int.toString, round.roundViolations)
        }
      )
      byRound
    })
    setSolverNoticeDismissed(_ => !result.fellBackToGreedy)

    result->SolverRounds.toRounds
  }

  // Handle draw generation
  let handleGenerateDraws = () => {
    let numberOfRoundsToGenerate = 10
    let token = beginGeneration()
    setIsGenerating(_ => true)

    let run = async () => {
      // Let the spinner reach the screen before the first (synchronous) solve.
      await SolverRounds.afterPaint()

      if rounds->Array.length == 0 || currentRoundInt == 0 {
        // Initial generation or regeneration from round 0: start from round 1.
        // When on round 0, playersWithCounts already includes round 0 adjustments
        // applied by toPlayerStateWithAdjustments.
        let pastAndCurrentRounds = rounds->Array.filterWithIndex((_, i) => i + 1 <= currentRoundInt)

        let newRounds = await generateRoundBlock(
          ~startRoundIndex=0,
          ~completedRounds=pastAndCurrentRounds,
          ~numberOfRounds=numberOfRoundsToGenerate,
        )
        if isLatestGeneration(token) {
          updateRounds(_ => newRounds)
          setCurrentRoundInt(_ => 1)
          EventManagerPersistence.saveCurrentRound(data.id, 1)

          // Clear rating adjustments for future rounds (round 1 and beyond)
          setRatingAdjustmentHistory(prevHistory => {
            let filteredHistory = prevHistory->Array.filter(adj => adj.appliedAtRound < 0)
            EventManagerPersistence.saveRatingAdjustmentHistory(data.id, filteredHistory)
            filteredHistory
          })

          setIsDirty(_ => false)
        }
      } else {
        // Regeneration: keep past/current rounds, replace future rounds.
        // checkedInPlayers already reflects state through the current round.
        let pastAndCurrentRounds = rounds->Array.filterWithIndex((_, i) => i + 1 <= currentRoundInt)

        let newRounds = await generateRoundBlock(
          ~startRoundIndex=currentRoundInt,
          ~completedRounds=pastAndCurrentRounds,
          ~numberOfRounds=numberOfRoundsToGenerate,
        )

        if isLatestGeneration(token) {
          updateRounds(_ => Array.concat(pastAndCurrentRounds, newRounds))

          // Clear rating adjustments for future rounds (currentRoundInt and beyond)
          setRatingAdjustmentHistory(prevHistory => {
            let filteredHistory = prevHistory->Array.filter(adj =>
              adj.appliedAtRound < currentRoundInt
            )
            EventManagerPersistence.saveRatingAdjustmentHistory(data.id, filteredHistory)
            filteredHistory
          })

          setIsDirty(_ => false)
        }
      }
    }

    run()
    ->Promise.catch(err => {
      Js.Console.error2("[EventManager] draw generation failed:", err)
      Promise.resolve()
    })
    ->Promise.finally(() =>
      if isLatestGeneration(token) {
        setIsGenerating(_ => false)
      }
    )
    ->ignore
  }

  // Auto-regenerate future rounds when recorded history changes — a score
  // entered, a match deleted, a seed adjusted.
  //
  // Keyed on `historyRevision` rather than `isDirty` on purpose: `isDirty` also
  // fires on settings changes, and regenerating there applied a newly picked
  // strategy before the user pressed "Update Rounds Below", leaving that button
  // with nothing left to do.
  //
  // Declared here rather than with the other effects because it needs the async
  // generator above.
  React.useEffect1(() => {
    if historyRevision > 0 && currentRoundInt > -1 {
      let shouldAutoRegenerate = switch strategy {
      // Skill-sensitive strategies: new scores move ratings, so the rounds
      // ahead are stale and worth rebuilding without being asked. All three
      // solver presets qualify — even Round Robin (SolverRoundRobin) breaks its
      // novelty ties competitively, and Random Balanced splits teams by
      // rating, so both read the ratings a score just moved.
      | CompetitivePlus
      | Competitive
      | Mixed
      | SolverRoundRobin
      | SolverRandomBalanced
      | SolverCompetitivePlus
      | SolverAuto => true
      // Pure-novelty strategies read partner and bye history, which a score
      // does not change.
      | RoundRobin | Random | DUPR | NoveltyRoundRobin => false
      }

      // Never clobber scores someone has already entered for a future round.
      if shouldAutoRegenerate && !futureRoundsHaveScores {
        Js.log("Auto-regenerating future rounds after current round changes")
        let token = beginGeneration()
        let pastAndCurrentRounds = rounds->Array.filterWithIndex((_, i) => i + 1 <= currentRoundInt)

        // On the solver path this is seconds of real work, so show the same
        // pending state a manual generation does rather than doing it silently.
        setIsGenerating(_ => true)

        // Wait for the frame carrying the score the user just picked to be
        // drawn. Otherwise their click appears to do nothing until the whole
        // regeneration finishes.
        SolverRounds.afterPaint()
        ->Promise.then(() =>
          generateRoundBlock(
            ~startRoundIndex=currentRoundInt,
            ~completedRounds=pastAndCurrentRounds,
            ~numberOfRounds=10,
          )
        )
        ->Promise.thenResolve(newRounds =>
          if isLatestGeneration(token) {
            updateRounds(_ => Array.concat(pastAndCurrentRounds, newRounds))
          }
        )
        ->Promise.catch(err => {
          Js.Console.error2("[EventManager] auto-regeneration failed:", err)
          Promise.resolve()
        })
        ->Promise.finally(() =>
          if isLatestGeneration(token) {
            setIsGenerating(_ => false)
          }
        )
        ->ignore

        setIsDirty(_ => false)
      }
    }
    None
  }, [historyRevision])

  // Handle court count change
  let handleCourtCountChange = (count: int) => {
    setCourtCount(_ => count)
    setIsDirty(_ => true)
    EventManagerPersistence.saveCourtCount(data.id, count)
  }

  // Handle strategy change
  let handleStrategyChange = (s: strategy) => {
    setStrategy(_ => s)
    setIsDirty(_ => true)
    EventManagerPersistence.saveStrategy(data.id, s)
    // Selecting a strategy means "use that strategy's tuned profile". A stored
    // config would override the profile with the slider mapping, so switching
    // clears any customisation rather than writing the nominal position.
    if s->isSolverStrategy {
      setWeightConfig(_ => None)
      EventManagerPersistence.clearWeightConfig(data.id)
    }
  }

  let handleWeightConfigChange = (config: CostModel.uiWeightConfig) => {
    setWeightConfig(_ => Some(config))
    setIsDirty(_ => true)
    EventManagerPersistence.saveWeightConfig(data.id, config)
  }

  // Back to the strategy's tuned preset (and, for Auto, the live blend).
  let handleWeightConfigReset = () => {
    setWeightConfig(_ => None)
    setIsDirty(_ => true)
    EventManagerPersistence.clearWeightConfig(data.id)
  }

  // Effective config shown by the weight panel: the stored override, or the
  // current strategy's preset.
  let effectiveWeightConfig = switch weightConfig {
  | Some(config) => config
  | None => CostModel.presetConfig(strategy)
  }

  // Auto's live blend position, for the panel's display: computed from the
  // same rated player state generation uses, so the values shown are the
  // values the next draw will be built with. None once customised — a stored
  // config freezes the mix and the display follows the store instead.
  let autoBlendT =
    strategy == SolverAuto && weightConfig->Option.isNone
      ? Some(CostModel.autoT(CostModel.readinessRatio(checkedInPlayers)))
      : None

  // First solve of a session waits on the wasm download, which is worth calling
  // out; later ones are fast enough that a plain spinner reads better.
  let generatingLabel = HighsBindings.isLoaded()
    ? ts`Generating…`
    : ts`Preparing optimizer…`

  // Handle advance to next round
  let handleAdvanceRound = () => {
    if currentRoundInt < rounds->Array.length {
      let newRoundInt = currentRoundInt + 1
      setCurrentRoundInt(_ => newRoundInt)
      EventManagerPersistence.saveCurrentRound(data.id, newRoundInt)
    }
  }

  // Handle go to previous round
  let handlePreviousRound = () => {
    if currentRoundInt > 0 {
      let newRoundInt = currentRoundInt - 1
      setCurrentRoundInt(_ => newRoundInt)
      EventManagerPersistence.saveCurrentRound(data.id, newRoundInt)
    }
  }

  // Handle sync scores - submit all completed matches to server
  let handleSyncScores = async () => {
    setSyncState(_ => Syncing)
    setSyncProgress(_ => 0)

    // Get activity slug
    let activitySlug = data.activity->Option.flatMap(a => a.slug)

    switch activitySlug {
    | None => {
        Js.log("No activity slug found, cannot sync scores")
        setSyncState(_ => Error)
      }
    | Some(slug) => {
        // Collect only unsynced matches with scores from all rounds
        let matchesWithScores =
          rounds
          ->Array.flatMap(round => round)
          ->Array.filterMap(({id, match, score, createdAt, synced}) => {
            if synced {
              None
            } else {
              score->Option.map(scoreValue => (id, match, scoreValue, createdAt))
            }
          })

        let totalMatches = matchesWithScores->Array.length

        if totalMatches == 0 {
          Js.log("No unsynced scored matches to sync")
          setSyncState(_ => Success)
        } else {
          // Submit matches with 500ms delay between each
          let results = []
          for i in 0 to totalMatches - 1 {
            let (matchId, match, scoreValue, createdAt) = matchesWithScores->Array.getUnsafe(i)

            try {
              await submitMatch(match, scoreValue, slug, matchId, createdAt)
              results->Array.push(Ok())->ignore
              let progress = Float.fromInt(i + 1) /. Float.fromInt(totalMatches) *. 100.
              setSyncProgress(_ => progress->Float.toInt)
              // 500ms delay between submissions
              await Promise.make((resolve, _) => {
                let _ = setTimeout(() => resolve(), 500)
              })
            } catch {
            | error => {
                Js.log2("Error syncing match:", error)
                results->Array.push(Error())->ignore
              }
            }
          }

          // Check if all succeeded
          let allSucceeded = results->Array.every(result =>
            switch result {
            | Ok() => true
            | Error() => false
            }
          )

          if allSucceeded {
            // Mark all scored matches as synced
            updateRounds(currentRounds =>
              currentRounds->Array.map(round =>
                round->Array.map(
                  m =>
                    if m.score->Option.isSome {
                      {...m, synced: true}
                    } else {
                      m
                    },
                )
              )
            )
          }

          setSyncState(_ => allSucceeded ? Success : Error)
        }
      }
    }
  }

  // Can go back if not on round 0
  let canGoBack = currentRoundInt > 0

  // Can advance if there are more rounds
  let canAdvance = currentRoundInt < rounds->Array.length

  // Helper to extract user fragmentRefs from rsvpNode
  let getUserFragmentRefs = (rsvpNode: rsvpNode) => {
    rsvpNode.user->Option.map(user => user.fragmentRefs)
  }

  let hasExistingDraws = rounds->Array.length > 0

  // The one clear in this component, reached from the quota banner, the
  // storage-low warning and the debug Reset Storage button. It drops every event
  // on the device, so it only ever runs after ClearAllStorageModal is confirmed.
  // Afterwards it re-tests persistence, so a banner raised by a full disk clears
  // itself once space is free.
  let handleClearAllStorage = () => {
    // Empties the store, drops the IndexedDB database and brings persistence
    // back up against a fresh one — which also re-tests writability, so a quota
    // failure clears itself once the space is free.
    EventManagerPersistence.clearAllEventData()->ignore

    // This event's rows are gone too, so return the screen to its initial state.
    setRounds(_ => [])
    setCurrentRoundInt(_ => 0)
    setCourtCount(_ => suggestedCourtCount(players->Array.length))
    setCheckedInPlayerIds(_ => Set.make())
    setRatingAdjustmentHistory(_ => [])
    setIsDirty(_ => false)
    setTeams(_ => NonEmptyArray.empty)
    setAntiTeams(_ => NonEmptyArray.empty)
    setPlayerOverrides(_ => Js.Dict.empty())

    setShowClearAllStorage(_ => false)
  }

  // Handle delete rating adjustment - removes adjustment from history and triggers recalculation
  let handleDeleteAdjustment = (timestamp: float) => {
    setRatingAdjustmentHistory(prevHistory => {
      let updatedHistory = prevHistory->Array.filter(adj => adj.timestamp != timestamp)

      // Persist to TinyBase
      EventManagerPersistence.saveRatingAdjustmentHistory(data.id, updatedHistory)

      // Mark as dirty to trigger regeneration prompt
      setIsDirty(_ => true)
      bumpHistoryRevision()

      updatedHistory
    })
  }

  // Internal function to update player overrides
  let updatePlayerOverrides = (updatedPlayer: Player.t<rsvpNode>) => {
    // Find the original player to check if gender changed
    let originalPlayer = playersWithCounts->Array.find(p => p.id == updatedPlayer.id)
    let genderChanged =
      originalPlayer->Option.mapOr(false, original => original.gender != updatedPlayer.gender)

    // Save player overrides to TinyBase
    EventManagerPersistence.savePlayerOverride(
      data.id,
      updatedPlayer.id,
      updatedPlayer.name,
      updatedPlayer.gender,
      updatedPlayer.paid,
    )

    // Update player overrides state to trigger re-render
    setPlayerOverrides(prev => {
      let updated = Js.Dict.empty()
      prev->Js.Dict.entries->Array.forEach(((k, v)) => updated->Js.Dict.set(k, v))
      updated->Js.Dict.set(
        updatedPlayer.id,
        {
          EventManagerPersistence.playerId: updatedPlayer.id,
          name: Some(updatedPlayer.name),
          gender: Some(updatedPlayer.gender),
          paid: Some(updatedPlayer.paid),
        },
      )
      updated
    })

    // Mark as dirty only if gender changed
    // Gender changes affect match generation (e.g., for gender-mixed doubles)
    if genderChanged {
      setIsDirty(_ => true)
    }
  }

  // Handle updating a player's settings from modal
  let handleUpdatePlayer = (updatedPlayer: Player.t<rsvpNode>) => {
    updatePlayerOverrides(updatedPlayer)
    // Close modal
    setPlayerSettingsOpen(_ => None)
  }

  // Handle toggling a player's paid status
  let handleTogglePaid = (playerId: string) => {
    // Find the player and toggle their paid status
    playersWithCounts->Array.forEach(player => {
      if player.id == playerId {
        let updatedPlayer = {...player, paid: !player.paid}
        updatePlayerOverrides(updatedPlayer)
      }
    })
  }

  // Handle adding guest players from the modal
  let handleAddGuestPlayers = (names: array<string>) => {
    // Create guest players with unique IDs starting from nextGuestId
    let newGuests = names->Array.mapWithIndex((name, index) => {
      let guestId = nextGuestId + index
      Player.makeDefaultRatingPlayer(name, Gender.Male, guestId)
    })

    // Add new guests to existing guest players
    let updatedGuestPlayers = guestPlayers->Array.concat(newGuests)
    setGuestPlayers(_ => updatedGuestPlayers)

    // Update next guest ID
    setNextGuestId(prev => prev + names->Array.length)

    // Auto check-in the new guest players
    setCheckedInPlayerIds(prev => {
      let newSet = Set.fromArray(prev->Set.values->Array.fromIterator)
      newGuests->Array.forEach(guest => {
        newSet->Set.add(guest.id)->ignore
      })
      newSet
    })

    // Save to TinyBase
    EventManagerPersistence.saveGuestPlayers(data.id, updatedGuestPlayers)

    // Save updated checked-in IDs
    let updatedCheckedInIds = checkedInPlayerIds->Set.values->Array.fromIterator
    let newGuestIds = newGuests->Array.map(g => g.id)
    EventManagerPersistence.saveCheckedInPlayerIds(
      data.id,
      updatedCheckedInIds->Array.concat(newGuestIds),
    )

    // Close modal
    setShowAddGuestsModal(_ => false)
  }

  // Handle deleting a guest player
  let handleDeleteGuestPlayer = (playerId: string) => {
    // Remove from guest players
    let updatedGuestPlayers = guestPlayers->Array.filter(p => p.id != playerId)
    setGuestPlayers(_ => updatedGuestPlayers)

    // Remove from checked-in players if present
    setCheckedInPlayerIds(prev => {
      let newSet = Set.fromArray(prev->Set.values->Array.fromIterator)
      newSet->Set.delete(playerId)->ignore
      newSet
    })

    // Remove from teams if present
    let updatedTeams =
      teams
      ->NonEmptyArray.toArray
      ->Array.map(team => team->Array.filter(p => p.id != playerId))
      ->Array.filter(team => team->Array.length > 0)
    if updatedTeams->Array.length > 0 {
      setTeams(_ => updatedTeams->NonEmptyArray.fromArray)
      EventManagerPersistence.saveTeams(data.id, updatedTeams)
    } else {
      setTeams(_ => None)
      EventManagerPersistence.saveTeams(data.id, [])
    }

    // Remove from anti-teams if present
    let updatedAntiTeams =
      antiTeams
      ->NonEmptyArray.toArray
      ->Array.map(team => team->Array.filter(p => p.id != playerId))
      ->Array.filter(team => team->Array.length > 0)
    if updatedAntiTeams->Array.length > 0 {
      setAntiTeams(_ => updatedAntiTeams->NonEmptyArray.fromArray)
      EventManagerPersistence.saveAntiTeams(data.id, updatedAntiTeams)
    } else {
      setAntiTeams(_ => None)
      EventManagerPersistence.saveAntiTeams(data.id, [])
    }

    // Save to TinyBase
    EventManagerPersistence.saveGuestPlayers(data.id, updatedGuestPlayers)
    EventManagerPersistence.saveCheckedInPlayerIds(
      data.id,
      checkedInPlayerIds->Set.values->Array.fromIterator->Array.filter(id => id != playerId),
    )

    // Mark as dirty to trigger regeneration
    setIsDirty(_ => true)
  }

  // Convert teams from NonEmptyArray to TeamManagementModal.teamData format
  let teamsAsData: array<TeamManagementModal.teamData> =
    teams
    ->NonEmptyArray.toArray
    ->Array.mapWithIndex((team, index) => {
      {
        TeamManagementModal.id: index,
        name: ts`Team ${(index + 1)->Int.toString}`,
        playerIds: team->Array.map(p => p.id),
      }
    })

  // === RENDER ===

  <>
    {teamManagementOpen
      ? <TeamManagementModal
          teams={teamsAsData}
          antiTeams={antiTeams
          ->NonEmptyArray.toArray
          ->Array.mapWithIndex((team, index) => {
            {
              TeamManagementModal.id: index,
              name: ts`Anti-Team ${(index + 1)->Int.toString}`,
              playerIds: team->Array.map(p => p.id),
            }
          })}
          players={playersWithCounts}
          onSave={(updatedTeams, updatedAntiTeams) => {
            // Handle Teams
            let newTeams = updatedTeams->Array.filterMap(teamData => {
              let teamPlayers =
                teamData.playerIds->Array.filterMap(id =>
                  playersWithCounts->Array.find(p => p.id == id)
                )

              if teamPlayers->Array.length > 0 {
                Some(teamPlayers)
              } else {
                None
              }
            })

            setTeams(_ => newTeams->NonEmptyArray.fromArray)
            EventManagerPersistence.saveTeams(data.id, newTeams)

            // Handle Anti-Teams
            let newAntiTeams = updatedAntiTeams->Array.filterMap(teamData => {
              let teamPlayers =
                teamData.playerIds->Array.filterMap(id =>
                  playersWithCounts->Array.find(p => p.id == id)
                )

              if teamPlayers->Array.length > 0 {
                Some(teamPlayers)
              } else {
                None
              }
            })

            setAntiTeams(_ => newAntiTeams->NonEmptyArray.fromArray)
            EventManagerPersistence.saveAntiTeams(data.id, newAntiTeams)

            setTeamManagementOpen(_ => false)
            setIsDirty(_ => true)
          }}
          onClose={() => setTeamManagementOpen(_ => false)}
        />
      : React.null}
    {playerSettingsOpen
    ->Option.map((player: Player.t<rsvpNode>) => {
      // Check if this is a guest player (no data means it's a guest)
      let isGuest = player.data->Option.isNone
      if isGuest {
        <PlayerSettingsModal
          player
          onSave={handleUpdatePlayer}
          onClose={() => setPlayerSettingsOpen(_ => None)}
          onDelete={() => handleDeleteGuestPlayer(player.id)}
        />
      } else {
        <PlayerSettingsModal
          player onSave={handleUpdatePlayer} onClose={() => setPlayerSettingsOpen(_ => None)}
        />
      }
    })
    ->Option.getOr(React.null)}
    {showAddGuestsModal
      ? <AddGuestPlayersModal
          onAdd={handleAddGuestPlayers} onClose={() => setShowAddGuestsModal(_ => false)}
        />
      : React.null}
    <FramerMotion.AnimatePresence mode="sync">
      {showFullScreenRound
        ? {
            let currentRoundMatches = rounds->Array.get(currentRoundInt - 1)->Option.getOr([])
            <FullScreenRoundView
              key="fullscreen-round-view"
              matches={currentRoundMatches}
              roundNumber={currentRoundInt}
              onClose={() => setShowFullScreenRound(_ => false)}
              getUserFragmentRefs={data => data.user->Option.map(u => u.fragmentRefs)}
            />
          }
        : React.null}
    </FramerMotion.AnimatePresence>
    {switch (seedSource, clubRatingSource) {
    | (EventManagerPersistence.ClubRatings, Some((clubId, _, activitySlug))) =>
      <React.Suspense fallback={React.null}>
        <ClubRatingsLoader
          eventId={data.id}
          clubId
          activitySlug
          onLoaded={ratings => setClubRatings(_ => Some(ratings->Js.Dict.fromArray))}
        />
      </React.Suspense>
    | _ => React.null
    }}
    <StorageLowWarning onClearData={() => setShowClearAllStorage(_ => true)} />
    {showClearAllStorage
      ? <ClearAllStorageModal
          currentEventId={data.id}
          onConfirm={handleClearAllStorage}
          onCancel={() => setShowClearAllStorage(_ => false)}
        />
      : React.null}
    <div className="min-h-screen bg-slate-50 flex flex-col">
      <div className="bg-slate-800 text-white px-6 py-4">
        // The title is dead weight on a phone — the controls beside it are what
        // an organiser actually reaches for mid-event. Hiding it leaves only one
        // child in the row, so switch to justify-end there or the controls would
        // jump to the left edge.
        <div className="flex items-center justify-end sm:justify-between">
          <h1 className="hidden sm:block text-2xl font-bold"> {t`Sports Event Draws`} </h1>
          <div className="flex items-center gap-2">
            <PersistenceChip
              health={persistenceHealth} onShowError={() => setDismissedFailure(_ => None)}
            />
            {debugMode
              ? <>
                  <StorageUsageDebug />
                  <button
                    onClick={_ => setShowClearAllStorage(_ => true)}
                    className="px-3 py-1 text-sm font-semibold rounded bg-red-600 hover:bg-red-700 transition-colors">
                    {t`Reset Storage`}
                  </button>
                </>
              : React.null}
            <Link
              to="/event-manager-guide"
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 transition-colors text-white no-underline">
              <Lucide.CircleHelp className="w-5 h-5" />
              <span className="text-sm font-medium"> {t`Help`} </span>
            </Link>
            <button
              onClick={_ => setDebugMode(prev => !prev)}
              className="flex items-center gap-2 px-4 py-2 rounded-lg bg-slate-700 hover:bg-slate-600 transition-colors">
              <Lucide.CircleHelp className="w-5 h-5" />
              <span className="text-sm font-medium">
                {debugMode ? t`Debug: ON` : t`Debug: OFF`}
              </span>
            </button>
          </div>
        </div>
      </div>
      {switch visibleFailure {
      | Some(failure) =>
        <PersistenceErrorBanner
          failure
          onRetry={() => EventManagerPersistence.retry()->ignore}
          onFreeUpSpace={() => setShowClearAllStorage(_ => true)}
          onDismiss={() => setDismissedFailure(_ => Some(failure->snd))}
        />
      | None => React.null
      }}
      <PlayerCheckin
        players={playersWithCounts}
        checkedInPlayerIds
        onToggleCheckin={handleToggleCheckin}
        onTogglePaid={handleTogglePaid}
        onAdjustSeeds={adjustPlayerSeeds}
        onOpenTeamManagement={() => setTeamManagementOpen(_ => true)}
        onOpenPlayerSettings={player => setPlayerSettingsOpen(_ => Some(player))}
        onOpenAddGuests={() => setShowAddGuestsModal(_ => true)}
        getUserFragmentRefs
        initialPlayers={players}
        eventUrl={"https://www.pkuru.com/events/" ++ eventId}
        seedSourceOption=?{clubRatingSource->Option.map(((_, clubName, _)) => {
          SeedAdjustModal.clubName,
          usingClubRatings: seedSource == EventManagerPersistence.ClubRatings,
          isLoading: seedSource == EventManagerPersistence.ClubRatings &&
            clubRatings->Option.isNone,
          onUseClubRatings: useClub => {
            let next =
              useClub
                ? EventManagerPersistence.ClubRatings
                : EventManagerPersistence.GlobalRatings
            setSeedSource(_ => next)
            EventManagerPersistence.saveSeedSource(data.id, next)
            // Ratings move, so any draws built on the old pool are stale.
            setIsDirty(_ => true)
            bumpHistoryRevision()
          },
        })}
      />
      {!hasExistingDraws
        ? <>
            <DrawGenerator
              courtCount
              onCourtCountChange={handleCourtCountChange}
              checkedInPlayerCount={checkedInPlayerIds->Set.size}
              hasExistingDraws={false}
              strategy
              onStrategyChange={handleStrategyChange}
              onGenerateDraws={handleGenerateDraws}
              weightConfig={effectiveWeightConfig}
              weightConfigIsCustom={weightConfig->Option.isSome}
              autoBlendT=?{autoBlendT}
              onWeightConfigChange={handleWeightConfigChange}
              onWeightConfigReset={handleWeightConfigReset}
              drawSeed
              onNewSeed={handleNewSeed}
              isGenerating
              generatingLabel={generatingLabel}
              isInitiallyExpanded={true}
              highlight={isDirty}
              futureRoundsHaveScores
            />
          </>
        : React.null}
      {hasExistingDraws
        ? <>
            <RoundHeader
              currentRound={currentRoundInt}
              onAdvanceRound={handleAdvanceRound}
              onPreviousRound={handlePreviousRound}
              canAdvance
              canGoBack
            />
            <div className="flex-1 overflow-auto p-6">
              {debugMode && rounds->Array.length > 0
                ? <OverallAverageQualityDebug rounds />
                : React.null}
              {currentRoundInt == 0
                ? <DrawGenerator
                    courtCount
                    onCourtCountChange={handleCourtCountChange}
                    checkedInPlayerCount={checkedInPlayerIds->Set.size}
                    hasExistingDraws={rounds->Array.length > 0}
                    strategy
                    onStrategyChange={handleStrategyChange}
                    onGenerateDraws={handleGenerateDraws}
                    weightConfig={effectiveWeightConfig}
                    weightConfigIsCustom={weightConfig->Option.isSome}
                    autoBlendT=?{autoBlendT}
                    onWeightConfigChange={handleWeightConfigChange}
                    onWeightConfigReset={handleWeightConfigReset}
                    drawSeed
                    onNewSeed={handleNewSeed}
                    isGenerating
                    generatingLabel={generatingLabel}
                    isInitiallyExpanded={true}
                    highlight={isDirty}
                    futureRoundsHaveScores
                  />
                : React.null}
              {
                // Display rating adjustments for round 0 (appliedAtRound = -1)
                // These are adjustments made before any rounds are generated
                let adjustmentsForRound0 =
                  ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound == -1)

                if adjustmentsForRound0->Array.length > 0 {
                  <SeedAdjustmentTimeline
                    adjustments={adjustmentsForRound0}
                    playersCache
                    getUserFragmentRefs={data => data.user->Option.map(u => u.fragmentRefs)}
                    onDelete={() => {
                      // Delete all adjustments with the same timestamp (same batch)
                      adjustmentsForRound0
                      ->Array.get(0)
                      ->Option.forEach(adj => handleDeleteAdjustment(adj.timestamp))
                    }}
                  />
                } else {
                  React.null
                }
              }
              {solverNoticeDismissed
                ? React.null
                : <div
                    className="mb-4 flex items-start gap-3 rounded-lg border border-slate-300 bg-slate-100 px-4 py-3 text-sm text-slate-700">
                    <Lucide.AlertTriangle className="w-4 h-4 mt-0.5 shrink-0" />
                    <span className="flex-1">
                      {(ts`Optimizer unavailable — used standard matchmaking for this draw.`)
                        ->React.string}
                    </span>
                    <button
                      onClick={_ => setSolverNoticeDismissed(_ => true)}
                      className="text-xs font-medium text-slate-500 hover:text-slate-900">
                      {(ts`Dismiss`)->React.string}
                    </button>
                  </div>}
              {rounds
              ->Array.mapWithIndex((roundMatches, roundIndex) => {
                let roundNum = roundIndex + 1
                let isCurrentRound = roundNum == currentRoundInt
                let isPastRound = roundNum < currentRoundInt

                // Get adjustments that should be applied before this round
                // appliedAtRound is 0-indexed (matches roundIndex)
                let adjustmentsForRound =
                  ratingAdjustmentHistory->Array.filter(adj => adj.appliedAtRound == roundIndex)

                <React.Fragment key={roundNum->Int.toString}>
                  // Display rating adjustments that apply at this round (before the round)
                  {if adjustmentsForRound->Array.length > 0 {
                    <SeedAdjustmentTimeline
                      adjustments={adjustmentsForRound}
                      playersCache
                      getUserFragmentRefs={data => data.user->Option.map(u => u.fragmentRefs)}
                      onDelete={() => {
                        // Delete all adjustments with the same timestamp (same batch)
                        adjustmentsForRound
                        ->Array.get(0)
                        ->Option.forEach(adj => handleDeleteAdjustment(adj.timestamp))
                      }}
                    />
                  } else {
                    React.null
                  }}
                  <SolverWarnings
                    matches={roundMatches}
                    matchViolations={solverMatchViolations}
                    roundViolations={solverRoundViolations
                    ->Js.Dict.get(roundIndex->Int.toString)
                    ->Option.getOr([])}
                    playersCache
                  />
                  {isCurrentRound
                    ? <div ref={currentRoundRef->ReactDOM.Ref.domRef}>
                        <RoundSection
                          matches={roundMatches}
                          roundNumber={roundNum}
                          isCurrentRound
                          isPastRound
                          playersCache
                          checkedInPlayerIds
                          handleMatchCanceled={matchId => handleMatchCanceled(matchId)}
                          handleMatchUpdated={(completedMatch, matchId) =>
                            handleMatchCompleted(matchId, completedMatch)}
                          setMatches={updateFn => {
                            updateRounds(rounds => {
                              rounds->Array.mapWithIndex(
                                (round, idx) => {
                                  if idx == roundIndex {
                                    updateFn(round)
                                  } else {
                                    round
                                  }
                                },
                              )
                            })
                          }}
                          setQueue={_ => ()}
                          setRequiredPlayers={_ => ()}
                          setShowMatchSelector={_ => ()}
                          onRebalance={() => handleRebalanceRound(roundIndex)}
                          onRebalanceMatch={matchId => handleRebalanceMatch(roundIndex, matchId)}
                          onReset={genderMixed => handleResetRound(roundIndex, ~genderMixed)}
                          onFullScreen={() => setShowFullScreenRound(_ => true)}
                          getUserFragmentRefs
                          debug={debugMode}
                          allRounds={rounds}
                        />
                        // Advance Round Button - Below Current Round
                        {canAdvance
                          ? <div className="mt-6 flex justify-center">
                              <button
                                onClick={_ => {
                                  handleAdvanceRound()
                                  // Small delay to ensure state updates before scrolling
                                  let _ = setTimeout(() => {
                                    currentRoundRef.current
                                    ->Nullable.toOption
                                    ->Option.forEach(
                                      element => {
                                        element->scrollIntoView({
                                          "behavior": "smooth",
                                          "block": "center",
                                        })
                                      },
                                    )
                                  }, 100)
                                }}
                                className="flex items-center gap-3 px-8 py-4 rounded-xl font-bold text-lg bg-blue-600 text-white hover:bg-blue-700 transition-all shadow-lg hover:shadow-xl">
                                <span>
                                  {t`Advance to Round ${(currentRoundInt + 1)->Int.toString}`}
                                </span>
                                <Lucide.ChevronRight className="w-6 h-6" />
                              </button>
                            </div>
                          : React.null}
                      </div>
                    : <RoundSection
                        matches={roundMatches}
                        roundNumber={roundNum}
                        isCurrentRound
                        isPastRound
                        playersCache
                        checkedInPlayerIds
                        handleMatchCanceled={matchId => handleMatchCanceled(matchId)}
                        handleMatchUpdated={(completedMatch, matchId) =>
                          handleMatchCompleted(matchId, completedMatch)}
                        setMatches={updateFn => {
                          updateRounds(rounds => {
                            rounds->Array.mapWithIndex(
                              (round, idx) => {
                                if idx == roundIndex {
                                  updateFn(round)
                                } else {
                                  round
                                }
                              },
                            )
                          })
                        }}
                        setQueue={_ => ()}
                        setRequiredPlayers={_ => ()}
                        setShowMatchSelector={_ => ()}
                        onRebalance={() => handleRebalanceRound(roundIndex)}
                        onRebalanceMatch={matchId => handleRebalanceMatch(roundIndex, matchId)}
                        onReset={genderMixed => handleResetRound(roundIndex, ~genderMixed)}
                        getUserFragmentRefs
                        debug={debugMode}
                        allRounds={rounds}
                      />}
                  {isCurrentRound
                    ? <DrawGenerator
                        courtCount
                        onCourtCountChange={handleCourtCountChange}
                        checkedInPlayerCount={checkedInPlayerIds->Set.size}
                        hasExistingDraws={rounds->Array.length > roundNum}
                        strategy
                        onStrategyChange={handleStrategyChange}
                        onGenerateDraws={handleGenerateDraws}
                        weightConfig={effectiveWeightConfig}
                        weightConfigIsCustom={weightConfig->Option.isSome}
                        autoBlendT=?{autoBlendT}
                        onWeightConfigChange={handleWeightConfigChange}
                        onWeightConfigReset={handleWeightConfigReset}
                        drawSeed
                        onNewSeed={handleNewSeed}
                        isGenerating
                        generatingLabel={generatingLabel}
                        isInitiallyExpanded={currentRoundInt == 0}
                        highlight={isDirty}
                        futureRoundsHaveScores
                      />
                    : React.null}
                </React.Fragment>
              })
              ->React.array}
              // Sync Scores Button - At the end
              {rounds->Array.length > 0
                ? {
                    let allMatches = rounds->Array.flatMap(r => r)
                    let syncedCount = allMatches->Array.filter(m => m.synced)->Array.length
                    let unsyncedCount =
                      allMatches
                      ->Array.filter(m => m.score->Option.isSome && !m.synced)
                      ->Array.length
                    <div className="mt-8 flex flex-col items-center gap-2">
                      <div className="flex items-center gap-3">
                        <button
                          onClick={_ => setShowPrintableDraws(_ => true)}
                          className="flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-slate-800 hover:bg-slate-900 text-white hover:shadow-xl">
                          <Lucide.Printer className="w-5 h-5" />
                          <span> {t`Print Draws`} </span>
                        </button>
                        <button
                          onClick={_ => handleSyncScores()->ignore}
                          disabled={syncState == Syncing}
                          className={switch syncState {
                          | Idle => "flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-blue-600 hover:bg-blue-700 text-white hover:shadow-xl"
                          | Syncing => "flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-blue-500 text-white cursor-wait"
                          | Success => "flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-green-600 text-white"
                          | Error => "flex items-center gap-3 px-6 py-4 rounded-xl font-semibold text-lg transition-all shadow-lg bg-red-600 text-white"
                          }}>
                          {switch syncState {
                          | Idle =>
                            <>
                              <Lucide.RotateCcw className="w-5 h-5" />
                              <span> {t`Sync Scores`} </span>
                            </>
                          | Syncing =>
                            <>
                              <Lucide.RotateCcw className="w-5 h-5 animate-spin" />
                              <span> {t`Syncing... ${syncProgress->Int.toString}%`} </span>
                            </>
                          | Success =>
                            <>
                              <Lucide.Check className="w-5 h-5" />
                              <span> {t`Scores Synced!`} </span>
                            </>
                          | Error =>
                            <>
                              <Lucide.AlertCircle className="w-5 h-5" />
                              <span> {t`Sync Failed`} </span>
                            </>
                          }}
                        </button>
                      </div>
                      {syncedCount > 0 || unsyncedCount > 0
                        ? <p className="text-sm text-slate-500">
                            <span className="font-semibold text-green-600">
                              {React.string(syncedCount->Int.toString)}
                            </span>
                            {React.string(" " ++ (ts`synced`))}
                            {unsyncedCount > 0
                              ? <span className="text-amber-600 font-medium">
                                  {React.string(
                                    " · " ++ unsyncedCount->Int.toString ++ " " ++ (ts`to sync`),
                                  )}
                                </span>
                              : syncedCount > 0
                              ? <span className="text-green-600 font-medium">
                                {React.string(" · " ++ (ts`all up to date`))}
                              </span>
                              : React.null}
                          </p>
                        : React.null}
                    </div>
                  }
                : React.null}
            </div>
          </>
        : React.null}
    </div>
    {showPrintableDraws
      ? <PrintableDraws
          rounds={rounds->Array.mapWithIndex((roundMatches, roundIdx) => {
            {
              PrintableDraws.roundNumber: roundIdx + 1,
              matches: roundMatches->Array.mapWithIndex((entity, matchIdx) => {
                let (team1Players, team2Players) = entity.match
                {
                  PrintableDraws.id: entity.id,
                  courtNumber: matchIdx + 1,
                  team1: {
                    players: team1Players->Array.map(
                      p => {
                        PrintableDraws.id: p.id,
                        number: p.intId,
                        name: p.name,
                      },
                    ),
                  },
                  team2: {
                    players: team2Players->Array.map(
                      p => {
                        PrintableDraws.id: p.id,
                        number: p.intId,
                        name: p.name,
                      },
                    ),
                  },
                }
              }),
            }
          })}
          onClose={() => setShowPrintableDraws(_ => false)}
        />
      : React.null}
  </>
}
