%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
module Fragment = %relay(`
  fragment MiniEventRsvp_rsvp on Rsvp {
    user {
      id
      picture
      lineUsername
    }
    rating {
      ordinal
      mu
      sigma
    }
  }
`)

module ListItem = {
  @react.component
  let make = (~children) => {
    <FramerMotion.DivCss
      className=""
      style={originX: 0.05, originY: 0.05}
      initial={opacity: 0., scale: 1.15}
      animate={opacity: 1., scale: 1.}
      exit={opacity: 0., scale: 1.15}>
      <div className="flex-none">
        <span className="sr-only"> {t`Player`} </span>
        // <UserCircleIcon className="h-6 w-5 text-gray-400" aria-hidden="true" />
      </div>
      {children}
    </FramerMotion.DivCss>
  }
}

@react.component
let make = (~rsvp, ~maxRating) => {
  let rsvp = Fragment.use(rsvp)

  rsvp.user
  ->Option.map(user => {
    let progress =
      rsvp.rating
      ->Option.flatMap(rating => rating.mu)
      ->Option.map(mu => Int.fromFloat(mu /. maxRating *. 100.))
      ->Option.getOr(100)

    <ListItem key={user.id}>
      <AvatarWithProgress
        src={user.picture->Option.getOr("")}
        alt={user.lineUsername->Option.getOr("[Line username missing]")}
        progress
      />
    </ListItem>
  })
  ->Option.getOr(React.null)
}
