%%raw("import { t } from '@lingui/macro'")
open LangProvider.Router

module ViewerFragment = %relay(`
  fragment AddEventButton_viewer on Viewer {
    user {
      id
    }
  }
`)

@react.component
let make = (
  ~context: AIAssistantModal.context={},
  ~createBasePath: option<string>=?,
  ~viewer: RescriptRelay.fragmentRefs<[> #AddEventButton_viewer]>,
) => {
  open Lingui.Util
  let viewerData = ViewerFragment.use(viewer)
  let isLoggedIn = viewerData.user->Option.isSome

  <WaitForMessages>
    {_ =>
      <Link
        to={
          let searchParamsObj = Js.Dict.empty()
          context.clubId
          ->Option.map(clubId => searchParamsObj->Js.Dict.set("clubId", clubId))
          ->ignore
          context.locationId
          ->Option.map(locationId => searchParamsObj->Js.Dict.set("locationId", locationId))
          ->ignore
          context.activitySlug
          ->Option.map(activitySlug =>
            searchParamsObj->Js.Dict.set("activitySlug", activitySlug)
          )
          ->ignore
          let base = createBasePath->Option.getOr("/events/create")
          let targetUrl =
            base ++ "?" ++ Router.createSearchParams(searchParamsObj)->Router.SearchParams.toString
          if isLoggedIn {
            targetUrl
          } else {
            let loginSearchParamsObj = Js.Dict.empty()
            loginSearchParamsObj->Js.Dict.set("return", targetUrl)
            "/oauth-login?" ++
              Router.createSearchParams(loginSearchParamsObj)->Router.SearchParams.toString
          }}
        className="flex w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-2xl font-medium transition-all shadow-lg shadow-purple-500/25 items-center justify-center gap-2">
        <Lucide.Sparkles className="w-5 h-5" />
        {t`Add an Event`}
      </Link>}
  </WaitForMessages>
}
