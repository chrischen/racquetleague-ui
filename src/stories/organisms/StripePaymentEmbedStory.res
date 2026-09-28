// Storybook support for StripePaymentEmbed.stories.tsx; the app never imports
// this. The component loads Stripe.js and mounts Stripe's Payment Element for
// a client secret the backend created. Stories use neither: this module puts
// a stand-in `window.Stripe` in place before @stripe/stripe-js looks for one
// (that library defers its own script injection by a tick, and uses an
// existing `window.Stripe` instead), so nothing is fetched from Stripe and no
// Stripe object is created. The stand-in mounts a plainly labelled skeleton
// where the card fields would be, and answers confirmSetup/confirmPayment
// with the outcome the story picks.
//
// Caveat: @stripe/stripe-js caches the Stripe.js it found for the whole page,
// so if a story using the real library rendered earlier in the same preview
// session, that one wins until the preview reloads.

type outcome = [#saves | #declines | #failsSilently | #hangs | #blocked]

let currentOutcome: ref<outcome> = ref(#saves)

let installStandIn: (unit => outcome) => unit = %raw(`
  function (outcome) {
    if (window.Stripe) return;
    const field = (label, width) =>
      '<div style="flex:' + width + ';min-width:0">' +
      '<div style="font-size:13px;margin-bottom:6px;opacity:.75">' + label + "</div>" +
      '<div style="height:44px;border:1px solid rgba(128,128,128,.35);border-radius:6px;background:rgba(128,128,128,.06)"></div>' +
      "</div>";
    const skeleton =
      '<div data-story-stand-in="payment-element" style="display:flex;flex-direction:column;gap:12px">' +
      '<div style="display:flex;gap:12px">' + field("Card number", 1) + "</div>" +
      '<div style="display:flex;gap:12px">' + field("Expiration date", 1) + field("Security code", 1) + "</div>" +
      '<div style="display:flex;gap:12px">' + field("Country", 1) + "</div>" +
      '<div style="font-size:11px;opacity:.55">Stand-in for Stripe’s Payment Element (Storybook)</div>' +
      "</div>";
    const answer = (kind, id) => {
      switch (outcome()) {
        case "hangs":
          return new Promise(() => {});
        case "declines":
          return Promise.resolve({ error: { type: "card_error", code: "card_declined", message: "Your card was declined." } });
        case "failsSilently":
          return Promise.resolve({ error: { type: "api_error" } });
        default:
          return Promise.resolve({ [kind]: { id, status: "succeeded" } });
      }
    };
    const StandIn = function () {
      if (outcome() === "blocked") return null;
      return {
        elements: () => ({
          create: () => {
            let node = null;
            const listeners = {};
            return {
              mount(domNode) {
                node = domNode;
                node.innerHTML = skeleton;
                (listeners.ready ?? []).forEach((cb) => cb({ elementType: "payment" }));
              },
              on(event, cb) {
                (listeners[event] ??= []).push(cb);
              },
              off(event, cb) {
                listeners[event] = (listeners[event] ?? []).filter((x) => x !== cb);
              },
              update() {},
              destroy() {
                if (node) node.innerHTML = "";
              },
            };
          },
          update() {},
          getElement: () => null,
        }),
        createToken: async () => ({}),
        createPaymentMethod: async () => ({}),
        confirmCardPayment: async () => ({}),
        confirmSetup: () => answer("setupIntent", "seti_1StoryFixture0000000000"),
        confirmPayment: () => answer("paymentIntent", "pi_3StoryFixture0000000000"),
        _registerWrapper() {},
        registerAppInfo() {},
      };
    };
    StandIn.version = 3;
    window.Stripe = StandIn;
  }
`)

installStandIn(() => currentOutcome.contents)

/** Well-formed but fictitious: no Stripe object exists behind these. */
let setupSecret = "seti_1StoryFixture0000000000_secret_StoryFixtureSecret000000000"
let paymentSecret = "pi_3StoryFixture0000000000_secret_StoryFixtureSecret000000000"
let connectedAccount = "acct_1StoryFixture0000"

@genType @react.component
let make = (
  ~mode: [#setup | #payment]=#setup,
  ~outcome: outcome=#saves,
  ~amountLabel: option<string>=?,
  ~onSuccess=(_: string) => (),
  ~onClose=() => (),
) => {
  // Read when the component loads Stripe (on mount) and when it confirms.
  currentOutcome := outcome
  switch mode {
  | #setup =>
    <StripePaymentEmbed clientSecret=setupSecret mode=Setup ?amountLabel onSuccess onClose />
  | #payment =>
    // Payments live on the organizer's connected account.
    <StripePaymentEmbed
      clientSecret=paymentSecret
      stripeAccountId=connectedAccount
      mode=Payment
      ?amountLabel
      onSuccess
      onClose
    />
  }
}
