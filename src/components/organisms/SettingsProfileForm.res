%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t
module Mutation = %relay(`
 mutation SettingsProfileFormMutation($input: UpdateProfileInput!) {
   updateProfile(input: $input) {
     viewer {
       id
       fullName
       biography
       lineUsername
       gender
       email
     }
     errors {
       message
     }
   }
 }
`)

module QueryFragment = %relay(`
  fragment SettingsProfileForm_query on Query {
    viewer {
      profile {
        id
        fullName
        biography
        lineUsername
        gender
        email
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
  let navigate = LangProvider.Router.useNavigate()
  open Lingui.Util
  let query = QueryFragment.use(query)

  let (commitMutation, _) = Mutation.use()

  let (gender, setGender) = React.useState(() =>
    query.viewer
    ->Option.flatMap(viewer => viewer.profile)
    ->Option.flatMap(profile => profile.gender)
    ->Option.flatMap(g =>
      switch g {
      | RelaySchemaAssets_graphql.Female =>
        Some((RelaySchemaAssets_graphql.Female: RelaySchemaAssets_graphql.enum_Gender_input))
      | Male => Some(Male)
      | FutureAddedValue(_) => None
      }
    )
  )

  let {register, handleSubmit, formState, setValue} = useFormOfInputs(
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

  React.useEffect(() => {
    query.viewer->Option.forEach(viewer => {
      viewer.profile->Option.forEach(
        profile => {
          profile.fullName->Option.forEach(v => setValue(FullName, Value(v)))
          profile.biography->Option.forEach(v => setValue(Biography, Value(v)))
          profile.lineUsername->Option.forEach(v => setValue(Username, Value(v)))
        },
      )
    })
    None
  }, [query.viewer])

  let onSubmit = (data: inputs) => {
    let baseInput: RelaySchemaAssets_graphql.input_UpdateProfileInput = {
      fullName: data.fullName,
      biography: data.biography,
      username: data.username,
    }
    let input = switch gender {
    | Some(g) => {...baseInput, gender: g}
    | None => baseInput
    }
    commitMutation(
      ~variables={
        input: input,
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
    animate={FramerMotion.opacity: 1., scale: 1., y: 0.00}
    exit={opacity: 0., scale: 1., y: -50.}>
    <WaitForMessages>
      {() => <>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
          <div
            className="border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
            <div className="px-4 pb-4 pt-6 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label
                    htmlFor="fullName"
                    className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                    {t`Full name`}
                  </label>
                  <input
                    {...register(FullName)}
                    id="fullName"
                    type_="text"
                    placeholder={ts`Doe John`}
                    className="block w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100"
                  />
                  {switch formState.errors.fullName {
                  | Some({message: ?Some(message)}) =>
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                      {message->React.string}
                    </p>
                  | _ => React.null
                  }}
                  <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                    {t`Some events require your legal name as shown on an ID card.`}
                  </p>
                </div>
                <div>
                  <label
                    htmlFor="gender"
                    className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                    {t`Gender`}
                  </label>
                  <select
                    id="gender"
                    className="block w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100"
                    value={switch gender {
                    | Some(RelaySchemaAssets_graphql.Female) => "female"
                    | Some(Male) => "male"
                    | None => ""
                    }}
                    onChange={e => {
                      let value = (e->ReactEvent.Form.target)["value"]
                      setGender(_ =>
                        switch value {
                        | "female" => Some(RelaySchemaAssets_graphql.Female)
                        | "male" => Some(Male)
                        | _ => None
                        }
                      )
                    }}>
                    <option value=""> {(ts`Prefer not to say`)->React.string} </option>
                    <option value="male"> {(ts`Male`)->React.string} </option>
                    <option value="female"> {(ts`Female`)->React.string} </option>
                  </select>
                </div>
              </div>
              <div>
                <label
                  htmlFor="biography"
                  className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                  {t`Biography`}
                </label>
                <textarea
                  {...register(Biography)}
                  id="biography"
                  rows=6
                  placeholder={ts`Tell us a little about yourself...`}
                  className="block w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors resize-none bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100"
                />
                <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                  {t`tell us a little about yourself`}
                </p>
                {switch formState.errors.biography {
                | Some({message: ?Some(message)}) =>
                  <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                    {message->React.string}
                  </p>
                | _ => React.null
                }}
              </div>
              <div>
                <SeekingPartnerInput seekingPartner={None} onChange={_ => ()} />
              </div>
            </div>
          </div>
          <div className="pt-2">
            <button
              type_="submit"
              className="w-full bg-[#a3e635] text-gray-900 py-4 px-6 rounded-lg font-bold hover:bg-[#84cc16] focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:ring-offset-2 dark:focus:ring-offset-[#111111] transition-colors shadow-sm">
              {t`Save profile`}
            </button>
          </div>
        </form>
      </>}
    </WaitForMessages>
  </FramerMotion.Div>
}
