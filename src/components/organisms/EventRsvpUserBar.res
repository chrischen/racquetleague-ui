module Fragment = %relay(`
  fragment EventRsvpUserBar_user on User {
    picture
    lineUsername
  }
`)

let fromRegisteredUser = (user: EventRsvpUserBar_user_graphql.Types.fragment) => {
  {
    Rating.name: user.lineUsername->Option.getOr("[Line username missing]"),
    picture: user.picture,
  }
}
let make = (
  props: RsvpUser.props<
    RescriptRelay.fragmentRefs<[> #EventRsvpUserBar_user]>,
    bool,
    string,
    string,
    'a,
    'b,
  >,
) => {
  // open Lingui.Util;
  let user = Fragment.use(props.user)->fromRegisteredUser
  <RsvpUser
    user={user}
    highlight=?props.highlight
    link=?props.link
    secondaryText=?props.secondaryText
    sigmaPercent=?props.sigmaPercent
    ratingPercent=?props.ratingPercent
  />
}
