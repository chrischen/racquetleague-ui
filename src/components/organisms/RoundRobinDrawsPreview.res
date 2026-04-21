%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
open Rating

module Query = %relay(`
  query RoundRobinDrawsPreviewQuery(
    $eventId: ID!
  ) {
    event(id: $eventId) {
      id
      tags
      startDate
      maxRsvps
      activity {
        id
        slug
      }
      rsvps(first: 100)
        @connection(key: "RoundRobinDrawsPreview_event_rsvps") {
        edges {
          node {
            listType
            user {
              id
              lineUsername
              gender
              ...MatchCard_user
              ...PlayerRow_user
            }
            rating {
              id
              mu
              sigma
              ordinal
            }
          }
        }
      }
    }
  }
`)

type rsvpNode = RoundRobinDrawsPreviewQuery_graphql.Types.response_event_rsvps_edges_node

@react.component
let make = (~eventId: string, ~managerHref: string) => {
  let data = Query.use(~variables={eventId: eventId})

  switch data.event {
  | None => React.null
  | Some(event) => {
      // Extract players from RSVPs
      let players: array<Player.t<rsvpNode>> = React.useMemo1(() => {
        event.rsvps
        ->Option.flatMap(rsvps => rsvps.edges)
        ->Option.getOr([])
        ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
        ->Array.filter(rsvp => rsvp.listType == Some(0) || rsvp.listType == None)
        ->Array.filterMap(rsvp => {
          rsvp.user->Option.map(
            user => {
              let (mu, sigma, ordinal) = switch rsvp.rating {
              | Some(rating) => (
                  rating.mu->Option.getOr(25.0),
                  rating.sigma->Option.getOr(8.333),
                  rating.ordinal->Option.getOr(0.0),
                )
              | None => (25.0, 8.333, 0.0)
              }

              {
                Player.data: Some(rsvp),
                id: user.id,
                intId: 0,
                name: user.lineUsername->Option.getOr("Unknown"),
                rating: {Rating.mu, sigma},
                ratingOrdinal: ordinal,
                paid: false,
                gender: switch user.gender {
                | Some(Male) => Gender.Male
                | Some(Female) => Gender.Female
                | _ => Gender.Male
                },
                count: 0,
              }
            },
          )
        })
        ->Array.toSorted((a, b) => {
          let ratingDiff = b.rating.mu -. a.rating.mu
          if ratingDiff != 0. {
            ratingDiff
          } else {
            String.compare(a.id, b.id)
          }
        })
        ->Array.mapWithIndex((player, i) => {...player, intId: i + 1})
        // Cap to maxRsvps to exclude waitlist players
        ->(players => switch event.maxRsvps {
          | Some(max) => players->Array.slice(~start=0, ~end=max)
          | None => players
        })
      }, [event.rsvps])

      // Need at least 4 players for doubles
      let hasEnoughPlayers = players->Array.length >= 4

      // Court count - user-adjustable
        let defaultCourtCount = suggestedCourtCount(players->Array.length)
        let (courtCount, setCourtCount) = React.useState(() => defaultCourtCount)

        React.useEffect1(() => {
          setCourtCount(_ => suggestedCourtCount(players->Array.length))
          None
        }, [players])

        let maxCourts = Math.Int.max(1, players->Array.length / 4)

      // Generate preview rounds (client-side only to avoid SSR issues with Set.intersection)
      let (previewRounds, setPreviewRounds) = React.useState(() => [])
      React.useEffect2(() => {
        if hasEnoughPlayers {
          let numberOfRounds = 2
          let rounds = generateRounds(
            ~numberOfRounds,
            ~availablePlayers=players,
            ~completedRounds=[],
            ~strategy=RoundRobin,
            ~courtCount,
            ~startTime=Js.Date.make(),
            (),
          )
          setPreviewRounds(_ => rounds)
        } else {
          setPreviewRounds(_ => [])
        }
        None
      }, (players, courtCount))

      // getUserFragmentRefs for MatchCard
      let getUserFragmentRefs = (rsvpNode: rsvpNode) => {
        rsvpNode.user->Option.map(user => user.fragmentRefs)
      }

      if !hasEnoughPlayers {
        React.null
      } else {
        <div className="mt-6">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="p-5 border-b border-gray-200 flex justify-between items-center">
              <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                <Lucide.Shuffle className="w-5 h-5 text-blue-500" />
                {t`Round Robin Draws`}
              </h2>
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-600 font-medium"> {t`Courts:`} </span>
                <button
                  onClick={_ => setCourtCount(c => Math.Int.max(1, c - 1))}
                  disabled={courtCount <= 1}
                  className={courtCount <= 1
                    ? "p-1.5 rounded text-gray-300 cursor-not-allowed"
                    : "p-1.5 rounded text-gray-600 hover:bg-gray-100"}>
                  <Lucide.Minus className="w-4 h-4" />
                </button>
                <div className="w-8 text-center text-lg font-semibold text-gray-900">
                  {courtCount->Int.toString->React.string}
                </div>
                <button
                  onClick={_ => setCourtCount(c => Math.Int.min(maxCourts, c + 1))}
                  disabled={courtCount >= maxCourts}
                  className={courtCount >= maxCourts
                    ? "p-1.5 rounded text-gray-300 cursor-not-allowed"
                    : "p-1.5 rounded text-gray-600 hover:bg-gray-100"}>
                  <Lucide.Plus className="w-4 h-4" />
                </button>
              </div>
            </div>
            <div className="relative">
              // Draws content with disabled interactivity
              <div className="p-4 space-y-6 pointer-events-none select-none">
                {previewRounds
                ->Array.mapWithIndex((roundMatches, roundIndex) => {
                  let roundNum = roundIndex + 1

                  // Calculate min/max ratings for normalization
                  let allPlayers = roundMatches->Array.flatMap(({match: m}) => {
                    let (team1, team2) = m
                    Array.concat(team1, team2)
                  })

                  let minRating =
                    allPlayers
                    ->Array.map(p => p.rating.mu)
                    ->Array.reduce(100., (acc, next) => next < acc ? next : acc)

                  let maxRating =
                    allPlayers
                    ->Array.map(p => p.rating.mu)
                    ->Array.reduce(0., (acc, next) => next > acc ? next : acc)

                  // On small screens, hide rounds beyond the first
                  let roundClassName = roundIndex > 0 ? "hidden sm:block" : ""

                  <div key={roundNum->Int.toString} className=roundClassName>
                    <div className="flex items-center gap-2 mb-3">
                      <span
                        className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-blue-100 text-blue-700 text-xs font-bold">
                        {roundNum->Int.toString->React.string}
                      </span>
                      <h3 className="text-sm font-semibold text-gray-700">
                        {t`Round ${roundNum->Int.toString}`}
                      </h3>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
                      {roundMatches
                      ->Array.mapWithIndex((matchEntity, matchIndex) => {
                        let {id: matchId, match} = matchEntity
                        let courtNumber = matchIndex + 1
                        // On small screens (first round only), hide matches beyond 2
                        let matchClassName = matchIndex >= 2 ? "hidden sm:block" : ""

                        <div key={matchId} className=matchClassName>
                          <MatchCard match courtNumber minRating maxRating getUserFragmentRefs>
                            {[]}
                          </MatchCard>
                        </div>
                      })
                      ->React.array}
                    </div>
                  </div>
                })
                ->React.array}
              </div>
              // Fade-out gradient overlay
              <div
                className="absolute bottom-0 left-0 right-0 h-40 bg-gradient-to-t from-white via-white/80 to-transparent pointer-events-none"
              />
              // View Full Draws button
              <div className="absolute bottom-0 left-0 right-0 flex justify-center pb-6">
                <LangProvider.Router.Link
                  to=managerHref
                  className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg shadow-md hover:bg-blue-700 transition-colors">
                  {t`View Full Draws`}
                  <Lucide.ChevronRight className="w-4 h-4" />
                </LangProvider.Router.Link>
              </div>
            </div>
          </div>
        </div>
      }
    }
  }
}
