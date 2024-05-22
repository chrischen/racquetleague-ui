%%raw("import { t } from '@lingui/macro'")
open Lingui.Util;
@genType @react.component
let make = () => {
  let viewer = GlobalQuery.useViewer()

  {
    viewer.user
    ->Option.map(user =>
      <a href={"webcal://www.racquetleague.com/cal-feed/" ++ user.id}> {t`sync calendar`} </a>
    )
    ->Option.getOr(React.null)
  }
}
