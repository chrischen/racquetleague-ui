%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
module Fragment = %relay(`
  fragment EventRsvps_rsvp on Rsvp {
    user {
      id
      ...EventRsvpUser_user
    }
    rating {
      ordinal
      mu
      sigma
    }
    message
  }
`)

module ListItem = {
  @react.component
  let make = (~children) => {
    <FramerMotion.Li
      className="mt-4 flex w-full flex-none"
      style={originX: 0.05, originY: 0.05}
      initial={opacity: 0., scale: 1.15}
      animate={opacity: 1., scale: 1.}
      exit={opacity: 0., scale: 1.15}>
      <div className="flex-none">
        <span className="sr-only"> {t`Player`} </span>
        // <UserCircleIcon className="h-6 w-5 text-gray-400" aria-hidden="true" />
      </div>
      <div className="w-full text-sm font-medium leading-6 text-gray-900"> {children} </div>
    </FramerMotion.Li>
  }
}

module StatusMessage = {
  @react.component
  let make = (~message) => {
    let (expanded, setExpanded) = React.useState(() => false)
    let isLong = message->String.length > 25

    let content = if isLong && !expanded {
      message->String.slice(~start=0, ~end=25) ++ "..."
    } else {
      message
    }

    <div
      className={"text-sm text-gray-500 ml-2 mt-4" ++ (isLong ? " cursor-pointer" : "")}
      onClick={_ => isLong ? setExpanded(prev => !prev) : ()}>
      {content->React.string}
    </div>
  }
}
@react.component
let make = (
  ~rsvp,
  ~viewer: option<EventRsvps_user_graphql.Types.fragment>,
  ~activitySlug,
  ~maxRating,
) => {
  let rsvp = Fragment.use(rsvp)

  rsvp.user
  ->Option.map(user => {
    <ListItem key={user.id}>
      <EventRsvpUser
        link={"/league/" ++ activitySlug->Option.getOr("badminton") ++ "/p/" ++ user.id}
        user={user.fragmentRefs}
        // rating=?{rsvp.rating->Option.flatMap(r => r.mu)}
        // sigma=?{rsvp.rating->Option.flatMap(r => r.sigma)}
        secondaryText={switch activitySlug {
        | Some("pickleball") =>
          rsvp.rating
          ->Option.flatMap(r => r.mu)
          ->Option.map(mu =>
            "DUPR " ++ Rating.guessDupr(mu)->Js.Float.toFixedWithPrecision(~digits=2)
          )
          ->Option.getOr("")
        | _ => ""
        }}
        sigmaPercent={rsvp.rating
        ->Option.flatMap(rating =>
          rating.sigma->Option.map(sigma => 3. *. sigma /. maxRating *. 100.)
        )
        ->Option.getOr(0.)}
        ratingPercent={rsvp.rating
        ->Option.flatMap(rating =>
          rating.mu->Option.flatMap(
            mu => rating.sigma->Option.map(sigma => (mu -. sigma *. 3.0) /. maxRating *. 100.),
          )
        )
        ->Option.getOr(0.)}
        highlight={viewer
        ->Option.map(viewer => viewer.id == user.id)
        ->Option.getOr(false)}
      />
      {rsvp.message
      ->Option.map(message => <StatusMessage message={message} />)
      ->Option.getOr(React.null)}
    </ListItem>
  })
  ->Option.getOr(React.null)
}
