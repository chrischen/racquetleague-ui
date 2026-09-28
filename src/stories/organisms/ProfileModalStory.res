// Storybook support for ProfileModal.stories.tsx; the app never imports this.
// The query spreads the modal's fragment directly so there is a fragment ref
// to hand it. .storybook/relay.tsx fills the store before this renders.
module Query = %relay(`
  query ProfileModalStoryQuery {
    ...ProfileModal_viewer
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = ProfileModalStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~isOpen=true,
  ~context: [#Join | #Availability | #Profile]=#Join,
  ~onClose=() => (),
  ~onProfileComplete: option<unit => unit>=?,
) => {
  let data = Query.use(~variables=())
  let context = switch context {
  | #Join => ProfileModal.Join
  | #Availability => ProfileModal.Availability
  | #Profile => ProfileModal.Profile
  }
  <ProfileModal isOpen context onClose ?onProfileComplete query=data.fragmentRefs />
}
