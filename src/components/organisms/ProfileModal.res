%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

// ─── DOM bindings ────────────────────────────────────────────────────────────

type keyboardEv
@get external keyEvKey: keyboardEv => string = "key"
@val @scope("window")
external addKeyListener: (string, keyboardEv => unit) => unit = "addEventListener"
@val @scope("window")
external removeKeyListener: (string, keyboardEv => unit) => unit = "removeEventListener"

// Why the modal was opened. Only changes the subtitle copy; the form itself
// always asks for everything, so a profile completed here satisfies any gate.
type context = Join | Availability | Profile

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
        lineUsername
        email
        fullName
        biography
        gender
        selfRating
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
        selfRating
        dupr {
          doubles
          doublesReliable
          doublesReliability
        }
      }
    }
  }
`)

@rhf
type inputs = {
  lineUsername: Zod.string_,
  email: Zod.string_,
  biography: Zod.string_,
}

let schema = Zod.z->Zod.object(
  (
    {
      lineUsername: Zod.z->Zod.preprocess(
        s => Js.String2.trim(s),
        Zod.z->Zod.string({required_error: ts`Display name is required`})->Zod.String.min(1),
      ),
      // Presence is enforced by `canSave`, which knows whether the field is
      // even on screen — validating it here would deadlock the hidden case.
      email: Zod.z->Zod.string({required_error: ts`Email is required`}),
      biography: Zod.z->Zod.preprocess(
        s => Js.String2.trim(s),
        Zod.z
        ->Zod.string({required_error: ts`Biography is required`})
        ->Zod.String.min(1)
        ->Zod.String.max(280),
      ),
    }: inputs
  ),
)

@react.component
let make = (
  ~isOpen: bool,
  ~onClose: unit => unit,
  ~onProfileComplete: option<unit => unit>=?,
  ~context: context=Join,
  ~query,
) => {
  let ts = Lingui.UtilString.t
  let fragmentData = Fragment.use(query)
  let (emailError, setEmailError) = React.useState(() => None)
  let (saveError, setSaveError) = React.useState(() => None)
  let (commitMutation, isContactInFlight) = UpdateViewerContactMutation.use()
  let (commitUpdateProfile, isProfileInFlight) = UpdateProfileMutation.use()

  let profile = fragmentData.viewer->Option.flatMap(v => v.profile)

  // Check if email already exists and is non-empty
  let existingEmail = profile->Option.flatMap(u => u.email)
  let emailExists = existingEmail->Option.map(email => email != "")->Option.getOr(false)

  let storedName = profile->Option.flatMap(u => u.lineUsername)->Option.getOr("")
  let storedEmail = existingEmail->Option.getOr("")
  let storedBio = profile->Option.flatMap(u => u.biography)->Option.getOr("")
  // The backend treats an unset gender as male, so there's no "prefer not to
  // say" to offer — an unset profile just starts on male.
  let storedGender = switch profile->Option.flatMap(u => u.gender) {
  | Some(RelaySchemaAssets_graphql.Female) =>
    (Female: RelaySchemaAssets_graphql.enum_Gender_input)
  | _ => Male
  }
  // selfRating is stored on the internal scale; the picker speaks DUPR.
  let storedLevel =
    profile
    ->Option.flatMap(u => u.selfRating)
    ->Option.map(mu => mu->Rating.guessDupr->LevelPicker.nearest)

  // A linked DUPR rating already answers "how good are you?", so the picker
  // steps aside rather than asking the same question a second way.
  let duprLink = profile->Option.flatMap(u => u.dupr)

  let (gender, setGender) = React.useState(() => storedGender)
  let (level, setLevel) = React.useState(() => storedLevel)

  let {register, formState, handleSubmit, watch, setValue} = useFormOfInputs(
    ~options={
      resolver: Resolver.zodResolver(schema),
      defaultValues: {
        lineUsername: storedName,
        email: storedEmail,
        biography: storedBio,
      },
    },
  )

  // The gate keeps this component mounted for the life of the page, so the
  // defaults above and the two useState initializers only ever run once —
  // re-seed from the store on each open so it can't show stale values.
  React.useEffect1(() => {
    if isOpen {
      setValue(LineUsername, Value(storedName))
      setValue(Email, Value(storedEmail))
      setValue(Biography, Value(storedBio))
      setGender(_ => storedGender)
      setLevel(_ => storedLevel)
    }
    None
  }, [isOpen])

  // Close on Escape
  let onCloseRef = React.useRef(onClose)
  onCloseRef.current = onClose
  React.useEffect1(() => {
    if !isOpen {
      None
    } else {
      let onKey = (e: keyboardEv) =>
        if e->keyEvKey === "Escape" {
          onCloseRef.current()
        }
      addKeyListener("keydown", onKey)
      Some(() => removeKeyListener("keydown", onKey))
    }
  }, [isOpen])

  let isMutationInFlight = isContactInFlight || isProfileInFlight

  let watchedString = field =>
    switch watch(field) {
    | Some(String(v)) => v
    | _ => ""
    }
  let bio = watchedString(Biography)
  let canSave =
    watchedString(LineUsername)->String.trim != "" &&
    (emailExists || watchedString(Email)->String.trim != "") &&
    bio->String.trim != "" &&
    (duprLink->Option.isSome || level->Option.isSome) &&
    !isMutationInFlight

  let onSubmit = (data: inputs) => {
    setEmailError(_ => None)
    setSaveError(_ => None)

    // Second leg: profile fields. Only reached once the contact mutation
    // succeeded, so a failing email never silently saves half the form.
    let commitProfile = () =>
      commitUpdateProfile(
        ~variables={
          input: {
            fullName: profile->Option.flatMap(u => u.fullName)->Option.getOr(""),
            biography: data.biography,
            username: data.lineUsername,
            gender,
            // Omitted while DUPR is linked, so the stored self-report is
            // left as it was rather than overwritten.
            selfRating: ?(duprLink->Option.isSome ? None : level->Option.map(Rating.duprToMu)),
          },
        },
        ~onCompleted=(response, _) => {
          switch response.updateProfile.errors {
          | Some([]) | None =>
            onProfileComplete->Option.forEach(callback => callback())
            onClose()
          | Some(errors) =>
            errors->Array.forEach(error => Js.Console.error2("Error:", error.message))
            setSaveError(_ => Some(ts`Could not save your profile. Please try again.`))
          }
        },
        ~onError=_ => {
          setSaveError(_ => Some(ts`Could not save your profile. Please try again.`))
        },
      )->ignore

    commitMutation(
      ~variables={
        input: {
          // An address we already hold isn't in the form, so don't resend it.
          email: ?(emailExists ? None : Some(data.email)),
          lineUsername: data.lineUsername,
        },
      },
      ~onCompleted=(response, _) => {
        switch response.updateViewerContact.errors {
        | Some([]) | None => commitProfile()
        | Some(errors) =>
          errors->Array.forEach(error => {
            // Check for EMAIL_UNAVAILABLE error
            if error.message == "EMAIL_UNAVAILABLE" {
              setEmailError(_ => Some(
                ts`Email address is unavailable. Please use a different email or login with the email you are trying to use here.`,
              ))
            } else {
              Js.Console.error2("Error:", error.message)
              setSaveError(_ => Some(ts`Could not save your profile. Please try again.`))
            }
          })
        }
      },
      ~onError=_ => {
        setSaveError(_ => Some(ts`Could not save your profile. Please try again.`))
      },
    )->ignore
  }

  let subtitle = switch context {
  | Join => ts`We need a few details before you can join this event`
  | Availability => ts`Complete your profile before sharing availability with players and hosts.`
  | Profile => ts`Keep your player profile accurate and useful to the community.`
  }

  let inputClass = "mt-1.5 h-10 w-full rounded-md border border-gray-200 bg-white px-3 text-sm text-gray-900 outline-none transition-colors placeholder:text-gray-400 focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-100"
  let labelClass = "text-xs font-semibold text-gray-800 dark:text-gray-200"

  <WaitForMessages>
    {_ =>
      <FramerMotion.AnimatePresence>
        {isOpen
          ? <>
              <FramerMotion.DivCss
                key="profile-modal-backdrop"
                className="fixed inset-0 z-[80] bg-black/45"
                initial={opacity: 0.}
                animate={opacity: 1.}
                exit={opacity: 0.}
                onClick={_ => onClose()}
              />
              <div
                key="profile-modal-panel"
                className="pointer-events-none fixed inset-0 z-[90] flex items-end justify-center p-3 sm:items-center sm:p-4">
                <FramerMotion.DivCss
                  role="dialog"
                  \"aria-modal"="true"
                  className="pointer-events-auto flex max-h-[calc(100vh-24px)] w-full max-w-lg flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-2xl dark:border-[#3a3b40] dark:bg-[#1e1f23]"
                  initial={opacity: 0., y: 18., scale: 0.98}
                  animate={opacity: 1., y: 0., scale: 1.}
                  exit={opacity: 0., y: 12., scale: 0.98}
                  transition={type_: "spring", stiffness: 520, damping: 36}>
                  // Header
                  <div
                    className="flex items-start justify-between gap-4 border-b border-gray-100 px-5 py-4 dark:border-[#2a2b30]">
                    <div className="flex min-w-0 gap-3">
                      <span
                        className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-[#bdf25d]/30 text-[#4d6f12] dark:text-[#bdf25d]">
                        <Lucide.UserRound size=17 \"aria-hidden"="true" />
                      </span>
                      <div>
                        <h2 className="text-base font-semibold text-gray-900 dark:text-gray-100">
                          {(ts`Complete your player profile`)->React.string}
                        </h2>
                        <p
                          className="mt-0.5 text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                          {subtitle->React.string}
                        </p>
                      </div>
                    </div>
                    <button
                      type_="button"
                      onClick={_ => onClose()}
                      ariaLabel={ts`Close profile form`}
                      className="rounded-md p-1.5 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:hover:bg-[#2a2b30] dark:hover:text-gray-100">
                      <Lucide.X className="w-4 h-4" />
                    </button>
                  </div>
                  // Form
                  <form
                    onSubmit={handleSubmit(onSubmit)}
                    className="flex min-h-0 flex-1 flex-col overflow-hidden">
                    <div className="space-y-5 overflow-y-auto px-5 py-4">
                      // Display Name
                      <label className="block">
                        <span className={labelClass}> {(ts`Display name`)->React.string} </span>
                        <input
                          {...register(LineUsername)}
                          id="display-name"
                          type_="text"
                          autoFocus=true
                          maxLength=50
                          placeholder={ts`How other players will see you`}
                          className={inputClass}
                        />
                        {switch formState.errors.lineUsername {
                        | Some({message: ?Some(message)}) =>
                          <span className="mt-1 block text-xs text-red-500">
                            {message->React.string}
                          </span>
                        | _ => React.null
                        }}
                      </label>
                      // Email (only when we don't already have one) + Gender
                      <div
                        className={emailExists
                          ? "grid grid-cols-1 gap-4"
                          : "grid grid-cols-1 gap-4 sm:grid-cols-2"}>
                        {emailExists
                          ? React.null
                          : <label className="block">
                              <span className={labelClass}>
                                {(ts`Email address`)->React.string}
                              </span>
                              <input
                                {...register(Email)}
                                id="email"
                                type_="email"
                                placeholder="you@example.com"
                                className={inputClass}
                              />
                              {switch (formState.errors.email, emailError) {
                              | (Some({message: ?Some(message)}), _) =>
                                <span className="mt-1 block text-xs text-red-500">
                                  {message->React.string}
                                </span>
                              | (_, Some(errorMsg)) =>
                                <span className="mt-1 block text-xs text-red-500">
                                  {errorMsg->React.string}
                                </span>
                              | _ =>
                                <span className="mt-1 block text-[9px] text-gray-400">
                                  {(ts`For event updates and notifications`)->React.string}
                                </span>
                              }}
                            </label>}
                        <label className="block">
                          <span className={labelClass}> {(ts`Gender`)->React.string} </span>
                          <select
                            className={inputClass}
                            value={switch gender {
                            | RelaySchemaAssets_graphql.Female => "female"
                            | Male => "male"
                            }}
                            onChange={e => {
                              let value = (e->ReactEvent.Form.target)["value"]
                              setGender(_ =>
                                switch value {
                                | "female" => RelaySchemaAssets_graphql.Female
                                | _ => Male
                                }
                              )
                            }}>
                            <option value="male"> {(ts`Male`)->React.string} </option>
                            <option value="female"> {(ts`Female`)->React.string} </option>
                          </select>
                        </label>
                      </div>
                      // Biography
                      <label className="block">
                        <span className={labelClass}> {(ts`Biography`)->React.string} </span>
                        <textarea
                          {...register(Biography)}
                          rows=4
                          maxLength=280
                          placeholder={ts`Share a little about yourself so organizers or other players can see why they should invite you.`}
                          className="mt-1.5 w-full resize-none rounded-md border border-gray-200 bg-white px-3 py-2.5 text-sm leading-relaxed text-gray-900 outline-none transition-colors placeholder:text-gray-400 focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-100"
                        />
                        <span className="mt-1 block text-right font-mono text-[9px] text-gray-400">
                          {(bio->String.length->Int.toString ++ "/280")->React.string}
                        </span>
                        {switch formState.errors.biography {
                        | Some({message: ?Some(message)}) =>
                          <span className="mt-1 block text-xs text-red-500">
                            {message->React.string}
                          </span>
                        | _ => React.null
                        }}
                      </label>
                      // Level
                      <div>
                        <span className={labelClass}> {(ts`Level`)->React.string} </span>
                        {switch duprLink {
                        | Some(link) =>
                          <div className="flex items-center gap-2 text-gray-900 dark:text-gray-100">
                            <DuprRatingBadge
                              doubles={link.doubles}
                              doublesReliable={CombinedRating.duprEstablished(
                                ~reliability=link.doublesReliability,
                                ~reliable=link.doublesReliable,
                              )}
                              compact=true
                            />
                            <RatingSourceChip
                              source=Dupr
                              reliable={CombinedRating.duprEstablished(
                                ~reliability=link.doublesReliability,
                                ~reliable=link.doublesReliable,
                              )}
                            />
                          </div>
                        | None => <LevelPicker value=level onChange={v => setLevel(_ => Some(v))} />
                        }}
                      </div>
                      {switch saveError {
                      | Some(msg) => <p className="text-xs text-red-500"> {msg->React.string} </p>
                      | None => React.null
                      }}
                    </div>
                    // Footer
                    <div
                      className="flex items-center justify-between gap-3 border-t border-gray-100 bg-gray-50 px-5 py-3 dark:border-[#2a2b30] dark:bg-[#1a1a1e]">
                      <button
                        type_="button"
                        onClick={_ => onClose()}
                        className="text-xs font-medium text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100">
                        {(ts`Not now`)->React.string}
                      </button>
                      <button
                        type_="submit"
                        disabled={!canSave}
                        className="inline-flex items-center gap-1.5 rounded-md bg-[#bdf25d] px-4 py-2 text-sm font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-45">
                        <Lucide.Check size=14 strokeWidth=2.5 \"aria-hidden"="true" />
                        {(ts`Save profile`)->React.string}
                      </button>
                    </div>
                  </form>
                </FramerMotion.DivCss>
              </div>
            </>
          : React.null}
      </FramerMotion.AnimatePresence>}
  </WaitForMessages>
}
