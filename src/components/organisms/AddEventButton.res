%%raw("import { t } from '@lingui/macro'")

module ViewerFragment = %relay(`
  fragment AddEventButton_viewer on Viewer {
    user {
      id
    }
  }
`)

module SetAvailabilityMutation = %relay(`
  mutation AddEventButtonSetAvailabilityMutation($input: SetAvailabilityDayInput!) {
    setAvailabilityDay(input: $input) {
      day {
        id
        localDate
        intervals {
          startHour
          endHour
        }
      }
      errors {
        message
      }
    }
  }
`)

let defaultActivityId = "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"

@react.component
let make = (
  ~context: AIAssistantModal.context={},
  ~createBasePath: option<string>=?,
  ~viewer: RescriptRelay.fragmentRefs<[> #AddEventButton_viewer]>,
) => {
  open Lingui.Util
  let viewerData = ViewerFragment.use(viewer)
  let isLoggedIn = viewerData.user->Option.isSome
  let navigate = Router.useNavigate()

  let (showModal, setShowModal) = React.useState(() => false)
  let (commitSetAvailability, _) = SetAvailabilityMutation.use()
  let env = RescriptRelay.useEnvironmentFromContext()
  let userLocation = UseUserLocation.use()

  let buildCreateUrl = (
    ~localDate: option<string>=?,
    ~startHour: option<int>=?,
    ~_unused: unit=(),
    (),
  ) => {
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
    localDate->Option.map(d => searchParamsObj->Js.Dict.set("date", d))->ignore
    startHour
    ->Option.map(h => searchParamsObj->Js.Dict.set("startHour", h->Int.toString))
    ->ignore
    let base = createBasePath->Option.getOr("/events/create")
    base ++ "?" ++ Router.createSearchParams(searchParamsObj)->Router.SearchParams.toString
  }

  let handleButtonClick = _ => {
    if isLoggedIn {
      setShowModal(_ => true)
    } else {
      let targetUrl = buildCreateUrl()
      let loginSearchParamsObj = Js.Dict.empty()
      loginSearchParamsObj->Js.Dict.set("return", targetUrl)
      navigate(
        "/oauth-login?" ++
        Router.createSearchParams(loginSearchParamsObj)->Router.SearchParams.toString,
        None,
      )
    }
  }

  let handleMarkAvailable = (
    localDate: string,
    intents: array<TimeWindowPicker.playIntent>,
  ) => {
    let intervals: array<RelaySchemaAssets_graphql.input_IntervalInput> = intents->Array.map((
      i
    ): RelaySchemaAssets_graphql.input_IntervalInput => {
      startHour: i.start->Float.toInt,
      endHour: i.end->Float.toInt,
    })
    let _ = commitSetAvailability(
      ~variables={
        input: {
          localDate,
          activityId: defaultActivityId,
          location: userLocation,
          intervals,
        },
      },
      ~onCompleted=(res, _err) => {
        if res.setAvailabilityDay.day->Option.isSome {
          RescriptRelay.commitLocalUpdate(
            ~environment=env,
            ~updater=store =>
              store
              ->RescriptRelay.RecordSourceSelectorProxy.getRoot
              ->RescriptRelay.RecordProxy.invalidateRecord,
          )
        }
      },
    )
  }

  let handleCreateEvent = (localDate: string, intent: TimeWindowPicker.playIntent) => {
    let searchParamsObj = Js.Dict.empty()
    context.clubId->Option.map(clubId => searchParamsObj->Js.Dict.set("clubId", clubId))->ignore
    context.locationId
    ->Option.map(locationId => searchParamsObj->Js.Dict.set("locationId", locationId))
    ->ignore
    context.activitySlug
    ->Option.map(activitySlug => searchParamsObj->Js.Dict.set("activitySlug", activitySlug))
    ->ignore
    searchParamsObj->Js.Dict.set("date", localDate)
    searchParamsObj->Js.Dict.set("startHour", intent.start->Float.toInt->Int.toString)
    searchParamsObj->Js.Dict.set("endHour", intent.end->Float.toInt->Int.toString)
    let base = createBasePath->Option.getOr("/events/create")
    let url =
      base ++ "?" ++ Router.createSearchParams(searchParamsObj)->Router.SearchParams.toString
    navigate(url, None)
  }

  <WaitForMessages>
    {_ => <>
      <button
        onClick=handleButtonClick
        className="flex w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-2xl font-medium transition-all shadow-lg shadow-purple-500/25 items-center justify-center gap-2">
        <Lucide.Sparkles className="w-5 h-5" />
        {t`Add an Event`}
      </button>
      <NewPlanModal.make
        isOpen=showModal
        onClose={_ => setShowModal(_ => false)}
        onMarkAvailable=handleMarkAvailable
        onCreateEvent=handleCreateEvent
      />
    </>}
  </WaitForMessages>
}
