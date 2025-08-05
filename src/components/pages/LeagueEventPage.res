%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeagueEventPageQuery($eventId: ID!, $after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String) {
    viewer {
      user {
        id
      }
    }
    event(id: $eventId) {
      __id
      title
      ...AiTetsu_event @arguments(after: $after, first: 50, before: $before)
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
  let {event, viewer, fragmentRefs: queryRefs} = Query.usePreloaded(~queryRef=query.data)
  // <Layout.Container className="mt-4">
  <WaitForMessages>
    {() => {
      event
      ->Option.map(event => {
        let {__id, fragmentRefs} = event
        <>
          {viewer->Option.flatMap(v => v.user->Option.map(u => true))->Option.getOr(false)
            ? <AiTetsu event=fragmentRefs>
                <React.Suspense
                  fallback={<Layout.Container> {t`Loading matches...`} </Layout.Container>}>
                  <MatchList matches=queryRefs />
                </React.Suspense>
              </AiTetsu>
            : <Container>
                <div className="border-l-4 border-yellow-400 bg-yellow-50 p-4 mb-2">
                  <div className="flex">
                    <div className="flex-shrink-0">
                      <HeroIcons.ExclamationTriangleIcon
                        \"aria-hidden"="true" className="h-5 w-5 text-yellow-400"
                      />
                    </div>
                    <div className="ml-3">
                      <p className="text-sm text-yellow-700">
                        {t`please login before managing the session`}
                      </p>
                    </div>
                  </div>
                </div>
              </Container>}
        </>
      })
      ->Option.getOr(React.null)
    }}
  </WaitForMessages>
  // </Layout.Container>
}
