// module Query = %relay(`
//   query UpdateLocationEventPageQuery($locationId: ID!) {
//     location(id: $locationId) {
//       ...SelectedLocation_location
//     }
//   }
//   `)
// type loaderData = UpdateLocationEventPageQuery_graphql.queryRef
// @module("react-router-dom")
// external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  // let data = useLoaderData()
  // let query = Query.usePreloaded(~queryRef=data.data)
  // <SelectLocation locations={query.fragmentRefs} />
  let navigate = Router.useNavigate()
  <AutocompleteLocation onSelected={location => navigate("../" ++ location, None)} />
}
