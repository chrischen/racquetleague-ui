module Query = %relay(`
  query PkViewerEventsPageQuery($after: String, $first: Int, $before: String, $afterDate: Datetime, $filters: EventFilters, $availabilityFromDate: String!, $availabilityToDate: String!) {
    ...PkEventsListFragment @arguments(
      after: $after
      first: $first
      before: $before
      afterDate: $afterDate
      filters: $filters
      availabilityFromDate: $availabilityFromDate
      availabilityToDate: $availabilityToDate
    )
  }
`)

type loaderData = PkViewerEventsPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  let query = useLoaderData()
  let {fragmentRefs} = Query.usePreloaded(~queryRef=query.data)

  <WaitForMessages> {() => <PkEventsList events=fragmentRefs />} </WaitForMessages>
}
