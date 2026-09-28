// Storybook support for PkEventRow.stories.tsx; the app never imports this.
// PkEventRow is one event in the events lists (PkEventsList, ClubEventsList).
// The wrapper lists every event the mocks put on Query.events, one row each,
// with the waitlist count PkEventsList works out for the leave confirmation.
module Query = %relay(`
  query PkEventRowStoryQuery {
    ...UseProfileGate_query
    viewer {
      user {
        ...PkEventRow_user
      }
    }
    events(first: 20) {
      edges {
        node {
          id
          maxRsvps
          rsvps(first: 100) {
            edges {
              node {
                id
                listType
              }
            }
          }
          ...PkEventRow_event
        }
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PkEventRowStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~onEventClick: option<string => unit>=?, ~dimmed=false) => {
  let data = Query.use(~variables=())
  let user = data.viewer->Option.flatMap(v => v.user)->Option.map(u => u.fragmentRefs)
  let nodes =
    data.events.edges
    ->Option.getOr([])
    ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
  <div
    className="max-w-4xl border-y border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#222326]">
    {nodes
    ->Array.mapWithIndex((node, i) => {
      let mainList =
        node.rsvps
        ->Option.flatMap(r => r.edges)
        ->Option.getOr([])
        ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
        ->Array.filter(n => n.listType == None || n.listType == Some(0))
        ->Array.length
      let waitlistCount = node.maxRsvps->Option.map(max => Js.Math.max_int(0, mainList - max))
      <PkEventRow
        key=node.id
        event=node.fragmentRefs
        user
        isLastInGroup={i == nodes->Array.length - 1}
        waitlistCount={waitlistCount->Option.getOr(0)}
        query=data.fragmentRefs
        ?onEventClick
        dimmed
      />
    })
    ->React.array}
  </div>
}
