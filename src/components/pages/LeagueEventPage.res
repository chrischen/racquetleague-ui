%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeagueEventPageQuery($eventId: ID!, $after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String!) {
    event(id: $eventId) {
      __id
      title
      ...AiTetsu_event @arguments(after: $after, first: 20, before: $before)
    }
    ...MatchListFragment @arguments(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace)
  }
`)

type loaderData = LeagueEventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@genType @react.component
let make = () => {
  open Lingui.Util
  let query = useLoaderData()
  let {event, fragmentRefs: queryRefs} = Query.usePreloaded(~queryRef=query.data)
  <Layout.Container className="mt-4">
    <WaitForMessages>
      {() => {
        event
        ->Option.map(event => {
          let {__id, fragmentRefs} = event
          <>
            <AiTetsu event=fragmentRefs>
              <React.Suspense
                fallback={<Layout.Container> {t`Loading matches...`} </Layout.Container>}>
                <MatchList matches=queryRefs />
              </React.Suspense>
            </AiTetsu>
          </>
        })
        ->Option.getOr(React.null)
      }}
    </WaitForMessages>
  </Layout.Container>
}
