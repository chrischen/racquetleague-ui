import { signedInViewer } from "./_shared.mjs";

// src/helpers/UseProfileGate.res treats a profile as incomplete when the
// display name or email is blank, or when there is no rating signal at all
// (no computed rating, no DUPR doubles, no self-rating). Availability and
// profile actions also need a biography. This user fails every check.
export default {
  description:
    "Signed in, profile incomplete: no display name, email, biography or rating. Gated actions open the profile modal.",
  mocks: {
    Query: { viewer: {} },
    Viewer: signedInViewer(),
    User: {
      lineUsername: "",
      email: null,
      fullName: null,
      biography: "",
      gender: null,
      selfRating: null,
      dupr: null,
      rating: null,
      picture: null,
      // GlobalQuery.LocaleSync navigates whenever this differs from the URL's
      // language, so keep it matching the pages you open ("en" for /...).
      locale: "en",
      stripeAccountId: null,
      stripeChargesEnabled: false,
    },
  },
};
