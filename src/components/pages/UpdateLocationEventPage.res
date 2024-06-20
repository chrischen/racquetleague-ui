%%raw("import { t } from '@lingui/macro'")
module Query = %relay(`
  query UpdateLocationEventPageQuery($eventId: ID!, $locationId: ID!) {
    location(id: $locationId) {
      ...CreateLocationEvent_location
    }
    event(id: $eventId) {
      ...CreateLocationEvent_event
    }
    ...CreateLocationEvent_activities
  }
  `)
type loaderData = UpdateLocationEventPageQuery_graphql.queryRef
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
      ->Option.flatMap(location => query.event->Option.map( event => <CreateLocationEvent event=event.fragmentRefs location=location.fragmentRefs query=query.fragmentRefs />))
      ->Option.getOr(t`Event or Location doesn't exist.`)}
  </WaitForMessages>
}
