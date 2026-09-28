// Storybook support for PinsMap.stories.tsx; the app never imports this.
// PinsMap draws on a real Google map, so the story wraps it in the same
// APIProvider the app's wrapper.tsx uses, with the app's browser key (passed
// in by the story, which reads it from wrapper.tsx). The events come from the
// story's Relay mocks.
module Query = %relay(`
  query PinsMapStoryQuery {
    events(first: 20) {
      ...PinsMap_eventConnection
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PinsMapStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~mapsApiKey: string,
  ~selected: option<string>=?,
  ~onLocationClick: string => unit=_ => (),
) => {
  let data = Query.use(~variables=())
  <GoogleMap.APIProvider apiKey=mapsApiKey libraries=["places"]>
    // The events map page gives the map the viewport's height beside the list.
    <div className="h-dvh w-full">
      <PinsMap
        connection=data.events.fragmentRefs
        onLocationClick={location => onLocationClick(location.id)}
        ?selected
        navigateOnClick=false
      />
    </div>
  </GoogleMap.APIProvider>
}
