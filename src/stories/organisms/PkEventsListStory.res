// Storybook support for PkEventsList.stories.tsx; the app never imports this.
// The query spreads the list's two root fragments the way the Discover page
// (Events.res) does, with the availability window fixed to the stories'
// fortnight. .storybook/relay.tsx fills the store before this renders.
module Query = %relay(`
  query PkEventsListStoryQuery {
    ...PkEventsListFragment
    ...PkEventsAvailabilityDay_query @arguments(fromDate: "2026-10-14", toDate: "2026-10-28")
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PkEventsListStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  // Discover (Events.res) turns both on; a player's own list
  // (PkViewerEventsPage) leaves both off.
  ~showInlineCourts=true,
  ~showLocationFilter=true,
  // Hide events from clubs the viewer isn't in, as Discover does for members.
  ~hideOtherClubs=false,
  ~selectedLocationId: option<string>=?,
  ~onHoverLocation: option<option<string> => unit>=?,
) => {
  let data = Query.use(~variables=())
  // Discover's rule (Events.res): shadow events, and for a club member,
  // events of clubs they aren't in, start behind "Show n more".
  let shouldHideEvent = hideOtherClubs
    ? Some(
        (
          event: PkEventsListFragment_graphql.Types.fragment_events_edges_node,
          viewer: option<PkEventsListFragment_graphql.Types.fragment_viewer>,
        ) => {
          let clubIds =
            viewer
            ->Option.flatMap(v => v.clubs.edges)
            ->Option.getOr([])
            ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
            ->Array.map(node => node.id)
          let otherClub =
            clubIds->Array.length > 0 &&
              event.club->Option.map(c => !(clubIds->Array.includes(c.id)))->Option.getOr(false)
          event.shadow->Option.getOr(false) || otherClub
        },
      )
    : None
  <div className="max-w-4xl bg-white dark:bg-[#222326]">
    <PkEventsList
      events=data.fragmentRefs
      showInlineCourts
      showLocationFilter
      ?shouldHideEvent
      ?selectedLocationId
      ?onHoverLocation
    />
  </div>
}
