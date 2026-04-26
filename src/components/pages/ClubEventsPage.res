%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

@val @scope(("navigator", "clipboard"))
external writeText: string => Js.Promise.t<unit> = "writeText"
@val @scope(("window", "location")) external locationOrigin: string = "origin"

module Query = %relay(`
  query ClubEventsPageQuery($slug: String!) {
    club(slug: $slug) {
      id
      name
      description
      shareLink
      viewerMembership { isAdmin }
      ...ClubDetails_club
    }
    viewer {
      ...AddEventButton_viewer
    }
  }
`)

type loaderData = ClubEventsPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

type urlParams = {slug: string}

@react.component
let make = () => {
  let ts = Lingui.UtilString.t
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  let {club, viewer} = query
  let (shareCopied, setShareCopied) = React.useState(() => false)
  let urlParams: urlParams = Router.useParams()

  <WaitForMessages>
    {() =>
      club
      ->Option.map(c =>
        <div className="flex flex-col h-full overflow-y-auto">
          <div className="px-4 py-3 border-b border-gray-200 dark:border-[#2a2b30]">
            <h1 className="text-lg font-semibold text-gray-900 dark:text-white">
              {c.name->Option.getOr("?")->React.string}
            </h1>
            {c.description
            ->Option.map(d =>
              <p className="font-mono text-xs text-gray-500 dark:text-gray-400 mt-1">
                {d->React.string}
              </p>
            )
            ->Option.getOr(React.null)}
            <div className="flex items-center gap-2 mt-2">
              {c.viewerMembership
              ->Option.flatMap(m => m.isAdmin)
              ->Option.getOr(false)
                ? c.shareLink
                  ->Option.map(link =>
                    <button
                      className="text-xs font-mono px-2 py-1 rounded border border-gray-200 dark:border-[#3a3b40] text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors"
                      onClick={_ => {
                        writeText(locationOrigin ++ link)->ignore
                        setShareCopied(_ => true)
                        let _ = Js.Global.setTimeout(() => setShareCopied(_ => false), 2000)
                      }}>
                      {(shareCopied ? ts`Copied!` : ts`Share link`)->React.string}
                    </button>
                  )
                  ->Option.getOr(React.null)
                : React.null}
              {viewer
              ->Option.map(v =>
                <AddEventButton
                  context={clubId: ?Some(c.id)}
                  createBasePath={"/clubs/" ++ urlParams.slug ++ "/events/create"}
                  viewer={v.fragmentRefs}
                />
              )
              ->Option.getOr(React.null)}
            </div>
          </div>
          <React.Suspense
            fallback={<div className="p-6 text-gray-500"> {t`Loading events...`} </div>}>
            <Router.Outlet />
          </React.Suspense>
        </div>
      )
      ->Option.getOr(<div className="p-6 text-gray-500"> {t`Club not found`} </div>)}
  </WaitForMessages>
}
