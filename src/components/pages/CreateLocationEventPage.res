%%raw("import { t } from '@lingui/macro'")
module Query = %relay(`
  query CreateLocationEventPageQuery($locationId: ID!) {
    location(id: $locationId) {
      ...CreateLocationEvent_location
    }
    ...CreateLocationEvent_activities
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
      ->Option.map(location => <CreateLocationEvent location=location.fragmentRefs query=query.fragmentRefs />)
      ->Option.getOr(t`Location doesn't exist.`)}
  </WaitForMessages>
}
