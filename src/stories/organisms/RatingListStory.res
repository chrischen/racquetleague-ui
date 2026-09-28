// Storybook support for RatingList.stories.tsx; the app never imports this.
// The query spreads the list's fragment at the root with literal arguments,
// as LeagueRankingsPage does with its route variables. The optional "Your
// standing" row is filled from the shared roster (StoryFixturesProfile).
module Query = %relay(`
  query RatingListStoryQuery {
    ...RatingListFragment @arguments(activitySlug: "pickleball", namespace: "doubles:comp")
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = RatingListStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~genderFilter: RatingList.genderFilter=#all,
  ~search="",
  ~showDraftUi=false,
  ~viewerId: option<string>=?,
) => {
  let data = Query.use(~variables=())
  let viewer =
    viewerId->Option.flatMap(id => StoryFixturesProfile.roster->Array.find(p => p.id == id))
  // The rankings page's list area sits on this grey band.
  <div className="bg-[#f4f4f5] py-4 font-sans dark:bg-[#151518] md:py-6">
    <RatingList
      ratings=data.fragmentRefs
      genderFilter
      search
      showDraftUi
      viewerUserId=?{viewer->Option.map(p => p.id)}
      viewerOrdinal=?{viewer->Option.map(p => p.mu -. 3. *. p.sigma)}
      viewerMu=?{viewer->Option.map(p => p.mu)}
      viewerDays=?{viewer->Option.map(p => p.daysNumberOne)}
      viewerName=?{viewer->Option.map(p => p.lineUsername)}
      viewerPicture=?{viewer->Option.flatMap(p => p.picture->Js.Null.toOption)}
    />
  </div>
}
