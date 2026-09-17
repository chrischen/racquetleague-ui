module Query = %relay(`
  query ClubEventsListPageQuery(
    $slug: String!
    $after: String
    $first: Int
    $before: String
    $afterDate: Datetime
    $token: String
    $level: Float
    $availabilityFromDate: String!
    $availabilityToDate: String!
    $availabilityLocationId: ID!
    $availabilityByLocation: Boolean!
  ) {
    ...UseProfileGate_query
    ...PkEventsAvailabilityDay_query @arguments(
      fromDate: $availabilityFromDate
      toDate: $availabilityToDate
      clubSlug: $slug
      locationId: $availabilityLocationId
      byLocation: $availabilityByLocation
    )
    club(slug: $slug) {
      ...ClubEventsListFragment @arguments(
        after: $after
        first: $first
        before: $before
        afterDate: $afterDate
        token: $token
        level: $level
      )
    }
    viewer {
      user {
        ...PkEventRow_user
      }
      clubs(first: 100) {
        edges {
          node {
            id
          }
        }
      }
    }
  }
`)

type loaderData = ClubEventsListPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)

  let viewerUser = query.viewer->Option.flatMap(v => v.user->Option.map(u => u.fragmentRefs))

  <WaitForMessages>
    {() =>
      query.club
      ->Option.map(club =>
        <ClubEventsList events=club.fragmentRefs query=query.fragmentRefs ?viewerUser />
      )
      ->Option.getOr(React.null)}
  </WaitForMessages>
}
