%%raw("import { t } from '@lingui/macro'")
open LangProvider.Router

module Query = %relay(`
  query ViewerClubsPageQuery($after: String, $first: Int, $before: String) {
    viewer {
      __id
      adminClubs(after: $after, first: $first, before: $before)
        @connection(key: "viewer_adminClubs") {
        edges {
          node {
            id
            name
            slug
          }
        }
      }
    }
  }
  `)
type loaderData = ViewerClubsPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)

  let clubs =
    query.viewer
    ->Option.map(v => v.adminClubs)
    ->Option.flatMap(clubs => clubs.edges)
    ->Option.getOr([])
    ->Array.filterMap(edge => edge)
    ->Array.filterMap(edge => edge.node)

  <WaitForMessages>
    {_ => <>
      <Layout.Container>
        <h1>
          <div className="flex items-center mt-1 text-2xl font-semibold leading-6 text-gray-900">
            {t`my clubs`}
          </div>
        </h1>
        {switch clubs->Array.length {
        | 0 => <div className="mt-4 text-gray-500"> {t`You are not an admin of any clubs.`} </div>
        | _ =>
          <ul className="mt-4 divide-y divide-gray-200">
            {clubs
            ->Array.map(club =>
              <li key={club.id} className="py-4">
                {club.slug
                ->Option.map(slug =>
                  <Link
                    to={"/clubs/" ++ slug}
                    className="text-lg font-semibold text-indigo-600 hover:text-indigo-500">
                    {club.name->Option.getOr("---")->React.string}
                  </Link>
                )
                ->Option.getOr(
                  <span className="text-lg font-semibold text-gray-900">
                    {club.name->Option.getOr("---")->React.string}
                  </span>,
                )}
              </li>
            )
            ->React.array}
          </ul>
        }}
      </Layout.Container>
    </>}
  </WaitForMessages>
}
