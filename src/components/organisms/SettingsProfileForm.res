%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t
module Mutation = %relay(`
 mutation SettingsProfileFormMutation(
    $input: UpdateProfileInput!
  ) {
    updateProfile(input: $input) {
      viewer {
        fullName
        biography
        lineUsername
      }
      errors {
        message
      }
    }
  }
`)

module QueryFragment = %relay(`
  fragment SettingsProfileForm_query on Query
  {
    viewer {
      profile {
        fullName
        biography
        lineUsername
      }
    }
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

@rhf
type inputs = {
  biography: Zod.string_,
  fullName: Zod.string_,
  username: Zod.string_,
}

let schema = Zod.z->Zod.object(
  (
    {
      biography: Zod.z->Zod.string({}),
      fullName: Zod.z->Zod.string({}),
      username: Zod.z->Zod.string({}),
    }: inputs
  ),
)

external alert: string => unit = "alert"
@react.component
let make = (~query) => {
  let navigate = Router.useNavigate()
  open Lingui.Util
  open Form
  let query = QueryFragment.use(query)

  let (commitMutation, _) = Mutation.use()

  let {register, handleSubmit, formState } = useFormOfInputs(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {
        fullName: query.viewer
        ->Option.flatMap(viewer => viewer.profile->Option.flatMap(profile => profile.fullName))
        ->Option.getOr(""),
        biography: query.viewer
        ->Option.flatMap(viewer => viewer.profile->Option.flatMap(profile => profile.biography))
        ->Option.getOr(""),
        username: query.viewer
        ->Option.flatMap(viewer => viewer.profile->Option.flatMap(profile => profile.lineUsername))
        ->Option.getOr(""),
      },
    },
  )

  let onSubmit = (data: inputs) => {
    commitMutation(
      ~variables={
        input: {
          fullName: data.fullName,
          biography: data.biography,
          username: data.username,
        },
      },
      // ~onCompleted=(response, _errors) => {
      //   let count = response.createEvents.events->Option.getOr([])->Array.length
      //   alert(ts`${count->Int.toString} events created!`)
      //   // ->Option.map(_ =>
      //   //   navigate(club.slug->Option.map(slug => "/clubs/" ++ slug)->Option.getOr("/"), None)
      //   // )
      //   // ->ignore
      // },
    )->RescriptRelay.Disposable.ignore
    navigate("/", None)
  }
  // let onSubmit = data => Js.log(data)

  <FramerMotion.Div
    style={opacity: 0., y: -50.}
    initial={opacity: 0., scale: 1., y: -50.}
    animate={opacity: 1., scale: 1., y: 0.00}
    exit={opacity: 0., scale: 1., y: -50.}>
    <WaitForMessages>
      {() => <>
        <Grid>
          <form onSubmit={handleSubmit(onSubmit)}>
            <FormSection title={t`profile`} description={t`details about yourself`}>
              <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6">
                <div className="sm:col-span-4 md:col-span-3">
                  <div className="">
                    <Input
                      label={t`full name`}
                      id="fullName"
                      name="fullName"
                      hint={t`Some events require your legal name as shown on an ID card.`}
                      placeholder={ts`Doe John`}
                      register={register(FullName)}
                    />
                    <p>
                      {switch formState.errors.fullName {
                      | Some({message: ?Some(message)}) => message
                      | _ => ""
                      }->React.string}
                    </p>
                  </div>
                  <div>
                    <SeekingPartnerInput seekingPartner={None} onChange={_ => ()} />
                  </div>
                </div>
                <div className="sm:col-span-4 md:col-span-3">
                  <TextArea
                    label={t`biography`}
                    rows=10
                    id="biography"
                    name="biography"
                    hint={t`tell us a little about yourself`}
                    register={register(Biography)}
                  />
                  <p>
                    {switch formState.errors.biography {
                    | Some({message: ?Some(message)}) => message
                    | _ => ""
                    }->React.string}
                  </p>
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
