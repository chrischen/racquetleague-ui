// Storybook support for MediaList.stories.tsx; the app never imports this.
// MediaList embeds a venue's videos (Location.media) under the location
// details on the event page.
module Query = %relay(`
  query MediaListStoryQuery {
    location(id: "loc-story-1") {
      ...MediaList_location
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = MediaListStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  switch data.location {
  | Some(location) =>
    <div className="flex flex-col gap-2 font-sans" dataTestId="media-list">
      <MediaList media=location.fragmentRefs />
    </div>
  | None => React.null
  }
}
