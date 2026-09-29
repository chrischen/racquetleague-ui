%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")

open Lingui.Util
open LangProvider.Router

module Fragment = %relay(`
  fragment MatchHistoryListFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    activitySlug: { type: "String!" }
    userId: { type: "ID" }
  )
  @refetchable(queryName: "MatchHistoryListRefetchQuery")
  {
    __id
    matches(after: $after, first: $first, before: $before, activitySlug: $activitySlug, userId: $userId)
    @connection(key: "MatchHistoryListFragment_matches") {
      __id
      edges {
        node {
          id
          ...MatchHistoryList_match
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
  fragment MatchHistoryList_match on Match {
    id
    winners {
      id
      ...MatchHistoryListTeam_user
    }
    losers {
      id
      ...MatchHistoryListTeam_user
    }
    namespace
    score
    createdAt
    playerMetadata
  }
`)

module TeamFragment = %relay(`
  fragment MatchHistoryListTeam_user on User {
    id
    lineUsername
    picture
    gender
  }
`)

module PlayerRating = {
  type t = {
    mu: float,
    sigma: float,
    muDiff: option<float>,
    sigmaDiff: option<float>,
  }

  let decode = (json: Js.Json.t): option<t> => {
    try {
      let dict = json->Js.Json.decodeObject
      dict->Option.flatMap(d => {
        let mu = d->Js.Dict.get("mu")->Option.flatMap(v => Js.Json.decodeNumber(v))
        let sigma = d->Js.Dict.get("sigma")->Option.flatMap(v => Js.Json.decodeNumber(v))
        let muDiff = d->Js.Dict.get("muDiff")->Option.flatMap(v => Js.Json.decodeNumber(v))
        let sigmaDiff = d->Js.Dict.get("sigmaDiff")->Option.flatMap(v => Js.Json.decodeNumber(v))

        switch (mu, sigma) {
        | (Some(mu), Some(sigma)) => Some({mu, sigma, muDiff, sigmaDiff})
        | _ => None
        }
      })
    } catch {
    | _ => None
    }
  }
}

module PlayerMetadata = {
  type t = Js.Dict.t<PlayerRating.t>

  let decode = (jsonString: option<string>): option<t> => {
    jsonString->Option.flatMap(str => {
      try {
        let json = Js.Json.parseExn(str)
        json
        ->Js.Json.decodeObject
        ->Option.flatMap(dict => {
          let metadata = Js.Dict.empty()
          dict
          ->Js.Dict.entries
          ->Array.forEach(
            ((playerId, ratingJson)) => {
              PlayerRating.decode(ratingJson)->Option.forEach(
                rating => {
                  metadata->Js.Dict.set(playerId, rating)
                },
              )
            },
          )
          Some(metadata)
        })
      } catch {
      | _ => None
      }
    })
  }

  let get = (metadata: option<t>, playerId: string): option<PlayerRating.t> => {
    metadata->Option.flatMap(m => m->Js.Dict.get(playerId))
  }

  // Calculate min/max mu values for normalization
  let getMinMaxMu = (metadata: option<t>, playerIds: array<string>): (float, float) => {
    let muValues =
      playerIds
      ->Array.filterMap(id => metadata->Option.flatMap(m => m->Js.Dict.get(id)))
      ->Array.map(rating => rating.mu)

    let minMu = muValues->Array.reduce(99999.0, (min, mu) => mu < min ? mu : min)
    let maxMu = muValues->Array.reduce(0.0, (max, mu) => mu > max ? mu : max)

    (minMu, maxMu)
  }

  // Normalize player skill to 0-100 range based on match participants
  let normalizeSkill = (mu: float, minMu: float, maxMu: float): float => {
    if maxMu == minMu {
      50.0 // All players equal, show 50%
    } else {
      (mu -. minMu) /. (maxMu -. minMu) *. 100.0
    }
  }
}

module MatchHistoryListUserFragment = %relay(`
  fragment MatchHistoryListUser_user on User {
    id
  }
`)

// A draw recorded without a score is stored as (-1, -1).
let isUnscored = (leftScore, rightScore) => leftScore < 0.0 && rightScore < 0.0

