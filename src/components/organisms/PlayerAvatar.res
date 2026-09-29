// PlayerAvatar Component - Displays user avatar with skill level progress bar
//
// This component displays a user's avatar image with an optional skill level indicator.
// Uses GraphQL fragments to fetch user picture data efficiently.
//
// Usage Example:
// ```rescript
// <PlayerAvatar
//   userFragmentRefs={player.data->Option.flatMap(getUserFragmentRefs)}
//   name={player.name}
//   skillLevel={player.ratingOrdinal}
//   size=#medium
// />
// ```

module Fragment = %relay(`
  fragment PlayerAvatar_user on User {
    picture
  }
`)

@react.component
let make = (
  ~userFragmentRefs: option<RescriptRelay.fragmentRefs<[> #PlayerAvatar_user]>>,
  ~name: string,
  ~skillLevel: float,
  ~size: [#small | #medium | #large]=#medium,
  ~className: string="",
  ~style: option<ReactDOM.Style.t>=?,
) => {
  // useOpt keeps the hook unconditional whether or not a user ref is passed.
  let pictureUrl = Fragment.useOpt(userFragmentRefs)->Option.flatMap(userData => userData.picture)

  <div className style=?style>
    <AvatarWithProgressBar ?pictureUrl name skillLevel size containerClassName=className />
  </div>
}
