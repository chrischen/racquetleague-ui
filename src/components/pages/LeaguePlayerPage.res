%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeaguePlayerPageQuery(
    $after: String
    $first: Int
    $before: String
    $activitySlug: String!
    $namespace: String!
    $userId: ID!
  ) {
    ...MatchListFragment
      @arguments(
        after: $after
        first: $first
        before: $before
        activitySlug: $activitySlug
        namespace: $namespace
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
      ...MatchListUser_user
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
        <>
          <div className="border-b border-black-500">
            <Layout.Container>
              <div className="overflow-hidden rounded-lg bg-white">
                <h2 className="sr-only" id="profile-overview-title"> {t`Player Profile Page`} </h2>
                <div className="bg-white p-6">
                  <div className="sm:flex sm:items-center sm:justify-between">
                    <div className="sm:flex sm:space-x-5 mx-auto">
                      <div className="flex-shrink-0">
                        {user.picture
                        ->Option.map(picture =>
                          <img className="mx-auto h-20 w-20 rounded-full" src={picture} alt="" />
                        )
                        ->Option.getOr(React.null)}
                      </div>
                      <div className="mt-4 text-center sm:mt-0 sm:pt-1 sm:text-left">
                        <p className="text-xl font-bold text-gray-900 sm:text-2xl">
                          {user.lineUsername->Option.getOr("")->React.string}
                        </p>
                        <p className="text-sm font-medium text-gray-600">
                          {user.gender
                          ->Option.map(gender =>
                            switch gender {
                            | Male => t`Male`
                            | Female => t`Female`
                            | _ => "--"->React.string
                            }
                          )
                          ->Option.getOr(React.null)}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
                // <div
                //   className="grid grid-cols-1 divide-y divide-gray-200 border-t border-gray-200 bg-gray-50 sm:grid-cols-3 sm:divide-x sm:divide-y-0">
                //   <div key={stat.label} className="px-6 py-5 text-center text-sm font-medium">
                //     <span className="text-gray-900">{stat.value}</span> <span className="text-gray-600">{"label"->React.string}</span>
                //   </div>
                // </div>
              </div>
            </Layout.Container>
          </div>
          <Layout.Container className="mt-5">
            // <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:max-w-7xl lg:px-8">
            <h1 className="sr-only"> {t`Player Profile Page`} </h1>
            <div className="grid grid-cols-1 items-start gap-4 lg:grid-cols-3 lg:gap-8">
              <div className="grid grid-cols-1 gap-4 lg:col-span-2">
                <section ariaLabelledby="section-1-title">
                  <h2 className="sr-only" id="section-1-title"> {t`Match History`} </h2>
                  <div className="overflow-hidden rounded-lg bg-white shadow">
                    <div className="p-6">
                      <h2 className="text-2xl font-semibold text-gray-900"> {t`Match History`} </h2>
                      <React.Suspense
                        fallback={<Layout.Container> {t`Loading rankings...`} </Layout.Container>}>
                        <MatchList matches=fragmentRefs user=?userRefs />
                      </React.Suspense>
                    </div>
                  </div>
                </section>
              </div>
              <div className="grid grid-cols-1 gap-4">
                <section ariaLabelledby="section-2-title">
                  <h2 className="sr-only" id="section-2-title"> {t`Rating`} </h2>
                  <div className="overflow-hidden rounded-lg bg-white shadow">
                    <div className="p-6">
                      <dt className="truncate text-sm font-medium text-gray-500"> {t`Rating`} </dt>
                      <dd className="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
                        {user.rating
                        ->Option.flatMap(r => r.ordinal->Option.map(Float.toFixed(_, ~digits=2)))
                        ->Option.getOr("Unrated")
                        ->React.string}
                      </dd>
                      {switch activitySlug {
                      | "pickleball" =>
                        user.rating
                        ->Option.flatMap(r => r.mu)
                        ->Option.map(mu => {
                          let dupr = Rating.guessDupr(mu)
                          <>
                            <dt className="mt-4 truncate text-sm font-medium text-gray-500">
                              {t`Estimated DUPR`}
                            </dt>
                            <dd
                              className="mt-1 text-3xl font-semibold tracking-tight text-gray-900">
                              {dupr->Float.toFixed(~digits=2)->React.string}
                            </dd>
                          </>
                        })
                        ->Option.getOr(React.null)
                      | _ => React.null
                      }}
                    </div>
                  </div>
                </section>
              </div>
            </div>
          </Layout.Container>
          // </div>
        </>
      }}
    </WaitForMessages>
  )
}
