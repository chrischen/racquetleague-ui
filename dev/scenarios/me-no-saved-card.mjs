// Overlay mode: your real session and data, except that you have no card on
// file. Sign in first.
//
// Viewer.savedCard is the only thing the UI reads to decide this: with it, a
// priced event offers a one-click join with the saved card; without it, the
// Stripe card form opens as soon as the join lands (PkEventPage's
// cardRequiredOnJoin). The backend follows the UI here: a join without a card
// starts a fresh card setup (setupRsvpPaymentMethod) and only reuses a stored
// card when the UI asks for it (useSavedPaymentMethod), so the whole no-card
// flow runs for real against Stripe test mode. Test card 4242 4242 4242 4242.
//
// The viewer has no id (the app keeps a single viewer record), so patching
// data.viewer covers every copy. Mutation responses are left alone: a card you
// save shows up until the next reload, then is hidden again.
export default {
  description:
    "Overlay on your real session: no saved card, so joining a priced event opens the Stripe card form. Cards you save go to Stripe test mode on your dev account.",
  mode: "overlay",
  patch: (_operationName, data, _variables, { operation } = {}) => {
    if (operation !== "mutation" && data?.viewer && "savedCard" in data.viewer) {
      data.viewer.savedCard = null;
    }
    return data;
  },
};
