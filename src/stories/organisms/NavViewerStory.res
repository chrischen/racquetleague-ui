// Storybook support for NavViewer.stories.tsx; the app never imports this.
// Renders the account menu the way PkuruLayout's top bar does: the viewer's
// menu when there is a viewer, the LINE login button when there is none.
module Query = %relay(`
  query NavViewerStoryQuery {
    viewer {
      ...NavViewer_viewer
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = NavViewerStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  <div
    className="flex h-14 items-center justify-end border-b border-gray-200 px-4 font-sans dark:border-[#2a2b30]">
    {switch data.viewer {
    | Some(viewer) => <NavViewer viewer=viewer.fragmentRefs />
    | None => <LoginLink />
    }}
  </div>
}
