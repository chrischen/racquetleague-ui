%%raw("import { t } from '@lingui/macro'")
module Query = %relay(`
  query UpdateEventPageQuery($eventId: ID!, $locationId: ID!) {
    location(id: $locationId) {
      ...CreateLocationEventForm_location
      ...SelectedLocation_location
    }
    event(id: $eventId) {
      id
      ...CreateLocationEventForm_event
    }
    ...CreateLocationEventForm_query
  }
  `)
type loaderData = UpdateEventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  let navigate = Router.useNavigate()
  <Layout.Container>
    <WaitForMessages>
      {() =>
        query.location
        ->Option.flatMap(location => {
          query.event->Option.map(event =>
            <Grid>
              <SelectedLocation
                key="selected_location"
                location={location.fragmentRefs}
                onNewLocation={location =>
                  navigate("../update/" ++ event.id ++ "/" ++ location, None)}
              />
              <CreateLocationEventForm
                key="create_location_event_form"
                event=event.fragmentRefs
                location=location.fragmentRefs
                query=query.fragmentRefs
              />
            </Grid>
          )
        })
        ->Option.getOr(t`Event or Location doesn't exist.`)}
    </WaitForMessages>
  </Layout.Container>
}
