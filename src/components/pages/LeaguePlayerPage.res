%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module UserStatsFragment = %relay(`
  fragment LeaguePlayerPage_userStats on User
  @argumentDefinitions(
    activitySlug: { type: "String!" }
    namespace: { type: "String" }
    clubSlug: { type: "String" }
  )
  @refetchable(queryName: "LeaguePlayerPageUserStatsRefetchQuery")
  {
    rating(activitySlug: $activitySlug, namespace: $namespace, clubSlug: $clubSlug) {
      ordinal
      mu
    }
    leagueUserStats(activity: $activitySlug, namespace: "doubles:comp", clubSlug: $clubSlug) {
      mdRating {
        mu
        sigma
      }
      mdZScore
      wdRating {
        mu
        sigma
      }
      wdZScore
      xdRating {
        mu
        sigma
      }
      xdZScore
      bestPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      worstPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      bestOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      worstOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mdBestPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mdWorstPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mdBestOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mdWorstOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      wdBestPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      wdWorstPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      wdBestOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      wdWorstOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      xdBestPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      xdWorstPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      xdBestOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      xdWorstOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mfBestPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mfWorstPartners {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mfBestOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mfWorstOpponents {
        score
        user {
          id
          lineUsername
          picture
          gender
        }
      }
      mfPartnerTendency
      hardcourtRating {
        mu
        sigma
      }
      hardcourtZScore
      indoorIndoorBallRating {
        mu
        sigma
      }
      indoorIndoorBallZScore
      indoorOutdoorBallRating {
        mu
        sigma
      }
      indoorOutdoorBallZScore
    }
  }
`)

module Query = %relay(`
  query LeaguePlayerPageQuery(
    $after: String
    $first: Int
    $before: String
    $activitySlug: String!
    $namespace: String
    $userId: ID!
    $clubSlug: String
  ) {
    ...MatchHistoryListFragment
      @arguments(
        after: $after
        first: $first
        before: $before
        activitySlug: $activitySlug
        userId: $userId
      )
    ...RatingGraphWrapperFragment
      @arguments(
        after: $after
        first: $first
        before: $before
        activitySlug: $activitySlug
        userId: $userId
      )
    viewer {
      clubs(first: 100) {
        edges {
          node {
            id
            name
            slug
          }
        }
      }
    }
    user(id: $userId) {
      id
      picture
      lineUsername
      gender
      ...LeaguePlayerPage_userStats
        @arguments(activitySlug: $activitySlug, namespace: $namespace, clubSlug: $clubSlug)
      ...MatchHistoryListUser_user
    }
  }
`)

type loaderData = LeaguePlayerPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

module Params = {
  type t = {activitySlug: string, clubSlug: option<string>}
}
@module("react-router-dom") external useParams: unit => Params.t = "useParams"

type categoryFilter = All | Md | Wd | Xd

type statEntryUser = {
  id: string,
  lineUsername: option<string>,
  picture: option<string>,
}

type statEntry = {
  score: float,
  user: option<statEntryUser>,
}

external toStatEntries: array<'a> => array<statEntry> = "%identity"

let pickEntries = (
  all: array<statEntry>,
  md: array<statEntry>,
  wd: array<statEntry>,
  xd: array<statEntry>,
  filter: categoryFilter,
) => {
  let entries = switch filter {
  | All => all
  | Md => md
  | Wd => wd
  | Xd => xd
  }
  entries->Array.slice(~start=0, ~end=3)
}

module FilterTabs = {
  @react.component
  let make = (~value: categoryFilter, ~onChange: categoryFilter => unit) => {
    open Lingui.Util
    let categories = [All, Md, Wd, Xd]
    <div className="flex gap-1 mt-2">
      {categories
      ->Array.map(cat => {
        let isActive = cat == value
        let activeClass = isActive
          ? "bg-gray-900 text-white"
          : "bg-gray-100 text-gray-500 hover:bg-gray-200 hover:text-gray-700"
        let key = switch cat {
        | All => "all"
        | Md => "md"
        | Wd => "wd"
        | Xd => "xd"
        }
        let label = switch cat {
        | All => t`All`
        | Md => "MD"->React.string
        | Wd => "WD"->React.string
        | Xd => "XD"->React.string
        }
        <button
          key
          onClick={_ => onChange(cat)}
          className={`flex items-center justify-center px-2 h-5 rounded-md transition-colors ${activeClass}`}>
          <span className="text-[11px] font-bold leading-none"> {label} </span>
        </button>
      })
      ->React.array}
    </div>
  }
}

