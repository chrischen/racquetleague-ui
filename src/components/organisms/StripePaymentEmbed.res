%%raw("import { t } from '@lingui/macro'")

// Bindings for @stripe/stripe-js and @stripe/react-stripe-js, limited to what
// the embedded checkout form needs.
module Stripe = {
  type t
  type elements
  type intent = {id: string}
  type error = {message?: string}
  type confirmResult = {error?: error, setupIntent?: intent, paymentIntent?: intent}
  type confirmParams = {elements: elements, redirect: string}
  type loadOptions = {stripeAccount: string}

  // Resolves to null when Stripe.js fails to load. Elements accepts the
  // promise directly.
  @module("@stripe/stripe-js")
  external load: (string, ~options: loadOptions=?) => promise<Js.Nullable.t<t>> = "loadStripe"

  @send external confirmSetup: (t, confirmParams) => promise<confirmResult> = "confirmSetup"
  @send external confirmPayment: (t, confirmParams) => promise<confirmResult> = "confirmPayment"

  // Null until Stripe.js has loaded inside <Elements>.
  @module("@stripe/react-stripe-js")
  external useStripe: unit => Js.Nullable.t<t> = "useStripe"
  @module("@stripe/react-stripe-js")
  external useElements: unit => Js.Nullable.t<elements> = "useElements"

  type appearanceVariables = {colorPrimary: string}
  type appearance = {theme: string, variables: appearanceVariables}
  type elementsOptions = {clientSecret: string, locale: string, appearance: appearance}

  module Elements = {
    @module("@stripe/react-stripe-js") @react.component
    external make: (
      ~stripe: promise<Js.Nullable.t<t>>,
      ~options: elementsOptions,
      ~children: React.element,
    ) => React.element = "Elements"
  }

  module PaymentElement = {
    @module("@stripe/react-stripe-js") @react.component
    external make: unit => React.element = "PaymentElement"
  }
}

@val external publishableKey: string = "import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY"

// Setup saves the card for the organizer to charge after the event
// (SetupIntent, confirmSetup); Payment charges it now (PaymentIntent,
// confirmPayment). onSuccess receives the id of whichever intent was confirmed.
type mode = Setup | Payment

module CheckoutForm = {
  @react.component
  let make = (~mode: mode, ~onSuccess: string => unit, ~onClose: unit => unit) => {
    let stripe = Stripe.useStripe()->Js.Nullable.toOption
    let elements = Stripe.useElements()->Js.Nullable.toOption
    let (error, setError) = React.useState(() => None)
    let (processing, setProcessing) = React.useState(() => false)

    let handleSubmit = async (e: ReactEvent.Form.t) => {
      ReactEvent.Form.preventDefault(e)
      switch (stripe, elements) {
      | (Some(stripe), Some(elements)) =>
        setProcessing(_ => true)
        setError(_ => None)
        let params: Stripe.confirmParams = {elements, redirect: "if_required"}
        let result = switch mode {
        | Setup => await stripe->Stripe.confirmSetup(params)
        | Payment => await stripe->Stripe.confirmPayment(params)
        }
        switch result.error {
        | Some(error) =>
          let message = switch error.message {
          | Some(message) => message->React.string
          | None =>
            switch mode {
            | Setup => Lingui.Util.t`Could not save your card`
            | Payment => Lingui.Util.t`Payment failed`
            }
          }
          setError(_ => Some(message))
          setProcessing(_ => false)
        | None =>
          switch (result.setupIntent, result.paymentIntent) {
          | (Some({id}), _) | (_, Some({id})) => onSuccess(id)
          | (None, None) => setProcessing(_ => false)
          }
        }
      | _ => ()
      }
    }

    <form onSubmit={e => handleSubmit(e)->ignore} className="space-y-4">
      <Stripe.PaymentElement />
      {switch error {
      | Some(error) => <p className="mt-2 text-sm text-red-500 dark:text-red-400"> {error} </p>
      | None => React.null
      }}
      <div className="flex gap-3 justify-end pt-2">
        <button
          type_="button"
          onClick={_ => onClose()}
          disabled=processing
          className="px-4 py-2 text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white disabled:opacity-50 transition-colors">
          {Lingui.Util.t`Cancel`}
        </button>
        <button
          type_="submit"
          disabled={stripe->Option.isNone || processing}
          className="px-4 py-2 text-sm font-semibold rounded-md bg-amber-500 text-white hover:bg-amber-600 disabled:opacity-60 inline-flex items-center gap-1.5 transition-colors">
          {if processing {
            Lingui.Util.t`Processing…`
          } else {
            switch mode {
            | Setup => Lingui.Util.t`Save card`
            | Payment => Lingui.Util.t`Pay now`
            }
          }}
        </button>
      </div>
    </form>
  }
}

@react.component
let make = (
  ~clientSecret: string,
  // The connected account the intent lives on. Absent for a card setup: cards
  // are saved on the platform account and cloned to organizers when charged.
  ~stripeAccountId: option<string>=?,
  ~mode: mode,
  // The fee the organizer will charge later, formatted (e.g. "¥1,000").
  // Only shown in setup mode.
  ~amountLabel: option<string>=?,
  ~onSuccess: string => unit,
  ~onClose: unit => unit,
) => {
  let {i18n: {locale}} = Lingui.useLingui()
  let stripePromise = React.useMemo1(
    () =>
      Stripe.load(
        publishableKey,
        ~options=?stripeAccountId->Option.map(stripeAccount => {
          Stripe.stripeAccount: stripeAccount,
        }),
      ),
    [stripeAccountId],
  )

  <div
    className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 sm:p-4"
    onClick={e => {
      if ReactEvent.Mouse.target(e) === ReactEvent.Mouse.currentTarget(e) {
        onClose()
      }
    }}>
    <div
      className="w-full max-w-md max-h-full overflow-y-auto overscroll-contain bg-white dark:bg-[#1e1f23] rounded-t-2xl sm:rounded-2xl p-6 shadow-xl">
      <h2 className="text-base font-semibold text-gray-900 dark:text-white mb-4">
        {switch mode {
        | Setup => Lingui.Util.t`Save your card`
        | Payment => Lingui.Util.t`Complete payment`
        }}
      </h2>
      {switch mode {
      | Setup =>
        <div
          className="mb-5 rounded-lg bg-amber-50 dark:bg-amber-900/30 border border-amber-300 dark:border-amber-700 px-4 py-3 flex gap-3 items-start">
          <span className="text-amber-500 text-lg leading-none mt-0.5">
            {"💳"->React.string}
          </span>
          <p className="text-sm font-semibold text-amber-800 dark:text-amber-200 leading-snug">
            {switch amountLabel {
            | Some(amountLabel) =>
              Lingui.Util.t`Your card is saved now, not charged. The organizer will charge ${amountLabel} later.`
            | None =>
              Lingui.Util.t`Your card is saved now, not charged. The organizer will charge the participation fee later.`
            }}
          </p>
        </div>
      | Payment => React.null
      }}
      <Stripe.Elements
        stripe=stripePromise
        options={{
          clientSecret,
          locale,
          appearance: {theme: "stripe", variables: {colorPrimary: "#a3e635"}},
        }}>
        <CheckoutForm mode onSuccess onClose />
      </Stripe.Elements>
    </div>
  </div>
}
