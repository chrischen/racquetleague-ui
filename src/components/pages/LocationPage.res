%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LocationPageQuery($id: ID!, $after: String, $first: Int, $before: String, $filters: EventFilters!, $afterDate: Datetime) {
    location(id: $id) {
      name
      ...EventLocation_location
    }
    ...EventsListFragment @arguments(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate)
    ...CalendarEventsFragment @arguments(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate)
  }
  `)
type loaderData = LocationPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  <WaitForMessages>
    {_ => {
      query.location
      ->Option.map(location => <>
        <Layout.Container>
          <h1>
            <div className="text-base leading-6 text-gray-500"> {t`location`} </div>
            <div className="mt-1 text-2xl font-semibold leading-6 text-gray-900">
              {location.name->Option.getOr("?")->React.string}
            </div>
          </h1>
          <EventLocation location={location.fragmentRefs} />
        </Layout.Container>
        <EventsList events={query.fragmentRefs} />
      </>)
      ->Option.getOr(<Layout.Container>{t`page not found`}</Layout.Container>)
    }}
  </WaitForMessages>
}
