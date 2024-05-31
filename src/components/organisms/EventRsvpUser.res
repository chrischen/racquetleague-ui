%%raw("import { css, cx } from '@linaria/core'")
/* %%raw("import Query, { QueryResponse } from '../shared/Query'") */
/* let clone = react["cloneElement"] */
module Fragment = %relay(`
  fragment EventRsvpUser_user on User {
    lineUsername
  }
`)

@genType @react.component
let make = (~user, ~highlight: bool=false) => {
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
  let display =
    user.lineUsername->Option.getOr("[Line username missing]")->React.string
  // <Transition
  //   show={true}
  //   appear={true}
  //   enter="transition duration-500 ease-in-out"
  //   enterFrom="scale-125 opacity-0"
  //   enterTo="scale-100 opacity-100"
  //   leave="transition duration-300"
  //   leaveFrom="scale-100 opacity-100"
  //   leaveTo="scale-125 opacity-0">
    {switch highlight {
    | true => <strong> {display} </strong>
    | false => display
    }}
  // </Transition>
}

@genType
let default = make
