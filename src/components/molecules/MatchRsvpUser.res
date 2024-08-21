%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
/* %%raw("import Query, { QueryResponse } from '../shared/Query'") */
/* let clone = react["cloneElement"] */

// type userData = Registered(EventRsvpUser_user_graphql.Types.fragment) | Guest
// type userData<'a> = Registered(RescriptRelay.fragmentRefs<[> #EventRsvpUser_user] as 'a>) | Guest
// type user = {
//   name: string,
//   picture: option<string>,
//   // data: 'a,
// }

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
type status = Break | Available | Queued | Playing

@react.component
let make = (
  ~user: Rating.user,
  ~compact: option<bool>=false,
  ~highlight: status=Available,
  ~link: option<string>=?,
  ~rating as _: option<float>=?,
  ~ratingPercent as _: option<float>=?,
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
  <div
    className={Util.cx([
      "relative flex min-w-0 gap-x-4",
      "rounded-lg shadow",
      compact ? "p-2" : "p-4",
      switch highlight {
      | Playing => "bg-white opacity-50 blur-sm"
      | Available => "bg-white"
      | Queued => "bg-green-300"
      | Break => "bg-yellow-300"
      },
    ])}>
    {user.picture
    ->Option.map(picture =>
      <img
        className={Util.cx([
          compact ? "h-8 w-8" : "h-16 w-16", "flex-none rounded-full bg-gray-50", "drop-shadow-lg"])}
        src={picture}
        alt=""
      />
    )
    ->Option.getOr(
      <div
        className={Util.cx([
          compact ? "h-8 w-8" : "h-16 w-16",
          "flex-none rounded-full bg-gray-50",
        ])}
      />,
    )}
    <div className="min-w-0 flex-auto">
      <p className="text-2xl font-semibold leading-6 text-gray-900">
        {switch link {
        | Some(link) =>
          <Link to={link}>
            <span className="absolute inset-x-0 -top-px bottom-0" />
            {switch highlight {
            | Queued => <strong className="text-lg"> {user.name->React.string} </strong>
            | _ => user.name->React.string
            }}
          </Link>
        | None =>
          <>
            <span className="absolute inset-x-0 -top-px bottom-0" />
            // {switch highlight {
            // | true => <strong className="text-lg"> {user.name->React.string} </strong>
            {user.name->React.string}
            // }}
          </>
        }}
      </p>
      <p className="mt-1 flex text-xs leading-5 text-gray-500">
        <span className="relative truncate hover:underline" />
      </p>
    </div>
  </div>

  // </Transition>
}
