// Storybook support for RsvpOptions.stories.tsx; the app never imports this.
// RsvpOptions is the menu behind every RSVP chip: View Profile for anyone,
// and for an organizer the list moves, removal and the payment actions its
// payment's status allows. The wrapper renders the event's first RSVP with a
// chip like PkEventRsvp's as the trigger.
module Query = %relay(`
  query RsvpOptionsStoryQuery {
    event(id: "evt-story-1") {
      id
      rsvps(first: 1) {
        edges {
          node {
            id
            user {
              lineUsername
              picture
            }
            ...RsvpOptions_rsvp
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
let query: concreteRequest = RsvpOptionsStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~isAdmin=false, ~chargesEnabled=false) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    <div className="min-h-72 font-sans">
      {event.rsvps
      ->Option.flatMap(c => c.edges)
      ->Option.getOr([])
      ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
      ->Array.map(node => {
        let name = node.user->Option.flatMap(u => u.lineUsername)->Option.getOr("?")
        <div key=node.id className="inline-block">
          <RsvpOptions
            rsvp=node.fragmentRefs
            eventId=event.id
            eventActivitySlug="pickleball"
            isAdmin
            chargesEnabled
            connectionKey="PkRSVPSection_event_rsvps"
            triggerClassName="relative inline-flex items-center gap-1.5 pl-0.5 pr-2 py-0.5 rounded-full cursor-pointer transition-colors border border-gray-200 dark:border-[#3a3b40] hover:bg-gray-50 dark:hover:bg-[#26272b]">
            <AvatarWithProgress
              src={node.user->Option.flatMap(u => u.picture)->Option.getOr("")}
              alt=name
              progress=80
              size=22
              strokeWidth=1.5
            />
            <span className="text-[11px] leading-none text-gray-900 dark:text-gray-100">
              {name->React.string}
            </span>
          </RsvpOptions>
        </div>
      })
      ->React.array}
    </div>
  | None => React.null
  }
}
