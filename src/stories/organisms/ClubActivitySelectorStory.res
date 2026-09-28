// Storybook support for ClubActivitySelector.stories.tsx; the app never
// imports this. The query spreads the selector's fragment at the root with its
// default page size, as the event pages do.
module Query = %relay(`
  query ClubActivitySelectorStoryQuery {
    ...ClubActivitySelector_query
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = ClubActivitySelectorStoryQuery_graphql.node->Obj.magic

/** What the selector reports to its parent on every change. */
@genType
type selection = {
  clubId: option<string>,
  activityId: option<string>,
  isAddingClub: bool,
}

@genType @react.component
let make = (
  ~initialClubId: option<string>=?,
  ~initialActivitySlug: option<string>=?,
  ~onChange: option<selection => unit>=?,
) => {
  let data = Query.use(~variables=())
  <div className="max-w-2xl font-sans">
    <ClubActivitySelector
      query=data.fragmentRefs
      ?initialClubId
      ?initialActivitySlug
      onChange={s =>
        onChange->Option.forEach(f =>
          f({clubId: s.clubId, activityId: s.activityId, isAddingClub: s.isAddingClub})
        )}
    />
  </div>
}
