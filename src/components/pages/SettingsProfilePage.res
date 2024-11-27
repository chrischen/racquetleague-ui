%%raw("import { t } from '@lingui/macro'")
module Query = %relay(`
  query SettingsProfilePageQuery {
    ...SettingsProfileForm_query
  }
  `)
type loaderData = SettingsProfilePageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  <Layout.Container>
    <SettingsProfileForm query=query.fragmentRefs />
  </Layout.Container>
}
