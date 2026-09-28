// Storybook support for RsvpUser.stories.tsx; the app never imports this.
// RsvpUser is a player row on the check-in list (SelectPlayersList): picture,
// name, and a bar for the player's rating (and, when known, its uncertainty).
// Guests added by name have no picture.
@genType @react.component
let make = (
  ~name="Emily",
  ~withPicture=true,
  ~highlight=false,
  ~linked=false,
  ~secondaryText: option<string>=?,
  ~ratingPercent: option<float>=?,
  ~sigmaPercent: option<float>=?,
) => {
  let user: Rating.user = {
    name,
    picture: withPicture ? Some(StoryFixturesEvent.avatar(name, 2)) : None,
  }
  <div className="max-w-sm font-sans">
    <RsvpUser
      user
      highlight
      link=?{linked ? Some("/league/pickleball/p/user-emily") : None}
      ?secondaryText
      ?ratingPercent
      ?sigmaPercent
    />
  </div>
}
