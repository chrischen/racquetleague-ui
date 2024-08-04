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
    id
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

open Rating
let rsvpToPlayer = (rsvp: AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node): option<
  Player.t<'a>,
> => {
  switch (rsvp.user->Option.map(u => u.id), rsvp.rating) {
  | (Some(userId), rating) =>
    let rating = switch rating {
    | Some({mu: Some(mu), sigma: Some(sigma)}) => Rating.make(mu, sigma)
    | _ => Rating.makeDefault()
    }
    {
      data: Some(rsvp),
      Player.id: userId,
      name: rsvp.user->Option.flatMap(u => u.lineUsername)->Option.getOr(""),
      ratingOrdinal: rating->Rating.ordinal,
      rating,
    }->Some
  | _ => None
  }
}
module PlayerState = {
  type t = {count: int}
  let make = () => {count: 0}
}
module Session = {
  type t = Js.Dict.t<PlayerState.t>
  let make = () => Js.Dict.empty()
  let get = (session: t, id: string) => session->Js.Dict.get(id)->Option.getOr(PlayerState.make())
  let update = (session: t, id: string, f: PlayerState.t => PlayerState.t) => {
    let session = Js.Dict.fromArray(session->Js.Dict.entries)
    switch session->Js.Dict.get(id)->Option.map(state => session->Js.Dict.set(id, f(state))) {
    | Some(_) => ()
    | None => session->Js.Dict.set(id, f(PlayerState.make()))
    }
    session
  }
}

type rsvpNode = AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node
type player = Player.t<rsvpNode>
type team = array<player>
type match = (team, team)

type matches = array<match>

module SelectPlayersList = {
  type sort = Rating | MatchCount
  @react.component
  let make = (
    ~players: array<Player.t<rsvpNode>>,
    ~selected: array<string>,
    ~playing: Set.t<string>,
    ~session: Session.t,
    ~onClick: Player.t<'a> => unit,
    ~onRemove: Player.t<'a> => unit,
  ) => {
    let (sort, setSort) = React.useState(() => Rating)

    let players = players->Array.toSorted((a, b) =>
      switch sort {
      | MatchCount =>
        (session->Session.get(a.id)).count < (session->Session.get(b.id)).count ? -1. : 1.
      | Rating => a.ratingOrdinal < b.ratingOrdinal ? 1. : -1.
      }
    )
    <FramerMotion.Div className="bg-gray-100">
      <table className="mt-6 w-full whitespace-nowrap text-left">
        <colgroup>
          <col className="w-full sm:w-4/12" />
          <col className="lg:w-4/12" />
          <col className="lg:w-2/12" />
          <col className="lg:w-1/12" />
          <col className="lg:w-1/12" />
          <col className="lg:w-1/12" />
        </colgroup>
        <thead className="border-b border-black/10 text-sm leading-6 text-black">
          <tr>
            <th scope="col" className="py-2 pl-4 pr-8 font-semibold sm:pl-6 lg:pl-8">
              <UiAction className="group inline-flex" onClick={() => setSort(_ => Rating)}>
                {t`Player`}
                {sort == Rating
                  ? <span
                      className="ml-2 flex-none rounded bg-gray-100 text-gray-900 group-hover:bg-gray-200">
                      <HeroIcons.ChevronDownIcon className="w-5 h-5" />
                    </span>
                  : React.null}
              </UiAction>
            </th>
            <th
              scope="col"
              className="py-2 pl-0 pr-4 text-right font-semibold table-cell sm:pr-6 lg:pr-8"
            />
            <th
              scope="col"
              className="py-2 pl-0 pr-4 text-right font-semibold table-cell sm:pr-6 lg:pr-8">
              <UiAction className="group inline-flex" onClick={() => setSort(_ => MatchCount)}>
                {t`Match Count`}
                {sort == MatchCount
                  ? <span
                      className="ml-2 flex-none rounded bg-gray-100 text-gray-900 group-hover:bg-gray-200">
                      <HeroIcons.ChevronUpIcon className="w-5 h-5" />
                    </span>
                  : React.null}
              </UiAction>
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-black/5">
          {switch players {
          | [] => t`no players yet`
          | players =>
            players
            ->Array.map(player => {
              let isGuest = player.data->Option.isNone
              let selected = selected->Array.indexOf(player.id) > -1
              <FramerMotion.Tr
                layout=true
                // className="mt-2 relative flex justify-between"
                style={originX: 0.05, originY: 0.05}
                key={player.id}
                initial={opacity: 0., scale: 1.15}
                animate={opacity: 1., scale: 1.}
                exit={opacity: 0., scale: 1.15}>
                <td className="py-2 pl-0 pr-8">
                  <div className="flex items-center gap-x-4">
                    <div
                      className={Util.cx([
                        "text-sm w-full font-medium leading-6 text-gray-900",
                        !selected ? "opacity-50" : "",
                      ])}>
                      <UiAction onClick={() => onClick(player)}>
                        {player.data
                        ->Option.flatMap(data =>
                          data.user->Option.map(
                            user => {
                              <EventRsvpUser
                                user={user.fragmentRefs->EventRsvpUser.fromRegisteredUser}
                              />
                            },
                          )
                        )
                        ->Option.getOr(<>
                          {<EventRsvpUser user={name: player.name, picture: None, data: Guest} />}
                        </>)}
                      </UiAction>
                    </div>
                  </div>
                </td>
                <td>
                  {isGuest && !selected
                    ? <UiAction onClick={() => onRemove(player)}>
                        {"Remove"->React.string}
                      </UiAction>
                    : React.null}
                </td>
                <td
                  className="py-2 pl-0 pr-4 text-right text-sm leading-6 text-gray-400 table-cell sm:pr-6 lg:pr-8">
                  <div className="flex items-center justify-end gap-x-2">
                    <div
                      className={Util.cx([
                        playing->Set.has(player.id) ? "text-green-400 bg-green-400/10" : "hidden",
                        "flex-none rounded-full p-1",
                      ])}>
                      <div className="h-1.5 w-1.5 rounded-full bg-current" />
                    </div>
                    {Session.get(session, player.id).count->Int.toString->React.string}
                  </div>
                </td>
              </FramerMotion.Tr>
            })
            ->React.array
          }}
        </tbody>
      </table>
    </FramerMotion.Div>
  }
}

