%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

module UpdateViewerContactMutation = %relay(`
  mutation ProfileModalUpdateViewerContactMutation($input: UpdateViewerContactInput!) {
    updateViewerContact(input: $input) {
      viewer {
        id
        lineUsername
        email
      }
      errors {
        message
      }
    }
  }
`)

module UpdateProfileMutation = %relay(`
  mutation ProfileModalUpdateProfileMutation($input: UpdateProfileInput!) {
    updateProfile(input: $input) {
      viewer {
        id
        gender
      }
      errors {
        message
      }
    }
  }
`)

module Fragment = %relay(`
  fragment ProfileModal_viewer on Query {
    viewer {
      profile {
        id
        lineUsername
        email
        fullName
        biography
        gender
      }
    }
  }
`)

@rhf
type inputs = {
  lineUsername: Zod.string_,
  email: Zod.string_,
}

let schema = Zod.z->Zod.object(
  (
    {
      lineUsername: Zod.z->Zod.preprocess(
        s => Js.String2.trim(s),
        Zod.z->Zod.string({required_error: ts`Display name is required`})->Zod.String.min(1),
      ),
      email: Zod.z->Zod.string({required_error: ts`Email is required`})->Zod.String.min(1),
    }: inputs
  ),
)

@react.component
let make = (
  ~isOpen: bool,
  ~onClose: unit => unit,
  ~onProfileComplete: option<unit => unit>=?,
  ~query,
) => {
  open Form
  let ts = Lingui.UtilString.t
  let fragmentData = Fragment.use(query)
  let (isAnimating, setIsAnimating) = React.useState(() => false)
  let (emailError, setEmailError) = React.useState(() => None)
  let (commitMutation, isMutationInFlight) = UpdateViewerContactMutation.use()
  let (commitUpdateProfile, _) = UpdateProfileMutation.use()

  let (gender, setGender) = React.useState(() =>
    fragmentData.viewer
    ->Option.flatMap(v => v.profile)
    ->Option.flatMap(u => u.gender)
    ->Option.flatMap(g =>
      switch g {
      | RelaySchemaAssets_graphql.Female =>
        Some((RelaySchemaAssets_graphql.Female: RelaySchemaAssets_graphql.enum_Gender_input))
      | Male => Some(Male)
      | FutureAddedValue(_) => None
      }
    )
  )

  // Check if email already exists and is non-empty
  let existingEmail =
    fragmentData.viewer
    ->Option.flatMap(v => v.profile)
    ->Option.flatMap(u => u.email)
  let emailExists =
    existingEmail
    ->Option.map(email => email != "")
    ->Option.getOr(false)

  let {register, formState, handleSubmit} = useFormOfInputs(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {
        lineUsername: fragmentData.viewer
        ->Option.flatMap(v => v.profile)
        ->Option.flatMap(u => u.lineUsername)
        ->Option.getOr(""),
        email: fragmentData.viewer
        ->Option.flatMap(v => v.profile)
        ->Option.flatMap(u => u.email)
        ->Option.getOr(""),
      },
    },
  )

  React.useEffect1(() => {
    if isOpen {
      setIsAnimating(_ => true)
    }
    None
  }, [isOpen])

  let handleClose = () => {
    setIsAnimating(_ => false)
    let _ = Js.Global.setTimeout(() => {
      onClose()
    }, 300)
  }

  let onSubmit = (data: inputs) => {
    // Clear any previous email errors
    setEmailError(_ => None)

    // Update gender via updateProfile if gender is set
    switch gender {
    | Some(g) =>
      commitUpdateProfile(
        ~variables={
          input: {
            fullName: fragmentData.viewer
            ->Option.flatMap(v => v.profile)
            ->Option.flatMap(u => u.fullName)
            ->Option.getOr(""),
            biography: fragmentData.viewer
            ->Option.flatMap(v => v.profile)
            ->Option.flatMap(u => u.biography)
            ->Option.getOr(""),
            username: data.lineUsername,
            gender: g,
          },
        },
      )->ignore
    | None => ()
    }

    commitMutation(
      ~variables={
        input: {
          email: data.email,
          lineUsername: data.lineUsername,
        },
      },
      ~onCompleted=(response, _) => {
        switch response.updateViewerContact.errors {
        | Some([]) | None => {
            // Validate the updated viewer data
            let isProfileComplete = switch response.updateViewerContact.viewer {
            | Some(viewer) =>
              switch (viewer.lineUsername, viewer.email) {
              | (Some(username), Some(email)) => username != "" && email != ""
              | _ => false
              }
            | None => false
            }

            handleClose()

            // If profile is now complete, trigger the callback
            if isProfileComplete {
              onProfileComplete->Option.forEach(callback => callback())
            }
          }
        | Some(errors) =>
          errors->Array.forEach(error => {
            // Check for EMAIL_UNAVAILABLE error
            if error.message == "EMAIL_UNAVAILABLE" {
              setEmailError(_ => Some(
                ts`Email address is unavailable. Please use a different email or login with the email you are trying to use here.`,
              ))
            } else {
              Js.Console.error2("Error:", error.message)
            }
          })
        }
      },
      ~onError=_ => {
        Js.Console.error("Failed to update profile")
      },
    )->ignore
  }

  if !isOpen && !isAnimating {
    React.null
  } else {
    <WaitForMessages>
      {_ =>
        <div
          className={`fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4 sm:p-0 ${isAnimating
              ? "opacity-100"
              : "opacity-0"} transition-opacity duration-300`}>
          // Backdrop
          <div
            className="fixed inset-0 bg-black bg-opacity-40 backdrop-blur-sm"
            onClick={_ => handleClose()}
          />
          // Modal
          <div
            className={`relative w-full sm:max-w-md bg-white shadow-xl rounded-t-2xl sm:rounded-2xl overflow-hidden z-10 transform ${isAnimating
                ? "translate-y-0"
                : "translate-y-full sm:translate-y-8"} transition-transform duration-300 ease-out`}
            onClick={e => e->ReactEvent.Mouse.stopPropagation}>
            // Header
            <div className="relative p-6 pb-4 border-b border-gray-100">
              <button
                onClick={_ => handleClose()}
                className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors">
                <Lucide.X className="w-6 h-6" />
              </button>
              <div className="pr-8">
                <h2 className="text-2xl font-bold text-gray-900">
                  {(ts`Complete your profile`)->React.string}
                </h2>
                <p className="text-sm text-gray-600 mt-1">
                  {(ts`We need a few details before you can join this event`)->React.string}
                </p>
              </div>
            </div>
            // Form
            <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-5">
              // Display Name
              <div>
                <Input
                  label={<div
                    className="flex items-center gap-2 text-sm font-medium text-gray-700 mb-2">
                    <Lucide.User className="w-4 h-4 text-gray-400" />
                    {(ts`Display name`)->React.string}
                  </div>}
                  id="display-name"
                  name="lineUsername"
                  type_="text"
                  placeholder="John Smith"
                  register={register(LineUsername)}
                />
                {switch formState.errors.lineUsername {
                | Some({message: ?Some(message)}) =>
                  <p className="text-xs text-red-500 mt-1"> {message->React.string} </p>
                | _ =>
                  <p className="text-xs text-gray-500 mt-1">
                    {(ts`This is how others will see you`)->React.string}
                  </p>
                }}
              </div>
              // Email
              <div>
                <Input
                  label={<div className="text-sm font-medium text-gray-700 mb-2">
                    {(ts`Email address`)->React.string}
                  </div>}
                  id="email"
                  name="email"
                  type_="email"
                  placeholder="you@example.com"
                  disabled=emailExists
                  register={register(Email)}
                />
                {switch (formState.errors.email, emailError) {
                | (Some({message: ?Some(message)}), _) =>
                  <p className="text-xs text-red-500 mt-1"> {message->React.string} </p>
                | (_, Some(errorMsg)) =>
                  <p className="text-xs text-red-500 mt-1"> {errorMsg->React.string} </p>
                | _ =>
                  <p className="text-xs text-gray-500 mt-1">
                    {emailExists
                      ? (ts`Email cannot be changed`)->React.string
                      : (ts`For event updates and notifications`)->React.string}
                  </p>
                }}
              </div>
              // Gender
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {(ts`Gender`)->React.string}
                </label>
                <select
                  className="block w-full rounded-lg border border-gray-200 py-2.5 pl-3 pr-10 text-gray-900 focus:ring-2 focus:ring-blue-500 sm:text-sm"
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
              // Submit Button
              <div className="pt-2">
                <button
                  type_="submit"
                  disabled={isMutationInFlight}
                  className={`w-full py-3 px-4 rounded-lg font-medium transition-all duration-200 ${isMutationInFlight
                      ? "bg-gray-200 text-gray-400 cursor-not-allowed"
                      : "bg-blue-600 text-white hover:bg-blue-700 shadow-sm hover:shadow-md"}`}>
                  {(ts`Save & Join Event`)->React.string}
                </button>
              </div>
            </form>
          </div>
        </div>}
    </WaitForMessages>
  }
}
