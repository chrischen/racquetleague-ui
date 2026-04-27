%%raw("import { t } from '@lingui/macro'")
module Query = %relay(`
  query CreateClubEventsPageQuery($clubId: ID!) {
    club(id: $clubId) {
      ...CreateClubEventsForm_club
    }
    ...CreateClubEventsForm_query
  }
  `)
type loaderData = CreateClubEventsPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  let (searchParams, _) = Router.useSearchParams()
  let prefillDate = searchParams->Router.SearchParams.get("date")
  <div className="max-w-2xl mx-auto px-4 py-8 space-y-6 w-full">
    <WaitForMessages>
      {() =>
        query.club
        ->Option.map(club =>
          <CreateClubEventsForm club=club.fragmentRefs query=query.fragmentRefs ?prefillDate />
        )
        ->Option.getOr(t`club doesn't exist.`)}
    </WaitForMessages>
  </div>
}
