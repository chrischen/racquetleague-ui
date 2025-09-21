@genType @react.component
let make: unit => React.element

@genType
let \"Component": props => React.element

type params = {
  after?: string,
  afterDate?: Util.Datetime.t,
  before?: string,
  filters?: EventsQuery_graphql.Types.eventFilters,
  first?: int,
  lang: option<string>,
}

module LoaderArgs: {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

@genType
let loader: LoaderArgs.t => promise<WaitForMessages.data<EventsQuery_graphql.queryRef>>
