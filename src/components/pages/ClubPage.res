%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query ClubPageQuery($id: ID!, $after: String, $first: Int, $before: String, $filters: EventFilters!) {
    club(id: $id) {
      name
      ...ClubDetails_club
    }
    ...EventsListFragment @arguments(after: $after, first: $first, before: $before, filters: $filters)
  }
  `)
type loaderData = ClubPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  <WaitForMessages>
    {_ => {
      query.club
      ->Option.map(club => <>
        <Layout.Container>
          <h1>
            <div className="text-base leading-6 text-gray-500"> {t`club`} </div>
            <div className="mt-1 text-2xl font-semibold leading-6 text-gray-900">
              {club.name->Option.getOr("?")->React.string}
            </div>
          </h1>
          <ClubDetails club={club.fragmentRefs} />
        </Layout.Container>
        <EventsList events={query.fragmentRefs} />
      </>)
      ->Option.getOr(<Layout.Container>{t`club not found`}</Layout.Container>)
    }}
  </WaitForMessages>
}
