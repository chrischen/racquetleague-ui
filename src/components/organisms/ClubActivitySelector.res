%%raw("import { t } from '@lingui/macro'")

@send
external scrollIntoView: (Dom.element, {"behavior": string, "block": string}) => unit =
  "scrollIntoView"

module QueryFragment = %relay(`
  fragment ClubActivitySelector_query on Query
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 100 }
  ) {
    activities {
      id
      name
      slug
    }
    ...CreateClubForm_activities
    viewer {
      __id
      adminClubs(after: $after, first: $first, before: $before)
        @connection(key: "viewer_adminClubs") {
        edges {
          node {
            id
            name
            defaultActivity {
              id
            }
          }
        }
      }
    }
  }
`)

type selection = {
  clubId: option<string>,
  activityId: option<string>,
  isAddingClub: bool,
}

@react.component
let make = (
  ~query: RescriptRelay.fragmentRefs<[> #ClubActivitySelector_query]>,
  ~initialClubId: option<string>=?,
  ~initialActivitySlug: option<string>=?,
  ~initialActivityId: option<string>=?,
  ~onChange: selection => unit,
  ~triggerShake: int=0,
) => {
  open Lingui.Util
  let td = Lingui.UtilString.dynamic
  let formQuery = QueryFragment.use(query)
  let clubs =
    formQuery.viewer
    ->Option.map(v => v.adminClubs->QueryFragment.getConnectionNodes)
    ->Option.getOr([])

  let defaultActivityId =
    formQuery.activities
    ->Array.find(a => a.slug->Option.map(s => s == "pickleball")->Option.getOr(false))
    ->Option.map(a => a.id)
    ->Option.orElse(formQuery.activities->Array.get(0)->Option.map(a => a.id))

  let resolvedInitialActivity =
    initialActivitySlug
    ->Option.flatMap(slug =>
      formQuery.activities->Array.find(a =>
        a.slug->Option.map(s => s == slug)->Option.getOr(false)
      )
    )
    ->Option.map(a => a.id)
    ->Option.orElse(initialActivityId)
    ->Option.orElse(defaultActivityId)

  let resolvedInitialClub =
    initialClubId->Option.orElse(clubs->Array.get(0)->Option.map(c => c.id))

  let (selectedClub, setSelectedClub) = React.useState(() => resolvedInitialClub)
  let (selectedActivity, setSelectedActivity) = React.useState(() => resolvedInitialActivity)
  let (isClubActivitySelectorActive, setIsClubActivitySelectorActive) = React.useState(() => false)
  let (showAddClub, setShowAddClub) = React.useState(() => false)
  let (shakeClubForm, setShakeClubForm) = React.useState(() => false)
  let clubFormRef: React.ref<Js.Nullable.t<Dom.element>> = React.useRef(Js.Nullable.null)

  // Notify parent of initial selection on mount
  React.useEffect(() => {
    onChange({clubId: selectedClub, activityId: selectedActivity, isAddingClub: false})
    None
  }, [])

  // Shake club form when parent increments triggerShake
  React.useEffect(() => {
    if triggerShake > 0 {
      clubFormRef.current
      ->Js.Nullable.toOption
      ->Option.map(el => {
        el->scrollIntoView({"behavior": "smooth", "block": "center"})
        setShakeClubForm(_ => true)
        let _ = Js.Global.setTimeout(() => setShakeClubForm(_ => false), 600)
      })
      ->ignore
    }
    None
  }, [triggerShake])

  <div>
    <label
      className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
      {t`Club & Activity`}
    </label>
    {!isClubActivitySelectorActive
      ? <button
          type_="button"
          onClick={_ => setIsClubActivitySelectorActive(_ => true)}
          className="w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg text-left hover:border-gray-400 dark:hover:border-gray-600 bg-white dark:bg-[#222222] hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635]">
          <div className="flex items-center gap-2 text-gray-900 dark:text-gray-100">
            {switch selectedClub
            ->Option.flatMap(id => clubs->Array.find(c => c.id == id))
            ->Option.flatMap(c => c.name) {
            | Some(name) =>
              <>
                <span className="font-medium"> {name->React.string} </span>
                <span className="text-gray-400"> {"•"->React.string} </span>
                {selectedActivity
                ->Option.flatMap(id => formQuery.activities->Array.find(a => a.id == id))
                ->Option.flatMap(a => a.name)
                ->Option.map(name => <span> {td(name)->React.string} </span>)
                ->Option.getOr(React.null)}
              </>
            | None =>
              <>
                <span className="text-gray-500 dark:text-gray-400"> {t`No club`} </span>
                {selectedActivity
                ->Option.flatMap(id => formQuery.activities->Array.find(a => a.id == id))
                ->Option.flatMap(a => a.name)
                ->Option.map(name =>
                  <>
                    <span className="text-gray-400"> {"•"->React.string} </span>
                    <span> {td(name)->React.string} </span>
                  </>
                )
                ->Option.getOr(React.null)}
              </>
            }}
          </div>
        </button>
      : showAddClub
      ? {
          switch formQuery.viewer->Option.map(v => v.__id) {
          | Some(connectionId) =>
            <div
              ref={ReactDOM.Ref.domRef(clubFormRef)}
              className={Util.cx([
                "transition-transform",
                shakeClubForm ? "animate-[shake_0.5s_ease-in-out]" : "",
              ])}>
              <CreateClubForm
                connectionId
                query={formQuery.fragmentRefs}
                onCancel={_ => {
                  setShowAddClub(_ => false)
                  setIsClubActivitySelectorActive(_ => false)
                  onChange({clubId: selectedClub, activityId: selectedActivity, isAddingClub: false})
                }}
                onCreated={club => {
                  let newClub = Some(club.id)
                  let newActivity =
                    club.defaultActivity->Option.map(a => a.id)->Option.orElse(selectedActivity)
                  setSelectedClub(_ => newClub)
                  setSelectedActivity(_ => newActivity)
                  setShowAddClub(_ => false)
                  setIsClubActivitySelectorActive(_ => false)
                  onChange({clubId: newClub, activityId: newActivity, isAddingClub: false})
                }}
                inline=true
              />
            </div>
          | None => React.null
          }
        }
      : <div
          className="space-y-4 p-4 border-2 border-[#a3e635] rounded-lg bg-[#f7fee7] dark:bg-[#3f6212]/10 transition-colors">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label
                htmlFor="club-selector-club"
                className="block text-xs font-medium text-gray-700 dark:text-gray-400 mb-1.5">
                {t`Club`}
              </label>
              <select
                id="club-selector-club"
                value={selectedClub->Option.getOr("")}
                onChange={e => {
                  let value = ReactEvent.Form.target(e)["value"]
                  if value == "__add_new__" {
                    setShowAddClub(_ => true)
                    setSelectedClub(_ => None)
                    onChange({clubId: None, activityId: selectedActivity, isAddingClub: true})
                  } else {
                    let newClub = value == "" ? None : Some(value)
                    let newActivity =
                      if value != "" {
                        clubs
                        ->Array.find(c => c.id == value)
                        ->Option.flatMap(c => c.defaultActivity)
                        ->Option.map(a => a.id)
                        ->Option.orElse(selectedActivity)
                      } else {
                        selectedActivity
                      }
                    setSelectedClub(_ => newClub)
                    setSelectedActivity(_ => newActivity)
                    setShowAddClub(_ => false)
                    onChange({clubId: newClub, activityId: newActivity, isAddingClub: false})
                  }
                }}
                className="block w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100">
                <option value=""> {t`No club / Independent event`} </option>
                {clubs
                ->Array.map(club =>
                  <option key={club.id} value={club.id}>
                    {club.name->Option.getOr("")->React.string}
                  </option>
                )
                ->React.array}
                <option
                  value="__add_new__"
                  className="text-[#65a30d] dark:text-[#a3e635] font-medium">
                  {t`+ Add new club...`}
                </option>
              </select>
            </div>
            <div>
              <label
                htmlFor="club-selector-activity"
                className="block text-xs font-medium text-gray-700 dark:text-gray-400 mb-1.5">
                {t`Activity`}
              </label>
              <select
                id="club-selector-activity"
                value={selectedActivity->Option.getOr("")}
                onChange={e => {
                  let value = ReactEvent.Form.target(e)["value"]
                  let newActivity = value == "" ? None : Some(value)
                  setSelectedActivity(_ => newActivity)
                  onChange({clubId: selectedClub, activityId: newActivity, isAddingClub: false})
                }}
                className="block w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100">
                {formQuery.activities
                ->Array.map(activity =>
                  <option key={activity.id} value={activity.id}>
                    {td(activity.name->Option.getOr("---"))->React.string}
                  </option>
                )
                ->React.array}
              </select>
            </div>
          </div>
          <button
            type_="button"
            onClick={_ => setIsClubActivitySelectorActive(_ => false)}
            className="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors">
            {t`Done`}
          </button>
        </div>}
  </div>
}
