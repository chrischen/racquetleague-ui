%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module EventsQuery = %relay(`
  query EventsQuery($after: String, $first: Int, $before: String, $afterDate: Datetime, $filters: EventFilters) {
    ...PkEventsListFragment @arguments(
      after: $after,
      first: $first,
      before: $before,
      afterDate: $afterDate,
      filters: $filters
    )
  }
`)
/* module Fragment = %relay(`
  fragment Events_event on Event {
    ... Event_event
  }
`)*/
/* module Query = %relay(`
  query EventQuery {
    event(id: "1") {
      title
			... EventRsvps_event
		}
  }
`)*/
module ActivityDropdownMenu = {
  type navItem = {label: string, url: string, initials?: string}
  let ts = Lingui.UtilString.t
  @react.component
  let make = () => {
    open Dropdown
    let activities = [
      {label: ts`Pickleball`, url: "/e/pickleball", initials: "P"},
      {label: ts`Badminton`, url: "/e/badminton", initials: "B"},
    ]
    <DropdownMenu className="min-w-80 lg:min-w-64" anchor="bottom start">
      {activities
      ->Array.map(a =>
        <React.Fragment key={a.label}>
          <DropdownItem href=a.url>
            {a.initials
            ->Option.map(initials =>
              <Avatar slot="icon" initials className="bg-purple-500 text-white" />
            )
            ->Option.getOr(React.null)}
            <DropdownLabel> {a.label->React.string} </DropdownLabel>
          </DropdownItem>
          <DropdownDivider />
        </React.Fragment>
      )
      ->React.array}
    </DropdownMenu>
  }
}
type loaderData = EventsQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

// URL Params
type params = {activitySlug: option<string>, lang: option<string>}

@react.component
let make = () => {
  let query = useLoaderData()
  let {fragmentRefs} = EventsQuery.usePreloaded(~queryRef=query.data)

  let shouldHideEvent = (
    event: PkEventsListFragment_graphql.Types.fragment_events_edges_node,
    viewer: option<PkEventsListFragment_graphql.Types.fragment_viewer>,
  ) => {
    let userClubIds =
      viewer
      ->Option.flatMap(v => v.clubs.edges)
      ->Option.map(edges =>
        edges
        ->Array.filterMap(edge => edge)
        ->Array.filterMap(edge => edge.node)
        ->Array.map(node => node.id)
        ->Set.fromArray
      )
      ->Option.getOr(Set.make())

    let hasClubs = Set.size(userClubIds) > 0

    let isPrivate = event.shadow->Option.getOr(false)
    let isFromNonMemberClub = switch viewer {
    | None => false
    | Some(_) if !hasClubs => false
    | Some(_) =>
      event.club
      ->Option.map(club => !Set.has(userClubIds, club.id))
      ->Option.getOr(false)
    }
    isPrivate || isFromNonMemberClub
  }

  <WaitForMessages> {() => <PkEventsList events=fragmentRefs shouldHideEvent />} </WaitForMessages>
}
let \"Component" = make

module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  ja: Lingui.import("../../locales/src/components/pages/Events.re/ja"),
  en: Lingui.import("../../locales/src/components/pages/Events.re/en"),
  th: Lingui.import("../../locales/src/components/pages/Events.re/th"),
  zhCN: Lingui.import("../../locales/src/components/pages/Events.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/Events.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/Events.re/vi"),
  zhTW: Lingui.import("../../locales/src/components/pages/Events.re/zh-TW"),
})

let loader = async ({context, params, request}: LoaderArgs.t) => {
  let validLangs = ["en", "ja", "th", "zh-TW", "zh-CN", "ko", "vi"]
  switch params.lang {
  | Some(lang) if !(validLangs->Array.includes(lang)) =>
    // Throw custom ReScript exception for invalid language
    raise(Lang.InvalidLanguageException(lang))
  | _ => ()
  }
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  let shadow =
    url.searchParams
    ->Router.SearchParams.get("shadow")
    ->Option.map(v => v == "true")
    ->Option.getOr(true)
  let afterDate =
    url.searchParams
    ->Router.SearchParams.get("afterDate")
    ->Option.map(d => {
      d->Js.Date.fromString->Util.Datetime.fromDate
    })
  // @TODO: Server Date will mismatch with client date potentially
  // ->Option.getOr(Js.Date.make()->Util.Datetime.fromDate)

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  {
    WaitForMessages.data: EventsQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        ?after,
        ?before,
        ?afterDate,
        filters: {
          activitySlug: ?params.activitySlug,
          shadow,
        },
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    // i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
    // i18nData: !RelaySSRUtils.ssr ? await Localized.loadMessages(params.lang, loadMessages) : %raw("[]"),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  }
}

// @genType
// let \"HydrateFallbackElement" =
//   <div> {React.string("Loading fallback...")} </div>

// %raw("loade;.hydrate = true")
// let useFragmentRefs = (): RescriptRelay.fragmentRefs<[#EventsListFragment]> => {
//   let data = Router.useOutletContext()
//   data
// }
