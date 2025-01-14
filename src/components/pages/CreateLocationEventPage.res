%%raw("import { t } from '@lingui/macro'")
module Query = %relay(`
  query CreateLocationEventPageQuery($locationId: ID!, $after: String, $first: Int, $before: String) {
    location(id: $locationId) {
      ...CreateLocationEventForm_location
    }
    ...CreateLocationEventForm_query @arguments(after: $after, first: $first, before: $before)
  }
  `)
type loaderData = CreateLocationEventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  <WaitForMessages>
    {() =>
      query.location
      ->Option.map(location => <>
        <CreateLocationEventForm location=location.fragmentRefs query=query.fragmentRefs />
      </>)
      ->Option.getOr(t`location doesn't exist.`)}
  </WaitForMessages>
}