// Whether the recorded winners sit on the left. From a player's page their
// team does (viewerInWinners says which team that is). With no player, as on
// an event's results, the team that won on the score does, so every card
// reads "left beat right". The winners/losers split is vestigial — the score
// decides the result — so this only picks the team shown on the left.
let winnersOnLeft = (~viewerInWinners: option<bool>, ~winnersScore: float, ~losersScore: float) =>
  switch viewerInWinners {
  | Some(inWinners) => inWinners
  | None => winnersScore >= losersScore
  }

type leftReading = {
  winnersLeft: bool,
  isWin: bool,
  isLoss: bool,
  // The scoreline to show, left team first; None when there is none.
  shownScore: option<(float, float)>,
}

// How a match reads from the left team's side. The higher score wins. Equal
// scores are a draw, covering both a real scoreline like 10-10 and the
// (-1,-1) unscored-draw sentinel, which shows no score. A match with no
// score at all shows none either, and its recorded winners won.
let readFromLeft = (~viewerInWinners: option<bool>, ~score: option<array<float>>) =>
  switch score {
  | Some([winnersScore, losersScore]) =>
    let winnersLeft = winnersOnLeft(~viewerInWinners, ~winnersScore, ~losersScore)
    let (leftScore, rightScore) = if winnersLeft {
      (winnersScore, losersScore)
    } else {
      (losersScore, winnersScore)
    }
    {
      winnersLeft,
      isWin: leftScore > rightScore,
      isLoss: leftScore < rightScore,
      shownScore: isUnscored(leftScore, rightScore) ? None : Some((leftScore, rightScore)),
    }
  | _ =>
    let winnersLeft = viewerInWinners->Option.getOr(true)
    {winnersLeft, isWin: winnersLeft, isLoss: !winnersLeft, shownScore: None}
  }

// A pre-match favourite whose win probability is under this is no favourite:
// the bar shows "Even" instead of a percentage, and a loss is no upset.
let evenBelow = 0.55

