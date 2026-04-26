%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Query = %relay(`
  query PkLocationPageQuery(
    $id: ID!
    $after: String
    $first: Int
    $before: String
    $afterDate: Datetime
  ) {
    location(id: $id) {
      name
      details
      address
      links
    }
    ...PkEventsListFragment @arguments(
      after: $after
      first: $first
      before: $before
      afterDate: $afterDate
      filters: { locationId: $id }
    )
    events(after: $after, first: $first, before: $before, filters: { locationId: $id }, afterDate: $afterDate) {
      ...PinMap_eventConnection
    }
  }
`)

type loaderData = PkLocationPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  let data = useLoaderData()
  let {fragmentRefs, location, events} = Query.usePreloaded(~queryRef=data.data)
  let (selectedLocationId, setSelectedLocationId) = React.useState((): option<string> => None)
  let onHoverLocation = (locationId: option<string>) => setSelectedLocationId(_ => locationId)

  <WaitForMessages>
    {() =>
      location
      ->Option.map(loc =>
        <div className="flex flex-col h-full overflow-y-auto">
          <div className="px-4 py-3 border-b border-gray-200 dark:border-[#2a2b30]">
            <h1 className="text-lg font-semibold text-gray-900 dark:text-white">
              {loc.name->Option.getOr("?")->React.string}
            </h1>
            {loc.details
            ->Option.map(d =>
              <p className="font-mono text-xs text-gray-500 dark:text-gray-400 mt-1">
                {d->React.string}
              </p>
            )
            ->Option.getOr(React.null)}
            {loc.address
            ->Option.map(addr => {
              let defaultLink = loc.links->Option.flatMap(links => links->Array.get(0))
              let mapsUrl = defaultLink->Option.getOr(`https://maps.google.com/?q=${addr}`)
              <a
                href=mapsUrl
                target="_blank"
                rel="noopener noreferrer"
                className="font-mono text-xs text-gray-500 dark:text-gray-400 mt-0.5 block hover:underline">
                {addr->React.string}
              </a>
            })
            ->Option.getOr(React.null)}
          </div>
          <div className="h-48 border-b border-gray-200 dark:border-[#2a2b30] flex-shrink-0">
            <PinMap
              connection={events.fragmentRefs}
              onLocationClick={location => setSelectedLocationId(_ => Some(location.id))}
              selected=?selectedLocationId
            />
          </div>
          <PkEventsList events=fragmentRefs onHoverLocation />
        </div>
      )
      ->Option.getOr(<div className="p-6 text-gray-500"> {t`Location not found`} </div>)}
  </WaitForMessages>
}
