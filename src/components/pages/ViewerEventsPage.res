%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Query = %relay(`
  query ViewerEventsPageQuery($after: String, $first: Int, $before: String, $afterDate: Datetime, $filters: EventFilters) {
    ... EventsListFragment @arguments(after: $after, first: $first, before: $before, afterDate: $afterDate, filters: $filters)
    ... CalendarEventsFragment @arguments(after: $after, first: $first, before: $before, afterDate: $afterDate, filters: $filters)
  }
`)

type loaderData = ViewerEventsPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@genType @react.component
let make = () => {
  open Router;
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  let viewer = GlobalQuery.useViewer()
  let {fragmentRefs} = Query.usePreloaded(~queryRef=query.data)

  <WaitForMessages>
    {() => {
      <>
        <Layout.Container>
          <Grid>
            <PageTitle> {t`my events`} </PageTitle>
            <div>
              <Link to={"/"}> {t`public events`} </Link>
              {viewer.user
              ->Option.map(_ => <>
                {" "->React.string}
                <svg viewBox="0 0 2 2" className="h-1.5 w-1.5 inline flex-none fill-gray-600">
                  <circle cx={1->Int.toString} cy={1->Int.toString} r={1->Int.toString} />
                </svg>
                {" "->React.string}
                <Link to={"/events"} relative="path"> {t`my events`} </Link>
              </>)
              ->Option.getOr(React.null)}
            </div>
          </Grid>
        </Layout.Container>
        <Layout.Container>
          <AddToCalendar />
        </Layout.Container>
        <React.Suspense
          fallback={<Layout.Container> {"Loading events..."->React.string} </Layout.Container>}>
          <EventsList events=fragmentRefs />
        </React.Suspense>
      </>
    }}
  </WaitForMessages>
}
