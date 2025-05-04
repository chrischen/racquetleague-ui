module Fragment = %relay(`
  fragment EventRsvpUser_user on User {
    picture
    lineUsername
  }
`)

// type userData = Registered(EventRsvpUser_user_graphql.Types.fragment) | Guest

let fromRegisteredUser = (user: EventRsvpUser_user_graphql.Types.fragment) => {
  {
    Rating.name: user.lineUsername->Option.getOr("[Line username missing]"),
    picture: user.picture,
    // data: Registered(user),
  }
}
// let toRatingPlayer = (player: user): Rating.Player.t<'a> => {
//   let rating = Rating.Rating.makeDefault()
//   {
//     data: None,
//     id: player.name,
//     name: player.name,
//     rating,
//     ratingOrdinal: rating->Rating.Rating.ordinal,
//   }
// }

// @genType @react.component
// type props = {
//   // user: EventRsvpUser_user_graphql.Types.fragment,
//   highlight: bool,
//   link: option<string>,
//   rating: option<float>,
//   ratingPercent: option<float>,
// }
let make = (
  props: RsvpUser.props<
    RescriptRelay.fragmentRefs<[> #EventRsvpUser_user]>,
    bool,
    string,
    string,
    'a,
    'b,
  >,
) => {
  // open Lingui.Util;
  let user = Fragment.use(props.user)->fromRegisteredUser
  <RsvpUser {...props} user={user} />
}
