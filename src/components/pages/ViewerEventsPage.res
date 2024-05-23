%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Query = %relay(`
  query ViewerEventsPageQuery($after: String, $first: Int, $before: String, $afterDate: Datetime, $filters: EventFilters) {
    ... EventsListFragment @arguments(after: $after, first: $first, before: $before, afterDate: $afterDate, filters: $filters)
  }
`)

type loaderData = ViewerEventsPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@genType @react.component
let make = () => {
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  let {fragmentRefs} = Query.usePreloaded(~queryRef=query.data)

  <WaitForMessages>
    {() => {
      <>
        <Layout.Container>
          <Grid>
            <PageTitle> {t`all events`} </PageTitle>
          </Grid>
        </Layout.Container>
        <Layout.Container>
          <Grid>
            <AddToCalendar />
          </Grid>
        </Layout.Container>
        <React.Suspense
          fallback={<Layout.Container> {"Loading events..."->React.string} </Layout.Container>}>
          <EventsList events=fragmentRefs />
        </React.Suspense>
      </>
    }}
  </WaitForMessages>
}

