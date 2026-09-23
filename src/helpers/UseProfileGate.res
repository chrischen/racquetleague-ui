// Shared "is the viewer's profile complete enough to do this?" gate. Hosts call
// `require(action)`: the action runs immediately when the profile passes, and
// otherwise gets stashed while ProfileModal collects the missing fields — then
// runs on save. Dismissing the modal drops the pending action.
//
// Two bars, because the surfaces ask for different things:
//   Join         — display name, email
//   Availability — display name, email, biography
// Both additionally want a skill rating, but only from players we can't already
// rate: a computed Rating (from played matches) satisfies it, as does a linked
// DUPR rating, so the self-report is asked for only when there is neither.
//
// Callers keep owning their login redirects; `require` assumes a logged-in
// viewer.

// Read completeness off `viewer.profile`, not `viewer.user`: `user` is built
// from the auth session, which only ever carries id/lineUsername/email/picture/
// locale — biography, fullName, gender and selfRating are never populated on it.
// Both fields resolve to the same User id, so selecting those fields under
// `user` writes nulls over the real values `profile` fetched from the database.
module Fragment = %relay(`
  fragment UseProfileGate_query on Query
  @argumentDefinitions(activitySlug: {type: "String", defaultValue: "pickleball"}) {
    ...ProfileModal_viewer
    viewer {
      profile {
        id
        lineUsername
        email
        biography
        selfRating
        dupr {
          doubles
        }
        rating(activitySlug: $activitySlug) {
          id
        }
      }
    }
  }
`)

type t = {
  isComplete: bool,
  require: (unit => unit) => unit,
  modal: React.element,
}

let nonEmpty = (v: option<string>) => v->Option.map(s => s->String.trim != "")->Option.getOr(false)

let use = (
  ~query: RescriptRelay.fragmentRefs<[> #UseProfileGate_query]>,
  ~context: ProfileModal.context,
  // Overrides the fragment's activity-scoped rating lookup where the host has a
  // better answer (an event page knows the viewer's rating for that event).
  ~hasComputedRating: option<bool>=?,
) => {
  let data = Fragment.use(query)
  let (isOpen, setIsOpen) = React.useState(() => false)
  let (pending, setPending) = React.useState(() => None)

  let profile = data.viewer->Option.flatMap(v => v.profile)

  // Any of the three signals clears the bar; which one would actually be
  // used is CombinedRating's call, not this gate's.
  let ratingOk =
    hasComputedRating->Option.getOr(profile->Option.flatMap(u => u.rating)->Option.isSome) ||
    CombinedRating.resolve(
      ~pkuruMu=None,
      ~duprDoubles=profile->Option.flatMap(u => u.dupr)->Option.flatMap(d => d.doubles),
      ~duprReliable=false,
      ~selfMu=profile->Option.flatMap(u => u.selfRating),
    )->Option.isSome

  let isComplete = switch profile {
  | None => false
  | Some(u) =>
    let base = nonEmpty(u.lineUsername) && nonEmpty(u.email) && ratingOk
    switch context {
    | ProfileModal.Join => base
    | Availability | Profile => base && nonEmpty(u.biography)
    }
  }

  let require = (action: unit => unit) =>
    if isComplete {
      action()
    } else {
      setPending(_ => Some(action))
      setIsOpen(_ => true)
    }

  let modal =
    <ProfileModal
      isOpen
      context
      query={data.fragmentRefs}
      onClose={() => {
        setPending(_ => None)
        setIsOpen(_ => false)
      }}
      onProfileComplete={() => {
        pending->Option.forEach(action => action())
        setPending(_ => None)
        setIsOpen(_ => false)
      }}
    />

  {isComplete, require, modal}
}
