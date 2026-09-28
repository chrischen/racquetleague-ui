import { patchRecords } from "./_shared.mjs";

// Overlay mode: your real session and real data from the backend, with your
// own profile emptied everywhere it appears. Sign in first.
//
// Everything the profile gate and the profile form read is blanked: name,
// email, bio, gender, and all three rating signals (computed rating, DUPR
// link, self-rating). The patch is by user id, not by path, because the same
// user record also arrives under viewer.user, in RSVP lists and so on, and an
// unpatched copy would put the real values back.
//
// Mutation responses are left alone, so filling in the profile modal and
// saving behaves like the real flow: it writes to your account in the local
// dev database, and the page shows what you saved until the next reload,
// when the profile reads as empty again.
export default {
  description:
    "Overlay on your real session: your own profile reads as empty everywhere (name, email, bio, gender, rating). Saving a profile writes to your dev account.",
  mode: "overlay",
  patch: (_operationName, data, _variables, { operation, viewerId }) => {
    if (operation === "mutation") return data;
    return patchRecords(data, viewerId, {
      lineUsername: "",
      email: null,
      fullName: null,
      biography: "",
      gender: null,
      selfRating: null,
      dupr: null,
      rating: null,
      effectiveRating: null,
    });
  },
};
