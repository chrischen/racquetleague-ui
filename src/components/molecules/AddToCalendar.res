%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
@genType @react.component
let make = () => {
  let viewer = GlobalQuery.useViewer()

  <WaitForMessages>
    {() =>
      viewer.user
      ->Option.map(user =>
        <div className="flex items-center lg:text-sm">
          <Lucide.CalendarPlus
            className="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-500" \"aria-hidden"="true"
          />
          <a href={"webcal://www.pkuru.com/cal-feed/" ++ user.id}> {t`sync calendar`} </a>
        </div>
      )
      ->Option.getOr(React.null)}
  </WaitForMessages>
}
