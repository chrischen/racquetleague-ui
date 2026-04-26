%%raw("import { t } from '@lingui/macro'")
open LangProvider.Router

module ClubLeaderboardFragment = %relay(`
  fragment ClubPage_leaderboard on Query
  @argumentDefinitions(
    activitySlug: { type: "String!" }
    namespace: { type: "String!" }
    clubSlug: { type: "String" }
    first: { type: "Int", defaultValue: 5 }
  ) {
    ratings(
      activitySlug: $activitySlug
      namespace: $namespace
      clubSlug: $clubSlug
      first: $first
    ) {
      edges {
        node {
          id
          ordinal
          mu
          user {
            id
            fullName
            lineUsername
            picture
          }
        }
      }
    }
  }
`)

module Query = %relay(`
  query ClubPageQuery(
    $slug: String!
  ) {
    ...ClubPage_leaderboard
      @arguments(
        activitySlug: "pickleball"
        namespace: "doubles:comp"
        clubSlug: $slug
        first: 5
      )
    club(slug: $slug) {
      id
      slug
      name
      description
      shareLink
      viewerMembership { status isAdmin }
      events(first: 5) {
        edges {
          node {
            id
            title
            startDate
            endDate
            timezone
            deleted
            location { id name }
            maxRsvps
            rsvps(first: 100) {
              edges { node { id } }
            }
          }
        }
      }
    }
    viewer {
      user { id }
    }
  }
  `)

module JoinClubMutation = %relay(`
  mutation ClubPageJoinClubMutation(
    $connections: [ID!]!
    $input: JoinClubInput!
  ) {
    joinClub(input: $input) {
      errors { message }
      club {
        viewerMembership @appendNode(connections: $connections, edgeTypeName: "MembershipEdge") {
          status
        }
      }
    }
  }
`)

module RemoveUserFromClubMutation = %relay(`
  mutation ClubPageRemoveUserFromClubMutation(
    $input: RemoveUserFromClubInput!
  ) {
    removeUserFromClub(input: $input) {
      errors { message }
      membershipIds
      club {
        viewerMembership {
          status
        }
      }
    }
  }
`)

type loaderData = ClubPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

// type clubStat = {
//   label: string,
//   value: string,
//   color: string,
//   bg: string,
// }

let getRankColor = (rank: int) => {
  switch rank {
  | 1 => "text-yellow-500 bg-yellow-50 border-yellow-200"
  | 2 => "text-gray-500 bg-gray-50 border-gray-200"
  | 3 => "text-amber-700 bg-amber-50 border-amber-200"
  | _ => "text-gray-500 bg-white border-transparent"
  }
}

// let getStatIcon = (index: int) => {
//   switch index {
//   | 0 => <Lucide.Trophy className="w-6 h-6" />
//   | 1 => <Lucide.Users className="w-6 h-6" />
//   | 2 => <Lucide.Activity className="w-6 h-6" />
//   | _ => <Lucide.UserCheck className="w-6 h-6" />
//   }
// }

