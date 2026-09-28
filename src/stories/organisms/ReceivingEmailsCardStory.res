// Storybook support for ReceivingEmailsCard.stories.tsx; the app never
// imports this. The card reads the viewer's profile, as on the settings page.
// .storybook/relay.tsx fills the store before this renders.
module Query = %relay(`
  query ReceivingEmailsCardStoryQuery {
    viewer {
      profile {
        ...ReceivingEmailsCard_user
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = ReceivingEmailsCardStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  <div className="mx-auto max-w-2xl font-sans">
    {switch data.viewer->Option.flatMap(v => v.profile) {
    | Some(profile) => <ReceivingEmailsCard user=profile.fragmentRefs />
    | None => React.null
    }}
  </div>
}
