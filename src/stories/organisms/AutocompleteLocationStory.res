// Storybook support for AutocompleteLocation.stories.tsx; the app never
// imports this. The venue search runs on the Google Places SDK, which the app
// loads through the APIProvider in wrapper.tsx. Stories get a stand-in
// instead (StoryFixturesServices.PlacesProvider): the same `places` library
// surface, answering from a fixed list of Tokyo venues, with no network and
// no API key. Picking a venue saves it through the component's own
// autocompleteLocation mutation, which the story's Relay mocks answer.

@genType @react.component
let make = (
  ~places: [#answers | #unavailable | #notLoaded]=#answers,
  ~error: option<string>=?,
  ~autoSearchAddress: option<string>=?,
  ~onSelected=(_: string) => (),
  ~onSelectedDetails: option<((string, string)) => unit>=?,
) => {
  // Room below the field for the suggestion list.
  let field =
    <div className="max-w-md pb-80">
      <AutocompleteLocation onSelected ?onSelectedDetails ?error ?autoSearchAddress />
    </div>
  switch places {
  | #notLoaded => field
  | #answers => <StoryFixturesServices.PlacesProvider> field </StoryFixturesServices.PlacesProvider>
  | #unavailable =>
    <StoryFixturesServices.PlacesProvider answer=#unavailable>
      field
    </StoryFixturesServices.PlacesProvider>
  }
}
