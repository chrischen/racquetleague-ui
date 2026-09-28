// Storybook support for AvatarRsvpUser.stories.tsx; the app never imports
// this. AvatarRsvpUser is the avatar-and-name entry on the classic event
// page's RSVP lists (through EventRsvpUser): the ring around the picture is
// the player's rating as a share of the strongest player's, with its
// uncertainty in a lighter arc after it.
@genType @react.component
let make = (
  ~name="Kenji W.",
  ~withPicture=true,
  ~highlight=false,
  ~secondaryText: option<string>=?,
  ~ratingPercent: option<float>=?,
  ~sigmaPercent: option<float>=?,
) => {
  let user: Rating.user = {
    name,
    picture: withPicture ? Some(StoryFixturesEvent.avatar(name, 1)) : None,
  }
  <div className="font-sans">
    <AvatarRsvpUser
      user
      highlight
      link="/league/pickleball/p/user-kenji"
      ?secondaryText
      ?ratingPercent
      ?sigmaPercent
    />
  </div>
}
