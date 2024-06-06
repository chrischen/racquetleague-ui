module DeferTestRouteQuery = %relay(`
  query DeferTestRouteQuery {
    ...DeferTestRouteFragment @defer
    ...DeferTestRouteFragment2 @defer
  }
`)

module DeferTestRouteFragment = %relay(`
  fragment DeferTestRouteFragment on Query {
    currentTime
  }
`)
module DeferTestRouteFragment2 = %relay(`
  fragment DeferTestRouteFragment2 on Query {
    currentTime2
  }
`)

module CurrentTime = {
  @react.component
  let make = (~fragmentRefs) => {
    let query = DeferTestRouteFragment.use(fragmentRefs)
    <>
      {React.string("Current time: ")}
      {React.string(query.currentTime->Option.map(Float.toString(_))->Option.getOr("0"))}
    </>
  }
}

module CurrentTime2 = {
  @react.component
  let make = (~fragmentRefs) => {
    let query = DeferTestRouteFragment2.use(fragmentRefs)
    <>
      {React.string("Current time2: ")}
      {React.string(query.currentTime2->Option.map(Float.toString(_))->Option.getOr("0"))}
    </>
  }
}
type loaderData = DeferTestRouteQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

module DeferTest = {
  @react.component
  let make = () => {
    let query = useLoaderData()
    let {fragmentRefs} = DeferTestRouteQuery.usePreloaded(~queryRef=query.data)
    <div>
      <React.Suspense fallback={"..."->React.string}>
        <CurrentTime fragmentRefs={fragmentRefs} />
      </React.Suspense>
      <React.Suspense fallback={"..."->React.string}>
        <CurrentTime2 fragmentRefs={fragmentRefs} />
      </React.Suspense>
    </div>
  }
}
@genType
let \"Component" = DeferTest.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

@genType
let loader = async ({context}: LoaderArgs.t) => {
  Router.defer({
    WaitForMessages.data: DeferTestRouteQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables=(),
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
  })
}
