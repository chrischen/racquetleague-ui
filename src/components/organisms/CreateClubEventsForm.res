%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t
module Mutation = %relay(`
 mutation CreateClubEventsFormMutation(
   $connections: [ID!]!
   $input: CreateEventsInput!
 ) {
   createEvents(input: $input) {
     events @appendNode(connections: $connections, edgeTypeName: "EventEdge") {
       __typename
       id
       title
       details
       activity {
         id
         name
         slug
       }
       startDate
       endDate
       listed
     }
   }
 }
`)

module Fragment = %relay(`
  fragment CreateClubEventsForm_club on Club {
    id
    name
    slug
  }
`)
module QueryFragment = %relay(`
  fragment CreateClubEventsForm_query on Query {
    activities {
      id
      name
      slug
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

@rhf
type inputs = {
  input: Zod.string_,
  activity: Zod.string_,
  listed: bool,
}

let schema = Zod.z->Zod.object(
  (
    {
      input: Zod.z->Zod.string({required_error: ts`input is required`})->Zod.String.min(1),
      activity: Zod.z->Zod.string({required_error: ts`activity is required`}),
      listed: Zod.z->Zod.boolean({}),
    }: inputs
  ),
)

module ParseEventsPreview = {
  module Query = %relay(`
  query CreateClubEventsFormPreviewQuery($input: String!) {
    parseBulkEvents(input: $input)
  }
  `)
  @react.component
  let make = (~input) => {
    open Lingui.Util
    let preview = Query.use(~variables={input: input})

    {
      <Form.TextArea
        id="eventsPreview"
        rows=10
        label={t`events preview`}
        disabled=true
        value={preview.parseBulkEvents}
      />
    }
  }
}

external alert: string => unit = "alert"
@react.component
let make = (~query, ~club, ~prefillDate: option<string>=?) => {
  open Lingui.Util
  let td = Lingui.UtilString.dynamic
  let (queryPreview, setQueryPreview) = React.useState(() => None)
  let query = QueryFragment.use(query)
  let club = Fragment.use(club)

  let textareaDefault = prefillDate->Option.map(isoDate => {
    let parts = isoDate->String.split("-")
    switch parts {
    | [_year, month, day] =>
      let m = month->Int.fromString->Option.getOr(1)
      let d = day->Int.fromString->Option.getOr(1)
      ts`${m->Int.toString}/${d->Int.toString} 10:00-12:00\nVenue\nOpen Play\nMax 18 people`
    | _ => ""
    }
  })->Option.getOr(
    ts`3/2 10:00-12:00\nVenue\nOpen Play\nMax 18 people\n\n3/5 10:00-12:00\nVenue\nOpen Play\nMax 18 people`,
  )

  let (commitMutationCreate, _) = Mutation.use()

  let {register, handleSubmit, formState, setValue, watch} = useFormOfInputs(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {listed: false},
    },
  )

  let listed =
    watch(Listed)
    ->Option.map(listed =>
      switch listed {
      | Bool(bool) => bool
      | _ => false
      }
    )
    ->Option.getOr(false)
  let eventsInput =
    watch(Input)
    ->Option.map(input =>
      switch input {
      | String(str) => str
      | _ => ""
      }
    )
    ->Option.getOr("")

  let previewEvents = () => {
    setQueryPreview(_ => Some(eventsInput))
  }

  let onSubmit = (data: inputs) => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      "client:root"->RescriptRelay.makeDataId,
      "EventsListFragment_events",
      (),
    )

    commitMutationCreate(
      ~variables={
        input: {
          input: data.input,
          activityId: data.activity,
          clubId: club.id,
          listed: data.listed,
        },
        connections: [connectionId],
      },
      ~onCompleted=(response, _errors) => {
        let count = response.createEvents.events->Option.getOr([])->Array.length
        alert(ts`${count->Int.toString} events created!`)
        // ->Option.map(_ =>
        //   navigate(club.slug->Option.map(slug => "/clubs/" ++ slug)->Option.getOr("/"), None)
        // )
        // ->ignore
      },
    )->RescriptRelay.Disposable.ignore
  }
  // let onSubmit = data => Js.log(data)

  <FramerMotion.Div
    style={opacity: 0., y: -50.}
    initial={opacity: 0., scale: 1., y: -50.}
    animate={FramerMotion.opacity: 1., scale: 1., y: 0.00}
    exit={opacity: 0., scale: 1., y: -50.}>
    <WaitForMessages>
      {() => <>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          <div>
            <h2 className="text-lg font-bold text-gray-900 dark:text-gray-100">
              {React.string(club.name->Option.getOr("?") ++ " — " ++ (ts`Create Events`))}
            </h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {t`Create multiple events at once`}
            </p>
          </div>
          <div>
            <label
              htmlFor="input"
              className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
              {t`Events`}
            </label>
            <textarea
              {...register(Input)}
              id="input"
              rows=10
              className={Util.cx([
                "block w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors resize-none bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 font-mono text-sm",
                formState.errors.input->Option.isSome
                  ? "border-red-300 dark:border-red-700"
                  : "border-gray-300 dark:border-gray-700",
              ])}
              defaultValue=textareaDefault
            />
            {switch formState.errors.input {
            | Some({message: ?Some(message)}) =>
              <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                {message->React.string}
              </p>
            | _ => React.null
            }}
            <button
              type_="button"
              onClick={e => {
                e->JsxEventU.Mouse.preventDefault
                previewEvents()
              }}
              className="mt-2 inline-flex items-center px-3 py-2 text-sm font-medium border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-[#222222] text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors">
              {t`Preview events`}
            </button>
            {queryPreview
            ->Option.map(preview =>
              <React.Suspense fallback={t`loading...`}>
                <ParseEventsPreview.make input=preview />
              </React.Suspense>
            )
            ->Option.getOr(React.null)}
          </div>
          <div>
            <label
              htmlFor="activity"
              className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
              {t`Activity`}
            </label>
            <select
              {...register(Activity)}
              id="activity"
              className="block w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100">
              {query.activities
              ->Array.map(activity =>
                <option key={activity.id} value={activity.id}>
                  {td(activity.name->Option.getOr("---"))->React.string}
                </option>
              )
              ->React.array}
            </select>
            {switch formState.errors.activity {
            | Some({message: ?Some(message)}) =>
              <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                {message->React.string}
              </p>
            | _ => React.null
            }}
          </div>
          <div className="flex items-start gap-3">
            <input
              id="listed"
              type_="checkbox"
              checked={listed}
              onChange={_ => setValue(Listed, Value(!listed))}
              className="h-5 w-5 text-[#a3e635] focus:ring-[#a3e635] border-gray-300 dark:border-gray-600 rounded mt-0.5 bg-white dark:bg-[#222222]"
            />
            <div>
              <label
                htmlFor="listed"
                className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
                {t`List events publicly`}
              </label>
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                {t`Show events on the home page. Otherwise only people with a direct link can find them.`}
              </p>
            </div>
          </div>
          <div className="pt-2">
            <button
              type_="submit"
              className="w-full bg-[#a3e635] text-gray-900 py-4 px-6 rounded-lg font-bold hover:bg-[#84cc16] focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:ring-offset-2 dark:focus:ring-offset-[#111111] transition-colors shadow-sm">
              {t`Create Events`}
            </button>
          </div>
        </form>
      </>}
    </WaitForMessages>
  </FramerMotion.Div>
}
let td = Lingui.UtilString.td

// NOTE: Force lingui to extract these dynamic Activity names
@live
td({id: "Badminton"})->ignore
@live
td({id: "Table Tennis"})->ignore
@live
td({id: "Pickleball"})->ignore
@live
td({id: "Futsal"})->ignore
@live
td({id: "Basketball"})->ignore
@live
td({id: "Volleyball"})->ignore
