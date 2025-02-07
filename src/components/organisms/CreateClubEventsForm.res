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
  fragment CreateClubEventsForm_query on Query
  {
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
let make = (~query, ~club) => {
  open Lingui.Util
  let td = Lingui.UtilString.dynamic
  open Form
  let (queryPreview, setQueryPreview) = React.useState(() => None)
  let query = QueryFragment.use(query)
  let club = Fragment.use(club)

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
    animate={opacity: 1., scale: 1., y: 0.00}
    exit={opacity: 0., scale: 1., y: -50.}>
    <WaitForMessages>
      {() => <>
        <Grid className="grid-cols-1">
          <form onSubmit={handleSubmit(onSubmit)}>
            <FormSection
              title={t`${club.name->Option.getOr("?")} event details`}
              description={t`create multiple events at one time`}>
              <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div className="sm:col-span-4 md:col-span-3">
                  <TextArea
                    label={t`events`}
                    rows=10
                    id="input"
                    name="input"
                    defaultValue="3/2 10:00-12:00\n港区立赤羽小学校\nOpen Play\nMax 18 people\n\n3/5 10:00-12:00\n港区立赤羽小学校\nOpen Play\nMax 18 people"
                    hint={t`type your events in the format above`}
                    register={register(Input)}
                  />
                  <p>
                    {switch formState.errors.input {
                    | Some({message: ?Some(message)}) => message
                    | _ => ""
                    }->React.string}
                  </p>
                  <button
                    type_="button"
                    onClick={e => {
                      e->JsxEventU.Mouse.preventDefault
                      previewEvents()
                    }}
                    className="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
                    {t`preview events`}
                  </button>
                  {queryPreview
                  ->Option.map(preview =>
                    <React.Suspense fallback={t`loading...`}>
                      <ParseEventsPreview.make input=preview />
                    </React.Suspense>
                  )
                  ->Option.getOr(React.null)}
                </div>
                <div className="sm:col-span-2 md:col-span-3 lg:col-span-2 lg:max-w-lg">
                  <Select
                    label={t`activity`}
                    id="activity"
                    name="activity"
                    options={query.activities->Array.map(activity => (
                      td(activity.name->Option.getOr("---")),
                      activity.id,
                    ))}
                    register={register(Activity)}
                  />
                  <p>
                    {switch formState.errors.activity {
                    | Some({message: ?Some(message)}) => message
                    | _ => ""
                    }->React.string}
                  </p>
                </div>
                <div className="col-span-full">
                  <HeadlessUi.Switch.Group \"as"="div" className="flex items-center">
                    <HeadlessUi.Switch
                      checked={listed}
                      onChange={_ => {
                        // Set in React Hook Form
                        setValue(Listed, Value(!listed))
                      }}
                      className={Util.cx([
                        listed ? "bg-indigo-600" : "bg-gray-200",
                        "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2",
                      ])}>
                      <span
                        ariaHidden=true
                        className={Util.cx([
                          listed ? "translate-x-5" : "translate-x-0",
                          "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
                        ])}
                      />
                    </HeadlessUi.Switch>
                    <HeadlessUi.Switch.Label \"as"="span" className="ml-3 text-sm">
                      <span className="font-medium text-gray-900"> {t`list publicly`} </span>
                      {" "->React.string}
                      <span className="text-gray-500">
                        {t`show your event publicly on our home page. Otherwise, only people with a link to your event will be able to find it.`}
                      </span>
                    </HeadlessUi.Switch.Label>
                  </HeadlessUi.Switch.Group>
                </div>
              </div>
            </FormSection>
            <Form.Footer />
          </form>
        </Grid>
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
