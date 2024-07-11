%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

type data<'a> = Promise('a) | Empty

module ActivitiesFragment = %relay(`
  fragment CreateClubForm_activities on Query {
    activities {
      id
      name
      slug
    }
  }
`)
module Mutation = %relay(`
 mutation CreateClubFormMutation(
    $connections: [ID!]!
    $input: CreateClubInput!
  ) {
    createClub(input: $input) {
      club @appendNode(connections: $connections, edgeTypeName: "ClubEdge") {
        __typename
        id
        name
        slug
        defaultActivity {
          id
          name
          slug
        }
      }
      errors {
        message
      }
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

@rhf
type inputs = {
  name: Zod.string_,
  slug: Zod.string_,
  activity: Zod.string_,
  description: Zod.optional<Zod.string_>,
}

let schema = Zod.z->Zod.object(
  (
    {
      name: Zod.z->Zod.string({required_error: ts`name is required`})->Zod.String.min(1),
      slug: Zod.z->Zod.string({required_error: ts`url slug is required`})->Zod.String.min(1),
      activity: Zod.z
      ->Zod.string({required_error: ts`main activity is required`})
      ->Zod.String.min(1),
      description: Zod.z->Zod.string({})->Zod.optional,
    }: inputs
  ),
)
@react.component
let make = (~connectionId=?, ~query, ~onCancel, ~onCreated, ~inline: bool=false) => {
  open Lingui.Util
  open Form
  let td = Lingui.UtilString.dynamic

  let (commitMutationCreate, _) = Mutation.use()
  let {activities} = ActivitiesFragment.use(query)

  let {register, handleSubmit, reset, formState: {errors}} = useFormOfInputs(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {},
    },
  )
  let onSubmit = (data: inputs) => {
    let connections =
      connectionId
      ->Option.map(connectionId => [
        RescriptRelay.ConnectionHandler.getConnectionID(
          connectionId,
          // "client:root:viewer"->RescriptRelay.makeDataId,
          "SelectClub_adminClubs",
          (),
        ),
      ])
      ->Option.getOr([])

    commitMutationCreate(
      ~variables={
        input: {
          name: data.name,
          slug: data.slug,
          activity: data.activity,
          description: ?data.description,
        },
        connections,
      },
      ~onCompleted=(response, _errors) => {
        response.createClub.club
        ->Option.map(club => {
          reset()
          onCreated(club);
        })
        ->ignore
      },
    )->RescriptRelay.Disposable.ignore
  }
  // let onSubmit = data => Js.log(data)

  <WaitForMessages>
    {() =>
      <form onSubmit={handleSubmit(onSubmit)}>
        <Grid className="grid-cols-1">
          <FormSection title={t`club`}>
            <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
              <div className="col-span-full">
                <Input
                  label={t`name`}
                  id="name"
                  name="name"
                  placeholder={ts`ゆびバド`}
                  register={register(Name)}
                />
                <p>
                  {switch errors.name {
                  | Some({message: ?Some(message)}) => message
                  | _ => ""
                  }->React.string}
                </p>
              </div>
              <div className="sm:col-span-2 md:col-span-3 lg:col-span-2 lg:max-w-lg">
                <PrefixedInput
                  prefix="www.racquetleague.com/clubs/"
                  label={t`slug`}
                  id="slug"
                  name="slug"
                  placeholder={ts`yubibado`}
                  className="block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6"
                  register={register(Slug)}
                />
                <p>
                  {switch errors.slug {
                  | Some({message: ?Some(message)}) => message
                  | _ => ""
                  }->React.string}
                </p>
              </div>
              <div className="sm:col-span-2 md:col-span-3 lg:col-span-2 lg:max-w-lg">
                <Select
                  label={t`main activity`}
                  id="activity"
                  name="activity"
                  options={activities->Array.map(activity => (
                    td(activity.name->Option.getOr("---")),
                    activity.id,
                  ))}
                  register={register(Activity)}
                />
                <p>
                  {switch errors.activity {
                  | Some({message: ?Some(message)}) => message
                  | _ => ""
                  }->React.string}
                </p>
              </div>
              <div className="col-span-full">
                <TextArea
                  label={t`about`}
                  id="description"
                  name="description"
                  hint={t`tell people about your club`}
                  register={register(Description)}
                />
              </div>
            </div>
          </FormSection>
          <Form.Footer onCancel />
        </Grid>
      </form>}
  </WaitForMessages>
}

// let td = Lingui.UtilString.td
// @live
// td({id: "Badminton"})->ignore
// @live
// td({id: "Table Tennis"})->ignore
// @live
// td({id: "Pickleball"})->ignore
// @live
// td({id: "Futsal"})->ignore
// @live
// td({id: "Basketball"})->ignore
// @live
// td({id: "Volleyball"})->ignore
