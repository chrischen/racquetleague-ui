%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeagueRankingsPageQuery(
    $after: String
    $first: Int
    $before: String
    $activitySlug: String!
    $namespace: String!
    $clubSlug: String
  ) {
    viewer {
      # Add viewer block
      user {
        id
        lineUsername
        picture
        leagueUserStats(activity: $activitySlug, namespace: "doubles:comp") {
          daysNumberOne
        }
        rating(activitySlug: $activitySlug, namespace: $namespace, clubSlug: $clubSlug) {
          ordinal
          mu
        }
      }
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
    club(slug: $clubSlug) {
      name
      slug
    }
    ...RatingListFragment
      @arguments(
        after: $after
        first: $first
        before: $before
        activitySlug: $activitySlug
        namespace: $namespace
        clubSlug: $clubSlug
      )
  }
`)

type loaderData = {query: LeagueRankingsPageQuery_graphql.queryRef}
type params = {ns?: string, activitySlug?: string, lang?: string}

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

// Playoff bracket illustration for the draft banner.
module BracketIllustration = {
  @react.component
  let make = () => {
    <svg viewBox="0 0 96 100" fill="none" className="w-full h-auto">
      <g
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        opacity="0.85">
        // Round 1 — 4 team stubs
        <path d="M4 12 H24" />
        <path d="M4 32 H24" />
        <path d="M4 68 H24" />
        <path d="M4 88 H24" />
        // join pairs into semis
        <path d="M24 12 V32" />
        <path d="M24 68 V88" />
        <path d="M24 22 H46" />
        <path d="M24 78 H46" />
        // join semis into final
        <path d="M46 22 V78" />
        <path d="M46 50 H70" />
        // final line to champion
        <path d="M70 50 H82" />
      </g>
      // entrant dots
      <g fill="currentColor" opacity="0.5">
        <circle cx="4" cy="12" r="2.5" />
        <circle cx="4" cy="32" r="2.5" />
        <circle cx="4" cy="68" r="2.5" />
        <circle cx="4" cy="88" r="2.5" />
      </g>
      // champion node
      <circle
        cx="86"
        cy="50"
        r="8"
        fill="currentColor"
        fillOpacity="0.18"
        stroke="currentColor"
        strokeWidth="2"
      />
      <path
        d="M83 50 l2 2 l4 -4.5"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none"
      />
    </svg>
  }
}

// Playoff Draft sponsor logo — light/dark variants swapped via the `.dark` class.
@module("./rpm-light.svg") external rpmLightLogo: string = "default"
@module("./rpm-dark.svg") external rpmDarkLogo: string = "default"

// Playoff draft + prize banner. Shelved for later (see `usePlayoffDraft`) — all
// copy below is placeholder until the draft and prize data are wired up.
module DraftPrizeBanner = {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  @react.component
  let make = () => {
    <div
      className="relative overflow-hidden rounded-xl border border-amber-300/70 dark:border-amber-500/30 bg-amber-50 dark:bg-amber-950/30 shadow-sm mb-5">
      <div
        className="absolute -top-16 -right-10 w-56 h-56 bg-amber-400/10 blur-3xl rounded-full pointer-events-none"
      />
      <div className="relative p-4 md:p-5 flex flex-col md:flex-row md:items-center gap-4 md:gap-5">
        // Bracket illustration + countdown (desktop)
        <div
          className="flex-shrink-0 hidden sm:flex flex-col items-center justify-center gap-2 w-24 md:w-28 self-stretch">
          <div className="w-full text-amber-500 dark:text-amber-400">
            <BracketIllustration />
          </div>
          <span
            title={ts`Draft starts Tuesday, September 15, 2026`}
            className="inline-flex items-center gap-1 rounded-md bg-amber-400/15 border border-amber-400/40 px-2 py-1 text-[11px] font-bold text-amber-700 dark:text-amber-300 whitespace-nowrap">
            <Lucide.CalendarClock size={12} strokeWidth={2.5} />
            {t`Sep 15, 2026`}
          </span>
        </div>
        // Heading + draft info
        <div className="min-w-0 flex-1">
          <div className="flex items-center flex-wrap gap-x-2 gap-y-1.5">
            <h2
              className="font-black uppercase italic tracking-tight text-base md:text-lg text-gray-900 dark:text-white leading-none flex items-center gap-1.5">
              <Lucide.Trophy
                size={18} className="text-amber-600 dark:text-amber-400" strokeWidth={2.5}
              />
              {t`Playoff Draft`}
              <Lucide.Sparkles
                size={14} className="text-amber-500 dark:text-amber-400" fill="currentColor"
              />
            </h2>
            // Countdown merged into header (mobile)
            <span
              title={ts`Draft starts Tuesday, September 15, 2026`}
              className="sm:hidden inline-flex items-center gap-1 rounded-md bg-amber-400/15 border border-amber-400/40 px-2 py-0.5 text-[11px] font-bold text-amber-700 dark:text-amber-300 whitespace-nowrap">
              <Lucide.CalendarClock size={12} strokeWidth={2.5} />
              {t`Sep 15, 2026`}
            </span>
          </div>
          <p className="text-xs md:text-sm text-gray-600 dark:text-gray-300 mt-2 leading-snug">
            {t`The top 8 men and top 8 women qualify — each bracket is drafted into 4 doubles teams for the finals.`}
          </p>
        </div>
        // Prize + sponsor card
        <div
          className="flex-shrink-0 w-full md:w-52 rounded-lg border border-amber-400/50 bg-white dark:bg-[#1e1f23] overflow-hidden">
          <div
            className="flex items-center justify-between gap-2 px-3 py-2 border-b border-gray-100 dark:border-[#2a2b30] bg-gray-50 dark:bg-[#17181c]">
            <span
              className="font-mono text-[9px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-500">
              {t`Presented by`}
            </span>
            <img
              className="h-5 w-auto max-w-[110px] object-contain flex-shrink-0 block dark:hidden"
              src={rpmLightLogo}
              alt={ts`Sponsor logo`}
            />
            <img
              className="h-5 w-auto max-w-[110px] object-contain flex-shrink-0 hidden dark:block"
              src={rpmDarkLogo}
              alt={ts`Sponsor logo`}
            />
          </div>
          <div className="flex items-center gap-2.5 px-3 py-2.5">
            <div
              className="flex-shrink-0 w-8 h-8 rounded-lg bg-amber-400/20 border border-amber-400/50 flex items-center justify-center">
              <Lucide.Gift
                size={16} className="text-amber-600 dark:text-amber-400" strokeWidth={2.25}
              />
            </div>
            <div className="min-w-0">
              <div
                className="font-black font-mono text-lg md:text-xl leading-none text-amber-700 dark:text-amber-300">
                {t`Prizes`}
              </div>
              <div
                className="text-[11px] font-medium text-gray-500 dark:text-gray-400 mt-1 leading-tight">
                {t`Details coming soon`}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  }
}

// Which prize-distribution banner to show. The Playoff Draft is shelved for
// now; flip this to true to bring it back in place of the Top Player awards.
let usePlayoffDraft = false

@genType @react.component
let make = () => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let query = useLoaderData()
  let params: params = Router.useParams()
  let {viewer, club, fragmentRefs} = Query.usePreloaded(~queryRef=query.data.query)

  let (search, setSearch) = React.useState(() => "")
  let (genderFilter, setGenderFilter) = React.useState((): RatingList.genderFilter => #all)

  let viewerUser = viewer->Option.flatMap(v => v.user)
  let viewerUserId = viewerUser->Option.map(u => u.id)
  let viewerOrdinal = viewerUser->Option.flatMap(u => u.rating)->Option.flatMap(r => r.ordinal)
  let viewerMu = viewerUser->Option.flatMap(u => u.rating)->Option.flatMap(r => r.mu)
  let viewerDays = viewerUser->Option.flatMap(u => u.leagueUserStats)->Option.map(s => s.daysNumberOne)
  let viewerName = viewerUser->Option.flatMap(u => u.lineUsername)
  let viewerPicture = viewerUser->Option.flatMap(u => u.picture)

  // Viewer's clubs, to populate the club filter dropdown.
  let clubs =
    viewer
    ->Option.flatMap(v => v.clubs.edges)
    ->Option.getOr([])
    ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))

  // The rankings are club-scoped by route, so the currently-loaded club is the
  // active filter. Changing it navigates to the club's rankings URL.
  let currentClubSlug = club->Option.flatMap(c => c.slug)
  let navigate = LangProvider.Router.useNavigate()
  let knownNamespaces = ["doubles:comp", "singles:comp"]
  let currentNamespace = switch params.ns {
  | Some(ns) if knownNamespaces->Array.includes(ns) => Some(ns)
  | _ => None
  }
  let handleClubChange = (slug: option<string>) => {
    // Main-domain rankings live under /league/:activitySlug/…; the JPL domain
    // has no activitySlug segment and mounts rankings at the root.
    let path = switch params.activitySlug {
    | Some(activitySlug) =>
      let base = "/league/" ++ activitySlug
      switch (slug, currentNamespace) {
      | (Some(s), Some(ns)) => `${base}/${s}/${ns}`
      | (Some(s), None) => `${base}/${s}`
      | (None, Some(ns)) => `${base}/${ns}`
      | (None, None) => base
      }
    | None =>
      switch slug {
      | Some(s) => `/${s}`
      | None => "/"
      }
    }
    navigate(path, None)
  }

  // Determine title based on club name or ns parameter
  let title = switch club->Option.flatMap(c => c.name) {
  | Some(clubName) => clubName->React.string
  | None =>
    switch params.ns {
    | Some("singles:comp") => t`Competitive Singles`
    | _ => t`Competitive Doubles`
    }
  }

  <WaitForMessages>
    {() => {
      <>
        // Header — dark broadcast style, flush under the nav
        <div
          className="relative bg-[#111113] text-white py-6 md:py-7 border-b-4 border-[#bdf25d] overflow-hidden shadow-lg">
          // Background effects
          <div
            className="absolute -top-24 -right-24 w-96 h-96 bg-[#bdf25d]/10 blur-3xl rounded-full pointer-events-none"
          />
          <div
            className="absolute top-0 right-0 p-4 opacity-5 pointer-events-none transform translate-x-1/4 -translate-y-1/4">
            <Lucide.Trophy size={300} strokeWidth={0.5} />
          </div>
          <Layout.Container className="relative z-10 flex flex-col gap-5">
            // Title + search
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div>
                <div
                  className="inline-flex items-center gap-2 px-2.5 py-0.5 rounded bg-red-500/20 border border-red-500/50 text-red-400 text-[10px] font-bold tracking-widest uppercase mb-2">
                  <span
                    className="w-1.5 h-1.5 rounded-full bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.8)] animate-pulse"
                  />
                  {t`Live Standings`}
                </div>
                <h1
                  className="text-3xl md:text-5xl font-black tracking-tighter uppercase italic flex items-center gap-2.5 drop-shadow-lg">
                  <Lucide.Activity className="text-[#bdf25d]" size={32} strokeWidth={3.} />
                  {title}
                </h1>
                <p className="text-gray-400 mt-3 text-sm max-w-xl">
                  {t`The official Pkuru.com competitive doubles rankings.`}
                </p>
                <p className="text-gray-400 text-sm">
                  {t`To participate, join any event with the trophy icon (competitive rated events) to receive a rating.`}
                </p>
              </div>
              <div className="relative w-full md:w-72 flex-shrink-0">
                <Lucide.Search
                  size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
                />
                <input
                  type_="text"
                  placeholder={ts`Search players...`}
                  value={search}
                  onChange={e => {
                    let value = ReactEvent.Form.target(e)["value"]
                    setSearch(_ => value)
                  }}
                  className="w-full pl-9 pr-4 py-2.5 bg-black/50 border border-gray-700 rounded-lg text-sm font-mono focus:outline-none focus:border-[#bdf25d] text-white transition-colors placeholder-gray-600"
                />
              </div>
            </div>
            // Gender segmented control
            <div className="flex flex-wrap items-center gap-2">
              <div
                className="flex items-center gap-1 bg-black/50 p-1 rounded-lg border border-gray-800"
                role="group"
                ariaLabel={ts`Filter by gender`}>
                {[("all", #all, ts`All`), ("male", #male, ts`Men`), ("female", #female, ts`Women`)]
                ->Array.map(((key, filter, label)) =>
                  <button
                    key={key}
                    onClick={_ => setGenderFilter(_ => filter)}
                    className={Util.cx([
                      "px-3.5 md:px-5 py-1.5 text-xs font-black uppercase tracking-wider rounded-md transition-all",
                      genderFilter == filter
                        ? "bg-[#bdf25d] text-black shadow-[0_0_10px_rgba(189,242,93,0.3)]"
                        : "text-gray-400 hover:text-white hover:bg-gray-800",
                    ])}>
                    {label->React.string}
                  </button>
                )
                ->React.array}
              </div>
              // Club filter dropdown
              {switch clubs {
              | [] => React.null
              | clubs =>
                <div
                  className={Util.cx([
                    "relative flex items-center rounded-lg border transition-colors",
                    currentClubSlug->Option.isSome
                      ? "bg-[#bdf25d]/10 border-[#bdf25d]/60"
                      : "bg-black/50 border-gray-800",
                  ])}>
                  <span
                    className={Util.cx([
                      "pl-3 pr-1.5 flex-shrink-0",
                      currentClubSlug->Option.isSome ? "text-[#bdf25d]" : "text-gray-400",
                    ])}>
                    <Lucide.Building className="w-3.5 h-3.5" />
                  </span>
                  <select
                    ariaLabel={ts`Filter by club`}
                    value={currentClubSlug->Option.getOr("")}
                    onChange={e => {
                      let value = (e->ReactEvent.Form.target)["value"]
                      handleClubChange(value == "" ? None : Some(value))
                    }}
                    className="appearance-none bg-transparent w-full py-2 pl-0 pr-8 text-xs font-black uppercase tracking-wider text-white focus:outline-none cursor-pointer">
                    <option
                      value="" className="bg-[#1e1f23] text-white normal-case tracking-normal">
                      {t`All Clubs`}
                    </option>
                    {clubs
                    ->Array.filterMap(club =>
                      club.slug->Option.map(slug =>
                        <option
                          key={club.id}
                          value={slug}
                          className="bg-[#1e1f23] text-white normal-case tracking-normal">
                          {club.name->Option.getOr(slug)->React.string}
                        </option>
                      )
                    )
                    ->React.array}
                  </select>
                  <Lucide.ChevronDown
                    size={14}
                    className={Util.cx([
                      "absolute right-2.5 pointer-events-none",
                      currentClubSlug->Option.isSome ? "text-[#bdf25d]" : "text-gray-400",
                    ])}
                  />
                </div>
              }}
            </div>
          </Layout.Container>
        </div>
        // List area
        <div className="bg-[#f4f4f5] dark:bg-[#151518] py-4 md:py-6">
          <Layout.Container>
            // Flip to true to swap the Top Player awards banner for the
            // shelved Playoff Draft banner.
            {usePlayoffDraft ? <DraftPrizeBanner /> : <TopPlayerAwardsBanner.Banner />}
          </Layout.Container>
          <React.Suspense
            fallback={<Layout.Container> {t`Loading rankings...`} </Layout.Container>}>
            <RatingList
              ratings=fragmentRefs
              genderFilter
              search
              showDraftUi=usePlayoffDraft
              ?viewerUserId
              ?viewerOrdinal
              ?viewerMu
              ?viewerDays
              ?viewerName
              ?viewerPicture
            />
          </React.Suspense>
        </div>
      </>
    }}
  </WaitForMessages>
}
