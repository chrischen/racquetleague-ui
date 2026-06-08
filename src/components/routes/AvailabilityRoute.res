@genType
let \"Component" = AvailabilityPage.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/vi"),
})

let defaultActivityId = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

let getDateRange = () => {
  let now = Js.Date.make()
  let fmtDate = (d: Js.Date.t) => {
    let y = d->Js.Date.getFullYear->Float.toInt->Int.toString
    let m = (d->Js.Date.getMonth->Float.toInt + 1)->Int.toString->String.padStart(2, "0")
    let day = d->Js.Date.getDate->Float.toInt->Int.toString->String.padStart(2, "0")
    y ++ "-" ++ m ++ "-" ++ day
  }
  let fromDate = fmtDate(now)
  let toDate = fmtDate(Js.Date.fromFloat(now->Js.Date.getTime +. Float.fromInt(14 * 86400000)))
  (fromDate, toDate)
}

@genType
let loader = async ({context, params}: LoaderArgs.t) => {
  let (fromDate, toDate) = getDateRange()
  let query = AvailabilityPageQuery_graphql.load(
    ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
    ~variables={
      activityId: defaultActivityId,
      fromDate,
      toDate,
      afterDate: Util.Datetime.fromDate(Js.Date.make()),
    },
    ~fetchPolicy=RescriptRelay.StoreOrNetwork,
  )
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: query,
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}
