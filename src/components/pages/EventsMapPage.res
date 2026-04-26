%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module EventsMapPageQuery = %relay(`
  query EventsMapPageQuery($after: String, $first: Int, $before: String, $afterDate: Datetime, $filters: EventFilters) {
    ...PkEventsListFragment @arguments(
      after: $after,
      first: $first,
      before: $before,
      afterDate: $afterDate,
      filters: $filters
    )
    events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate) {
      ...PinMap_eventConnection
    }
  }
`)

type loaderData = EventsMapPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@genType @react.component
let make = () => {
  let query = useLoaderData()
  let {fragmentRefs, events} = EventsMapPageQuery.usePreloaded(~queryRef=query.data)
  let (hoveredLocationId, setHoveredLocationId) = React.useState((): option<string> => None)
  let (selectedLocationId, setSelectedLocationId) = React.useState((): option<string> => None)
  let onHoverLocation = (locationId: option<string>) => setHoveredLocationId(_ => locationId)

  <WaitForMessages>
    {() =>
      <div className="flex flex-col lg:flex-row lg:items-start">
        <div
          className="w-full pb-[calc(50vh+57px)] lg:pb-0 lg:flex-1 min-w-0 lg:border-r lg:border-gray-200 lg:dark:border-[#2a2b30]">
          <PkEventsList events=fragmentRefs onHoverLocation ?selectedLocationId />
        </div>
        <div
          className="fixed bottom-[57px] left-0 right-0 h-[calc(50vh-57px)] z-30 lg:relative lg:z-auto lg:bottom-auto lg:left-auto lg:right-auto lg:flex-1 lg:sticky lg:top-0 lg:h-[calc(100vh-56px)]">
          <PinMap
            connection={events.fragmentRefs}
            onLocationClick={location =>
              setSelectedLocationId(prev => prev == Some(location.id) ? None : Some(location.id))}
            selected=?hoveredLocationId
            navigateOnClick=false
          />
        </div>
      </div>}
  </WaitForMessages>
}
