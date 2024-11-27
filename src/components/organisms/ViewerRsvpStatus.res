// %%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

@genType @react.component
let make = (~onJoin, ~onLeave, ~joined: bool) => {
  let viewer = GlobalQuery.useViewer()
  switch viewer.user {
  | Some(_) =>
    joined
      ? <div className="flex flex-col">
          
          <a
            href="#"
            onClick={e => {
              e->JsxEventU.Mouse.preventDefault
              onLeave()
            }}>
            {"⭠"->React.string}
            {t`leave event`}
          </a>
        </div>
      : <a
          href="#"
          onClick={e => {
            e->JsxEventU.Mouse.preventDefault
            onJoin()
          }}>
          {"⭢"->React.string}
          {t`join event`}
        </a>
  | None =>
    <>
      <em> {t`login to join the event`} </em>
      {" "->React.string}
      <LoginLink />
    </>
  }
}

@genType
let default = make
