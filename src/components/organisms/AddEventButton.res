%%raw("import { t } from '@lingui/macro'")

module ViewerFragment = %relay(`
  fragment AddEventButton_viewer on Viewer {
    user {
      id
    }
  }
`)

let defaultActivityId = "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"

@react.component
let make = (
  ~context: AIAssistantModal.context={},
  ~viewer: RescriptRelay.fragmentRefs<[> #AddEventButton_viewer]>,
  ~gateQuery: RescriptRelay.fragmentRefs<[> #UseProfileGate_query]>,
) => {
  open Lingui.Util
  let viewerData = ViewerFragment.use(viewer)
  let isLoggedIn = viewerData.user->Option.isSome
  let navigate = Router.useNavigate()
  let createHref = CreateEventLink.useHref()
  let profileGate = UseProfileGate.use(~query=gateQuery, ~context=ProfileModal.Availability)

  let (showModal, setShowModal) = React.useState(() => false)
  let (commitSetAvailability, _) = UseSetAvailabilityDay.use()
  let env = RescriptRelay.useEnvironmentFromContext()

  // The context (club, venue, activity) rides along as the form's prefill.
  let contextParams = () => {
    let params = []
    context.clubId->Option.forEach(v => params->Array.push(("clubId", v)))
    context.locationId->Option.forEach(v => params->Array.push(("locationId", v)))
    context.activitySlug->Option.forEach(v => params->Array.push(("activitySlug", v)))
    params
  }
  let buildCreateUrl = () => createHref(contextParams())

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
    intents: array<TimeWindow.playIntent>,
  ) => {
    let _ = commitSetAvailability(
      ~localDate,
      ~activityId=defaultActivityId,
      ~intervals=UseSetAvailabilityDay.intervalsOfIntents(intents),
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

  let handleCreateEvent = (localDate: string, intent: TimeWindow.playIntent) =>
    navigate(
      createHref(
        contextParams()->Array.concat([
          ("date", localDate),
          ("startHour", intent.start->Float.toString),
          ("endHour", intent.end->Float.toString),
        ]),
      ),
      None,
    )

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
        onMarkAvailable={(localDate, intents) =>
          profileGate.require(() => handleMarkAvailable(localDate, intents))}
        onCreateEvent=handleCreateEvent
      />
      {profileGate.modal}
    </>}
  </WaitForMessages>
}
