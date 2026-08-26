%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
// This is the default 404 page when a lang prefix is not specified
@genType @react.component
let make = () => {
  <Layout.Container> {t`page not found`} </Layout.Container>
}
