// Storybook support for EventRsvpUserBar.stories.tsx; the app never imports
// this. EventRsvpUserBar reads a player's LINE name and picture and draws them
// with RsvpUser (a row with a rating bar), as the check-in list
// (SelectPlayersList) does for each registered player.
module Query = %relay(`
  query EventRsvpUserBarStoryQuery {
    user(id: "user-emily") {
      ...EventRsvpUserBar_user
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventRsvpUserBarStoryQuery_graphql.node->Obj.magic

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
    <div className="max-w-sm font-sans">
      <EventRsvpUserBar
        user=user.fragmentRefs highlight ?secondaryText ?ratingPercent ?sigmaPercent
      />
    </div>
  | None => React.null
  }
}
