// %%raw("import { css, cx } from '@linaria/core'")
// %%raw("import { t, plural } from '@lingui/macro'")
// open Lingui.Util
//
// module Fragment = %relay(`
//   fragment AddLeagueMatch_event on Event
//   @argumentDefinitions (
//     after: { type: "String" }
//     before: { type: "String" }
//     first: { type: "Int", defaultValue: 50 }
//   )
//   @refetchable(queryName: "AddLeagueMatchRsvpsRefetchQuery")
//   {
//     __id
//     id
//     activity {
//       id
//       slug
//     }
//     rsvps(after: $after, first: $first, before: $before)
//     @connection(key: "SelectMatchRsvps_event_rsvps")
//     {
//       edges {
//         node {
//           __id
//           user {
//             id
//             lineUsername
//             ...EventRsvpUser_user
//           }
//           rating {
//             id
//             mu
//             sigma
//             ordinal
//           }
//         }
//       }
//       pageInfo {
//         hasNextPage
//         hasPreviousPage
//         endCursor
//       }
// 		}
//     ...SelectMatch_event @arguments(after: $after, first: $first, before: $before)
//   }
// `)
//
// @module("../layouts/appContext")
// external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"
// //@genType
// //let default = make
//
// open Rating
// type priority<'a> = {
//   prioritized: array<Player.t<'a>>,
//   deprioritized: Set.t<string>,
// }
// open Util
// module TeamListItem = {
//   @react.component
//   let make = (~id: int, ~team: array<Player.t<'a>>, ~onDelete: int => unit) => {
//     <>
//       <div className="text-xl">
//         <UiAction onClick={_ => onDelete(id)}>
//           <HeroIcons.XMarkIcon className="h-8 w-8 inline" />
//         </UiAction>
//         {t`Team ${id->Int.toString}`}
//       </div>
//       {team
//       ->Array.map(player => <CompMatch.PlayerMini player />)
//       ->React.array}
//     </>
//   }
// }
// module TeamsList = {
//   @react.component
//   let make = (~teams: NonEmptyArray.t<array<Player.t<'a>>>, ~onDelete: int => unit) => {
//     <ul>
//       {teams
//       ->NonEmptyArray.mapWithIndex((team, i) => {
//         <li key={i->Int.toString}>
//           <TeamListItem id={i + 1} team onDelete={_ => onDelete(i)} />
//         </li>
//       })
//       ->NonEmptyArray.toArray
//       ->React.array}
//     </ul>
//   }
// }
// module TeamSelector = {
//   @react.component
//   let make = (~players: array<Player.t<'a>>, ~onTeamCreate, ~teamPlayers) => {
//     let maxRating =
//       players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
//     let minRating =
//       players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)
//
//     let (members: array<Player.t<'a>>, setMembers) = React.useState(() => [])
//     let onSelectPlayer = (player: Player.t<'a>) => {
//       setMembers(_ => {
//         let removed = members->Array.filter(p => p.id != player.id)
//         switch removed->Array.length < members->Array.length {
//         | true => removed
//         | false => members->Array.concat([player])
//         }
//       })
//     }
//     <>
//       <SelectMatch.SelectEventPlayersList
//         players selected=members maxRating minRating onSelectPlayer disabled={teamPlayers}
//       />
//       <div className="mt-6 flex items-center justify-end gap-x-6">
//         <UiAction
//           onClick={() => {
//             switch members->Array.length {
//             | 1
//             | 0 => ()
//             | _ =>
//               onTeamCreate(members)
//               setMembers(_ => [])
//             }
//           }}
//           className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
//           {t`Create Team`}
//         </UiAction>
//       </div>
//     </>
//   }
// }
// let getPriorityPlayers = (players: array<Player.t<'a>>, session: Session.t, break: int) => {
//   let maxCount = players->Array.reduce(0, (acc, next) => {
//     let count = (session->Session.get(next.id)).count
//     count > acc ? count : acc
//   })
//   let minCount = players->Array.reduce(maxCount, (acc, next) => {
//     let count = (session->Session.get(next.id)).count
//     count < acc ? count : acc
//   })
//
//   // We find the n most played players, and extend to all players who have the
//   // same play count as the least played of this group
//   // let (breakPlayers, breakPool, _) =
//   //   players
//   //   ->Players.sortByPlayCountDesc(session)
//   //   ->Array.reduce(([], [], maxCount), ((breakPlayers, breakPool, maxCount), next) => {
//   //     let count = (session->Session.get(next.id)).count
//   //     let (breakPlayers, breakPool) = switch breakPlayers->Array.concat(breakPool)->Array.length <
//   //       break {
//   //     | true => (breakPlayers->Array.concat([next]), breakPool)
//   //     | false => count == maxCount ? (breakPlayers->Array.concat([next]), breakPool) : (breakPlayers, breakPool)
//   //     }
//   //
//   //     (breakPlayers, breakPool, count < maxCount ? count : maxCount)
//   //   })
//
//   let breakPlayers =
//     players
//     ->Array.filter(p => {
//       let count = (session->Session.get(p.id)).count
//       count == maxCount && count != minCount
//     })
//     ->Players.sortByPlayCountDesc(session)
//     ->Array.slice(~start=0, ~end=break)
//
//   // let lowestBreakPlayerCount =
//   // breakPlayers->Array.last->Option.map(p => (session->Session.get(p.id)).count)->Option.getOr(0)
//   {
//     prioritized: players->Array.reduce([], (acc, next) => {
//       let count = (session->Session.get(next.id)).count
//       minCount != maxCount && count == minCount ? acc->Array.concat([next]) : acc
//     }),
//     deprioritized: breakPlayers
//     ->Array.map(p => p.id)
//     ->Set.fromArray,
//   }
// }
// let rsvpToPlayer = (rsvp: AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node): option<
//   Player.t<'a>,
// > => {
//   switch (rsvp.user->Option.map(u => u.id), rsvp.rating) {
//   | (Some(userId), rating) =>
//     let rating = switch rating {
//     | Some({mu: Some(mu), sigma: Some(sigma)}) => Rating.make(mu, sigma)
//     | _ => Rating.makeDefault()
//     }
//     {
//       data: Some(rsvp),
//       Player.id: userId,
//       name: rsvp.user->Option.flatMap(u => u.lineUsername)->Option.getOr(""),
//       ratingOrdinal: rating->Rating.ordinal,
//       rating,
//     }->Some
//   | _ => None
//   }
// }
// let rsvpToPlayerDefault = (
//   rsvp: AddLeagueMatch_event_graphql.Types.fragment_rsvps_edges_node,
// ): option<Player.t<'a>> => {
//   switch (rsvp.user->Option.map(u => u.id), rsvp.rating) {
//   | (Some(userId), _) =>
//     let rating = Rating.makeDefault()
//     {
//       data: Some(rsvp),
//       Player.id: userId,
//       name: rsvp.user->Option.flatMap(u => u.lineUsername)->Option.getOr(""),
//       ratingOrdinal: rating->Rating.ordinal,
//       rating,
//     }->Some
//   | _ => None
//   }
// }
//
// let addGuestPlayer = (sessionPlayers, player) => {
//   sessionPlayers->Array.concat([player])
// }
// let removeGuestPlayer = (sessionPlayers: array<Player.t<'a>>, player: Player.t<'a>) => {
//   sessionPlayers->Array.filter(p => p.id != player.id)
// }
//
// type playerSettings = TeamBuilder | AddPlayer | Settings
// @genType @react.component
// let make = (~event, ~children) => {
//   let {__id, id: eventId, activity} = Fragment.use(event)
//   let (matches: array<match>, setMatches) = React.useState(() => [])
//   let (manualTeamOpen, setManualTeamOpen) = React.useState(() => false)
//   let (teams: NonEmptyArray.t<array<Player.t<'a>>>, setTeams) = React.useState(() =>
//     NonEmptyArray.empty
//   )
//   let (settingsPane: option<playerSettings>, setSettingsPane) = React.useState(() => None)
//   // let (activePlayers: array<Player.t<rsvpNode>>, setActivePlayers) = React.useState(_ => [])
//   let (activePlayers2: Js.Set.t<string>, setActivePlayers2) = React.useState(_ => Set.make())
//   let (sessionState, setSessionState) = React.useState(() => Session.make())
//   let (sessionPlayers: array<Player.t<'a>>, setSessionPlayers) = React.useState(() => [])
//   let (sessionMode, setSessionMode) = React.useState(() => false)
//   let (breakCount: int, setBreakCount) = React.useState(() => 0)
//
//   let {data} = Fragment.usePagination(event)
//   let players = switch sessionMode {
//   | true => sessionPlayers
//   | false =>
//     data.rsvps
//     ->Fragment.getConnectionNodes
//     ->Array.filterMap(rsvpToPlayer)
//     ->Array.concat(sessionPlayers)
//   }
//   let activePlayers = players->Array.filter(p => activePlayers2->Set.has(p.id))
//
//   // @TODO: @HERE: consumedPlayers and deprioritized should be merged and passed
//   // to CompMatch
//   let consumedPlayers =
//     matches
//     ->Array.flatMap(match => Array.concat(match->fst, match->snd)->Array.map(p => p.id))
//     ->Set.fromArray
//
//   let availablePlayers = activePlayers->Array.filter(p => !(consumedPlayers->Set.has(p.id)))
//
//   let {prioritized: priorityPlayers, deprioritized} = getPriorityPlayers(
//     availablePlayers,
//     sessionState,
//     breakCount,
//   )
//
//   let breakPlayersCount = consumedPlayers->Set.size > 0 ? availablePlayers->Array.length : 0
//   let availablePlayers = availablePlayers->Array.filter(p => !(deprioritized->Set.has(p.id)))
//   // let (players: array<Player.t<rsvpNode>>, setPlayers) = React.useState(_ => players')
//
//   // These players should be avoided in the same match
//   let incompatiblePlayers =
//     [
//       "User_7e5631a2-53a9-11ef-b5a9-2b281b5a76b0",
//       "User_55448d42-0843-11ef-8202-7b71b4052443",
//     ]->Set.fromArray
//   let avoidAllPlayers = availablePlayers->Array.filter(p => incompatiblePlayers->Set.has(p.id))
//
//   let maxRating =
//     players->Array.reduce(0., (acc, next) => next.rating.mu > acc ? next.rating.mu : acc)
//   let minRating =
//     players->Array.reduce(maxRating, (acc, next) => next.rating.mu < acc ? next.rating.mu : acc)
//
//   let queueMatch = match => {
//     let matches = matches->Array.concat([match])
//     setMatches(_ => matches)
//   }
//
//   let dequeueMatch = index => {
//     let matches = matches->Array.filterWithIndex((_, i) => i != index)
//     setMatches(_ => matches)
//   }
//   let updatePlayCounts = (match: match) =>
//     setSessionState(prevState => {
//       [match->fst, match->snd]
//       ->Array.flatMap(x => x)
//       ->Array.reduce(prevState, (state, p) =>
//         state->Session.update(p.id, prev => {count: prev.count + 1})
//       )
//     })
//
//   let initializeSessionMode = () => {
//     let players =
//       data.rsvps
//       ->Fragment.getConnectionNodes
//       ->Array.filterMap(rsvpToPlayerDefault)
//       ->Array.concat(sessionPlayers)
//     setSessionPlayers(_ => players)
//   }
//
//   let uninitializeSessionMode = () => {
//     setSessionPlayers(_ => players->Array.filter(p => p.data->Option.isNone))
//   }
//
//   let updateSessionPlayerRatings = (updatedPlayers: array<Player.t<'a>>) => {
//     setSessionPlayers(players => {
//       players->Array.map(p => {
//         let player = updatedPlayers->Array.find(p' => p.id == p'.id)
//         switch player {
//         | Some(player) => player
//         | None => p
//         }
//       })
//     })
//   }
//   let breakPlayersDesc = Lingui.UtilString.plural(
//     breakPlayersCount,
//     {one: "player", other: "players"},
//   )
//
//   let createTeam = (team: array<Player.t<'a>>) => {
//     setTeams(teams => {
//       teams->NonEmptyArray.concat(NonEmptyArray.pure(team))
//     })
//   }
//   let onDeleteTeam = (i: int) => {
//     setTeams(teams => teams->NonEmptyArray.filterWithIndex((_, i') => i' != i))
//   }
//   <>
//     <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-1 md:gap-8">
//       <div className="grid grid-cols-1 items-start gap-4 md:grid-cols-2 md:gap-8">
//         <div className="md:col-span-2">
//           <HeadlessUi.Field className="flex items-center">
//             <HeadlessUi.Switch
//               checked={sessionMode}
//               onChange={v => {
//                 setSessionMode(_ => v)
//                 v == true ? initializeSessionMode() : uninitializeSessionMode()
//               }}
//               className="group relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent bg-gray-200 transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 data-[checked]:bg-indigo-600">
//               <span className="sr-only"> {t`Tournament Mode`} </span>
//               <span
//                 ariaHidden=true
//                 className="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out group-data-[checked]:translate-x-5"
//               />
//             </HeadlessUi.Switch>
//             <HeadlessUi.Switch.Label className="ml-3 text-sm">
//               {t`Tournament Mode`}
//             </HeadlessUi.Switch.Label>
//           </HeadlessUi.Field>
//         </div>
//         <div className="">
//           <h2 className="text-2xl font-semibold text-gray-900"> {t`Players`} </h2>
//           <div className="flex text-right">
//             <UiAction
//               onClick={() =>
//                 setActivePlayers2(_ => {
//                   players->Array.map(p => p.id)->Set.fromArray
//                 })}>
//               {t`select all`}
//             </UiAction>
//             <UiAction
//               className="ml-auto"
//               onClick={() =>
//                 setSettingsPane(prev => prev == Some(TeamBuilder) ? None : Some(TeamBuilder))}>
//               {settingsPane == Some(TeamBuilder)
//                 ? <HeroIcons.Users className="h-8 w-8" />
//                 : <HeroIcons.UsersOutline className="h-8 w-8" />}
//             </UiAction>
//             <UiAction
//               className="ml-2"
//               onClick={() =>
//                 setSettingsPane(prev => prev == Some(AddPlayer) ? None : Some(AddPlayer))}>
//               {settingsPane == Some(AddPlayer)
//                 ? <HeroIcons.UserPlus className="h-8 w-8" />
//                 : <HeroIcons.UserPlusOutline className="h-8 w-8" />}
//             </UiAction>
//             <UiAction
//               className="ml-2"
//               onClick={() =>
//                 setSettingsPane(prev => prev == Some(Settings) ? None : Some(Settings))}>
//               {settingsPane == Some(Settings)
//                 ? <HeroIcons.Cog6Tooth className="h-8 w-8" />
//                 : <HeroIcons.Cog6ToothOutline className="h-8 w-8" />}
//             </UiAction>
//           </div>
//           {switch settingsPane {
//           | Some(TeamBuilder) =>
//             <>
//               <p className="mt-2 text-base leading-7 text-gray-600">
//                 {t`Players in teams will always be placed in a match together on the same side.`}
//               </p>
//               <TeamsList teams onDelete=onDeleteTeam />
//               <TeamSelector
//                 players=activePlayers
//                 onTeamCreate=createTeam
//                 teamPlayers={teams
//                 ->NonEmptyArray.toArray
//                 ->Array.flatMap(x => x)}
//               />
//             </>
//           | Some(AddPlayer) =>
//             <SessionAddPlayer
//               eventId
//               onPlayerAdd={player => {
//                 setSessionPlayers(guests => {
//                   guests->addGuestPlayer(player->SessionAddPlayer.toRatingPlayer)
//                 })
//                 setSettingsPane(_ => None)
//               }}
//             />
//           | Some(Settings) =>
//             <SessionEvenPlayMode
//               breakCount
//               breakPlayersCount
//               onChangeBreakCount={numberOnBreak => {
//                 setBreakCount(_ => numberOnBreak)
//                 setSettingsPane(_ => None)
//               }}
//             />
//           | _ => React.null
//           }}
//           <div> {t`${breakPlayersCount->Int.toString} ${breakPlayersDesc} are not playing`} </div>
//           <SelectPlayersList
//             players={players}
//             selected={activePlayers->Array.map((p: player) => p.id)}
//             session={sessionState}
//             playing={consumedPlayers}
//             onClick={player =>
//               setActivePlayers2(ps => {
//                 let newSet = Set.make()
//                 ps->Set.forEach(id => newSet->Set.add(id))
//                 switch ps->Set.has(player.id) {
//                 | true => newSet->Set.delete(player.id)->ignore
//                 | false => newSet->Set.add(player.id)->ignore
//                 }
//
//                 newSet
//               })}
//             onRemove={player => setSessionPlayers(guests => guests->removeGuestPlayer(player))}
//
//             // switch ps->Array.findIndexOpt(p => p.id == player.id) {
//             // | Some(_) => ps->Array.filter(v => v.id != player.id)
//             // | None => ps->Array.concat([player])
//             // }
//           />
//         </div>
//         <div className="">
//           <h2 className="text-2xl font-semibold text-gray-900"> {t`Matchmaking`} </h2>
//           <div className="flex text-right" />
//           <CompMatch
//             players={(activePlayers :> array<Player.t<'a>>)}
//             teams
//             consumedPlayers={consumedPlayers
//             ->Set.values
//             ->Array.fromIterator
//             ->Array.concat(deprioritized->Set.values->Array.fromIterator)
//             ->Set.fromArray}
//             priorityPlayers
//             avoidAllPlayers
//             onSelectMatch={match => {
//               // setSelectedMatch(_ => Some(([p1'.data, p2'.data], [p3'.data, p4'.data])))
//               queueMatch(match)
//             }}
//           />
//         </div>
//       </div>
//       <div className="col-span-1">
//         <UiAction onClick={() => setManualTeamOpen(prev => !prev)}> {t`manual team`} </UiAction>
//       </div>
//       {manualTeamOpen
//         ? <SelectMatch
//             players={activePlayers}
//             activity
//             onMatchCompleted={match => {
//               updatePlayCounts(match)
//               let match = match->Match.rate
//               updateSessionPlayerRatings(match->Array.flatMap(x => x))
//             }}
//             onMatchQueued={match => queueMatch(match)}
//             //   setSelectedMatch(_ => Some((match :> (array<player>, array<player>))))}
//           />
//         : React.null}
//       <div>
//         <h2 className="text-2xl font-semibold text-gray-900"> {t`Match History`} </h2>
//         {children}
//       </div>
//       <div className="grid grid-cols-1 gap-4">
//         <h2 className="text-2xl font-semibold text-gray-900"> {t`Queued Matches`} </h2>
//         <div className="grid grid-cols-1 gap-4">
//           {activity
//           ->Option.map(activity =>
//             matches
//             ->Array.mapWithIndex((match, i) =>
//               <SubmitMatch
//                 key={i->Int.toString}
//                 match
//                 minRating
//                 maxRating
//                 activity
//                 // onSubmitted={() => {
//                 // updatePlayCounts(match)
//                 // dequeueMatch(i)
//                 // }}
//                 onDelete={() => dequeueMatch(i)}
//                 onComplete={match => {
//                   updatePlayCounts(match)
//                   dequeueMatch(i)
//
//                   let match = match->Match.rate
//                   updateSessionPlayerRatings(match->Array.flatMap(x => x))
//                 }}
//               />
//             )
//             ->React.array
//           )
//           ->Option.getOr(React.null)}
//         </div>
//       </div>
//     </div>
//   </>
// }
//
//
// @genType
// let default = make
