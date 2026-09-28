// Storybook support for MiniEventRsvp.stories.tsx; the app never imports this.
// MiniEventRsvp is the small avatar with a rating ring that RSVPSection shows
// in its collapsed mobile bar: the first three players overlapped, then a
// "+N" count.
module Query = %relay(`
  query MiniEventRsvpStoryQuery {
    event(id: "evt-story-1") {
      rsvps(first: 20) {
        edges {
          node {
            id
            rating {
              mu
            }
            ...MiniEventRsvp_rsvp
          }
        }
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = MiniEventRsvpStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~layout: [#row | #mobileBar]=#row) => {
  let data = Query.use(~variables=())
  let nodes =
    data.event
    ->Option.flatMap(e => e.rsvps)
    ->Option.flatMap(c => c.edges)
    ->Option.getOr([])
    ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
  let maxRating = nodes->Array.reduce(0., (max, node) => {
    let mu = node.rating->Option.flatMap(r => r.mu)->Option.getOr(0.)
    mu > max ? mu : max
  })
  switch layout {
  | #row =>
    <div className="flex flex-wrap gap-3 font-sans">
      {nodes
      ->Array.map(node => <MiniEventRsvp key=node.id rsvp=node.fragmentRefs maxRating />)
      ->React.array}
    </div>
  | #mobileBar =>
    // The right half of RSVPSection's collapsed mobile bar (the join button
    // on its left is left out).
    <div className="max-w-sm bg-white shadow-lg border-t p-4 font-sans">
      <div className="flex justify-end items-center">
        <div className="flex items-center space-x-3">
          <h2 className="text-lg font-semibold"> {"RSVP"->React.string} </h2>
          <div className="flex -space-x-2">
            {nodes
            ->Array.slice(~start=0, ~end=3)
            ->Array.map(node =>
              <div key=node.id className="inline-block">
                <MiniEventRsvp rsvp=node.fragmentRefs maxRating />
              </div>
            )
            ->React.array}
            {nodes->Array.length > 3
              ? <div
                  className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-gray-200 text-xs font-medium text-gray-800">
                  {`+${(nodes->Array.length - 3)->Int.toString}`->React.string}
                </div>
              : React.null}
          </div>
          <Lucide.ChevronUp size=20 className="text-gray-500" />
        </div>
      </div>
    </div>
  }
}
