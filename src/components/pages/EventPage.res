%%raw("import { t } from '@lingui/macro'")

module EventPageQuery = %relay(`
  query EventPageQuery(
    $eventId: ID!
    $topic: String!
    $after: String
    $first: Int
    $before: String
  ) {
    viewer {
      user {
        id
        ...RSVPSection_user @arguments(eventId: $eventId)
      }
    }
    event(id: $eventId) {
      __id
      id
      title
      details
      startDate
      viewerIsAdmin
      viewerHasRsvp
      deleted
      activity {
        id
        name
        slug
      }
      location {
        name
        details
        id
      }
      club {
        name
      }
      ...EventDetails_event
      ...RSVPSection_event
        @arguments(after: $after, first: $first, before: $before)
      ...EventHeader_event
    }
    ...EventMessages_query @arguments(topic: $topic, after: $after, before: $before, first: $first)
  }
`)

module EventCancelMutation = %relay(`
 mutation EventPageCancelMutation($eventId: ID!) {
   cancelEvent(eventId: $eventId) {
     event {
       id
       listed
       deleted
     }
   }
 }
`)

module EventUncancelMutation = %relay(`
 mutation EventPageUncancelMutation($eventId: ID!) {
   uncancelEvent(eventId: $eventId) {
     event {
       id
       listed
       deleted
     }
   }
 }
`)

type loaderData = EventPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  let ts = Lingui.UtilString.t
  let query = useLoaderData()
  let {event, viewer, fragmentRefs: queryFragmentRefs} = EventPageQuery.usePreloaded(
    ~queryRef=query.data,
  )
  let viewerUser = viewer->Option.flatMap(v => v.user)

  // Admin mutations
  let (cancelEvent, canceling) = EventCancelMutation.use()
  let (uncancelEvent, uncanceling) = EventUncancelMutation.use()

  <WaitForMessages>
    {() =>
      event
      ->Option.map(event => {
        let startDateJs =
          event.startDate
          ->Option.map(Util.Datetime.toDate)
          ->Option.getOr(Js.Date.make())

        <div className="w-full max-w-7xl mx-auto pb-16 md:pb-8">
          <EventHeader event=event.fragmentRefs />
          {switch (event.viewerIsAdmin, viewerUser) {
          | (true, Some(_)) =>
            <div className="px-4 md:px-6 lg:px-8 mb-6">
              <div className="bg-gray-50 rounded-lg p-4 border">
                <div className="flex flex-row gap-2">
                  <Button.Button
                    href={"/events/update/" ++
                    event.id ++
                    "/" ++
                    event.location->Option.map(l => l.id)->Option.getOr("")}>
                    {(ts`edit event`)->React.string}
                  </Button.Button>
                  {switch event.deleted {
                  | Some(_) =>
                    <Button.Button
                      onClick={_ =>
                        !uncanceling ? uncancelEvent(~variables={eventId: event.id})->ignore : ()}>
                      {(ts`uncancel event`)->React.string}
                    </Button.Button>
                  | None =>
                    <Button.Button
                      onClick={_ =>
                        !canceling ? cancelEvent(~variables={eventId: event.id})->ignore : ()}>
                      {(ts`cancel event`)->React.string}
                    </Button.Button>
                  }}
                </div>
              </div>
            </div>
          | _ => React.null
          }}
          <div className="px-4 md:px-6 lg:px-8">
            <div className="md:grid md:grid-cols-12 md:gap-8">
              <div className="md:col-span-7 lg:col-span-8 pb-8 md:pb-0">
                <EventDetails event=event.fragmentRefs />
                {switch (viewerUser, event.activity) {
                | (Some(_), Some(activity)) =>
                  switch activity.slug {
                  | Some("pickleball" | "badminton") =>
                    <div className="mt-6">
                      <div className="bg-gray-50 rounded-lg p-4 border">
                        <Button.Button
                          href={"/league/events/" ++
                          event.id ++
                          "/" ++
                          activity.slug->Option.getOr("")}>
                          {(ts`Manage Event`)->React.string}
                        </Button.Button>
                      </div>
                    </div>
                  | _ => React.null
                  }
                | _ => React.null
                }}
                <EventMessages
                  queryRef=queryFragmentRefs
                  eventStartDate=startDateJs
                  eventId=event.id
                  viewerHasRsvp=?event.viewerHasRsvp
                />
              </div>
              <div className="md:col-span-5 lg:col-span-4">
                <RSVPSection
                  event=event.fragmentRefs user={viewerUser->Option.map(v => v.fragmentRefs)}
                />
              </div>
            </div>
          </div>
        </div>
      })
      ->Option.getOr(
        <div className="p-6 text-center text-gray-600">
          {(ts`Event not found`)->React.string}
        </div>,
      )}
  </WaitForMessages>
}

@genType
let default = make

@genType
let \"Component" = make

type params = {
  ...EventPageQuery_graphql.Types.variables,
  lang: option<string>,
}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/EventPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/EventPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/EventPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/EventPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/EventPage.re/zh-CN"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make

  // let lang = params.lang->Option.getOr("en")

  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore

  Router.defer({
    WaitForMessages.data: EventPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={eventId: params.eventId, topic: params.eventId ++ ".updated", ?after, ?before},
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

// @genType
// let \"HydrateFallbackElement" = <div> {React.string("Loading fallback...")} </div>
// %raw("loader.hydrate = true")

// @NOTE Force lingui to include the potential dynamic values here
let __unused = () => {
  let td = Lingui.UtilString.td

  @live (td({id: "Badminton"})->ignore)

  @live (td({id: "Table Tennis"})->ignore)

  @live (td({id: "Pickleball"})->ignore)

  @live (td({id: "Futsal"})->ignore)
  @live (td({id: "drill"})->ignore)
  @live (td({id: "comp"})->ignore)
  @live (td({id: "rec"})->ignore)
  @live (td({id: "all level"})->ignore)
}
