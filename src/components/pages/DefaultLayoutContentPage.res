%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Layout = {
  @react.component
  let make = (~children) => {
    <DefaultLayoutMap.Content> {children} </DefaultLayoutMap.Content>
  }
}

@genType @react.component
let make = () => {
  <Layout>
    <Router.Outlet />
  </Layout>
}
