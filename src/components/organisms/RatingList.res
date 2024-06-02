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
    ordinal
    user {
      id
      lineUsername
      picture
      gender
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
  open HeroIcons
  let td = Lingui.UtilString.dynamic
  let ts = Lingui.UtilString.t
  @react.component
  let make = (~rating, ~maxRating, ~highlightedLocation: bool=false) => {
    let {id, ordinal, user} = ItemFragment.use(rating)
    let tier = ordinal->Option.map(ordinal => Math.max(0., (ordinal /. maxRating) *. 100.0))->Option.map(Float.toFixed(_, ~digits=2))->Option.getOr("0.0")
    user
    ->Option.map(user =>
      <li
        key={id}
        className="relative px-4 py-5 hover:bg-gray-50 sm:px-6 lg:px-8">
        <div className="flex justify-between gap-x-6 ">
          <div className="flex min-w-0 gap-x-4">
            {user.picture
            ->Option.map(picture =>
              <img className="h-24 w-24 flex-none rounded-full bg-gray-50" src={picture} alt="" />
            )
            ->Option.getOr(React.null)}
            <div className="min-w-0 flex-auto">
              <p className="text-lg mt-9 font-semibold leading-6 text-gray-900">
                <Link to={"/p/" ++ user.id}>
                  <span className="absolute inset-x-0 -top-px bottom-0" />
                  {user.lineUsername
                  ->Option.map(lineUsername => lineUsername->React.string)
                  ->Option.getOr(React.null)}
                </Link>
              </p>
              <p className="mt-1 flex text-xs leading-5 text-gray-500">
                <a href="#" className="relative truncate hover:underline" />
              </p>
            </div>
          </div>
          <div className="flex shrink-0 items-center gap-x-4">
            <div className="sm:flex sm:flex-col sm:items-end">
              <p className="text-sm leading-6 text-gray-900">
                {user.gender
                ->Option.map(gender =>
                  switch gender {
                  | Male => t`Male`
                  | Female => t`Female`
                  | _ => "--"->React.string
                  }
                )
                ->Option.getOr(React.null)}
              </p>
              <p className="mt-1 text-xs leading-5 text-gray-500">
                {ordinal
                ->Option.map(ordinal => ordinal->Float.toFixed(~digits=2)->React.string)
                ->Option.getOr("ordinal missing"->React.string)}
              </p>
            </div>
            <ChevronRightIcon className="h-5 w-5 flex-none text-gray-400" \"aria-hidden"="true" />
          </div>
        </div>
        <div className="overflow-hidden rounded-full bg-gray-200 mt-5">
          <div className="h-2 rounded-full bg-red-400" style={{width: tier ++ "%"}} />
        </div>
      </li>
    )
    ->Option.getOr(React.null)
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

  <Layout.Container className="mt-4">
    {!isLoadingPrevious && hasPrevious
      ? pageInfo.startCursor
        ->Option.map(startCursor =>
          <Link to={"./" ++ "?before=" ++ startCursor}> {t`...load higher rated players`} </Link>
        )
        ->Option.getOr(React.null)
      : React.null}
    <ul role="list" className="divide-y divide-gray-200">
      {ratings
      ->Array.map(edge => <RatingItem key={edge.id} maxRating=11.71 rating=edge.fragmentRefs />)
      ->React.array}
    </ul>
    {hasNext && !isLoadingNext
      ? {
          pageInfo.endCursor
          ->Option.map(endCursor =>
            <Link to={"./" ++ "?after=" ++ endCursor}> {t`Load more players...`} </Link>
          )
          ->Option.getOr(React.null)
        }
      : React.null}
  </Layout.Container>
}

@genType
let default = make
