%%raw("import { t } from '@lingui/macro'")
module Query = %relay(`
  query UpdateEventPageQuery($eventId: ID!, $locationId: ID!) {
    location(id: $locationId) {
      ...CreateLocationEventForm_location
      ...SelectedLocation_location
    }
    event(id: $eventId) {
      id
      ...UpdateLocationEventForm_event
    }
    ...ClubActivitySelector_query
  }
  `)
type loaderData = UpdateEventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  open LangProvider.Router
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  let navigate = Router.useNavigate()
  <div
    className="min-h-screen bg-gray-50 dark:bg-[#111111] w-full text-gray-900 dark:text-gray-100 transition-colors">
    <WaitForMessages>
      {() => <>
        <div
          className="bg-white dark:bg-[#1a1a1a] shadow-sm border-b border-gray-200 dark:border-gray-800 transition-colors">
          <div className="max-w-2xl mx-auto px-4 py-4 flex items-center justify-between">
            <Link
              to={"/events/" ++ query.event->Option.map(e => e.id)->Option.getOr("")}
              className="inline-flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors font-medium">
              <Lucide.ArrowLeft className="w-5 h-5" />
              {t`Cancel`}
            </Link>
            <h1 className="text-lg font-bold"> {t`Update Event`} </h1>
            <div className="w-20" />
          </div>
        </div>
        <div className="max-w-2xl mx-auto px-4 py-8 space-y-6">
          {query.location
          ->Option.flatMap(location => {
            query.event->Option.map(event => <>
              <SelectedLocation
                location={location.fragmentRefs}
                onNewLocation={location =>
                  navigate("../update/" ++ event.id ++ "/" ++ location, None)}
              />
              <UpdateLocationEventForm
                event=event.fragmentRefs location=location.fragmentRefs query=query.fragmentRefs
              />
            </>)
          })
          ->Option.getOr(t`Event or Location doesn't exist.`)}
        </div>
      </>}
    </WaitForMessages>
  </div>
}
