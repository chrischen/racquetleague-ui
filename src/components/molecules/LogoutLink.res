%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

@react.component
let make = () => {
  <a href="/signout"> {t`(logout)`} </a>
}
