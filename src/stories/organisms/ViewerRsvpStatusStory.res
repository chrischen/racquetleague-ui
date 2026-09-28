// Storybook support for ViewerRsvpStatus.stories.tsx; the app never imports
// this. ViewerRsvpStatus reads the viewer from GlobalQuery's context, so the
// wrapper provides it the way the app layout does, from a query spreading the
// viewer fragments that context carries.
module Query = %relay(`
  query ViewerRsvpStatusStoryQuery {
    viewer {
      ...GlobalQueryProvider_viewer
      ...NavViewer_viewer
      ...NotificationsPreview_viewer
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = ViewerRsvpStatusStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~joined=false, ~onJoin=() => (), ~onLeave=() => ()) => {
  let data = Query.use(~variables=())
  <GlobalQuery.ContextProvider value={data.viewer->Option.map(viewer => viewer.fragmentRefs)}>
    <div className="text-sm font-sans">
      <ViewerRsvpStatus joined onJoin onLeave />
    </div>
  </GlobalQuery.ContextProvider>
}
