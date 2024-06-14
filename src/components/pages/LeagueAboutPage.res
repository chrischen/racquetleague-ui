%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

// module Query = %relay(`
//   query LeagueAboutPageQuery($after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String!) {
//     ... RatingListFragment @arguments(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace)
//   }
// `)

// type loaderData = LeagueAboutPageQuery_graphql.queryRef
// @module("react-router-dom")
// external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@genType @react.component
let make = () => {
  open Lingui.Util
  //let { fragmentRefs } = Fragment.use(events)
  // let query = useLoaderData()
  // let viewer = GlobalQuery.useViewer()
  // let {fragmentRefs} = Query.usePreloaded(~queryRef=query.data)

  let params: LeaguePage.params = Router.useParams()
  let description = {
    switch params.activitySlug {
    | None
    | Some("") =>
      <p>
        {t`The Japan Pickleball League is an open-source non-profit project to help improve the quality of community recreational pickleball games and events.`}
      </p>
    | _ =>
      <p>
        {t`The Tokyo Badminton League is an open-source non-profit project to help improve the quality of community recreational pickleball games and events.`}
      </p>
    }
  }
  <WaitForMessages>
    {() => {
      <>
        <div className="py-10 text-white bg-leaguePrimary">
          <Layout.Container>
            <PageTitle>
              <span className="text-white font-extrabold text-3xl"> {t`About the League`} </span>
            </PageTitle>
          </Layout.Container>
        </div>
        <Layout.Container className="mt-5">
        {description}
          <p className="mt-5">
            {t`Ratings are assigned to individual players just by playing doubles games, even with different partners each game. For doubles ratings we use OpenSkill (a derivative of TrueSkill), and for singles ratings we use Glicko2.`}
          </p>
        </Layout.Container>
      </>
    }}
  </WaitForMessages>
}