@react.component
let make = () => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  let leaderboardData = ClubLeaderboardFragment.use(query.fragmentRefs)
  let (commitJoinClub, isJoinInFlight) = JoinClubMutation.use()
  let (commitRemoveUser, isRemoveInFlight) = RemoveUserFromClubMutation.use()

  // let clubStats: array<clubStat> = [
  //   {label: ts`Average Rating`, value: "1,642", color: "text-amber-600", bg: "bg-amber-50"},
  //   {label: ts`Total Members`, value: "47", color: "text-blue-600", bg: "bg-blue-50"},
  //   {label: ts`Games This Month`, value: "156", color: "text-emerald-600", bg: "bg-emerald-50"},
  //   {label: ts`Active Players`, value: "32", color: "text-purple-600", bg: "bg-purple-50"},
  // ]

  let handleJoinClub = () => {
    query.club
    ->Option.map(club => {
      let membersConnectionId = RescriptRelay.ConnectionHandler.getConnectionID(
        RescriptRelay.makeDataId("client:root"),
        "ClubMembersPageMembersQuery_clubMembers",
        (),
      )
      commitJoinClub(
        ~variables={
          connections: [membersConnectionId],
          input: {clubId: club.id},
        },
        ~onCompleted=({joinClub}, _errors) => {
          switch joinClub.errors {
          | None | Some([]) => ()
          | Some(errors) => errors->Array.forEach(e => Js.Console.error(e.message))
          }
        },
      )->RescriptRelay.Disposable.ignore
    })
    ->Option.getOr()
  }

  let handleCancelRequest = () => {
    query.club
    ->Option.map(club => {
      switch query.viewer->Option.flatMap(v => v.user) {
      | Some(user) =>
        commitRemoveUser(
          ~variables={
            input: {clubId: club.id, userId: user.id},
          },
          ~onCompleted=({removeUserFromClub}, _errors) => {
            switch removeUserFromClub.errors {
            | None | Some([]) => ()
            | Some(errors) => errors->Array.forEach(e => Js.Console.error(e.message))
            }
          },
        )->RescriptRelay.Disposable.ignore
      | None => ()
      }
    })
    ->Option.getOr()
  }

  <WaitForMessages>
    {_ => {
      query.club
      ->Option.map(club => {
        let clubName = club.name->Option.getOr("?")
        let initials =
          clubName
          ->String.split(" ")
          ->Array.filterMap(w => w->String.get(0))
          ->Array.map(String.make)
          ->Array.join("")
          ->String.slice(~start=0, ~end=2)
          ->String.toUpperCase

        <div className="min-h-screen bg-gray-50 w-full pb-12">
          // Club Header
          <div className="bg-white shadow-sm border-b">
            <div className="h-32 bg-gradient-to-r from-blue-600 to-indigo-700 w-full" />
            <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pb-6">
              <div className="relative flex justify-between items-end -mt-12 sm:-mt-16 mb-4">
                <div className="flex items-end gap-5">
                  <div
                    className="w-24 h-24 sm:w-32 sm:h-32 bg-white rounded-xl shadow-md border-4 border-white flex items-center justify-center overflow-hidden">
                    <div
                      className="w-full h-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold text-3xl sm:text-4xl">
                      {initials->React.string}
                    </div>
                  </div>
                  <div className="pb-2">
                    <h1 className="text-2xl sm:text-3xl font-bold text-gray-900">
                      {clubName->React.string}
                    </h1>
                    <div className="flex items-center gap-4 mt-1 text-sm text-gray-600">
                      <div className="flex items-center gap-1">
                        <Lucide.Users className="w-4 h-4" />
                        // <span> {t`47 Members`} </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <p className="text-gray-600 max-w-3xl">
                {club.description->Option.getOr("")->React.string}
              </p>
              <div className="mt-4 flex flex-wrap items-center gap-2">
                {switch query.viewer->Option.flatMap(v => v.user) {
                | Some(_) => {
                    let status = club.viewerMembership->Option.flatMap(m => m.status)
                    let viewerIsAdmin =
                      club.viewerMembership
                      ->Option.flatMap(m => m.isAdmin)
                      ->Option.getOr(false)
                    switch status {
                    | Some(Active) =>
                      if viewerIsAdmin {
                        React.null
                      } else {
                        <Button.Button
                          color=#red
                          disabled={isRemoveInFlight}
                          onClick={_ => handleCancelRequest()}>
                          {t`Leave club`}
                        </Button.Button>
                      }
                    | Some(Pending) =>
                      <Button.Button
                        color=#red disabled={isRemoveInFlight} onClick={_ => handleCancelRequest()}>
                        {t`Cancel Request`}
                      </Button.Button>
                    | _ =>
                      <Button.Button
                        color=#indigo disabled={isJoinInFlight} onClick={_ => handleJoinClub()}>
                        {t`Request to join`}
                      </Button.Button>
                    }
                  }
                | None =>
                  <Button.Button
                    href={"/oauth-login?return=" ++
                    club.slug->Option.map(slug => "/clubs/" ++ slug)->Option.getOr("/clubs")}
                    color=#indigo>
                    {t`Join Club`}
                  </Button.Button>
                }}
                {club.viewerMembership
                ->Option.flatMap(m => m.isAdmin)
                ->Option.getOr(false)
                  ? <Button.Button href={"./members"} color=#indigo>
                      {t`Manage Members`}
                    </Button.Button>
                  : React.null}
              </div>
            </div>
          </div>
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            // Club Stats Row (commented out - hardcoded sample data)
            // <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            //   {clubStats
            //   ->Array.mapWithIndex((stat, idx) => {
            //     <div
            //       key={idx->Int.toString}
            //       className="bg-white rounded-xl shadow-sm border border-gray-200 p-5 flex items-center gap-4">
            //       <div className={"p-3 rounded-lg " ++ stat.bg ++ " " ++ stat.color}>
            //         {getStatIcon(idx)}
            //       </div>
            //       <div>
            //         <div className="text-sm font-medium text-gray-500 mb-0.5">
            //           {stat.label->React.string}
            //         </div>
            //         <div className="text-2xl font-bold text-gray-900">
            //           {stat.value->React.string}
            //         </div>
            //       </div>
            //     </div>
            //   })
            //   ->React.array}
            // </div>
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              // Upcoming Club Events
              <div className="lg:col-span-2">
                <div
                  className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                  <div className="p-5 border-b border-gray-200 flex justify-between items-center">
                    <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                      <Lucide.Calendar className="w-5 h-5 text-blue-500" />
                      {t`Upcoming Events`}
                    </h2>
                    <Link
                      to="./events"
                      className="text-sm font-medium text-blue-600 hover:text-blue-800 flex items-center">
                      {t`View All`}
                      <Lucide.ChevronRight className="w-4 h-4" />
                    </Link>
                  </div>
                  <div className="divide-y divide-gray-100">
                    {club.events.edges
                    ->Option.getOr([])
                    ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
                    ->Array.map(event => {
                      let rsvpCount =
                        event.rsvps
                        ->Option.map(r => r.edges->Option.getOr([])->Array.length)
                        ->Option.getOr(0)

                      <Link
                        key={event.id}
                        to={"/events/" ++ event.id}
                        className={"flex items-center justify-between px-5 py-4 hover:bg-gray-50 transition-colors" ++
                        (event.deleted->Option.isSome ? " opacity-60" : "")}>
                        <div className="flex-1 min-w-0">
                          <div
                            className={"font-semibold truncate " ++
                            (event.deleted->Option.isSome
                              ? "line-through text-gray-400"
                              : "text-gray-900")}>
                            {event.title->Option.getOr("")->React.string}
                          </div>
                          <div className="flex items-center gap-3 mt-1 text-sm text-gray-500">
                            {event.startDate
                            ->Option.map(
                              startDate => {
                                <div className="flex items-center gap-1">
                                  <Lucide.Calendar className="w-3.5 h-3.5" />
                                  <ReactIntl.FormattedDate
                                    value={startDate->Util.Datetime.toDate}
                                    month=#short
                                    day=#numeric
                                  />
                                </div>
                              },
                            )
                            ->Option.getOr(React.null)}
                            {event.location
                            ->Option.map(
                              loc => {
                                <div className="flex items-center gap-1">
                                  <Lucide.MapPin className="w-3.5 h-3.5" />
                                  <span className="truncate">
                                    {loc.name->Option.getOr("")->React.string}
                                  </span>
                                </div>
                              },
                            )
                            ->Option.getOr(React.null)}
                          </div>
                        </div>
                        <div className="flex items-center gap-1 text-sm text-gray-500 ml-4">
                          <Lucide.Users className="w-4 h-4" />
                          <span>
                            {(rsvpCount->Int.toString ++
                              event.maxRsvps
                              ->Option.map(max => "/" ++ max->Int.toString)
                              ->Option.getOr(""))->React.string}
                          </span>
                        </div>
                      </Link>
                    })
                    ->React.array}
                    {club.events.edges
                    ->Option.getOr([])
                    ->Array.length == 0
                      ? <div className="px-5 py-8 text-center text-gray-500">
                          {t`No upcoming events`}
                        </div>
                      : React.null}
                  </div>
                </div>
              </div>
              // Player Rankings Leaderboard
              <div className="lg:col-span-1">
                <div
                  className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden sticky top-6">
                  <div className="p-5 border-b border-gray-200 flex justify-between items-center">
                    <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                      <Lucide.Trophy className="w-5 h-5 text-amber-500" />
                      {t`Leaderboard`}
                    </h2>
                    <Link
                      to={"/league/pickleball/" ++ club.slug->Option.getOr("")}
                      className="text-sm font-medium text-blue-600 hover:text-blue-800 flex items-center">
                      {t`View All`}
                      <Lucide.ChevronRight className="w-4 h-4" />
                    </Link>
                  </div>
                  <div className="divide-y divide-gray-100">
                    {leaderboardData.ratings.edges
                    ->Option.getOr([])
                    ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
                    ->Array.mapWithIndex((player, idx) => {
                      let rank = idx + 1
                      let displayName =
                        player.user
                        ->Option.flatMap(u => u.lineUsername)
                        ->Option.getOr("Unknown")
                      let ordinalDisplay =
                        player.ordinal
                        ->Option.map(v => v->Float.toFixed(~digits=1))
                        ->Option.getOr("-")
                      let dupr =
                        player.mu
                        ->Option.map(Rating.guessDupr)
                        ->Option.map(v => v->Float.toFixed(~digits=2))
                        ->Option.getOr("-")

                      let userId =
                        player.user
                        ->Option.map(u => u.id)
                        ->Option.getOr("")

                      let profilePath =
                        "/league/pickleball/" ++ club.slug->Option.getOr("") ++ "/p/" ++ userId

                      <Link
                        key={player.id}
                        to={profilePath}
                        className="flex items-center justify-between px-4 py-3 hover:bg-gray-50 transition-colors">
                        <div className="flex items-center gap-3">
                          <div
                            className={"w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs border " ++
                            getRankColor(rank)}>
                            {rank->Int.toString->React.string}
                          </div>
                          <div>
                            <div className="font-semibold text-gray-900 text-sm">
                              {displayName->React.string}
                            </div>
                            <div className="flex items-center gap-1 mt-0.5">
                              <span
                                className="text-[10px] font-medium text-gray-500 bg-gray-100 px-1.5 py-0.5 rounded">
                                {"DUPR"->React.string}
                              </span>
                              <span className="text-xs text-gray-500"> {dupr->React.string} </span>
                            </div>
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="text-base font-bold text-blue-600">
                            {ordinalDisplay->React.string}
                          </div>
                        </div>
                      </Link>
                    })
                    ->React.array}
                    {leaderboardData.ratings.edges
                    ->Option.getOr([])
                    ->Array.length == 0
                      ? <div className="px-5 py-8 text-center text-gray-500">
                          {t`No ratings yet`}
                        </div>
                      : React.null}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      })
      ->Option.getOr(<Layout.Container> {t`club not found`} </Layout.Container>)
    }}
  </WaitForMessages>
}
