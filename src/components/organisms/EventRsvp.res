%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
module Fragment = %relay(`
  fragment EventRsvp_rsvp on Rsvp {
    user {
      id
      ...EventRsvpUser_user
    }
    ...RsvpOptions_rsvp
    rating {
      ordinal
      mu
      sigma
    }
    message
    paid
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
let make = (
  ~rsvp,
  ~viewer: option<RSVPSection_user_graphql.Types.fragment>,
  ~activitySlug,
  ~maxRating,
  ~eventId,
  ~isAdmin=false,
  ~eventPrice: option<int>=?,
  ~waitlistPosition: option<int>=?,
  ~connectionKey: string="RSVPSection_event_rsvps",
) => {
  let rsvp = Fragment.use(rsvp)

  rsvp.user
  ->Option.map(user => {
    <ListItem key={user.id}>
      <div className="flex items-center">
        <RsvpOptions
          rsvp={rsvp.fragmentRefs}
          eventId
          eventActivitySlug={activitySlug->Option.getOr("badminton")}
          isAdmin
          connectionKey>
          <EventRsvpUser
            user={user.fragmentRefs}
            isAdmin
            link={"/league/" ++ activitySlug->Option.getOr("badminton") ++ "/p/" ++ user.id}
            secondaryText={switch (activitySlug, waitlistPosition) {
            | (_, Some(pos)) => "#" ++ Int.toString(pos)
            | (Some("pickleball"), None) =>
              rsvp.rating
              ->Option.flatMap(r => r.mu)
              ->Option.map(mu => Rating.guessDupr(mu)->Js.Float.toFixedWithPrecision(~digits=2))
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
        </RsvpOptions>
        {rsvp.message
        ->Option.map(message =>
          <ResponsiveTooltip.Provider>
            <ResponsiveTooltip content=message side=#bottom>
              <div className="ml-2 cursor-help">
                <Lucide.MessageCircle className="h-4 w-4 text-gray-500" />
              </div>
            </ResponsiveTooltip>
          </ResponsiveTooltip.Provider>
        )
        ->Option.getOr(React.null)}
        {switch eventPrice {
        | Some(_) =>
          switch rsvp.paid {
          | Some(1) =>
            <span
              className="ml-2 inline-flex items-center rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700">
              {t`Paid`}
            </span>
          | _ =>
            <span
              className="ml-2 inline-flex items-center rounded-full bg-yellow-100 px-2 py-0.5 text-xs font-medium text-yellow-800">
              {t`Not paid`}
            </span>
          }
        | None => React.null
        }}
      </div>
    </ListItem>
  })
  ->Option.getOr(React.null)
}