let favoredSide = (leftTeamProbability: float): [#left | #right | #even] =>
  if Math.max(leftTeamProbability, 1.0 -. leftTeamProbability) < evenBelow {
    #even
  } else if leftTeamProbability > 0.5 {
    #left
  } else {
    #right
  }

module PlayerBadge = {
  @react.component
  let make = (
    ~player: RescriptRelay.fragmentRefs<[> #MatchHistoryListTeam_user]>,
    ~ratingChange: option<float>=?,
    ~align: [#left | #right]=#left,
    ~isYou: bool=false,
    ~normalizedSkill: float,
  ) => {
    let player = TeamFragment.use(player)
    let firstName =
      player.lineUsername->Option.getOr("")->String.split(" ")->Array.get(0)->Option.getOr("")

    let ratingChangeElement = ratingChange->Option.flatMap(change =>
      if change == 0.0 {
        None
      } else {
        Some(
          <div
            className={change > 0.0
              ? "flex items-center gap-0.5 text-emerald-600 dark:text-emerald-400"
              : "flex items-center gap-0.5 text-rose-600 dark:text-rose-400"}>
            {change > 0.0
              ? <Lucide.TrendingUp className="w-3 h-3" />
              : <Lucide.TrendingDown className="w-3 h-3" />}
            <span className="text-xs font-semibold">
              {((change > 0.0 ? "+" : "") ++ change->Float.toFixed(~digits=2))->React.string}
            </span>
          </div>,
        )
      }
    )

    switch align {
    | #right =>
      <div className="flex items-center justify-between gap-2">
        {ratingChangeElement->Option.getOr(React.null)}
        <LangProvider.Router.Link
          to={"../p/" ++ player.id}
          className="flex items-center gap-2 hover:opacity-80 transition-opacity">
          <span
            className={isYou
              ? "text-sm font-semibold text-gray-900 dark:text-gray-100"
              : "text-sm text-gray-700 dark:text-gray-300"}>
            {firstName->React.string}
          </span>
          <AvatarWithProgressBar
            pictureUrl=?player.picture
            name={player.lineUsername->Option.getOr("")}
            skillLevel=normalizedSkill
            size=#small
          />
        </LangProvider.Router.Link>
      </div>
    | #left =>
      <div className="flex items-center justify-between gap-2">
        <LangProvider.Router.Link
          to={"../p/" ++ player.id}
          className="flex items-center gap-2 hover:opacity-80 transition-opacity">
          <AvatarWithProgressBar
            pictureUrl=?player.picture
            name={player.lineUsername->Option.getOr("")}
            skillLevel=normalizedSkill
            size=#small
          />
          <span
            className={isYou
              ? "text-sm font-semibold text-gray-900 dark:text-gray-100"
              : "text-sm text-gray-700 dark:text-gray-300"}>
            {firstName->React.string}
          </span>
        </LangProvider.Router.Link>
        {ratingChangeElement->Option.getOr(React.null)}
      </div>
    }
  }
}

module Match = {
  @react.component
  let make = (
    ~user: option<RescriptRelay.fragmentRefs<[> #MatchHistoryListUser_user]>>=?,
    ~match,
  ) => {
    let {id, winners, losers, score, createdAt, playerMetadata, namespace} = ItemFragment.use(match)
    let metadata = PlayerMetadata.decode(playerMetadata)
    let _isCompetitive = namespace->Option.map(ns => ns == "competitive")->Option.getOr(false)

    // The player whose page this is, if any. useOpt keeps the hook
    // unconditional.
    let viewerId = MatchHistoryListUserFragment.useOpt(user)->Option.map(u => u.id)

    // Which side of the payload that player sits on: Some(true) in the
    // winners, Some(false) in the losers, None with no player (or one who
    // didn't play in this match).
    let viewerInWinners = viewerId->Option.flatMap(viewerId =>
      if winners->Option.getOr([])->Array.some(x => x.id == viewerId) {
        Some(true)
      } else if losers->Option.getOr([])->Array.some(x => x.id == viewerId) {
        Some(false)
      } else {
        None
      }
    )
    // Read from the player's side (WIN/LOSS), or neutrally as who beat whom.
    let fromViewer = viewerInWinners->Option.isSome

    let {winnersLeft, isWin, isLoss, shownScore} = readFromLeft(~viewerInWinners, ~score)

    // Get all player IDs for normalization
    let allPlayerIds = Array.concat(
      winners->Option.map(w => w->Array.map(p => p.id))->Option.getOr([]),
      losers->Option.map(l => l->Array.map(p => p.id))->Option.getOr([]),
    )

    let (minMu, maxMu) = PlayerMetadata.getMinMaxMu(metadata, allPlayerIds)

    // Calculate favored team using Rating.predictWin (using original winners/losers order)
    let (winnersFavored, favoredWinProb) = {
      let winnersRatings = winners->Option.map(w =>
        w
        ->Array.map(p =>
          PlayerMetadata.get(metadata, p.id)->Option.map(
            (r: PlayerRating.t): Rating.Rating.t => {
              mu: r.mu,
              sigma: r.sigma,
            },
          )
        )
        ->Array.filterMap(x => x)
      )
      let losersRatings = losers->Option.map(l =>
        l
        ->Array.map(p =>
          PlayerMetadata.get(metadata, p.id)->Option.map(
            (r: PlayerRating.t): Rating.Rating.t => {
              mu: r.mu,
              sigma: r.sigma,
            },
          )
        )
        ->Array.filterMap(x => x)
      )

      switch (winnersRatings, losersRatings) {
      | (Some(wr), Some(lr)) if wr->Array.length > 0 && lr->Array.length > 0 =>
        let winProbs = Rating.Rating.predictWin([wr, lr])
        let winnersProb = winProbs->Array.get(0)->Option.getOr(0.5)
        let losersProb = winProbs->Array.get(1)->Option.getOr(0.5)
        if winnersProb > losersProb {
          (true, winnersProb)
        } else {
          (false, losersProb)
        }
      | _ => (false, 0.5) // Default to no favorite if ratings unavailable
      }
    }

    // Determine if left team was favored based on team reordering
    let leftTeamFavored = if winnersLeft {
      winnersFavored // Left = winners
    } else {
      !winnersFavored // Left = losers
    }

    // Determine favorability indicator
    let leftTeamProbability = if leftTeamFavored {
      favoredWinProb
    } else {
      1.0 -. favoredWinProb
    }
    let rightTeamProbability = 1.0 -. leftTeamProbability

    // predictWin is never exactly 0.5, so "even" is a band around it
    let favoredTeam = favoredSide(leftTeamProbability)

    let leftTeamWon = isWin
    let rightTeamWon = isLoss
    let wasUpset = (favoredTeam == #left && rightTeamWon) || (favoredTeam == #right && leftTeamWon)

    let favoredProbability = Math.max(leftTeamProbability, rightTeamProbability)
    let barWidthPercentage = (favoredProbability -. 0.5) /. 0.5 *. 100.0
    let barPointsRight = leftTeamProbability < 0.5
    let showPill = favoredTeam != #even

    // Helper to render player badges for winners
    let renderWinnerBadges = (
      players: option<array<MatchHistoryList_match_graphql.Types.fragment_winners>>,
      align: [#left | #right],
    ) => {
      players
      ->Option.map(team =>
        team
        ->Array.mapWithIndex((player, _idx) => {
          let rating = PlayerMetadata.get(metadata, player.id)
          let normalizedSkill =
            rating
            ->Option.map(r => PlayerMetadata.normalizeSkill(r.mu, minMu, maxMu))
            ->Option.getOr(50.0)
          let ratingChange = rating->Option.flatMap(r => r.muDiff)
          <PlayerBadge
            key={player.id}
            player=player.fragmentRefs
            ?ratingChange
            align
            isYou={viewerId == Some(player.id)}
            normalizedSkill
          />
        })
        ->React.array
      )
      ->Option.getOr(React.null)
    }

    // Helper to render player badges for losers
    let renderLoserBadges = (
      players: option<array<MatchHistoryList_match_graphql.Types.fragment_losers>>,
      align: [#left | #right],
    ) => {
      players
      ->Option.map(team =>
        team
        ->Array.mapWithIndex((player, _idx) => {
          let rating = PlayerMetadata.get(metadata, player.id)
          let normalizedSkill =
            rating
            ->Option.map(r => PlayerMetadata.normalizeSkill(r.mu, minMu, maxMu))
            ->Option.getOr(50.0)
          let ratingChange = rating->Option.flatMap(r => r.muDiff)
          <PlayerBadge
            key={player.id}
            player=player.fragmentRefs
            ?ratingChange
            align
            isYou={viewerId == Some(player.id)}
            normalizedSkill
          />
        })
        ->React.array
      )
      ->Option.getOr(React.null)
    }

    // The result badge: the player's WIN or LOSS on their page. With no
    // player the winners sit on the left, so it reads "left BEAT right".
    let resultLabel = if isWin {
      fromViewer ? t`WIN` : t`BEAT`
    } else if isLoss {
      t`LOSS`
    } else {
      t`DRAW`
    }

    // Format date
    let formatDate = (date: Js.Date.t) => {
      date->Js.Date.toLocaleDateString
    }

    <div
      key={id}
      className="bg-white dark:bg-[#1e1f23] rounded-xl border border-gray-200 dark:border-[#2a2b30] overflow-hidden">
      // Main content. The extra bottom padding keeps the favourite tab, which
      // rises from the bar below, clear of the date.
      <div className="p-4 pb-6">
        // Mobile: Stacked teams with scores on right, Desktop: Horizontal
        // Mobile Layout - Only smallest screens
        <div className="sm:hidden space-y-3">
          // Top team (left team) with score
          <div
            className={`flex items-center justify-between gap-3 rounded-lg p-3 -m-3 mb-0 ${isWin
                ? "bg-emerald-50/50 dark:bg-emerald-500/10"
                : isLoss
                ? "bg-rose-50/50 dark:bg-rose-500/10"
                : "bg-gray-50/50 dark:bg-white/5"}`}>
            <div className="flex-1 space-y-2">
              {if winnersLeft {
                renderWinnerBadges(winners, #left)
              } else {
                renderLoserBadges(losers, #left)
              }}
            </div>
            <div className="text-3xl font-bold text-gray-900 dark:text-gray-100 tabular-nums">
              {shownScore
              ->Option.mapOr("", ((leftScore, _)) => leftScore->Float.toFixed(~digits=0))
              ->React.string}
            </div>
          </div>
          // VS divider with result badge
          <div className="flex items-center justify-center gap-3">
            <div className="flex-1 h-px bg-gray-200 dark:bg-gray-700" />
            <div
              className={`px-3 py-1 rounded-full text-xs font-semibold flex items-center gap-1.5 ${isWin
                  ? "bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-400 dark:border-emerald-800"
                  : isLoss
                  ? "bg-rose-50 text-rose-700 border border-rose-200 dark:bg-rose-900/30 dark:text-rose-400 dark:border-rose-800"
                  : "bg-gray-100 text-gray-700 border border-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-700"}`}>
              {_isCompetitive ? <Lucide.Trophy className="w-3 h-3" /> : React.null}
              {resultLabel}
            </div>
            <div className="flex-1 h-px bg-gray-200 dark:bg-gray-700" />
          </div>
          // Bottom team (right team) with score
          <div
            className={`flex items-center justify-between gap-3 rounded-lg p-3 -m-3 mt-0 ${isLoss
                ? "bg-emerald-50/50 dark:bg-emerald-500/10"
                : isWin
                ? "bg-rose-50/50 dark:bg-rose-500/10"
                : "bg-gray-50/50 dark:bg-white/5"}`}>
            <div className="flex-1 space-y-2">
              {if winnersLeft {
                renderLoserBadges(losers, #left)
              } else {
                renderWinnerBadges(winners, #left)
              }}
            </div>
            <div className="text-3xl font-bold text-gray-900 dark:text-gray-100 tabular-nums">
              {shownScore
              ->Option.mapOr("", ((_, rightScore)) => rightScore->Float.toFixed(~digits=0))
              ->React.string}
            </div>
          </div>
        </div>
        // Desktop Layout - Horizontal (sm and up)
        <div className="hidden sm:flex sm:items-center gap-4">
          // Left team
          <div
            className={`flex-1 space-y-2 rounded-lg p-3 ${isWin
                ? "bg-emerald-50/50 dark:bg-emerald-500/10"
                : isLoss
                ? "bg-rose-50/50 dark:bg-rose-500/10"
                : "bg-gray-50/50 dark:bg-white/5"}`}>
            {if winnersLeft {
              renderWinnerBadges(winners, #left)
            } else {
              renderLoserBadges(losers, #left)
            }}
          </div>
          // Center: Score and Result
          <div className="flex flex-col items-center gap-2 sm:min-w-[120px]">
            // Score (none for an unscored draw or a match without a score)
            {switch shownScore {
            | None => React.null
            | Some((leftScore, rightScore)) =>
              <div className="text-2xl font-bold text-gray-900 dark:text-gray-100 tabular-nums">
                {leftScore->Float.toFixed(~digits=0)->React.string}
                <span className="text-gray-400 mx-2"> {"-"->React.string} </span>
                {rightScore->Float.toFixed(~digits=0)->React.string}
              </div>
            }}
            // Result badge
            <div
              className={`px-3 py-1 rounded-full text-xs font-semibold flex items-center gap-1.5 ${isWin
                  ? "bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-900/30 dark:text-emerald-400 dark:border-emerald-800"
                  : isLoss
                  ? "bg-rose-50 text-rose-700 border border-rose-200 dark:bg-rose-900/30 dark:text-rose-400 dark:border-rose-800"
                  : "bg-gray-100 text-gray-700 border border-gray-200 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-700"}`}>
              {_isCompetitive ? <Lucide.Trophy className="w-3 h-3" /> : React.null}
              {resultLabel}
            </div>
          </div>
          // Right team
          <div
            className={`flex-1 space-y-2 rounded-lg p-3 ${isLoss
                ? "bg-emerald-50/50 dark:bg-emerald-500/10"
                : isWin
                ? "bg-rose-50/50 dark:bg-rose-500/10"
                : "bg-gray-50/50 dark:bg-white/5"}`}>
            {if winnersLeft {
              renderLoserBadges(losers, #right)
            } else {
              renderWinnerBadges(winners, #right)
            }}
          </div>
        </div>
        // Date - subtle, bottom left
        <div className="mt-3 text-xs text-gray-500 dark:text-gray-400">
          {createdAt
          ->Option.map(date => formatDate(date->Util.Datetime.toDate)->React.string)
          ->Option.getOr(React.null)}
        </div>
      </div>
      // Favorability indicator - subtle bottom bar
      <div className="h-1 w-full bg-gray-100 dark:bg-gray-800 relative">
        // Center marker - very subtle
        <div className="absolute left-1/2 top-0 bottom-0 w-px bg-gray-300 dark:bg-gray-600" />
        // Favorability bar
        {favoredTeam != #even
          ? <div
              className={`absolute top-0 bottom-0 transition-all ${wasUpset
                  ? "bg-amber-400"
                  : "bg-blue-400"} ${barPointsRight ? "left-1/2" : "right-1/2"}`}
              style={ReactDOM.Style.make(
                ~width=`${(barWidthPercentage /. 2.0)->Float.toString}%`,
                (),
              )}>
              // Pill - more subtle
              {showPill
                ? <div
                    className={`absolute bottom-full mb-0.5 ${barPointsRight
                        ? "right-0"
                        : "left-0"}`}>
                    <div
                      className={`flex items-center gap-1 px-2 py-0.5 text-white text-[10px] font-semibold ${wasUpset
                          ? "bg-amber-500"
                          : "bg-blue-500"}`}
                      style={ReactDOM.Style.make(~borderRadius="4px 4px 0 0", ())}>
                      {!barPointsRight
                        ? <Lucide.ChevronRight className="transform rotate-180 w-2.5 h-2.5" />
                        : React.null}
                      {if wasUpset {
                        t`Upset`
                      } else {
                        <span>
                          {`${(favoredProbability *. 100.0)
                            ->Math.round
                            ->Float.toString}%`->React.string}
                        </span>
                      }}
                      {barPointsRight
                        ? <Lucide.ChevronRight className="w-2.5 h-2.5" />
                        : React.null}
                    </div>
                  </div>
                : React.null}
            </div>
          : React.null}
        // Even match indicator
        {favoredTeam == #even
          ? <div className="absolute left-1/2 bottom-full mb-0.5 -translate-x-1/2">
              <div
                className="px-2 py-0.5 bg-gray-400 text-white text-[10px] font-semibold"
                style={ReactDOM.Style.make(~borderRadius="4px 4px 0 0", ())}>
                {t`Even`}
              </div>
            </div>
          : React.null}
      </div>
    </div>
  }
}

@genType @react.component
let make = (~matches, ~user=?) => {
  let (_isPending, _) = ReactExperimental.useTransition()
  let {data, isLoadingNext, hasNext, isLoadingPrevious} = Fragment.usePagination(matches)
  let matches = data.matches->Fragment.getConnectionNodes
  let pageInfo = data.matches.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage

  <WaitForMessages>
    {() => {
      <>
        {!isLoadingPrevious && hasPrevious
          ? pageInfo.startCursor
            ->Option.map(startCursor =>
              <Link to={"./" ++ "?before=" ++ startCursor->encodeURIComponent} className="mt-5">
                {t`...load previous matches`}
              </Link>
            )
            ->Option.getOr(React.null)
          : React.null}
        <div className="space-y-2 mt-5">
          {matches
          ->Array.map(edge => <Match key={edge.id} match=edge.fragmentRefs ?user />)
          ->React.array}
        </div>
        <div className="">
          {hasNext && !isLoadingNext
            ? {
                pageInfo.endCursor
                ->Option.map(endCursor =>
                  <Link to={"./" ++ "?after=" ++ endCursor->encodeURIComponent}>
                    {t`Load more matches...`}
                  </Link>
                )
                ->Option.getOr(React.null)
              }
            : React.null}
        </div>
      </>
    }}
  </WaitForMessages>
}

@genType
let default = make
