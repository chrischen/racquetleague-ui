%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")

open Lingui.Util
open LangProvider.Router
module Fragment = %relay(`
  fragment MatchListFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    activitySlug: { type: "String!" }
    namespace: { type: "String!" }
    userId: { type: "ID" }
  )
  @refetchable(queryName: "MatchListRefetchQuery")
  {
    __id
    matches(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace, userId: $userId)
    @connection(key: "MatchListFragment_matches") {
      __id
      edges {
        node {
          id
          ...MatchList_match
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
  fragment MatchList_match on Match {
    id
    winners {
      id
      ...MatchListTeam_user
    }
    losers {
      ...MatchListTeam_user
    }
    score
    createdAt
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

module MatchListTeamFragment = %relay(`
  fragment MatchListTeam_user on User {
    id
    lineUsername
    picture
    gender
  }
`)
module InlineTeam = {
  type player = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }

  @react.component
  let make = (~players: array<RescriptRelay.fragmentRefs<[> #MatchListTeam_user]>>) => {
    players
    ->Array.mapWithIndex(// {winner.picture
    // ->Option.map(picture =>
    //   <img
    //     className="w-10 h-10 rounded-full inline"
    //     src={picture}
    //     alt={winner.lineUsername->Option.getOr("")}
    //   />
    // )
    // ->Option.getOr(React.null)}
    (player, i) => {
      let player = MatchListTeamFragment.use(player)
      <React.Fragment key={player.id}>
        <Link to={"../p/" ++ player.id} key={player.id} className="font-medium text-gray-900">
          {player.lineUsername->Option.getOr("")->React.string}
        </Link>
        {i != players->Array.length - 1 ? " • "->React.string : React.null}
      </React.Fragment>
    })
    ->React.array
  }
}

module MatchListUserFragment = %relay(`
  fragment MatchListUser_user on User {
    id
  }
`)

module Match = {
  let td = Lingui.UtilString.dynamic
  let ts = Lingui.UtilString.t
  @react.component
  let make = (
    ~user: option<RescriptRelay.fragmentRefs<[> #MatchListUser_user]>>=?,
    ~match,
    ~idx: int,
    ~length: int,
  ) => {
    let {id, winners, losers, score, createdAt} = ItemFragment.use(match)

    let isWinner =
      user
      ->Option.flatMap(user => {
        let user = MatchListUserFragment.use(user)
        winners->Option.flatMap(Array.findMap(_, x => x.id == user.id ? Some(user.id) : None))
      })
      ->Option.isSome

    <li key={id}>
      <div className="relative pb-8">
        {idx !== length - 1
          ? <span
              className="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" ariaHidden=true
            />
          : React.null}
        <div className="relative flex space-x-3">
          <div>
            <span
              className={Util.cx([
                isWinner ? "bg-green-500" : "bg-red-500",
                "h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white",
              ])}>
              {isWinner
                ? <HeroIcons.CheckIcon className="h-5 w-5 text-white" \"aria-hidden"="true" />
                : <HeroIcons.XMarkIcon className="h-5 w-5 text-white" \"aria-hidden"="true" />}
            </span>
          </div>
          <div className="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
            <div>
              <p className="text-sm text-gray-500">
                {isWinner
                  ? {
                      winners
                      ->Option.map(winners =>
                        <InlineTeam players={winners->Array.map(x => x.fragmentRefs)} />
                      )
                      ->Option.getOr(React.null)
                    }
                  : {
                      losers
                      ->Option.map(winners =>
                        <InlineTeam players={winners->Array.map(x => x.fragmentRefs)} />
                      )
                      ->Option.getOr(React.null)
                    }}
                <span className="font-extrabold"> {" VS "->React.string} </span>
                {isWinner
                  ? {
                      losers
                      ->Option.map(winners =>
                        <InlineTeam players={winners->Array.map(x => x.fragmentRefs)} />
                      )
                      ->Option.getOr(React.null)
                    }
                  : {
                      winners
                      ->Option.map(winners =>
                        <InlineTeam players={winners->Array.map(x => x.fragmentRefs)} />
                      )
                      ->Option.getOr(React.null)
                    }}
              </p>
              {<>
                <div className="flex-auto rounded-md p-3 ring-1 ring-inset ring-gray-200 mt-5">
                  <div className="flex gap-x-4 text-center">
                    <div className="py-0.5 inline text-lg leading-5 text-gray-500">
                      {t`Score:`}
                      {" "->React.string}
                      {score
                      ->Option.map(score =>
                        switch score {
                        | [winScore, loseScore] =>
                          switch isWinner {
                          | true =>
                            (winScore->Float.toFixed(~digits=0) ++
                            " - " ++
                            loseScore->Float.toFixed(~digits=0))->React.string
                          | false =>
                            (loseScore->Float.toFixed(~digits=0) ++
                            " - " ++
                            winScore->Float.toFixed(~digits=0))->React.string
                          }
                        | _ => React.null
                        }
                      )
                      ->Option.getOr(React.null)}
                      // <span className="font-medium text-gray-900"> {"Chris"->React.string} </span>
                      // {"commented"->React.string}
                    </div>
                  </div>
                  <p className="text-sm leading-6 text-gray-500" />
                </div>
              </>}
            </div>
            <div className="whitespace-nowrap text-right text-sm text-gray-500">
              <time
                dateTime={createdAt
                ->Option.map(date => date->Util.Datetime.toDate->Js.Date.toDateString)
                ->Option.getOr("")}>
                {createdAt
                ->Option.map(date => <>
                  <ReactIntl.FormattedDate value={date->Util.Datetime.toDate} />
                  {" "->React.string}
                  <ReactIntl.FormattedTime value={date->Util.Datetime.toDate} />
                </>)
                ->Option.getOr(""->React.string)}
              </time>
            </div>
          </div>
        </div>
      </div>
    </li>

    // <div className="overflow-hidden rounded-full bg-gray-200 mt-5">
    //   <div className="h-2 rounded-full bg-red-400" style={{width: tier ++ "%"}} />
    // </div>
  }
}

@genType @react.component
let make = (~matches, ~user=?) => {
  let (_isPending, _) = ReactExperimental.useTransition()
  // let {id: userId} = MatchListUserFragment.use(user)
  let {data, isLoadingNext, hasNext, isLoadingPrevious} = Fragment.usePagination(matches)
  let matches = data.matches->Fragment.getConnectionNodes
  let pageInfo = data.matches.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage

  // let onLoadMore = _ =>
  //   startTransition(() => {
  //     loadNext(~count=1)->ignore
  //   })
  //

  <Layout.Container className="mt-4 max-w-screen-md">
    <h2 className="text-2xl font-semibold text-gray-900"> {t`Match History`} </h2>
    {!isLoadingPrevious && hasPrevious
      ? pageInfo.startCursor
        ->Option.map(startCursor =>
          <Link to={"./" ++ "?before=" ++ startCursor} className="mt-5">
            {t`...load previous matches`}
          </Link>
        )
        ->Option.getOr(React.null)
      : React.null}
    <div className="flow-root mt-5">
      <ul role="list" className="">
        {matches
        ->Array.mapWithIndex((edge, idx) =>
          <Match key={edge.id} match=edge.fragmentRefs idx length={matches->Array.length} ?user />
        )
        ->React.array}
      </ul>
    </div>
    <div className="">
      {hasNext && !isLoadingNext
        ? {
            pageInfo.endCursor
            ->Option.map(endCursor =>
              <Link to={"./" ++ "?after=" ++ endCursor}> {t`Load more matches...`} </Link>
            )
            ->Option.getOr(React.null)
          }
        : React.null}
    </div>
  </Layout.Container>
}

@genType
let default = make
