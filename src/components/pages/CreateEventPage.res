module Query = %relay(`
  query CreateEventPageQuery($after: String, $first: Int, $before: String) {
    ...SelectLocation_query @arguments(after: $after, first: $first, before: $before)
  }
  `)
type loaderData = CreateEventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  <AutocompleteLocation locations={query.fragmentRefs} />
}
