module Fragment = %relay(`
  fragment EventMatchRsvpUser_user on User
  {
    picture
    lineUsername
  }
`)

// type userData = Registered(EventRsvpUser_user_graphql.Types.fragment) | Guest

// let fromRegisteredUser = (user: EventRsvpUser_user_graphql.Types.fragment) => {
//   {
//     Rating.name: user.lineUsername->Option.getOr("[Line username missing]"),
//     picture: user.picture,
//     // data: Registered(user),
//   }
// }
let make = (
  props: MatchRsvpUser.props<
    RescriptRelay.fragmentRefs<[> #EventMatchRsvpUser_user]>,
    bool,
    MatchRsvpUser.status,
    string,
    'a,
    'b,
  >,
) => {
  let user: EventMatchRsvpUser_user_graphql.Types.fragment = Fragment.use(props.user)
  <MatchRsvpUser
    {...props}
    user={
      Rating.name: user.lineUsername->Option.getOr("[Line username missing]"),
      picture: user.picture,
    }
  />
}
