%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
%%raw("import '../../global/static.css'")

module Query = %relay(`
  query DefaultLayoutQuery {
    ...Nav_query
    viewer { 
      ... GlobalQueryProvider_viewer
      ...NavViewer_viewer
    }
  }
`)

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<DefaultLayoutQuery_graphql.queryRef> =
  "useLoaderData"

// module MenuInstance = {
//   @module("../ui/navigation-menu") @react.component
//   external make: unit => React.element = "MenuInstance"
// }

module Layout = {
  @react.component
  let make = (~children, ~query, ~viewer: option<Query.Types.response_viewer>) => {
    // let query = useLoaderData()
    // <UserProvider query={fragmentRefs}>
    let viewer = viewer->Option.map(v => v.fragmentRefs)
    <GlobalQuery.Provider value={viewer}>
      <Grid cols=1>
        <React.Suspense fallback={"..."->React.string}>
          <Nav query={query} />
        </React.Suspense>
        {children}
        <Footer />
      </Grid>
    </GlobalQuery.Provider>
    // </UserProvider>
  }
}

// module RouteParams = {
//   type t = {lang: option<string>}
//
//   let parse = (json: Js.Json.t): result<t, string> => {
//     open JsonCombinators.Json.Decode
//
//     let decoder = object(field => {
//       lang: field.optional("lang", string),
//     })
//     try {
//       json->JsonCombinators.Json.decode(decoder)
//     } catch {
//     | _ => Error("An unexpected error occurred when checking the id.")
//     }
//   }
// }

@genType @react.component
let make = () => {
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()

  // open Router
  // let paramsJs = useParams()

  // let lang = paramsJs->RouteParams.parse->Belt.Result.mapWithDefault(None, ({lang}) => lang)
  let {viewer, fragmentRefs} = Query.usePreloaded(~queryRef=query.data)

  // <Router.Await2 resolve=query.i18nLoaders errorElement={"Error"->React.string}>
  <Layout viewer={viewer} query={fragmentRefs}>
    <Router.Outlet />
  </Layout>
  // </Router.Await2>
}
