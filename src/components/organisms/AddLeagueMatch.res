%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment AddLeagueMatch_event on Event
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 50 }
  )
  @refetchable(queryName: "AddLeagueMatchRsvpsRefetchQuery")
  {
    __id
    activity {
      id
      slug
    }
    rsvps(after: $after, first: $first, before: $before)
    @connection(key: "SelectMatchRsvps_event_rsvps")
    {
      edges {
        node {
          __id
          user {
            id
            lineUsername
            ...EventRsvpUser_user
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
    ...SelectMatch_event @arguments(after: $after, first: $first, before: $before)
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"
//@genType
//let default = make

let rsvpToPlayer = (rsvp: AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node) => {
  switch (rsvp.user->Option.map(u => u.id), rsvp.rating) {
  | (Some(userId), rating) =>
    {
      data: rsvp,
      ManagedSession.Player.id: userId,
      name: rsvp.user->Option.flatMap(u => u.lineUsername)->Option.getOr(""),
      rating: switch rating {
      | Some({mu: Some(mu), sigma: Some(sigma)}) => ManagedSession.Rating.make(mu, sigma)
      | _ => ManagedSession.Rating.makeDefault()
      },
    }->Some
  | _ => None
  }
}

type team = array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node>
type match = (team, team)

type matches = array<match>

@genType @react.component
let make = (~event) => {
  let {__id, activity} = Fragment.use(event)
  let (selectedMatch: option<match>, setSelectedMatch) = React.useState(() => None)
  let (matches, setMatches) = React.useState(() => [])
  let (manualTeamOpen, setManualTeamOpen) = React.useState(() => false)

  let {data} = Fragment.usePagination(event)
  let players = data.rsvps->Fragment.getConnectionNodes
  let maxRating =
    players->Array.reduce(0., (acc, next) =>
      next.rating->Option.flatMap(r => r.mu)->Option.getOr(0.) > acc
        ? next.rating->Option.flatMap(r => r.mu)->Option.getOr(0.)
        : acc
    )
  let minRating =
    players->Array.reduce(maxRating, (acc, next) =>
      next.rating->Option.flatMap(r => r.mu)->Option.getOr(maxRating) < acc
        ? next.rating->Option.flatMap(r => r.mu)->Option.getOr(maxRating)
        : acc
    )

  let queueMatch = match => {
    let matches = matches->Array.concat([match])
    setMatches(_ => matches)
  }

  let dequeueMatch = index => {
    let matches = matches->Array.filterWithIndex((_, i) => i != index)
    setMatches(_ => matches)
  }
  // let (selectedMatch: option<ManagedSession.Match.t>, setSelectedMatch) = React.useState(() => None)

  // let onCreateMatch = _ => {
  //   let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
  //     __id,
  //     "LeagueEventMatches_matches",
  //     (),
  //   )
  //   commitMutationCreateLeagueMatch(
  //     ~variables={
  //       matchInput: {
  //         activitySlug: "pickleball",
  //         namespace: "doubles:rec",
  //         doublesMatch: {
  //           winners: [],
  //           losers: [],
  //           score: [],
  //           createdAt: Js.Date.make()->Util.Datetime.fromDate,
  //         },
  //       },
  //       // id: __id->RescriptRelay.dataIdToString,
  //       connections: [connectionId],
  //     },
  //   )->RescriptRelay.Disposable.ignore
  // }

  <Layout.Container>
    <ManagedSession
      players={players->Array.filterMap(x => rsvpToPlayer(x))}
      consumedPlayers={matches->Array.flatMap(match =>
        Array.concat(match->fst, match->snd)->Array.filterMap(r => rsvpToPlayer(r))
      )}
      onSelectMatch={(((p1', p2'), (p3', p4'))) => {
        // setSelectedMatch(_ => Some(([p1'.data, p2'.data], [p3'.data, p4'.data])))
        queueMatch(([p1'.data, p2'.data], [p3'.data, p4'.data]))
      }}
    />
    <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-1 md:gap-8">
      <div className="col-span-1">
        <UiAction onClick={() => setManualTeamOpen(prev => !prev)}> {t`manual team`} </UiAction>
      </div>
      {manualTeamOpen
        ? <SelectMatch
            event
            onMatchSelected={match =>
              setSelectedMatch(_ => Some(
                (match :> (
                  array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node>,
                  array<AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node>,
                )),
              ))}
          />
        : React.null}
      <div className="grid grid-cols-1 gap-4">
        <React.Suspense fallback={<div> {t`Loading`} </div>}>
          {activity
          ->Option.flatMap(activity =>
            selectedMatch->Option.map(match => <Match match minRating maxRating activity />)
          )
          ->Option.getOr(React.null)}
        </React.Suspense>
      </div>
      <div className="grid grid-cols-1 gap-4">
        {t`queued matches`}
        <div className="grid grid-cols-1 gap-4">
          {activity
          ->Option.map(activity =>
            matches
            ->Array.mapWithIndex((match, i) =>
              <React.Suspense fallback={<div> {t`Loading`} </div>}>
                <Match match minRating maxRating activity onDelete={() => dequeueMatch(i)} />
              </React.Suspense>
            )
            ->React.array
          )
          ->Option.getOr(React.null)}
        </div>
      </div>
    </div>
  </Layout.Container>
}

// let loadMessages = lang => {
//   let messages = switch lang {
//   | "ja" => Lingui.import("../../locales/ja/organisms/EventRsvps.mjs")
//   | _ => Lingui.import("../../locales/en/organisms/EventRsvps.mjs")
//   }->Promise.thenResolve(messages => Lingui.i18n.load(lang, messages["messages"]))
//
//   [messages]->Array.concat(ViewerRsvpStatus.loadMessages(lang))
// }

@genType
let default = make
