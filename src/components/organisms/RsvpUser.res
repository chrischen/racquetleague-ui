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
  ~secondaryText: option<string>=?,
  // ~rating: option<float>=?,
  // ~sigma: option<float>=?,
  ~sigmaPercent: option<float>=?,
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
  <div
    className={Util.cx(["relative flex min-w-0 gap-x-4 w-full", highlight ? "py-2 mx-0" : "mx-2"])}>
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
        {
          let nameElement = switch highlight {
          | true => <strong className="text-lg"> {user.name->React.string} </strong>
          | false => user.name->React.string
          }

          let secondaryTextElement =
            secondaryText
            ->Option.map(text =>
              <span className="ml-2 text-xs italic text-gray-500"> {text->React.string} </span>
            )
            ->Option.getOr(React.null)

          switch link {
          | Some(link) =>
            <Link to={link}>
              <span className="absolute inset-x-0 -top-px bottom-0" />
              {nameElement}
              {secondaryTextElement}
            </Link>
          | None =>
            <>
              <span className="absolute inset-x-0 -top-px bottom-0" />
              {nameElement}
              {secondaryTextElement}
            </>
          }
        }
      </p>
      <p className="mt-1 flex text-xs leading-5 text-gray-500">
        <span className="relative truncate hover:underline" />
      </p>
      {ratingPercent
      ->Option.map(ratingPercent =>
        <div className="overflow-hidden rounded-full bg-gray-200 mt-1 flex">
          // {rating
          // ->Option.map(rating =>
          //   <span className="absolute inset-y-0 right-0 pr-2 text-xs font-semibold text-gray-900">
          //     {rating->Float.toFixed(~digits=2)->React.string}
          //     {" "->React.string}
          //     {sigma
          //     ->Option.map(sigma => sigma->Float.toFixed(~digits=2)->React.string)
          //     ->Option.getOr(""->React.string)}
          //   </span>
          // )
          // ->Option.getOr(React.null)}
          {sigmaPercent
          ->Option.map(sigmaPercent =>
            <div className="flex w-full">
              <FramerMotion.Div
                className="h-2 rounded-l-full bg-red-400 z-10"
                initial={width: "0%"}
                animate={{
                  FramerMotion.width: ratingPercent->Float.toFixed(~digits=3) ++ "%",
                }}
              />
              <FramerMotion.Div
                className="h-2 rounded-r-full bg-red-300 -ml-2 blur-sm z-0"
                initial={width: "0%"}
                animate={{
                  // width: (sigmaPercent /. 100. *. ratingPercent)->Float.toFixed(~digits=3) ++ "%",
                  FramerMotion.width: sigmaPercent->Float.toFixed(~digits=3) ++ "%",
                }}
              />
            </div>
          )
          ->Option.getOr(
            <FramerMotion.Div
              className="h-2 rounded-full bg-red-400"
              initial={width: "0%"}
              animate={{
                FramerMotion.width: ratingPercent->Float.toFixed(~digits=3) ++ "%",
              }}
            />,
          )}
        </div>
      )
      ->Option.getOr(React.null)}
    </div>
  </div>

  // </Transition>
}
