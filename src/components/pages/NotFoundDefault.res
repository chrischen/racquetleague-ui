// This is the default 404 page when a lang prefix is not specified
@genType @react.component
let make = () => {
  <Layout.Container> {"page not found"->React.string} </Layout.Container>
}
