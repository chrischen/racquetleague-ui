// Storybook support for ClubEventsList.stories.tsx; the app never imports
// this. The query mirrors ClubEventsListPageQuery: the club's events, the
// availability rows scoped to the club's members, and the viewer. The list
// reads the club's own `slug` field (a location club is recognised by it), so
// the stories set it on the mocked Query.club rather than in the query.
module Query = %relay(`
  query ClubEventsListStoryQuery {
    ...UseProfileGate_query
    ...PkEventsAvailabilityDay_query
      @arguments(fromDate: "2026-10-14", toDate: "2026-10-28", clubSlug: "tokyo-pickleball")
    club(slug: "tokyo-pickleball") {
      ...ClubEventsListFragment
    }
    viewer {
      user {
        ...PkEventRow_user
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = ClubEventsListStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~selectedLocationId: option<string>=?,
  ~onHoverLocation: option<option<string> => unit>=?,
) => {
  let data = Query.use(~variables=())
  let viewerUser = data.viewer->Option.flatMap(v => v.user->Option.map(u => u.fragmentRefs))
  <div className="max-w-4xl bg-white dark:bg-[#222326]">
    {switch data.club {
    | Some(club) =>
      <ClubEventsList
        events=club.fragmentRefs
        query=data.fragmentRefs
        ?viewerUser
        ?selectedLocationId
        ?onHoverLocation
      />
    | None => React.null
    }}
  </div>
}
