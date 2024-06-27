%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
/* %%raw("import Query, { QueryResponse } from '../shared/Query'") */
/* let clone = react["cloneElement"] */
module Fragment = %relay(`
  fragment EventRsvpUser_user on User
  {
    picture
    lineUsername
  }
`)

@genType @react.component
let make = (
  ~user,
  ~highlight: bool=false,
  ~link: string=?,
  ~rating: option<float>=?,
  ~ratingPercent: option<float>=?,
) => {
  open LangProvider.Router
  // open Lingui.Util;
  let ts = Lingui.UtilString.t
  let user = Fragment.use(user)

  /* switch user.lineUsername {
  | Some(username) =>
    (username ++ " ... " ++ user.rating->Option.map(string_of_int)->Option.getWithDefault(""))
      ->React.string
  | None => React.string("")
  }*/
  // let display =
  //   (user.lineUsername->Option.getOr("[Line username missing]") ++
  //   " ... " ++
  //   user.rating->Option.getOr(0)->string_of_int)->React.string
  let display = user.lineUsername->Option.getOr("[Line username missing]")->React.string

  // <Transition
  //   show={true}
  //   appear={true}
  //   enter="transition duration-500 ease-in-out"
  //   enterFrom="scale-125 opacity-0"
  //   enterTo="scale-100 opacity-100"
  //   leave="transition duration-300"
  //   leaveFrom="scale-100 opacity-100"
  //   leaveTo="scale-125 opacity-0">
  <div className={Util.cx(["relative flex min-w-0 gap-x-4", highlight ? "py-3 mx-0" : "mx-4"])}>
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
            | true => <strong className="text-lg"> {display} </strong>
            | false => display
            }}
          </Link>
        | None =>
          <>
            <span className="absolute inset-x-0 -top-px bottom-0" />
            {switch highlight {
            | true => <strong className="text-lg"> {display} </strong>
            | false => display
            }}
          </>
        }}
      </p>
      <p className="mt-1 flex text-xs leading-5 text-gray-500">
        <span className="relative truncate hover:underline" />
      </p>
      <div className="overflow-hidden rounded-full bg-gray-200 mt-1">
        <div
          className="h-2 rounded-full bg-red-400"
          style={{width: ratingPercent->Option.getOr(0.)->Float.toFixed(~digits=3) ++ "%"}}
        />
      </div>
    </div>
  </div>

  // </Transition>
}

@genType
let default = make
