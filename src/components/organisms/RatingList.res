%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")

open Util
open LangProvider.Router
module Fragment = %relay(`
  fragment RatingListFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    activitySlug: { type: "String!" }
    namespace: { type: "String!" }
  )
  @refetchable(queryName: "RatingListRefetchQuery")
  {
    ratings(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace)
    @connection(key: "RatingListFragment_ratings") {
      edges {
        node {
          id
          ...RatingList_rating
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
        startCursor
      }
    }
  }
`)

module ItemFragment = %relay(`
  fragment RatingList_rating on Rating {
    id
    mu
    user {
      id
      lineUsername
      picture
    }
  }
`)

module NodeId: {
  type t
  let toId: t => string
  let make: (string, string) => t
} = {
  type t = (string, string)
  let make = (key, id) => {
    (key, id)
  }
  let toId = ((_, id): t) => {
    id
  }
}
module NodeIdDto: {
  type t = string
  let toDomain: t => result<NodeId.t, [> #InvalidNode]>
} = {
  type t = string
  let toDomain = (t: t) => {
    switch t->String.split(":") {
    | [key, id] => Ok(NodeId.make(key, id))
    | _ => Error(#InvalidNode)
    }
  }
}

module RatingItem = {
  open Lingui.Util
  let td = Lingui.UtilString.dynamic
  let ts = Lingui.UtilString.t
  @react.component
  let make = (~rating, ~highlightedLocation: bool=false) => {
    let {id, mu, user} = ItemFragment.use(rating)
    <li className="">
      <div className="min-w-0 flex-auto">
        <div className="flex items-center gap-x-3">
          <div
            className={Util.cx(["text-green-400 bg-green-400/10", "flex-none rounded-full p-1"])}>
            <div className="h-2 w-2 rounded-full bg-current" />
          </div>
          <h2 className="min-w-0 text-sm font-semibold leading-6 text-white">
            <Link to={"/players/" ++ id} relative="path" className="flex gap-x-2">
              {user
              ->Option.flatMap(user =>
                user.picture->Option.map(picture => <img width="50" height="50" src={picture} />)
              )
              ->Option.getOr(React.null)}
              {user->Option.flatMap(user =>
                user.lineUsername->Option.map(lineUsername =>
                  <span className="truncate"> {lineUsername->React.string} </span>
                )
              )->Option.getOr(React.null)}
            </Link>
          </h2>
        </div>
        <div className="mt-3 flex items-center gap-x-2.5 text-xs leading-5 text-gray-600">
          <p className="whitespace-nowrap">
            {mu
            ->Option.map(mu => mu->Float.toString->React.string)
            ->Option.getOr("mu missing"->React.string)}
          </p>
        </div>
      </div>
    </li>
    // )->Result.getOr(React.null)
  }
}

@genType @react.component
let make = (~ratings) => {
  open Lingui.Util
  let (_isPending, _) = ReactExperimental.useTransition()
  let {ratings: ratingsQuery} = Fragment.use(ratings)
  let {data, isLoadingNext, hasNext, isLoadingPrevious} = Fragment.usePagination(ratings)
  let ratings = data.ratings->Fragment.getConnectionNodes
  let pageInfo = data.ratings.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage
  let (highlightedLocation, setHighlightedLocation) = React.useState(() => "")
  let navigate = Router.useNavigate()

  // let onLoadMore = _ =>
  //   startTransition(() => {
  //     loadNext(~count=1)->ignore
  //   })
  //
  let intl = ReactIntl.useIntl()
  let viewer = GlobalQuery.useViewer()

  <>
    {!isLoadingPrevious
      ? pageInfo.startCursor
        ->Option.map(startCursor =>
          <Layout.Container>
            <Link to={"./" ++ "?before=" ++ startCursor}> {t`...load past ratings`} </Link>
          </Layout.Container>
        )
        ->Option.getOr(React.null)
      : React.null}
    <Layout.Container>
      <ul role="list" className="divide-y divide-gray-200">
        {ratings
        ->Array.map(edge => <RatingItem key={edge.id} rating=edge.fragmentRefs />)
        ->React.array}
      </ul>
      {hasNext && !isLoadingNext
        ? <Layout.Container>
            {pageInfo.endCursor
            ->Option.map(endCursor =>
              <Link to={"./" ++ "?after=" ++ endCursor}> {t`load more`} </Link>
            )
            ->Option.getOr(React.null)}
          </Layout.Container>
        : React.null}
    </Layout.Container>
  </>
}

@genType
let default = make