module ZScoreBadge = {
  @react.component
  let make = (~zScore: option<float>) => {
    switch zScore {
    | Some(z) =>
      let absZ = Float.fromString(z->Float.toFixed(~digits=1))->Option.getOr(0.0)->Math.abs
      let sign = z >= 0.0 ? "+" : ""
      let formatted = `${sign}${z->Float.toFixed(~digits=1)}σ`
      let (bgColor, textColor, icon) = if z >= 1.0 {
        ("bg-emerald-100", "text-emerald-700", <Lucide.TrendingUp className="w-3 h-3" />)
      } else if z >= 0.3 {
        ("bg-emerald-50", "text-emerald-600", <Lucide.TrendingUp className="w-3 h-3" />)
      } else if z > -0.3 {
        ("bg-gray-100", "text-gray-600", React.null)
      } else if z > -1.0 {
        ("bg-rose-50", "text-rose-600", <Lucide.TrendingDown className="w-3 h-3" />)
      } else {
        ("bg-rose-100", "text-rose-700", <Lucide.TrendingDown className="w-3 h-3" />)
      }
      <div
        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full ${bgColor} ${textColor} text-xs font-semibold`}>
        {icon}
        <span> {formatted->React.string} </span>
      </div>
    | None => React.null
    }
  }
}

let ordinal = (mu, sigma) => mu -. 3.0 *. sigma

let renderStatEntry = (
  ~score: float,
  ~id: string,
  ~name: option<string>,
  ~picture: option<string>,
  ~colorType: [#good | #bad],
  ~userId: string,
  ~predicted: bool=false,
) => {
  let textColor = switch colorType {
  | #good => "text-emerald-700"
  | #bad => "text-rose-700"
  }
  let progressColor = switch colorType {
  | #good => "bg-emerald-500"
  | #bad => "bg-rose-500"
  }
  let scorePercent = (score *. 100.0)->Float.toFixed(~digits=0)
  let rowClass =
    "flex items-center justify-between py-3 border-b border-gray-100 last:border-0" ++ (
      predicted ? " opacity-75" : ""
    )
  let avatarEl =
    picture
    ->Option.map(pic =>
      <img src={pic} alt={name->Option.getOr("")} className="w-10 h-10 rounded-full" />
    )
    ->Option.getOr(
      <div
        className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center text-gray-500 text-sm font-bold">
        {name
        ->Option.flatMap(n => n->String.charAt(0)->String.toUpperCase->Some)
        ->Option.getOr("?")
        ->React.string}
      </div>,
    )
  let nameEl =
    <div>
      <div className={"font-medium text-gray-900" ++ (predicted ? " italic" : "")}>
        {name->Option.getOr("Unknown")->React.string}
      </div>
    </div>
  let leftSection =
    <LangProvider.Router.Link
      to={`../p/${userId}`} className="flex items-center gap-3 hover:opacity-80 transition-opacity">
      {avatarEl}
      {nameEl}
    </LangProvider.Router.Link>
  let barStyle = predicted
    ? ReactDOM.Style.make(
        ~width=`${scorePercent}%`,
        ~backgroundImage="repeating-linear-gradient(90deg, transparent, transparent 3px, rgba(255,255,255,0.5) 3px, rgba(255,255,255,0.5) 6px)",
        (),
      )
    : ReactDOM.Style.make(~width=`${scorePercent}%`, ())
  let barClass = `h-full ${progressColor}` ++ (predicted ? " opacity-50" : "")
  let scoreClass = `text-sm font-bold ${textColor}` ++ (predicted ? " italic" : "")
  <div key={id} className={rowClass}>
    {leftSection}
    <div className="flex flex-col items-end gap-1">
      <div className={scoreClass}> {`${scorePercent}%`->React.string} </div>
      <div className="w-16 h-1.5 bg-gray-100 rounded-full overflow-hidden">
        <div className={barClass} style={barStyle} />
      </div>
    </div>
  </div>
}

type club = {id: string, name: string, slug: option<string>}

module PlayerContent = {
  @react.component
  let make = (
    ~userStats,
    ~userId: string,
    ~picture: option<string>,
    ~lineUsername: option<string>,
    ~clubs: array<club>,
    ~activitySlug: string,
    ~clubSlug: option<string>,
    ~mainFragmentRefs,
    ~userRefs=?,
  ) => {
    open Lingui.Util
    let navigate = Router.useNavigate()
    let (statsData, refetch) = UserStatsFragment.useRefetchable(userStats)

    let selectedClub =
      clubSlug->Option.flatMap(slug => clubs->Array.find(c => c.slug == Some(slug)))

    let (bestPartnersFilter, setBestPartnersFilter) = React.useState(() => All)
    let (worstPartnersFilter, setWorstPartnersFilter) = React.useState(() => All)
    let (bestOpponentsFilter, setBestOpponentsFilter) = React.useState(() => All)
    let (worstOpponentsFilter, setWorstOpponentsFilter) = React.useState(() => All)

    let prevClubSlugRef = React.useRef(clubSlug)
    React.useEffect1(() => {
      let prevClubSlug = prevClubSlugRef.current
      if prevClubSlug != clubSlug {
        prevClubSlugRef.current = clubSlug
        refetch(
          ~variables=UserStatsFragment.makeRefetchVariables(~clubSlug),
        )->RescriptRelay.Disposable.dispose
      }
      None
    }, [clubSlug])

    let handleClubChange = (slug: option<string>) => {
      switch slug {
      | Some(s) => navigate(`../${s}/p/${userId}`, None)
      | None => navigate(`../p/${userId}`, None)
      }
    }

    let selectedClubName = selectedClub->Option.map(c => c.name)

    <div className="min-h-screen bg-gray-50 w-full">
      // Header with back button
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-6xl mx-auto px-4 py-4">
          <LangProvider.Router.Link
            to="../"
            className="inline-flex items-center gap-2 text-gray-600 hover:text-gray-900 transition-colors">
            <Lucide.ChevronLeft className="w-5 h-5" />
            <span className="font-medium"> {t`Back to league`} </span>
          </LangProvider.Router.Link>
        </div>
      </div>
      <div className="max-w-6xl mx-auto px-4 py-8">
        // Club Context Switcher
        {switch clubs {
        | [] => React.null
        | clubs =>
          <div className="mb-6">
            <div className="flex items-center gap-3">
              <div className="relative">
                <select
                  value={clubSlug->Option.getOr("")}
                  onChange={e => {
                    let value = (e->ReactEvent.Form.target)["value"]
                    handleClubChange(value == "" ? None : Some(value))
                  }}
                  className="appearance-none bg-white border border-gray-300 rounded-lg py-2 pl-10 pr-10 text-sm font-medium text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 shadow-sm cursor-pointer">
                  <option value=""> {t`All Clubs`} </option>
                  {clubs
                  ->Array.filterMap(club =>
                    club.slug->Option.map(slug =>
                      <option key={club.id} value={slug}> {club.name->React.string} </option>
                    )
                  )
                  ->React.array}
                </select>
                <div
                  className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lucide.Building className="w-4 h-4 text-gray-500" />
                </div>
                <div
                  className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                  <Lucide.ChevronDown className="w-4 h-4 text-gray-500" />
                </div>
              </div>
            </div>
            {switch selectedClubName {
            | Some(name) =>
              <div
                className="mt-3 flex items-center justify-between bg-blue-50 border border-blue-200 rounded-lg px-4 py-3">
                <div className="flex items-center gap-2 text-blue-800 text-sm">
                  <Lucide.Info className="w-4 h-4 text-blue-600 flex-shrink-0" />
                  <span className="font-medium"> {t`Showing stats from ${name} only`} </span>
                </div>
                <button
                  onClick={_ => handleClubChange(None)}
                  className="text-blue-600 hover:text-blue-800 p-1 rounded-md hover:bg-blue-100 transition-colors"
                  ariaLabel="Clear filter">
                  <Lucide.X className="w-4 h-4" />
                </button>
              </div>
            | None => React.null
            }}
          </div>
        }}
        // Player Info Card
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
          <div className="flex items-start gap-6">
            {picture
            ->Option.map(pic =>
              <img
                src={pic}
                alt={lineUsername->Option.getOr("")}
                className="w-24 h-24 rounded-full border-4 border-blue-100"
              />
            )
            ->Option.getOr(
              <div
                className="w-24 h-24 rounded-full border-4 border-blue-100 bg-gray-200 flex items-center justify-center text-gray-500 text-2xl font-bold">
                {lineUsername
                ->Option.flatMap(name => name->String.charAt(0)->String.toUpperCase->Some)
                ->Option.getOr("?")
                ->React.string}
              </div>,
            )}
            <div className="flex-1">
              <h1 className="text-3xl font-bold text-gray-900 mb-2">
                {lineUsername->Option.getOr("")->React.string}
              </h1>
              <div className="flex flex-wrap gap-6 mt-4">
                // Current Rating
                <div>
                  <div className="text-sm text-gray-500 mb-1"> {t`Current Rating`} </div>
                  <div className="text-3xl font-bold text-blue-600">
                    {statsData.rating
                    ->Option.flatMap(r => r.ordinal->Option.map(Float.toFixed(_, ~digits=1)))
                    ->Option.getOr("--")
                    ->React.string}
                  </div>
                </div>
                // Estimated DUPR (for pickleball only)
                {switch activitySlug {
                | "pickleball" =>
                  statsData.rating
                  ->Option.flatMap(r => r.mu)
                  ->Option.map(mu => {
                    let dupr = Rating.guessDupr(mu)
                    <div>
                      <div className="text-sm text-gray-500 mb-1"> {t`Estimated DUPR`} </div>
                      <div className="text-2xl font-semibold text-gray-900">
                        {dupr->Float.toFixed(~digits=2)->React.string}
                      </div>
                    </div>
                  })
                  ->Option.getOr(React.null)
                | _ => React.null
                }}
              </div>
            </div>
          </div>
        </div>
        // Badges / Insights
        {switch statsData.leagueUserStats {
        | Some(stats) =>
          switch stats.mfPartnerTendency {
          | Some(tendency) =>
            let (emoji, label) = if tendency > 0.1 {
              ("💪", t`Performs better with stronger partners`)
            } else if tendency < -0.1 {
              ("🤝", t`Elevates weaker partners`)
            } else {
              ("⚖️", t`Balanced partner tendency`)
            }
            <div className="relative mb-6">
              <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4">
                <div
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-white rounded-full border border-gray-200 shadow-sm text-sm text-gray-700 whitespace-nowrap flex-shrink-0">
                  <span> {emoji->React.string} </span>
                  <span> {label} </span>
                </div>
              </div>
            </div>
          | None => React.null
          }
        | None => React.null
        }}
        // Rating Subscores
        {switch statsData.leagueUserStats {
        | Some(stats) =>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            {stats.mdRating
            ->Option.map(r => {
              let ord = ordinal(r.mu, r.sigma)
              <div key="md" className="rounded-xl p-5 border bg-blue-50 border-blue-100">
                <div className="flex items-center justify-between mb-2">
                  <div className="text-sm font-medium text-gray-600"> {t`Men's Doubles`} </div>
                  <ZScoreBadge zScore={stats.mdZScore} />
                </div>
                <div className="flex items-start justify-between">
                  <div>
                    <div className="text-3xl font-bold text-blue-600">
                      {ord->Float.toFixed(~digits=0)->React.string}
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      {`±${r.sigma->Float.toFixed(~digits=0)}`->React.string}
                    </div>
                  </div>
                  {switch activitySlug {
                  | "pickleball" =>
                    <div className="text-right self-start">
                      <div className="text-sm text-gray-500 mb-1"> {t`Estimated DUPR`} </div>
                      <div className="text-2xl font-semibold text-gray-900">
                        {Rating.guessDupr(r.mu)->Float.toFixed(~digits=2)->React.string}
                      </div>
                    </div>
                  | _ => React.null
                  }}
                </div>
              </div>
            })
            ->Option.getOr(React.null)}
            {stats.xdRating
            ->Option.map(r => {
              let ord = ordinal(r.mu, r.sigma)
              <div key="xd" className="rounded-xl p-5 border bg-purple-50 border-purple-100">
                <div className="flex items-center justify-between mb-2">
                  <div className="text-sm font-medium text-gray-600"> {t`Mixed Doubles`} </div>
                  <ZScoreBadge zScore={stats.xdZScore} />
                </div>
                <div className="flex items-start justify-between">
                  <div>
                    <div className="text-3xl font-bold text-purple-600">
                      {ord->Float.toFixed(~digits=0)->React.string}
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      {`±${r.sigma->Float.toFixed(~digits=0)}`->React.string}
                    </div>
                  </div>
                  {switch activitySlug {
                  | "pickleball" =>
                    <div className="text-right self-start">
                      <div className="text-sm text-gray-500 mb-1"> {t`Estimated DUPR`} </div>
                      <div className="text-2xl font-semibold text-gray-900">
                        {Rating.guessDupr(r.mu)->Float.toFixed(~digits=2)->React.string}
                      </div>
                    </div>
                  | _ => React.null
                  }}
                </div>
              </div>
            })
            ->Option.getOr(React.null)}
            {stats.wdRating
            ->Option.map(r => {
              let ord = ordinal(r.mu, r.sigma)
              <div key="wd" className="rounded-xl p-5 border bg-pink-50 border-pink-100">
                <div className="flex items-center justify-between mb-2">
                  <div className="text-sm font-medium text-gray-600"> {t`Women's Doubles`} </div>
                  <ZScoreBadge zScore={stats.wdZScore} />
                </div>
                <div className="flex items-start justify-between">
                  <div>
                    <div className="text-3xl font-bold text-pink-600">
                      {ord->Float.toFixed(~digits=0)->React.string}
                    </div>
                    <div className="text-xs text-gray-500 mt-1">
                      {`±${r.sigma->Float.toFixed(~digits=0)}`->React.string}
                    </div>
                  </div>
                  {switch activitySlug {
                  | "pickleball" =>
                    <div className="text-right self-start">
                      <div className="text-sm text-gray-500 mb-1"> {t`Estimated DUPR`} </div>
                      <div className="text-2xl font-semibold text-gray-900">
                        {Rating.guessDupr(r.mu)->Float.toFixed(~digits=2)->React.string}
                      </div>
                    </div>
                  | _ => React.null
                  }}
                </div>
              </div>
            })
            ->Option.getOr(React.null)}
            // Court & Ball Type Ratings
            {[
              (
                stats.hardcourtRating->Option.map(r => (r.mu, r.sigma)),
                stats.hardcourtZScore,
                "hardcourt",
                t`Hard Court`,
                "bg-amber-50",
                "border-amber-100",
                "text-amber-600",
              ),
              (
                stats.indoorOutdoorBallRating->Option.map(r => (r.mu, r.sigma)),
                stats.indoorOutdoorBallZScore,
                "indoor-outdoor",
                t`Indoor Court (Outdoor Ball)`,
                "bg-teal-50",
                "border-teal-100",
                "text-teal-600",
              ),
              (
                stats.indoorIndoorBallRating->Option.map(r => (r.mu, r.sigma)),
                stats.indoorIndoorBallZScore,
                "indoor-indoor",
                t`Indoor Court (Indoor Ball)`,
                "bg-indigo-50",
                "border-indigo-100",
                "text-indigo-600",
              ),
            ]
            ->Array.filterMap(((rating, zScore, key, label, bgClass, borderClass, textColor)) =>
              rating->Option.map(((mu, sigma)) => {
                let ord = ordinal(mu, sigma)
                <div key className={`rounded-xl p-5 border ${bgClass} ${borderClass}`}>
                  <div className="flex items-center justify-between mb-2">
                    <div className="text-sm font-medium text-gray-600"> {label} </div>
                    <ZScoreBadge zScore />
                  </div>
                  <div className="flex items-start justify-between">
                    <div>
                      <div className={`text-3xl font-bold ${textColor}`}>
                        {ord->Float.toFixed(~digits=0)->React.string}
                      </div>
                      <div className="text-xs text-gray-500 mt-1">
                        {`±${sigma->Float.toFixed(~digits=0)}`->React.string}
                      </div>
                    </div>
                    {switch activitySlug {
                    | "pickleball" =>
                      <div className="text-right self-start">
                        <div className="text-sm text-gray-500 mb-1"> {t`Estimated DUPR`} </div>
                        <div className="text-2xl font-semibold text-gray-900">
                          {Rating.guessDupr(mu)->Float.toFixed(~digits=2)->React.string}
                        </div>
                      </div>
                    | _ => React.null
                    }}
                  </div>
                </div>
              })
            )
            ->React.array}
          </div>
        | None => React.null
        }}
        // Rating Graph
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-6">
          <React.Suspense fallback={React.null}>
            <RatingGraphWrapper matches=mainFragmentRefs userId />
          </React.Suspense>
        </div>
        // Partner & Opponent Analysis
        {switch statsData.leagueUserStats {
        | Some(stats) =>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            // Best Partners
            {switch stats.bestPartners {
            | [] => React.null
            | _ =>
              <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div className="flex items-center gap-2">
                  <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg">
                    <Lucide.Users className="w-5 h-5" />
                  </div>
                  <h2 className="text-lg font-bold text-gray-900"> {t`Best Doubles Partners`} </h2>
                </div>
                <FilterTabs
                  value=bestPartnersFilter onChange={filter => setBestPartnersFilter(_ => filter)}
                />
                <div className="flex flex-col mt-2">
                  {
                    let filtered = pickEntries(
                      stats.bestPartners->toStatEntries,
                      stats.mdBestPartners->toStatEntries,
                      stats.wdBestPartners->toStatEntries,
                      stats.xdBestPartners->toStatEntries,
                      bestPartnersFilter,
                    )
                    switch filtered {
                    | [] =>
                      <p className="text-sm text-gray-400 py-4 text-center">
                        {t`No data for this category`}
                      </p>
                    | entries =>
                      entries
                      ->Array.filterMap(entry =>
                        entry.user->Option.map(u =>
                          renderStatEntry(
                            ~score=entry.score,
                            ~id=u.id,
                            ~name=u.lineUsername,
                            ~picture=u.picture,
                            ~colorType=#good,
                            ~userId=u.id,
                          )
                        )
                      )
                      ->React.array
                    }
                  }
                </div>
                {switch stats.mfBestPartners->toStatEntries->Array.slice(~start=0, ~end=3) {
                | [] => React.null
                | mfEntries =>
                  <div>
                    <div className="flex items-center gap-2 pt-3 pb-1">
                      <Lucide.Sparkles className="w-3 h-3 text-amber-500" />
                      <span className="text-[11px] font-medium text-amber-600 italic">
                        {t`Predicted`}
                      </span>
                      <div className="flex-1 h-px bg-amber-200" />
                    </div>
                    <div className="flex flex-col">
                      {mfEntries
                      ->Array.filterMap(entry =>
                        entry.user->Option.map(u =>
                          renderStatEntry(
                            ~score=entry.score,
                            ~id=u.id,
                            ~name=u.lineUsername,
                            ~picture=u.picture,
                            ~colorType=#good,
                            ~userId=u.id,
                            ~predicted=true,
                          )
                        )
                      )
                      ->React.array}
                    </div>
                  </div>
                }}
              </div>
            }}
            // Worst Partners
            {switch stats.worstPartners {
            | [] => React.null
            | _ =>
              <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div className="flex items-center gap-2">
                  <div className="p-2 bg-rose-50 text-rose-600 rounded-lg">
                    <Lucide.Users className="w-5 h-5" />
                  </div>
                  <h2 className="text-lg font-bold text-gray-900"> {t`Worst Doubles Partners`} </h2>
                </div>
                <FilterTabs
                  value=worstPartnersFilter onChange={filter => setWorstPartnersFilter(_ => filter)}
                />
                <div className="flex flex-col mt-2">
                  {
                    let filtered = pickEntries(
                      stats.worstPartners->toStatEntries,
                      stats.mdWorstPartners->toStatEntries,
                      stats.wdWorstPartners->toStatEntries,
                      stats.xdWorstPartners->toStatEntries,
                      worstPartnersFilter,
                    )
                    switch filtered {
                    | [] =>
                      <p className="text-sm text-gray-400 py-4 text-center">
                        {t`No data for this category`}
                      </p>
                    | entries =>
                      entries
                      ->Array.filterMap(entry =>
                        entry.user->Option.map(u =>
                          renderStatEntry(
                            ~score=entry.score,
                            ~id=u.id,
                            ~name=u.lineUsername,
                            ~picture=u.picture,
                            ~colorType=#bad,
                            ~userId=u.id,
                          )
                        )
                      )
                      ->React.array
                    }
                  }
                </div>
                {switch stats.mfWorstPartners->toStatEntries->Array.slice(~start=0, ~end=3) {
                | [] => React.null
                | mfEntries =>
                  <div>
                    <div className="flex items-center gap-2 pt-3 pb-1">
                      <Lucide.Sparkles className="w-3 h-3 text-amber-500" />
                      <span className="text-[11px] font-medium text-amber-600 italic">
                        {t`Predicted`}
                      </span>
                      <div className="flex-1 h-px bg-amber-200" />
                    </div>
                    <div className="flex flex-col">
                      {mfEntries
                      ->Array.filterMap(entry =>
                        entry.user->Option.map(u =>
                          renderStatEntry(
                            ~score=entry.score,
                            ~id=u.id,
                            ~name=u.lineUsername,
                            ~picture=u.picture,
                            ~colorType=#bad,
                            ~userId=u.id,
                            ~predicted=true,
                          )
                        )
                      )
                      ->React.array}
                    </div>
                  </div>
                }}
              </div>
            }}
            // Strong Against (Best Opponents)
            {switch stats.bestOpponents {
            | [] => React.null
            | _ =>
              <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div className="flex items-center gap-2">
                  <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg">
                    <Lucide.Swords className="w-5 h-5" />
                  </div>
                  <h2 className="text-lg font-bold text-gray-900"> {t`Strong Against`} </h2>
                </div>
                <FilterTabs
                  value=bestOpponentsFilter onChange={filter => setBestOpponentsFilter(_ => filter)}
                />
                <div className="flex flex-col mt-2">
                  {
                    let filtered = pickEntries(
                      stats.bestOpponents->toStatEntries,
                      stats.mdBestOpponents->toStatEntries,
                      stats.wdBestOpponents->toStatEntries,
                      stats.xdBestOpponents->toStatEntries,
                      bestOpponentsFilter,
                    )
                    switch filtered {
                    | [] =>
                      <p className="text-sm text-gray-400 py-4 text-center">
                        {t`No data for this category`}
                      </p>
                    | entries =>
                      entries
                      ->Array.filterMap(entry =>
                        entry.user->Option.map(u =>
                          renderStatEntry(
                            ~score=entry.score,
                            ~id=u.id,
                            ~name=u.lineUsername,
                            ~picture=u.picture,
                            ~colorType=#good,
                            ~userId=u.id,
                          )
                        )
                      )
                      ->React.array
                    }
                  }
                </div>
                {switch stats.mfBestOpponents->toStatEntries->Array.slice(~start=0, ~end=3) {
                | [] => React.null
                | mfEntries =>
                  <div>
                    <div className="flex items-center gap-2 pt-3 pb-1">
                      <Lucide.Sparkles className="w-3 h-3 text-amber-500" />
                      <span className="text-[11px] font-medium text-amber-600 italic">
                        {t`Predicted`}
                      </span>
                      <div className="flex-1 h-px bg-amber-200" />
                    </div>
                    <div className="flex flex-col">
                      {mfEntries
                      ->Array.filterMap(entry =>
                        entry.user->Option.map(u =>
                          renderStatEntry(
                            ~score=entry.score,
                            ~id=u.id,
                            ~name=u.lineUsername,
                            ~picture=u.picture,
                            ~colorType=#good,
                            ~userId=u.id,
                            ~predicted=true,
                          )
                        )
                      )
                      ->React.array}
                    </div>
                  </div>
                }}
              </div>
            }}
            // Weak Against (Worst Opponents)
            {switch stats.worstOpponents {
            | [] => React.null
            | _ =>
              <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
                <div className="flex items-center gap-2">
                  <div className="p-2 bg-rose-50 text-rose-600 rounded-lg">
                    <Lucide.ShieldIcon className="w-5 h-5" />
                  </div>
                  <h2 className="text-lg font-bold text-gray-900"> {t`Weak Against`} </h2>
                </div>
                <FilterTabs
                  value=worstOpponentsFilter
                  onChange={filter => setWorstOpponentsFilter(_ => filter)}
                />
                <div className="flex flex-col mt-2">
                  {
                    let filtered = pickEntries(
                      stats.worstOpponents->toStatEntries,
                      stats.mdWorstOpponents->toStatEntries,
                      stats.wdWorstOpponents->toStatEntries,
                      stats.xdWorstOpponents->toStatEntries,
                      worstOpponentsFilter,
                    )
                    switch filtered {
                    | [] =>
                      <p className="text-sm text-gray-400 py-4 text-center">
                        {t`No data for this category`}
                      </p>
                    | entries =>
                      entries
                      ->Array.filterMap(entry =>
                        entry.user->Option.map(u =>
                          renderStatEntry(
                            ~score=entry.score,
                            ~id=u.id,
                            ~name=u.lineUsername,
                            ~picture=u.picture,
                            ~colorType=#bad,
                            ~userId=u.id,
                          )
                        )
                      )
                      ->React.array
                    }
                  }
                </div>
                {switch stats.mfWorstOpponents->toStatEntries->Array.slice(~start=0, ~end=3) {
                | [] => React.null
                | mfEntries =>
                  <div>
                    <div className="flex items-center gap-2 pt-3 pb-1">
                      <Lucide.Sparkles className="w-3 h-3 text-amber-500" />
                      <span className="text-[11px] font-medium text-amber-600 italic">
                        {t`Predicted`}
                      </span>
                      <div className="flex-1 h-px bg-amber-200" />
                    </div>
                    <div className="flex flex-col">
                      {mfEntries
                      ->Array.filterMap(entry =>
                        entry.user->Option.map(u =>
                          renderStatEntry(
                            ~score=entry.score,
                            ~id=u.id,
                            ~name=u.lineUsername,
                            ~picture=u.picture,
                            ~colorType=#bad,
                            ~userId=u.id,
                            ~predicted=true,
                          )
                        )
                      )
                      ->React.array}
                    </div>
                  </div>
                }}
              </div>
            }}
          </div>
        | None => React.null
        }}
        // Match History
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4"> {t`Recent Matches`} </h2>
          <React.Suspense fallback={<div className="text-gray-500"> {t`Loading...`} </div>}>
            <MatchHistoryList matches=mainFragmentRefs user=?userRefs />
          </React.Suspense>
        </div>
      </div>
    </div>
  }
}

@genType @react.component
let make = () => {
  let query = useLoaderData()
  let {fragmentRefs, user, viewer} = Query.usePreloaded(~queryRef=query.data)
  let params = useParams()
  let activitySlug = params.activitySlug
  let clubSlug = params.clubSlug

  let clubs =
    viewer
    ->Option.flatMap(v => v.clubs.edges)
    ->Option.getOr([])
    ->Array.filterMap(edge =>
      edge
      ->Option.flatMap(e => e.node)
      ->Option.map(n => {
        id: n.id,
        name: n.name->Option.getOr(""),
        slug: n.slug,
      })
    )

  user->Option.map(user => {
    let userRefs = user.fragmentRefs
    <WaitForMessages>
      {() =>
        <PlayerContent
          userStats={user.fragmentRefs}
          userId={user.id}
          picture={user.picture}
          lineUsername={user.lineUsername}
          clubs
          activitySlug
          clubSlug
          mainFragmentRefs=fragmentRefs
          userRefs
        />}
    </WaitForMessages>
  })
}
