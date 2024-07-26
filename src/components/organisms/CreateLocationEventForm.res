%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

module Mutation = %relay(`
 mutation CreateLocationEventFormMutation(
    $connections: [ID!]!
    $input: CreateEventInput!
  ) {
    createEvent(input: $input) {
      event @appendNode(connections: $connections, edgeTypeName: "EventEdge") {
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

module EventFragment = %relay(`
  fragment CreateLocationEventForm_event on Event {
    id
    title
    details
    maxRsvps
    activity {
      id
      name
      slug
    }
    club {
      id
    }
    startDate
    endDate
    listed
  }
`)
module UpdateMutation = %relay(`
 mutation CreateLocationEventFormUpdateMutation(
    $eventId: ID!,
    $input: CreateEventInput!
  ) {
    updateEvent(eventId: $eventId, input: $input) {
      event {
        __typename
        id
        title
        details
        maxRsvps
        activity {
          id
        }
        location {
          id
        }
        club {
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
  fragment CreateLocationEventForm_location on Location {
    id
    name
    details
  }
`)
module QueryFragment = %relay(`
  fragment CreateLocationEventForm_query on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
  )
  {
    activities {
      id
      name
      slug
    }
    ...SelectClubStateful_query @arguments(after: $after, first: $first, before: $before)
    ...CreateClubForm_activities
    viewer {
      __id
      adminClubs(after: $after, first: $first, before: $before)
      @connection(key: "SelectClub_adminClubs") {
        edges {
          node {
            id
            name
          }
        }
      }
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

@rhf
type inputs = {
  title: Zod.string_,
  activity: Zod.string_,
  // clubId: Zod.string_,
  maxRsvps: Zod.optional<Zod.number>,
  startDate: Zod.string_,
  endTime: Zod.string_,
  details: Zod.optional<Zod.string_>,
  listed: bool,
}

let schema = Zod.z->Zod.object(
  (
    {
      title: Zod.z->Zod.string({required_error: ts`title is required`})->Zod.String.min(1),
      activity: Zod.z->Zod.string({required_error: ts`activity is required`}),
      // clubId: Zod.z->Zod.string({required_error: ts`club is required`}),
      maxRsvps: Zod.z->Zod.number({})->Zod.Number.gte(1.)->Zod.optional,
      startDate: Zod.z->Zod.string({required_error: ts`event date is required`})->Zod.String.min(1),
      endTime: Zod.z->Zod.string({required_error: ts`end time is required`})->Zod.String.min(5),
      details: Zod.z->Zod.string({})->Zod.optional,
      listed: Zod.z->Zod.boolean({}),
    }: inputs
  ),
)

type action = Create | Update(CreateLocationEventForm_event_graphql.Types.fragment)
let makeAction = (event: option<CreateLocationEventForm_event_graphql.Types.fragment>) =>
  switch event {
  | Some(event) => Update(event)
  | None => Create
  }

@react.component
let make = (~event=?, ~location, ~query) => {
  open Lingui.Util
  let td = Lingui.UtilString.dynamic
  open Form
  let event = event->Option.map(event => EventFragment.use(event))
  let location = Fragment.use(location)
  let query = QueryFragment.use(query)
  let clubs =
    query.viewer
    ->Option.map(viewer => viewer.adminClubs->QueryFragment.getConnectionNodes)
    ->Option.getOr([])

  let (commitMutationCreate, _) = Mutation.use()
  let (commitMutationUpdate, _) = UpdateMutation.use()
  let navigate = Router.useNavigate()

  let action = makeAction(event)

  let {register, handleSubmit, formState, setValue, watch} = useFormOfInputs(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: event
      ->Option.map((event): defaultValuesOfInputs => {
        title: event.title->Option.getOr(""),
        activity: event.activity->Option.map(a => a.id)->Option.getOr(""),
        maxRsvps: event.maxRsvps->Option.map(Int.toFloat),
        startDate: event.startDate
        ->Option.map(d => d->Util.Datetime.toDate->DateFns.formatWithPattern("yyyy-MM-dd'T'HH:00"))
        ->Option.getOr(""),
        endTime: event.endDate
        ->Option.map(d => d->Util.Datetime.toDate->DateFns.formatWithPattern("HH:mm"))
        ->Option.getOr(""),
        details: event.details,
        listed: event.listed->Option.getOr(false),
      })
      ->Option.getOr({listed: false}),
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
  let (selectedClub, setSelectedClub) = React.useState(() =>
    event
    ->Option.map(e => e.club->Option.map(c => c.id))
    ->Option.getOr(clubs->Array.get(0)->Option.map(c => c.id))
  )

  React.useEffect(() => {
    switch action {
    | Create =>
      // @NOTE: Date.make runs an effect therefore cannot be part of the render
      let now = Js.Date.make()
      let currentISODate =
        Js.Date.fromFloat(now->Js.Date.getTime -. now->Js.Date.getTimezoneOffset *. 60000.)
        ->Js.Date.toISOString
        ->String.slice(~start=0, ~end=16)

      let currentDate = DateFns.parseISO(currentISODate)
      let defaultStartDate = currentDate->DateFns.formatWithPattern("yyyy-MM-dd'T'HH:00")

      let defaultEndTime =
        defaultStartDate
        ->DateFns.parseISO
        ->DateFns.addHours(2.0)
        ->DateFns.formatWithPattern("HH:mm")
      setValue(StartDate, Value(defaultStartDate))
      setValue(EndTime, Value(defaultEndTime))
    | Update(_) => ()
    }

    None
  }, [])

  let onSubmit = (data: inputs) => {
    switch action {
    | Create =>
      let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
        "client:root"->RescriptRelay.makeDataId,
        "EventsListFragment_events",
        (),
      )

      let startDate = data.startDate->DateFns.parseISO
      let endDate = DateFns2.parse(data.endTime, "HH:mm", startDate)
      commitMutationCreate(
        ~variables={
          input: {
            title: data.title,
            activity: data.activity,
            maxRsvps: ?data.maxRsvps->Option.map(Float.toInt),
            details: data.details->Option.getOr(""),
            locationId: location.id,
            clubId: selectedClub->Option.getOr(""),
            startDate: startDate->Util.Datetime.fromDate,
            endDate: endDate->Util.Datetime.fromDate,
            listed: data.listed,
          },
          connections: [connectionId],
        },
        ~onCompleted=(response, _errors) => {
          response.createEvent.event
          ->Option.map(event => navigate("/events/" ++ event.id, None))
          ->ignore
        },
      )->RescriptRelay.Disposable.ignore
    | Update(event) => {
        let startDate = data.startDate->DateFns.parseISO
        let endDate = DateFns2.parse(data.endTime, "HH:mm", startDate)
        commitMutationUpdate(
          ~variables={
            eventId: event.id,
            input: {
              title: data.title,
              activity: data.activity,
              maxRsvps: ?data.maxRsvps->Option.map(Float.toInt),
              details: data.details->Option.getOr(""),
              locationId: location.id,
              clubId: selectedClub->Option.getOr(""),
              startDate: startDate->Util.Datetime.fromDate,
              endDate: endDate->Util.Datetime.fromDate,
              listed: data.listed,
            },
          },
          ~onCompleted=(_response, _errors) => {
            navigate("/events/" ++ event.id, None)
          },
        )->RescriptRelay.Disposable.ignore
      }
    }
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
          <SelectClubStateful
            clubs={clubs}
            onSelected={id => setSelectedClub(_ => Some(id))}
            fragments={query.fragmentRefs}
            value=selectedClub
            connectionId=?{query.viewer->Option.map(v => v.__id)}
          />
          <form onSubmit={handleSubmit(onSubmit)}>
            <FormSection
              title={t`${location.name->Option.getOr("?")} event details`}
              description={t`details specific to this event on the specified date and time.`}>
              <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div className="sm:col-span-4 md:col-span-3">
                  <Input
                    label={t`title`}
                    id="title"
                    name="title"
                    placeholder={ts`All Level`}
                    register={register(Title)}
                  />
                  <p>
                    {switch formState.errors.title {
                    | Some({message: ?Some(message)}) => message
                    | _ => ""
                    }->React.string}
                  </p>
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
                <div className="sm:col-span-2">
                  <Input
                    label={t`date and start time`}
                    type_="datetime-local"
                    id="startDate"
                    name="startDate"
                    register={register(StartDate)}
                  />
                </div>
                <div className="sm:col-span-2">
                  <Input
                    label={t`end time`}
                    type_="time"
                    id="endTime"
                    name="endTime"
                    register={register(EndTime)}
                  />
                </div>
                <div className="sm:col-span-2">
                  <Input
                    label={t`max participants`}
                    type_="number"
                    id="maxRsvps"
                    name="maxRsvps"
                    register={register(
                      MaxRsvps,
                      ~options={setValueAs: v => v == "" ? None : Some(Int.fromString(v))},
                    )}
                  />
                </div>
                <div className="col-span-full">
                  <TextArea
                    label={t`location details`}
                    id="location_details"
                    name="location_details"
                    hint={<Router.Link to="/locations/edit/">
                      {t`edit the location to edit the details for this location.`}
                    </Router.Link>}
                    disabled=true
                    value={location.details->Option.getOr("")}
                  />
                </div>
                <div className="col-span-full">
                  <TextArea
                    label={t`event details`}
                    id="details"
                    name="details"
                    hint={t`any details from the location will already be included. Mention any additional event-specific instructions, rules, or details.`}
                    register={register(Details)}
                  />
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
