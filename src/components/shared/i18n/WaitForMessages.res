%%raw("import { t } from '@lingui/macro'")
type data<'a> = {
  data: 'a,
  i18nLoaders?: promise<array<unit>>,
  i18nData?: array<unit>,
}

@module("react-router-dom")
external useLoaderData: unit => Js.Nullable.t<data<'a>> = "useLoaderData"

@react.component
let make = (~children: unit => React.element) => {
  //let { fragmentRefs } = Fragment.use(events)
  // Null on routes without a loader, which the create-event modal can sit over.
  let query = useLoaderData()->Js.Nullable.toOption

  // @NOTE: If we immediately suspend, client triggers the Suspense fallback
  // immediately from client loader
  // <React.Suspense fallback={"loading lang..."->React.string}>

  {
    switch query->Option.flatMap(q => q.i18nLoaders) {
    | Some(loaders) =>
      <Router.Await resolve={loaders} errorElement={<Layout.Container>{React.string("Error loading translations")}</Layout.Container>}>
        {_ => {
          children()
        }}
      </Router.Await>
    | None => children()
    }
  }

  // </React.Suspense>
}
