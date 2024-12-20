%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
/* %%raw("import Query, { QueryResponse } from '../shared/Query'") */
/* let clone = react["cloneElement"] */

// type userData = Registered(EventRsvpUser_user_graphql.Types.fragment) | Guest
// type userData<'a> = Registered(RescriptRelay.fragmentRefs<[> #EventRsvpUser_user] as 'a>) | Guest

// let fromRegisteredUser = (user: RescriptRelay.fragmentRefs<[> #EventRsvpUser_user]>) => {
//   let user = Fragment.use(user)
//   {
//     name: user.lineUsername->Option.getOr("[Line username missing]"),
//     picture: user.picture,
//     data: Registered(user),
//   }
// }
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

@react.component
let make = (
  ~user: Rating.user,
  ~highlight: bool=false,
  ~link: option<string>=?,
  ~rating as _: option<float>=?,
  ~ratingPercent: option<float>=?,
) => {
  open LangProvider.Router
  // open Lingui.Util;
  // let user = Fragment.use(user)

  // let display = user.lineUsername->Option.getOr("[Line username missing]")->React.string

  // <Transition
  //   show={true}
  //   appear={true}
  //   enter="transition duration-500 ease-in-out"
  //   enterFrom="scale-125 opacity-0"
  //   enterTo="scale-100 opacity-100"
  //   leave="transition duration-300"
  //   leaveFrom="scale-100 opacity-100"
  //   leaveTo="scale-125 opacity-0">
  <div className={Util.cx(["relative flex min-w-0 gap-x-4", highlight ? "py-2 mx-0" : "mx-2"])}>
    {user.picture
    ->Option.map(picture =>
      <img
        className={Util.cx([
          highlight ? "h-14 w-14" : "h-12 w-12",
          "flex-none rounded-full bg-gray-50",
          highlight ? "drop-shadow-lg" : "",
        ])}
        src={picture}
        alt=""
      />
    )
    ->Option.getOr(<div className="h-12 w-12 flex-none rounded-full bg-gray-50" />)}
    <div className="min-w-0 flex-auto">
      <p className="text-sm font-semibold leading-6 text-gray-900">
        {switch link {
        | Some(link) =>
          <Link to={link}>
            <span className="absolute inset-x-0 -top-px bottom-0" />
            {switch highlight {
            | true => <strong className="text-lg"> {user.name->React.string} </strong>
            | false => user.name->React.string
            }}
          </Link>
        | None =>
          <>
            <span className="absolute inset-x-0 -top-px bottom-0" />
            {switch highlight {
            | true => <strong className="text-lg"> {user.name->React.string} </strong>
            | false => user.name->React.string
            }}
          </>
        }}
      </p>
      <p className="mt-1 flex text-xs leading-5 text-gray-500">
        <span className="relative truncate hover:underline" />
      </p>
      {ratingPercent
      ->Option.map(ratingPercent =>
        <div className="overflow-hidden rounded-full bg-gray-200 mt-1">
          <FramerMotion.Div
            className="h-2 rounded-full bg-red-400"
            initial={width: "0%"}
            animate={{width: ratingPercent->Float.toFixed(~digits=3) ++ "%"}}
          />
        </div>
      )
      ->Option.getOr(React.null)}
    </div>
  </div>

  // </Transition>
}
