open LangProvider.Router
%%raw("import { t } from '@lingui/macro'")

@react.component
let make = () => {
  open Lingui.Util

  <WaitForMessages> {_ => <Router.Outlet />} </WaitForMessages>
}
