%%raw("import { t } from '@lingui/macro'")
open LangProvider.Router

@react.component
let make = (~context: AIAssistantModal.context={}) => {
  open Lingui.Util
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
          ->Option.map(activitySlug => searchParamsObj->Js.Dict.set("activitySlug", activitySlug))
          ->ignore
          let searchParams =
            Router.createSearchParams(searchParamsObj)->Router.SearchParams.toString
          "/events/create?" ++ searchParams
        }
        className="flex w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-2xl font-medium transition-all shadow-lg shadow-purple-500/25 items-center justify-center gap-2">
        <Lucide.Sparkles className="w-5 h-5" />
        {t`Add an Event`}
      </Link>}
  </WaitForMessages>
}
