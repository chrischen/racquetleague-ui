%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeagueEventPageQuery($eventId: ID!, $after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String!) {
    event(id: $eventId) {
      __id
      title
      ...AddLeagueMatch_event @arguments(after: $after, first: $first, before: $before)
    }
    ...MatchListFragment @arguments(after: $after, first: 3, before: $before, activitySlug: $activitySlug, namespace: $namespace)
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
  let viewer = GlobalQuery.useViewer()

  <WaitForMessages>
    {() => {
      event->Option.map(event => {
        let {__id, title, fragmentRefs} = event
        <>
          <React.Suspense
            fallback={<Layout.Container> {t`Loading rankings...`} </Layout.Container>}>
            <MatchList matches=queryRefs />
          </React.Suspense>
          <AddLeagueMatch event=fragmentRefs />
        </>
      })->Option.getOr(React.null)
    }}
  </WaitForMessages>
}
