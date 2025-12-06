%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeaguePlayerPageQuery(
    $after: String
    $first: Int
    $before: String
    $activitySlug: String!
    $namespace: String
    $userId: ID!
  ) {
    ...MatchHistoryListFragment
      @arguments(
        after: $after
        first: $first
        before: $before
        activitySlug: $activitySlug
        userId: $userId
      )
    ...RatingGraphWrapperFragment
      @arguments(
        after: $after
        first: $first
        before: $before
        activitySlug: $activitySlug
        userId: $userId
      )
    user(id: $userId) {
      id
      picture
      lineUsername
      gender
      rating(activitySlug: $activitySlug, namespace: $namespace) {
        ordinal
        mu
      }
      ...MatchHistoryListUser_user
    }
  }
`)

type loaderData = LeaguePlayerPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

module Params = {
  type t = {activitySlug: string}
}
@module("react-router-dom") external useParams: unit => Params.t = "useParams"

@genType @react.component
let make = () => {
  open Lingui.Util
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  // let viewer = GlobalQuery.useViewer()
  let {fragmentRefs, user} = Query.usePreloaded(~queryRef=query.data)
  let params = useParams()
  let activitySlug = params.activitySlug
  let userRefs = user->Option.map(user => user.fragmentRefs)

  user->Option.map(user =>
    <WaitForMessages>
      {() => {
        <div className="min-h-screen bg-gray-50 w-full">
          // Header with back button
          <div className="bg-white shadow-sm border-b">
            <div className="max-w-6xl mx-auto px-4 py-4">
              <LangProvider.Router.Link
                to="../"
                className="inline-flex items-center gap-2 text-gray-600 hover:text-gray-900 transition-colors">
                <Lucide.ChevronLeft className="w-5 h-5" />
                <span className="font-medium"> {t`Back to league`} </span>
              </LangProvider.Router.Link>
            </div>
          </div>
          <div className="max-w-6xl mx-auto px-4 py-8">
            // Player Info Card
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
              <div className="flex items-start gap-6">
                {user.picture
                ->Option.map(picture =>
                  <img
                    src={picture}
                    alt={user.lineUsername->Option.getOr("")}
                    className="w-24 h-24 rounded-full border-4 border-blue-100"
                  />
                )
                ->Option.getOr(
                  <div
                    className="w-24 h-24 rounded-full border-4 border-blue-100 bg-gray-200 flex items-center justify-center text-gray-500 text-2xl font-bold">
                    {user.lineUsername
                    ->Option.flatMap(name => name->String.charAt(0)->String.toUpperCase->Some)
                    ->Option.getOr("?")
                    ->React.string}
                  </div>,
                )}
                <div className="flex-1">
                  <h1 className="text-3xl font-bold text-gray-900 mb-2">
                    {user.lineUsername->Option.getOr("")->React.string}
                  </h1>
                  <div className="flex flex-wrap gap-6 mt-4">
                    // Current Rating
                    <div>
                      <div className="text-sm text-gray-500 mb-1"> {t`Current Rating`} </div>
                      <div className="text-3xl font-bold text-blue-600">
                        {user.rating
                        ->Option.flatMap(r => r.ordinal->Option.map(Float.toFixed(_, ~digits=1)))
                        ->Option.getOr("--")
                        ->React.string}
                      </div>
                    </div>
                    // Estimated DUPR (for pickleball only)
                    {switch activitySlug {
                    | "pickleball" =>
                      user.rating
                      ->Option.flatMap(r => r.mu)
                      ->Option.map(mu => {
                        let dupr = Rating.guessDupr(mu)
                        <div>
                          <div className="text-sm text-gray-500 mb-1"> {t`Estimated DUPR`} </div>
                          <div className="text-2xl font-semibold text-gray-900">
                            {dupr->Float.toFixed(~digits=2)->React.string}
                          </div>
                        </div>
                      })
                      ->Option.getOr(React.null)
                    | _ => React.null
                    }}
                  </div>
                </div>
              </div>
            </div>
            // Rating Graph
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
              <React.Suspense fallback={React.null}>
                <RatingGraphWrapper matches=fragmentRefs userId={user.id} />
              </React.Suspense>
            </div>
            // Match History
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-4"> {t`Recent Matches`} </h2>
              <React.Suspense fallback={<div className="text-gray-500"> {t`Loading...`} </div>}>
                <MatchHistoryList matches=fragmentRefs user=?userRefs />
              </React.Suspense>
            </div>
          </div>
        </div>
      }}
    </WaitForMessages>
  )
}