module SessionPlayer = {
  type t<'a> =
    | Registered(Player.t<'a>)
    | Guest({id: string, name: string, rating: Rating.t, ratingOrdinal: float})
  // let fromRsvpPlayer = player => {
  //   data: None,
  //   id: player.name,
  //   name: player.name,
  //   rating: Rating.makeDefault(),
  //   ratingOrdinal: 0.0,
  // }
}

let addGuestPlayer = (guestPlayers, player) => {
  guestPlayers->Array.concat([player])
}
let removeGuestPlayer = (guestPlayers: array<Player.t<'a>>, player: Player.t<'a>) => {
  guestPlayers->Array.filter(p => p.id != player.id)
}

@genType @react.component
let make = (~event, ~children) => {
  let {__id, id: eventId, activity} = Fragment.use(event)
  let (selectedMatch: option<match>, setSelectedMatch) = React.useState(() => None)
  let (matches: array<match>, setMatches) = React.useState(() => [])
  let (manualTeamOpen, setManualTeamOpen) = React.useState(() => false)
  let (addPlayerOpen, setAddPlayerOpen) = React.useState(() => false)
  // let (activePlayers: array<Player.t<rsvpNode>>, setActivePlayers) = React.useState(_ => [])
  let (activePlayers2: Js.Set.t<string>, setActivePlayers2) = React.useState(_ => Set.make())
  let (sessionState, setSessionState) = React.useState(() => Session.make())
  let (guestPlayers: array<Player.t<'a>>, setGuestPlayers) = React.useState(() => [])

  let {data} = Fragment.usePagination(event)
  let players =
    data.rsvps
    ->Fragment.getConnectionNodes
    ->Array.filterMap(rsvpToPlayer)
    ->Array.concat(guestPlayers)
  let activePlayers = players->Array.filter(p => activePlayers2->Set.has(p.id))

  // let (players: array<Player.t<rsvpNode>>, setPlayers) = React.useState(_ => players')

  let maxRating =
    players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
  let minRating =
    players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)
  let maxCount = players->Array.reduce(0, (acc, next) => {
    let count = (sessionState->Session.get(next.id)).count
    count > acc ? count : acc
  })
  let minCount = players->Array.reduce(0, (acc, next) => {
    let count = (sessionState->Session.get(next.id)).count
    count < acc ? count : acc
  })
  let priorityPlayers = activePlayers->Array.reduce([], (acc, next) => {
    let count = (sessionState->Session.get(next.id)).count
    minCount != maxCount && count == minCount ? acc->Array.concat([next]) : acc
  })

  let queueMatch = match => {
    let matches = matches->Array.concat([match])
    setMatches(_ => matches)
  }

  let dequeueMatch = index => {
    let matches = matches->Array.filterWithIndex((_, i) => i != index)
    setMatches(_ => matches)
  }
  let consumedPlayers =
    matches
    ->Array.flatMap(match => Array.concat(match->fst, match->snd)->Array.map(p => p.id))
    ->Set.fromArray

  let updatePlayCounts = (match: match) =>
    setSessionState(prevState => {
      [match->fst, match->snd]
      ->Array.flatMap(x => x)
      ->Array.reduce(prevState, (state, p) =>
        state->Session.update(p.id, prev => {count: prev.count + 1})
      )
    })

  <>
    <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-1 md:gap-8">
      <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-2 md:gap-8">
        <div className="">
          <h2 className="text-2xl font-semibold text-gray-900"> {t`Players`} </h2>
          <UiAction
            onClick={() =>
              setActivePlayers2(_ => {
                players->Array.map(p => p.id)->Set.fromArray
              })}>
            {t`select all`}
          </UiAction>
          <UiAction className="float-right" onClick={() => setAddPlayerOpen(prev => !prev)}>
            {t`Add Player`}
          </UiAction>
          {addPlayerOpen
            ? <SessionAddPlayer
                eventId
                onPlayerAdd={player => {
                  setGuestPlayers(guests => {
                    guests->addGuestPlayer(player->SessionAddPlayer.toRatingPlayer)
                  })
                  setAddPlayerOpen(_ => false)
                }}
                onCancel={_ => setAddPlayerOpen(_ => false)}
              />
            : React.null}
          <SelectPlayersList
            players={players}
            selected={activePlayers->Array.map((p: player) => p.id)}
            session={sessionState}
            playing={consumedPlayers}
            onClick={player =>
              setActivePlayers2(ps => {
                let newSet = Set.make()
                ps->Set.forEach(id => newSet->Set.add(id))
                switch ps->Set.has(player.id) {
                | true => newSet->Set.delete(player.id)->ignore
                | false => newSet->Set.add(player.id)->ignore
                }

                newSet
              })}
            onRemove={player => setGuestPlayers(guests => guests->removeGuestPlayer(player))}

            // switch ps->Array.findIndexOpt(p => p.id == player.id) {
            // | Some(_) => ps->Array.filter(v => v.id != player.id)
            // | None => ps->Array.concat([player])
            // }
          />
        </div>
        <div className="">
          <h2 className="text-2xl font-semibold text-gray-900"> {t`Matchmaking`} </h2>
          <CompMatch
            players={(activePlayers :> array<Player.t<'a>>)}
            consumedPlayers={consumedPlayers}
            priorityPlayers
            onSelectMatch={match => {
              // setSelectedMatch(_ => Some(([p1'.data, p2'.data], [p3'.data, p4'.data])))
              queueMatch(match)
            }}
          />
        </div>
      </div>
      <div className="col-span-1">
        <UiAction onClick={() => setManualTeamOpen(prev => !prev)}> {t`manual team`} </UiAction>
      </div>
      {manualTeamOpen
        ? <SelectMatch
            players={activePlayers}
            onMatchSelected={match =>
              setSelectedMatch(_ => Some((match :> (array<player>, array<player>))))}
          />
        : React.null}
      <div className="grid grid-cols-1 gap-4">
        <React.Suspense fallback={<div> {t`Loading`} </div>}>
          {activity
          ->Option.flatMap(activity =>
            selectedMatch->Option.map(match =>
              <SubmitMatch
                match
                minRating
                maxRating
                activity
                onSubmitted={() => {
                  updatePlayCounts(match)
                  setSelectedMatch(_ => None)
                }}
                onComplete={() => {
                  updatePlayCounts(match)
                  setSelectedMatch(_ => None)
                }}
              />
            )
          )
          ->Option.getOr(React.null)}
        </React.Suspense>
      </div>
      <div>
        <h2 className="text-2xl font-semibold text-gray-900"> {t`Match History`} </h2>
        {children}
      </div>
      <div className="grid grid-cols-1 gap-4">
        {t`queued matches`}
        <div className="grid grid-cols-1 gap-4">
          {activity
          ->Option.map(activity =>
            matches
            ->Array.mapWithIndex((match, i) =>
              <React.Suspense fallback={<div> {t`Loading`} </div>}>
                <SubmitMatch
                  match
                  minRating
                  maxRating
                  activity
                  onSubmitted={() => {
                    updatePlayCounts(match)
                    dequeueMatch(i)
                  }}
                  onDelete={() => dequeueMatch(i)}
                  onComplete={() => {
                    updatePlayCounts(match)
                    dequeueMatch(i)
                  }}
                />
              </React.Suspense>
            )
            ->React.array
          )
          ->Option.getOr(React.null)}
        </div>
      </div>
    </div>
  </>
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
