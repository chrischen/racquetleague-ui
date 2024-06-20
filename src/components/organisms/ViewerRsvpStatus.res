// %%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

@genType @react.component
let make = (~onJoin, ~onLeave, ~joined: bool) => {
  let viewer = GlobalQuery.useViewer()
  switch viewer.user {
  | Some(_) =>
    joined
      ? <>
          <a
            href="#"
            onClick={e => {
              e->JsxEventU.Mouse.preventDefault
              onLeave()
            }}>
            {"⭠"->React.string}
            {t`leave event`}
          </a>
        </>
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

// let loadMessages = lang => {
//   let messages = switch lang {
//   | "ja" => Lingui.import("../../locales/ja/organisms/ViewerRsvpStatus.mjs")
//   | _ => Lingui.import("../../locales/en/organisms/ViewerRsvpStatus.mjs")
//   }->Promise.thenResolve(messages => {
//     Lingui.i18n.load(lang, messages["messages"])
//   })
//   [messages]
// }

@genType
let default = make
