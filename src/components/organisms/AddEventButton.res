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
  ~viewer: RescriptRelay.fragmentRefs<[> #AddEventButton_viewer]>,
) => {
  open Lingui.Util
  let viewerData = ViewerFragment.use(viewer)
  let isLoggedIn = viewerData.user->Option.isSome

  <WaitForMessages>
    {_ =>
      <Link
        to={if isLoggedIn {
          let searchParamsObj = Js.Dict.empty()
          context.clubId
          ->Option.map(clubId => searchParamsObj->Js.Dict.set("clubId", clubId))
          ->ignore
          context.locationId
          ->Option.map(locationId => searchParamsObj->Js.Dict.set("locationId", locationId))
          ->ignore
          context.activitySlug
          ->Option.map(activitySlug => searchParamsObj->Js.Dict.set("activitySlug", activitySlug))
          ->ignore
          let searchParams =
            Router.createSearchParams(searchParamsObj)->Router.SearchParams.toString
          "/events/create?" ++ searchParams
        } else {
          // Build the target URL for event creation
          let targetSearchParamsObj = Js.Dict.empty()
          context.clubId
          ->Option.map(clubId => targetSearchParamsObj->Js.Dict.set("clubId", clubId))
          ->ignore
          context.locationId
          ->Option.map(locationId => targetSearchParamsObj->Js.Dict.set("locationId", locationId))
          ->ignore
          context.activitySlug
          ->Option.map(activitySlug =>
            targetSearchParamsObj->Js.Dict.set("activitySlug", activitySlug)
          )
          ->ignore
          let targetSearchParams =
            Router.createSearchParams(targetSearchParamsObj)->Router.SearchParams.toString
          let targetUrl = "/events/create?" ++ targetSearchParams

          // Create login URL with return parameter pointing to event creation page
          let loginSearchParamsObj = Js.Dict.empty()
          loginSearchParamsObj->Js.Dict.set("return", targetUrl)
          let loginSearchParams =
            Router.createSearchParams(loginSearchParamsObj)->Router.SearchParams.toString
          "/oauth-login?" ++ loginSearchParams
        }}
        className="flex w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-2xl font-medium transition-all shadow-lg shadow-purple-500/25 items-center justify-center gap-2">
        <Lucide.Sparkles className="w-5 h-5" />
        {t`Add an Event`}
      </Link>}
  </WaitForMessages>
}
