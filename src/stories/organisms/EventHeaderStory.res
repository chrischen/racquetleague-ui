// Storybook support for EventHeader.stories.tsx; the app never imports this.
// The query also reads the viewer so the header's add-to-calendar menu, which
// shows only to a signed-in viewer (GlobalQuery.useViewer), can appear.
module Query = %relay(`
  query EventHeaderStoryQuery {
    event(id: "evt-story-1") {
      ...EventHeader_event
    }
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
let query: concreteRequest = EventHeaderStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  <GlobalQuery.ContextProvider value={data.viewer->Option.map(viewer => viewer.fragmentRefs)}>
    <div className="font-sans">
      {switch data.event {
      | Some(event) => <EventHeader event=event.fragmentRefs />
      | None => React.null
      }}
    </div>
  </GlobalQuery.ContextProvider>
}
