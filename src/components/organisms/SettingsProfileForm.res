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
       selfRating
     }
     errors {
       message
     }
   }
 }
`)

module StripeMutation = %relay(`
  mutation SettingsProfileFormStripeAccountSessionMutation($country: String!) {
    createStripeAccountSession(country: $country) {
      accountId
      clientSecret
      errors {
        message
      }
    }
  }
`)

module QueryFragment = %relay(`
  fragment SettingsProfileForm_query on Query
  @refetchable(queryName: "SettingsProfileFormRefetchQuery") {
    ...DuprConnectCard_query
    viewer {
      user {
        stripeAccountId
        stripeChargesEnabled
      }
      profile {
        id
        fullName
        biography
        lineUsername
        gender
        email
        selfRating
        dupr {
          duprId
          doubles
          singles
          doublesReliable
          singlesReliable
        }
      }
    }
  }
`)

module StripeOnboardingEmbed = {
  @module("./StripeOnboardingEmbed") @react.component
  external make: (~clientSecret: string, ~onExit: unit => unit) => React.element =
    "StripeOnboardingEmbed"
}

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

// Stripe Connect onboarding lifecycle:
//   NotConnected — no Express account created yet
//   Pending      — account exists, onboarding in progress or under review
//   Active       — charges_enabled = true
type stripeStatus = NotConnected | Pending | Active

@react.component
let make = (~query) => {
  let navigate = LangProvider.Router.useNavigate()
  open Lingui.Util
  let (query, refetchQuery) = QueryFragment.useRefetchable(query)

  let (commitMutation, _) = Mutation.use()
  let (commitStripeMutation, isStripePending) = StripeMutation.use()

  let (stripeClientSecret, setStripeClientSecret) = React.useState(() => None)
  let (stripeCountry, setStripeCountry) = React.useState(() => "JP")

  // The backend treats an unset gender as male, so there's no "prefer not to
  // say" to offer — an unset profile just starts on male.
  let (gender, setGender) = React.useState(() =>
    switch query.viewer
    ->Option.flatMap(viewer => viewer.profile)
    ->Option.flatMap(profile => profile.gender) {
    | Some(RelaySchemaAssets_graphql.Female) =>
      (Female: RelaySchemaAssets_graphql.enum_Gender_input)
    | _ => Male
    }
  )

  // A linked DUPR account outranks the self-report everywhere, so while one
  // is connected the picker is replaced by the DUPR rating rather than
  // offering a second, contradictory number to edit.
  let duprLink =
    query.viewer->Option.flatMap(v => v.profile)->Option.flatMap(p => p.dupr)

  // selfRating is stored on the internal scale; the picker speaks DUPR.
  let (level, setLevel) = React.useState(() =>
    query.viewer
    ->Option.flatMap(viewer => viewer.profile)
    ->Option.flatMap(profile => profile.selfRating)
    ->Option.map(mu => mu->Rating.guessDupr->LevelPicker.nearest)
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
          profile.selfRating->Option.forEach(
            mu => setLevel(_ => Some(mu->Rating.guessDupr->LevelPicker.nearest)),
          )
        },
      )
    })
    None
  }, [query.viewer])

  let onSubmit = (data: inputs) => {
    let input: RelaySchemaAssets_graphql.input_UpdateProfileInput = {
      fullName: data.fullName,
      biography: data.biography,
      username: data.username,
      gender,
      // Omitted while DUPR is linked: the field is optional, so the stored
      // self-report is left untouched rather than overwritten, and comes
      // back intact if the player disconnects.
      selfRating: ?(duprLink->Option.isSome ? None : level->Option.map(Rating.duprToMu)),
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
              <div>
                <label
                  htmlFor="displayName"
                  className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                  {t`Display Name`}
                </label>
                <input
                  {...register(Username)}
                  id="displayName"
                  type_="text"
                  placeholder={ts`How you appear to other players`}
                  className="block w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100"
                />
                {switch formState.errors.username {
                | Some({message: ?Some(message)}) =>
                  <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                    {message->React.string}
                  </p>
                | _ => React.null
                }}
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label
                    htmlFor="fullName"
                    className="block text-xs font-medium uppercase tracking-wider text-gray-400 dark:text-gray-500 mb-2">
                    {t`Full name`}
                  </label>
                  <input
                    {...register(FullName)}
                    id="fullName"
                    type_="text"
                    placeholder={ts`Doe John`}
                    className="block w-full px-4 py-3 border border-gray-200 dark:border-gray-800 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-gray-50 dark:bg-[#1a1a1a] text-gray-600 dark:text-gray-400"
                  />
                  {switch formState.errors.fullName {
                  | Some({message: ?Some(message)}) =>
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                      {message->React.string}
                    </p>
                  | _ => React.null
                  }}
                  <p className="mt-2 text-xs text-gray-400 dark:text-gray-500">
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
                <label
                  className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
                  {t`Level`}
                </label>
                {switch duprLink {
                | Some(link) =>
                  <div>
                    <div className="flex items-center gap-3">
                      <DuprRatingBadge
                        doubles={link.doubles}
                        singles=?link.singles
                        doublesReliable={link.doublesReliable}
                        singlesReliable={link.singlesReliable}
                        compact=true
                      />
                      <RatingSourceChip source=Dupr reliable={link.doublesReliable} />
                    </div>
                    <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                      {t`Your rating comes from DUPR. Disconnect DUPR below to set your own level again.`}
                    </p>
                  </div>
                | None =>
                  <div>
                    <LevelPicker value=level onChange={v => setLevel(_ => Some(v))} />
                    <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                      {switch level {
                      | Some(v) =>
                        (ts`Estimated DUPR` ++ ": " ++ v->Float.toFixed(~digits=2))->React.string
                      | None => (ts`Your self-reported skill level`)->React.string
                      }}
                    </p>
                  </div>
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
        <div
          className="mt-8 border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
          <div className="px-4 py-5 sm:px-6">
            <h3
              className="text-sm font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
              {t`Notifications`}
            </h3>
          </div>
          <div className="px-4 pb-6">
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
              {t`Receive push notifications for event reminders and updates.`}
            </p>
            <PushNotifications />
          </div>
        </div>
        <DuprConnectCard
          query={query.fragmentRefs}
          onChanged={() =>
            refetchQuery(~variables=QueryFragment.makeRefetchVariables())->RescriptRelay.Disposable.ignore}
        />
        {
          let stripeAccountId = query.viewer->Option.flatMap(v => v.user)->Option.flatMap(u => u.stripeAccountId)
          let chargesEnabled =
            query.viewer
            ->Option.flatMap(v => v.user)
            ->Option.flatMap(u => u.stripeChargesEnabled)
            ->Option.getOr(false)

          let status = switch (stripeAccountId, chargesEnabled) {
          | (None, _) => NotConnected
          | (Some(_), false) => Pending
          | (Some(_), true) => Active
          }

          <div
            className="mt-8 border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
            <div className="px-4 py-5 sm:px-6">
              <h3
                className="text-sm font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
                {t`Stripe Connect`}
              </h3>
            </div>
            <div className="px-4 pb-6 space-y-4">
              // ── Status row ────────────────────────────────────────────────
              <div className="flex items-start gap-3">
                <span
                  className={"mt-0.5 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium shrink-0 " ++
                  switch status {
                  | Active => "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
                  | Pending => "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400"
                  | NotConnected => "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400"
                  }}>
                  {switch status {
                  | Active => t`Active`
                  | Pending => t`Pending`
                  | NotConnected => t`Not connected`
                  }}
                </span>
                <div className="space-y-1">
                  <p className="text-sm text-gray-700 dark:text-gray-300">
                    {switch status {
                    | Active => t`Your Stripe account is connected.`
                    | Pending =>
                      t`Your Stripe account is connected, but onboarding isn't complete yet.`
                    | NotConnected => t`No Stripe account is connected.`
                    }}
                  </p>
                  // What the state means for paid events. Attendees save a card at
                  // RSVP in every case; only a connected account lets the organizer
                  // charge it (one attendee or everyone, from the RSVP list).
                  <p className="text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                    {switch status {
                    | Active =>
                      t`Attendees of your paid events save a card when they RSVP; nothing is charged up front. From an event's RSVP list you can charge one attendee or everyone, and the money goes to this account.`
                    | Pending =>
                      t`Until onboarding is complete, your paid events run on the platform account: attendees save a card when they RSVP, but you can't charge it. Collect the fee at the event.`
                    | NotConnected =>
                      t`Attendees of your paid events still save a card when they RSVP, but it can't be charged, so you collect the fee at the event. Connect a Stripe account to charge saved cards from the RSVP list and receive the money here.`
                    }}
                  </p>
                  {switch stripeAccountId {
                  | Some(accountId) =>
                    <p className="text-xs text-gray-400 dark:text-gray-600 font-mono">
                      {accountId->React.string}
                    </p>
                  | None => React.null
                  }}
                </div>
              </div>
              // ── Action button (hidden once fully active) ──────────────────
              {switch status {
              | Active => React.null
              | _ =>
                <div className="space-y-3">
                  <div>
                    <label
                      htmlFor="stripeCountry"
                      className="block text-xs font-medium uppercase tracking-wider text-gray-400 dark:text-gray-500 mb-1.5">
                      {t`Country`}
                    </label>
                    <select
                      id="stripeCountry"
                      value=stripeCountry
                      onChange={e => {
                        let v = (e->ReactEvent.Form.target)["value"]
                        setStripeCountry(_ => v)
                      }}
                      className="block w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100">
                      <option value="JP"> {(ts`Japan`)->React.string} </option>
                      <option value="US"> {(ts`United States`)->React.string} </option>
                      <option value="AU"> {(ts`Australia`)->React.string} </option>
                      <option value="CA"> {(ts`Canada`)->React.string} </option>
                      <option value="GB"> {(ts`United Kingdom`)->React.string} </option>
                      <option value="SG"> {(ts`Singapore`)->React.string} </option>
                      <option value="HK"> {(ts`Hong Kong`)->React.string} </option>
                      <option value="TW"> {(ts`Taiwan`)->React.string} </option>
                      <option value="KR"> {(ts`South Korea`)->React.string} </option>
                    </select>
                  </div>
                  <button
                    type_="button"
                    disabled={isStripePending}
                    onClick={_ => {
                      commitStripeMutation(
                        ~variables={country: stripeCountry},
                        ~onCompleted=(response, _) => {
                          switch response.createStripeAccountSession.clientSecret {
                          | Some(secret) => setStripeClientSecret(_ => Some(secret))
                          | None => ()
                          }
                        },
                      )->RescriptRelay.Disposable.ignore
                    }}
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-lg shadow-sm text-gray-900 bg-[#a3e635] hover:bg-[#84cc16] focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:ring-offset-2 dark:focus:ring-offset-[#111111] disabled:opacity-50 transition-colors">
                    {if isStripePending {
                      t`Connecting...`
                    } else {
                      switch status {
                      | NotConnected => t`Connect Stripe account`
                      | Pending => t`Resume onboarding`
                      | Active => React.string("")
                      }
                    }}
                  </button>
                </div>
              }}
              {switch stripeClientSecret {
              | Some(secret) =>
                <div className="mt-4">
                  <StripeOnboardingEmbed
                    clientSecret=secret
                    onExit={() => {
                      setStripeClientSecret(_ => None)
                      refetchQuery(
                        ~variables=QueryFragment.makeRefetchVariables(),
                      )->RescriptRelay.Disposable.ignore
                    }}
                  />
                </div>
              | None => React.null
              }}
            </div>
          </div>
        }
      </>}
    </WaitForMessages>
  </FramerMotion.Div>
}
