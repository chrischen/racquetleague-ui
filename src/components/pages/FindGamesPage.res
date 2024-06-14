%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

// module Query = %relay(`
//   query FindGamesPageQuery($after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String!) {
//     ... RatingListFragment @arguments(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace)
//   }
// `)

// type loaderData = FindGamesPageQuery_graphql.queryRef
// @module("react-router-dom")
// external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"


@genType @react.component
let make = () => {
  open Lingui.Util
  //let { fragmentRefs } = Fragment.use(events)
  // let query = useLoaderData()
  // let viewer = GlobalQuery.useViewer()
  // let {fragmentRefs} = Query.usePreloaded(~queryRef=query.data)

  <WaitForMessages>
    {() => {
      <>
        <div className="py-10 text-white bg-leaguePrimary">
          <Layout.Container>
            <PageTitle>
              <span className="text-white font-extrabold text-3xl">
                {t`Where to Play`}
              </span>
            </PageTitle>
            <p>
              {t`To participate in the league and win prizes, please join the league events.`}
              {" "->React.string}
              <a className="text-gray-200 border-red-200 rounded p-5 border-2" href="https://www.racquetleague.com">
                {t`Find League Games`}
              </a>
            </p>
          </Layout.Container>
        </div>
      </>
    }}
  </WaitForMessages>
}
