// Storybook support for EventRsvpUser.stories.tsx; the app never imports this.
// EventRsvpUser reads a player's LINE name and picture and draws them with
// AvatarRsvpUser; EventRsvp computes the rating props it passes.
module Query = %relay(`
  query EventRsvpUserStoryQuery {
    user(id: "user-kenji") {
      ...EventRsvpUser_user
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventRsvpUserStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~highlight=false,
  ~secondaryText: option<string>=?,
  ~ratingPercent: option<float>=?,
  ~sigmaPercent: option<float>=?,
) => {
  let data = Query.use(~variables=())
  switch data.user {
  | Some(user) =>
    <div className="font-sans">
      <EventRsvpUser
        user=user.fragmentRefs
        highlight
        link="/league/pickleball/p/user-kenji"
        ?secondaryText
        ?ratingPercent
        ?sigmaPercent
      />
    </div>
  | None => React.null
  }
}
