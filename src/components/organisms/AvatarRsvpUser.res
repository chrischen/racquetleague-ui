%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")

@react.component
let make = (
  ~user: Rating.user,
  ~highlight: bool=false,
  ~link: option<string>=?,
  ~secondaryText: option<string>=?,
  ~sigmaPercent: option<float>=?,
  ~ratingPercent: option<float>=?,
) => {
  // Map rating percent (0-100 float) to AvatarWithProgress progress (0-100 int)
  let progressOpt: option<int> = ratingPercent->Option.map(p => {
    let pClamped = Js.Math.max_float(0.0, Js.Math.min_float(100.0, p))
    int_of_float(pClamped)
  })

  // Map sigma percent (0-100 float) to AvatarWithProgress sigmaProgress (0-100 int)
  let sigmaProgressOpt: option<int> = sigmaPercent->Option.map(p => {
    let pClamped = Js.Math.max_float(0.0, Js.Math.min_float(100.0, p))
    int_of_float(pClamped)
  })

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

  <div className={Util.cx(["flex items-center"])}>
    {user.picture
    ->Option.map(picture =>
      <AvatarWithProgress
        src={picture} alt={user.name} progress=?progressOpt sigmaProgress=?sigmaProgressOpt
      />
    )
    ->Option.getOr(<div className="h-12 w-12 flex-none rounded-full bg-gray-50" />)}
    <span className="text-sm ml-2">
      {nameElement}
      {secondaryTextElement}
    </span>
  </div>
}
