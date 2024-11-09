%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeagueRankingsPageQuery($after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String!) {
    ... RatingListFragment @arguments(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace)
  }
`)

type loaderData = {query: LeagueRankingsPageQuery_graphql.queryRef}
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@genType @react.component
let make = () => {
  open Lingui.Util
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  // let viewer = GlobalQuery.useViewer()
  let {fragmentRefs} = Query.usePreloaded(~queryRef=query.data.query)

  <WaitForMessages>
    {() => {
      <>
        <div className="py-10 text-white bg-leaguePrimary">
          <Layout.Container>
            <PageTitle>
              <span className="text-white font-extrabold text-3xl">
                {t`Recreational Doubles`}
              </span>
            </PageTitle>
            <p className="mt-5">
              {t`Play doubles games with different partners and receive an individual rating. Prizes are awarded monthly to top players.`}
            </p>
            <p>
              {t`To participate, please join the events here:`}
              {" "->React.string}
              <a className="text-gray-200" href="https://www.pkuru.com">
                {"> P*kuru <"->React.string}
              </a>
            </p>
          </Layout.Container>
        </div>
        <React.Suspense fallback={<Layout.Container> {t`Loading rankings...`} </Layout.Container>}>
          <RatingList ratings=fragmentRefs />
        </React.Suspense>
      </>
    }}
  </WaitForMessages>
}
