%%raw("import { t } from '@lingui/macro'")
module Query = %relay(`
  query CreateEventsPageQuery($after: String, $first: Int, $before: String) {
    ...SelectClub_query @arguments(after: $after, first: $first, before: $before)
  }
  `)
type loaderData = CreateEventsPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  <SelectClub clubs={query.fragmentRefs} />
}
