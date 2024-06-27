module Query = %relay(`
  query UpdateEventPageQuery($after: String, $first: Int, $before: String) {
    ...SelectLocation_query @arguments(after: $after, first: $first, before: $before)
  }
  `)
type loaderData = UpdateEventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  <SelectLocation locations={query.fragmentRefs} />
}
