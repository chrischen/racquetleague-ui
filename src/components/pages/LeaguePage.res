%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

@module("./jpl-logo.png")
external jplLogo: string = "default"

module Query = %relay(`
  query LeaguePageQuery($after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String!) {
    ... RatingListFragment @arguments(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace)
  }
`)

type loaderData = LeaguePageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@genType @react.component
let make = () => {
  open Lingui.Util;
  let ts = Lingui.UtilString.t
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  // let viewer = GlobalQuery.useViewer()
  let {fragmentRefs} = Query.usePreloaded(~queryRef=query.data)

  <WaitForMessages>
    {() => {
      <>
        <Layout.Container>
          <Grid>
            <PageTitle> <img src={jplLogo} alt=ts`japan pickle league` />  </PageTitle>
          </Grid>
        </Layout.Container>
        <React.Suspense
          fallback={<Layout.Container> {t`Loading rankings...`} </Layout.Container>}>
          <RatingList ratings=fragmentRefs />
        </React.Suspense>
      </>
    }}
  </WaitForMessages>
}
