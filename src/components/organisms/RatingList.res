%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")

open LangProvider.Router
module Fragment = %relay(`
  fragment RatingListFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    activitySlug: { type: "String!" }
    namespace: { type: "String!" }
    clubSlug: { type: "String" }
  )
  @refetchable(queryName: "RatingListRefetchQuery")
  {
    ratings(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace, clubSlug: $clubSlug)
    @connection(key: "RatingListFragment_ratings") {
      edges {
        node {
          id
          ordinal
          user {
            id
            lineUsername
            gender
          }
          ...RatingList_rating @arguments(activitySlug: $activitySlug)
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
  fragment RatingList_rating on Rating
  @argumentDefinitions(activitySlug: { type: "String!" })
  {
    id
    ordinal
    mu
    user {
      id
      lineUsername
      picture
      gender
      leagueUserStats(activity: $activitySlug, namespace: "doubles:comp") {
        daysNumberOne
      }
    }
  }
`)

type genderFilter = [#all | #male | #female]

// Silent URL update (no router navigation) so in-place pagination can keep
// the cursor in the address bar without re-running the route loader.
@val @scope(("window", "history"))
external replaceState: (Js.Nullable.t<'a>, string, string) => unit = "replaceState"

// Minimal IntersectionObserver binding for infinite-scroll auto-loading.
module IntersectionObserver = {
  type t
  type entry = {isIntersecting: bool}
  type options = {rootMargin?: string, threshold?: float}
  @new external make: (array<entry> => unit, options) => t = "IntersectionObserver"
  @send external observe: (t, Dom.element) => unit = "observe"
  @send external disconnect: t => unit = "disconnect"
}

// Playoff draft placeholders — replace with real draft data when available.
let draftSize = 8

let initialsOf = (name: string) => {
  let parts = name->String.trim->String.split(" ")->Array.filter(p => p != "")
  switch parts {
  | [] => "?"
  | [single] => single->String.slice(~start=0, ~end=2)->String.toUpperCase
  | _ =>
    parts
    ->Array.map(p => p->String.slice(~start=0, ~end=1))
    ->Array.slice(~start=0, ~end=2)
    ->Array.join("")
    ->String.toUpperCase
  }
}

module RatingItem = {
  open Lingui.Util
  @react.component
  let make = (
    ~rating,
    ~rank,
    ~genderRank: option<int>,
    ~maxRating,
    ~minRating,
    ~draftEnabled: bool,
  ) => {
    let {id: _, ordinal, mu, user} = ItemFragment.use(rating)
    let progress = switch ordinal {
    | Some(ordinal) =>
      maxRating == minRating ? 100. : (ordinal -. minRating) /. (maxRating -. minRating) *. 100.
    | None => 0.
    }
    let isLeader = progress >= 100.
    let qualifies = draftEnabled && genderRank->Option.map(r => r <= draftSize)->Option.getOr(false)
    let progressPct = progress->Float.toFixed(~digits=2) ++ "%"
    // Estimated DUPR from the player's mu, matching the rest of the app.
    let dupr = mu->Option.map(mu => Rating.guessDupr(mu)->Float.toFixed(~digits=2))

    user
    ->Option.map(user => {
      let name = user.lineUsername->Option.getOr("?")
      let daysAtOne = user.leagueUserStats->Option.map(s => s.daysNumberOne)
      <li
        className={Util.cx([
          "group relative flex items-center overflow-hidden shadow-sm hover:shadow-[0_0_15px_rgba(189,242,93,0.2)] transition-all py-3.5 md:py-5 px-3 md:px-4 border-b",
          qualifies
            ? "bg-amber-50/60 dark:bg-amber-950/20 border-amber-200/70 dark:border-amber-500/20 border-l-2 border-l-amber-400"
            : "bg-white dark:bg-[#1e1f23] border-gray-200 dark:border-[#2a2b30]",
        ])}>
        // Rating progress built into the row with a slanted edge
        <div
          style={{width: progressPct, clipPath: "polygon(0 0, 100% 0, calc(100% - 18px) 100%, 0 100%)"}}
          className={Util.cx([
            "absolute inset-y-0 left-0 pointer-events-none transition-[width] duration-700 ease-out",
            isLeader
              ? "bg-yellow-400/30 dark:bg-yellow-400/25"
              : "bg-[#bdf25d]/30 dark:bg-[#bdf25d]/20",
          ])}
        />
        // bright slanted leading edge that tracks the fill
        <div
          style={{left: progressPct}}
          className={Util.cx([
            "absolute inset-y-0 -ml-3 w-1.5 pointer-events-none transform -skew-x-12 transition-[left] duration-700 ease-out",
            isLeader
              ? "bg-yellow-400 shadow-[0_0_10px_rgba(250,204,21,0.6)]"
              : "bg-[#bdf25d] shadow-[0_0_10px_rgba(189,242,93,0.5)]",
          ])}
        />
        // Rank position
        <div className="relative w-10 md:w-14 flex-shrink-0 text-center">
          <span
            className={Util.cx([
              "font-black italic text-2xl md:text-3xl leading-none tabular-nums transition-colors",
              isLeader
                ? "text-yellow-500 dark:text-yellow-400"
                : "text-gray-400 dark:text-gray-500 group-hover:text-gray-900 dark:group-hover:text-white",
            ])}>
            {rank->Int.toString->React.string}
          </span>
        </div>
        // Player
        <div className="relative flex-1 ml-2 flex items-center gap-3 md:gap-4 min-w-0">
          <div
            className={Util.cx([
              "relative w-10 h-10 md:w-11 md:h-11 rounded-full bg-gray-100 dark:bg-[#2a2b30] flex items-center justify-center font-black text-sm text-gray-800 dark:text-white flex-shrink-0 border-2",
              isLeader ? "border-yellow-400" : "border-transparent",
            ])}>
            {user.picture
            ->Option.map(picture =>
              <img className="w-full h-full rounded-full object-cover" src={picture} alt="" />
            )
            ->Option.getOr(initialsOf(name)->React.string)}
            // Gender color code — no recorded gender is shown as male (blue).
            {user.gender == Some(Female)
              ? <span
                  className="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-white dark:border-[#1e1f23] bg-pink-500"
                />
              : <span
                  className="absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-white dark:border-[#1e1f23] bg-blue-500"
                />}
            {isLeader
              ? <Lucide.Crown
                  className="absolute -top-4 md:-top-5 text-yellow-400 drop-shadow-[0_0_8px_rgba(250,204,21,0.8)]"
                  size={20}
                  fill="currentColor"
                />
              : React.null}
          </div>
          <div className="min-w-0">
            <div
              className="font-bold text-sm md:text-lg uppercase tracking-wide text-gray-900 dark:text-white truncate flex items-center gap-2">
              <span className="truncate"> {name->React.string} </span>
              {qualifies
                ? <span
                    className="hidden md:inline-flex items-center gap-1 flex-shrink-0 px-1.5 py-0.5 rounded bg-amber-400/20 border border-amber-400/50 text-amber-700 dark:text-amber-300 font-mono text-[10px] font-black tracking-wider normal-case">
                    <Lucide.Trophy size={10} strokeWidth={2.5} />
                    {t`Draft`}
                  </span>
                : React.null}
            </div>
            <div className="flex items-center gap-2 mt-0.5">
              {dupr
              ->Option.map(dupr =>
                <div className="sm:hidden font-mono text-[10px] text-gray-500 dark:text-gray-400 font-bold">
                  {("DUPR " ++ dupr)->React.string}
                </div>
              )
              ->Option.getOr(React.null)}
              {qualifies
                ? <span
                    className="md:hidden inline-flex items-center gap-1 flex-shrink-0 font-mono text-[10px] font-black text-amber-600 dark:text-amber-400 uppercase tracking-wider">
                    <Lucide.Trophy size={10} strokeWidth={2.5} />
                    {t`Draft`}
                  </span>
                : React.null}
            </div>
          </div>
        </div>
        // Rating
        <div className="relative w-24 md:w-32 text-right">
          <div
            className={Util.cx([
              "font-mono text-xl md:text-3xl font-black tabular-nums transition-colors",
              isLeader ? "text-yellow-500 dark:text-yellow-400" : "text-gray-900 dark:text-white",
            ])}>
            {ordinal
            ->Option.map(ordinal => ordinal->Float.toFixed(~digits=2)->React.string)
            ->Option.getOr("--"->React.string)}
          </div>
        </div>
        // Est. DUPR (hidden on mobile — shown inline under the name instead)
        <div className="relative w-20 text-right hidden sm:block">
          <div className="font-mono text-sm font-bold text-gray-500 dark:text-gray-400">
            {dupr->Option.map(React.string)->Option.getOr("--"->React.string)}
          </div>
        </div>
        // Days spent as #1 of their gender pool (replaces the design's trend column)
        <div className="relative w-16 hidden md:flex justify-end items-center">
          {daysAtOne
          ->Option.flatMap(d => d > 0.0 ? Some(d) : None)
          ->Option.map(d =>
            <div className="flex items-center gap-1 text-amber-500 dark:text-amber-400">
              <Lucide.Crown size={13} strokeWidth={2.5} fill="currentColor" />
              <span className="font-mono text-xs font-bold"> {d->Float.toFixed(~digits=1)->React.string} </span>
            </div>
          )
          ->Option.getOr(
            <span className="font-mono text-xs text-gray-300 dark:text-gray-600"> {"—"->React.string} </span>,
          )}
        </div>
        // Full-row link to the player's profile
        <Link to={"./p/" ++ user.id} className="absolute inset-0 z-10">
          <span className="sr-only"> {name->React.string} </span>
        </Link>
      </li>
    })
    ->Option.getOr(React.null)
  }
}

// Pinned "Your standing" row — always shows the viewer's own rating and overall
// season rank above the (filtered) list.
module CurrentUserStanding = {
  open Lingui.Util
  @react.component
  let make = (
    ~rank,
    ~ordinal: float,
    ~dupr: option<string>,
    ~days: option<float>,
    ~progress: float,
    ~name,
    ~picture,
    ~userId,
  ) => {
    let progressPct = progress->Float.toFixed(~digits=2) ++ "%"
    <aside className="mb-4">
      <div className="mb-1.5 flex items-center gap-2 px-1">
        <span
          className="font-mono text-[9px] font-black uppercase tracking-[0.18em] text-[#64851d] dark:text-[#bdf25d]">
          {t`Your standing`}
        </span>
        <span className="h-px flex-1 bg-[#bdf25d]/35 dark:bg-[#bdf25d]/20" />
      </div>
      <div
        className="group relative flex items-center overflow-hidden rounded-xl border border-[#a3d949]/70 bg-white px-3 py-3.5 shadow-[0_8px_24px_rgba(82,112,17,0.14)] ring-1 ring-[#bdf25d]/20 transition-shadow hover:shadow-[0_8px_28px_rgba(82,112,17,0.24)] md:px-4 md:py-5 dark:border-[#bdf25d]/35 dark:bg-[#1e1f23] dark:shadow-[0_8px_28px_rgba(0,0,0,0.32)]">
        <div
          style={{width: progressPct, clipPath: "polygon(0 0, 100% 0, calc(100% - 18px) 100%, 0 100%)"}}
          className="pointer-events-none absolute inset-y-0 left-0 bg-[#bdf25d]/35 dark:bg-[#bdf25d]/20 transition-[width] duration-700 ease-out"
        />
        <div
          style={{left: progressPct}}
          className="pointer-events-none absolute inset-y-0 -ml-3 w-1.5 -skew-x-12 bg-[#bdf25d] shadow-[0_0_10px_rgba(189,242,93,0.5)] transition-[left] duration-700 ease-out"
        />
        <div className="relative w-10 flex-shrink-0 text-center md:w-14">
          <span
            className="text-2xl font-black italic leading-none tabular-nums text-[#64851d] md:text-3xl dark:text-[#bdf25d]">
            {rank->Int.toString->React.string}
          </span>
        </div>
        <div className="relative ml-2 flex min-w-0 flex-1 items-center gap-3 md:gap-4">
          <div
            className="flex h-10 w-10 flex-shrink-0 items-center justify-center overflow-hidden rounded-full border-2 border-[#bdf25d] bg-[#bdf25d]/20 text-sm font-black text-gray-900 md:h-11 md:w-11 dark:text-white">
            {picture
            ->Option.map(picture =>
              <img className="w-full h-full rounded-full object-cover" src={picture} alt="" />
            )
            ->Option.getOr(initialsOf(name)->React.string)}
          </div>
          <div className="min-w-0">
            <div
              className="flex items-center gap-2 truncate text-sm font-bold uppercase tracking-wide text-gray-900 md:text-lg dark:text-white">
              <span className="truncate"> {name->React.string} </span>
              <span
                className="rounded bg-[#bdf25d]/25 px-1.5 py-0.5 font-mono text-[9px] font-black normal-case tracking-wider text-[#526f16] dark:text-[#bdf25d]">
                {t`You`}
              </span>
            </div>
            {dupr
            ->Option.map(dupr =>
              <div className="mt-0.5 font-mono text-[10px] font-bold text-gray-500 sm:hidden dark:text-gray-400">
                {("DUPR " ++ dupr)->React.string}
              </div>
            )
            ->Option.getOr(React.null)}
          </div>
        </div>
        <div className="relative w-24 text-right md:w-32">
          <div
            className="font-mono text-xl font-black tabular-nums text-gray-900 md:text-3xl dark:text-white">
            {ordinal->Float.toFixed(~digits=2)->React.string}
          </div>
        </div>
        <div className="relative w-20 text-right hidden sm:block">
          <div className="font-mono text-sm font-bold text-gray-500 dark:text-gray-400">
            {dupr->Option.map(React.string)->Option.getOr("--"->React.string)}
          </div>
        </div>
        <div className="relative w-16 hidden md:flex justify-end items-center">
          {days
          ->Option.flatMap(d => d > 0.0 ? Some(d) : None)
          ->Option.map(d =>
            <div className="flex items-center gap-1 text-[#64851d] dark:text-[#bdf25d]">
              <Lucide.Crown size={13} strokeWidth={2.5} fill="currentColor" />
              <span className="font-mono text-xs font-bold"> {d->Float.toFixed(~digits=1)->React.string} </span>
            </div>
          )
          ->Option.getOr(
            <span className="font-mono text-xs text-gray-300 dark:text-gray-600"> {"—"->React.string} </span>,
          )}
        </div>
        // Full-row link to the viewer's own profile
        <Link to={"./p/" ++ userId} className="absolute inset-0 z-10">
          <span className="sr-only"> {t`View my profile`} </span>
        </Link>
      </div>
    </aside>
  }
}

@genType @react.component
let make = (
  ~ratings,
  ~genderFilter: genderFilter=#all,
  ~search: string="",
  // Playoff-draft badges/cutoff are shelved for now — off unless the caller
  // opts in (and the window still has to start at rank #1).
  ~showDraftUi: bool=false,
  ~viewerUserId: option<string>=?,
  ~viewerOrdinal: option<float>=?,
  ~viewerMu: option<float>=?,
  ~viewerDays: option<float>=?,
  ~viewerName: option<string>=?,
  ~viewerPicture: option<string>=?,
) => {
  open Lingui.Util
  let (_isPending, _) = ReactExperimental.useTransition()
  let {data, loadNext, isLoadingNext, hasNext} = Fragment.usePagination(ratings)
  let (searchParams, _) = Router.useSearchParamsFunc()
  // When the query was loaded via backward navigation (?before=X), Relay's
  // loadNext keeps that stale `before` in its refetch variables, which breaks
  // forward pagination once the window crosses X. In that state the first
  // forward page navigates to a clean ?after= URL (re-running the loader)
  // instead of refetching in place.
  let loadedWithBefore = searchParams->Router.SearchParams.get("before")->Option.isSome
  let allRatings = data.ratings->Fragment.getConnectionNodes
  let pageInfo = data.ratings.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage

  // Sentinel observed for infinite-scroll auto-loading.
  let sentinelRef: React.ref<Js.Nullable.t<Dom.element>> = React.useRef(Js.Nullable.null)
  let loadMoreInPlace = () => {
    // Keep the cursor in the URL (like the old ?after= links) so the current
    // position survives a page reload.
    switch pageInfo.endCursor {
    | Some(endCursor) =>
      replaceState(Js.Nullable.null, "", "?after=" ++ encodeURIComponent(endCursor))
    | None => ()
    }
    loadNext(~count=20)->RescriptRelay.Disposable.ignore
  }

  // Ranks are computed across the whole loaded connection so filtering
  // never renumbers players. Players with no recorded gender count as men for
  // the rankings and the draft, so anyone who isn't explicitly female is male.
  let genderRanks = {
    let dict = Dict.make()
    let maleCount = ref(0)
    let femaleCount = ref(0)
    allRatings->Array.forEach(node => {
      switch node.user->Option.flatMap(u => u.gender) {
      | Some(Female) => {
          femaleCount := femaleCount.contents + 1
          dict->Dict.set(node.id, femaleCount.contents)
        }
      | _ => {
          maleCount := maleCount.contents + 1
          dict->Dict.set(node.id, maleCount.contents)
        }
      }
    })
    dict
  }

  let searchQuery = search->String.trim->String.toLowerCase
  let filtered =
    allRatings
    ->Array.mapWithIndex((node, index) => (node, index + 1))
    ->Array.filter(((node, _rank)) => {
      // The viewer is pinned to the "Your standing" row, so keep them out of
      // the main list to avoid a duplicate.
      let notViewer = switch viewerUserId {
      | Some(id) => node.user->Option.map(u => u.id) != Some(id)
      | None => true
      }
      // No recorded gender counts as male, so "Men" is anyone not female.
      let genderOk = switch genderFilter {
      | #all => true
      | #male => node.user->Option.flatMap(u => u.gender) != Some(Female)
      | #female => node.user->Option.flatMap(u => u.gender) == Some(Female)
      }
      let searchOk =
        searchQuery == "" ||
        node.user
        ->Option.flatMap(u => u.lineUsername)
        ->Option.map(name => name->String.toLowerCase->String.includes(searchQuery))
        ->Option.getOr(false)
      notViewer && genderOk && searchOk
    })

  // "Your standing" row: overall season rank/progress across the whole loaded
  // connection (independent of the active filters). Rank is the count of loaded
  // players who outrank the viewer, +1 — exact once all higher-rated players
  // are loaded (pagination runs top-down), which is guaranteed once the
  // viewer's own row has loaded.
  let connOrdinals = allRatings->Array.filterMap(node => node.ordinal)
  let connMax = switch connOrdinals->Array.get(0) {
  | Some(first) => connOrdinals->Array.reduce(first, (acc, next) => next > acc ? next : acc)
  | None => 0.
  }
  let connMin = connOrdinals->Array.reduce(connMax, (acc, next) => next < acc ? next : acc)
  let viewerDupr = viewerMu->Option.map(mu => Rating.guessDupr(mu)->Float.toFixed(~digits=2))
  let viewerStanding = switch (viewerUserId, viewerOrdinal) {
  | (Some(userId), Some(ordinal)) =>
    let rank =
      1 + allRatings->Array.filter(node => node.ordinal->Option.getOr(0.) > ordinal)->Array.length
    let progress = connMax == connMin ? 100. : (ordinal -. connMin) /. (connMax -. connMin) *. 100.
    Some((userId, rank, ordinal, viewerDupr, progress))
  | _ => None
  }

  // Normalize the progress fill against the filtered set so the spread stays
  // readable whichever filter is active.
  let ordinals = filtered->Array.filterMap(((node, _)) => node.ordinal)
  let maxRating = switch ordinals->Array.get(0) {
  | Some(first) => ordinals->Array.reduce(first, (acc, next) => next > acc ? next : acc)
  | None => 0.
  }
  let minRating = ordinals->Array.reduce(maxRating, (acc, next) => next < acc ? next : acc)

  // The draft cutoff is a single clean line only when one gender is isolated
  // (so the visible order matches that gender's ranking) and no search is
  // narrowing the list.
  let singleGender = genderFilter == #male || genderFilter == #female
  let isFiltered = singleGender || searchQuery != ""

  // Draft badges/cutoff only render when the caller opts in and the window
  // starts at rank #1 (no pagination has scrolled us past the top).
  let draftEnabled = showDraftUi && !hasPrevious

  // Auto-load the next page when the sentinel scrolls into view. Only in the
  // in-place branch — the loadedWithBefore path must navigate, and we never
  // auto-navigate on scroll.
  let canAutoLoad = hasNext && !isLoadingNext && !loadedWithBefore
  React.useEffect2(() => {
    if canAutoLoad {
      switch sentinelRef.current->Js.Nullable.toOption {
      | Some(el) =>
        let observer = IntersectionObserver.make(
          entries =>
            switch entries->Array.get(0) {
            | Some(entry) if entry.isIntersecting => loadMoreInPlace()
            | _ => ()
            },
          {rootMargin: "0px 0px 320px 0px", threshold: 0.01},
        )
        observer->IntersectionObserver.observe(el)
        Some(() => observer->IntersectionObserver.disconnect)
      | None => None
      }
    } else {
      None
    }
  }, (canAutoLoad, allRatings->Array.length))

  <Layout.Container className="mt-4">
    <>
      // The server only supports forward pagination (no `last` arg), so going
      // back up the list re-runs the route loader with the `before` cursor.
      {hasPrevious
        ? pageInfo.startCursor
          ->Option.map(startCursor =>
            <Link
              className="flex w-full items-center justify-center gap-2 rounded-xl border border-dashed border-gray-300 px-4 py-3 mb-3 font-mono text-[10px] font-bold uppercase tracking-widest text-gray-400 transition-colors hover:border-[#a3d949] hover:text-[#4d6f12] dark:border-[#3a3b40] dark:text-gray-500 dark:hover:border-[#bdf25d]/60 dark:hover:text-[#bdf25d]"
              to={"./" ++ "?before=" ++ encodeURIComponent(startCursor)}>
              {t`...load higher rated players`}
            </Link>
          )
          ->Option.getOr(React.null)
        : React.null}
      // Pinned "Your standing" row
      {viewerStanding
      ->Option.map(((userId, rank, ordinal, dupr, progress)) =>
        <CurrentUserStanding
          rank
          ordinal
          dupr
          days=viewerDays
          progress
          name={viewerName->Option.getOr("You")}
          picture=viewerPicture
          userId
        />
      )
      ->Option.getOr(React.null)}
      // Table header
      {filtered->Array.length > 0
        ? <div
            className="flex items-center px-4 py-2 text-[10px] font-black font-mono text-gray-400 dark:text-gray-500 tracking-widest uppercase mb-2">
            <div className="w-10 md:w-14 text-center"> {"#"->React.string} </div>
            <div className="flex-1 ml-2"> {t`Player`} </div>
            <div className="w-24 md:w-32 text-right"> {t`Rating`} </div>
            <div className="w-20 text-right hidden sm:block"> {t`Est. DUPR`} </div>
            <div className="w-16 text-right hidden md:block"> {t`Days #1`} </div>
          </div>
        : React.null}
      <ul role="list" className="flex flex-col gap-0 pb-2">
        {filtered
        ->Array.map(((node, rank)) => {
          let genderRank = genderRanks->Dict.get(node.id)
          let showCutoff =
            draftEnabled && singleGender && searchQuery == "" && genderRank == Some(draftSize)
          <React.Fragment key={node.id}>
            <RatingItem rank genderRank maxRating minRating draftEnabled rating=node.fragmentRefs />
            // Draft cutoff line
            {showCutoff
              ? <li className="relative flex items-center gap-2 py-2 px-3 my-1">
                  <div className="h-px flex-1 bg-gradient-to-r from-transparent to-amber-400/60" />
                  <span
                    className="flex items-center gap-1.5 font-mono text-[10px] font-black uppercase tracking-widest text-amber-600 dark:text-amber-400 whitespace-nowrap">
                    <Lucide.Award size={12} strokeWidth={2.5} />
                    {t`Draft cutoff · Top 8 qualify`}
                  </span>
                  <div className="h-px flex-1 bg-gradient-to-l from-transparent to-amber-400/60" />
                </li>
              : React.null}
          </React.Fragment>
        })
        ->React.array}
      </ul>
      {filtered->Array.length == 0
        ? <div
            className="rounded-xl border border-gray-200 bg-white py-12 text-center dark:border-[#2a2b30] dark:bg-[#1e1f23]">
            <Lucide.Users size={24} className="mx-auto mb-3 text-gray-300 dark:text-gray-600" />
            <p
              className="font-mono text-sm font-bold uppercase tracking-widest text-gray-500 dark:text-gray-400">
              {t`No players found`}
            </p>
            {isFiltered
              ? <p className="mt-1 text-xs text-gray-400 dark:text-gray-500">
                  {t`Try broadening your search or filters.`}
                </p>
              : React.null}
          </div>
        : React.null}
      // Infinite-scroll sentinel + pagination footer
      <div ref={ReactDOM.Ref.domRef(sentinelRef)}>
        {isLoadingNext
        ? <div
            className="flex items-center justify-center gap-3 rounded-xl border border-gray-200 bg-white px-4 py-4 mt-3 mb-8 shadow-sm dark:border-[#2a2b30] dark:bg-[#1e1f23]">
            <Lucide.Loader2 size={18} className="animate-spin text-[#65a30d] dark:text-[#bdf25d]" />
            <span
              className="font-mono text-[11px] font-bold uppercase tracking-wider text-gray-600 dark:text-gray-300">
              {t`Loading next standings`}
            </span>
          </div>
        : hasNext
        ? {
            let loadMoreStyle = "flex w-full items-center justify-center gap-2 rounded-xl border border-dashed border-gray-300 px-4 py-4 mt-3 mb-8 font-mono text-[10px] font-bold uppercase tracking-widest text-gray-400 transition-colors hover:border-[#a3d949] hover:text-[#4d6f12] dark:border-[#3a3b40] dark:text-gray-500 dark:hover:border-[#bdf25d]/60 dark:hover:text-[#bdf25d]"
            let loadMoreLabel =
              <>
                <span className="flex gap-1">
                  <span className="h-1 w-1 rounded-full bg-current" />
                  <span className="h-1 w-1 rounded-full bg-current" />
                  <span className="h-1 w-1 rounded-full bg-current" />
                </span>
                {t`Load more players...`}
              </>
            loadedWithBefore
              ? // Clean loader re-run drops the stale `before` variable
                pageInfo.endCursor
                ->Option.map(endCursor =>
                  <Link
                    className=loadMoreStyle
                    to={"./" ++ "?after=" ++ encodeURIComponent(endCursor)}>
                    {loadMoreLabel}
                  </Link>
                )
                ->Option.getOr(React.null)
              : <button type_="button" onClick={_ => loadMoreInPlace()} className=loadMoreStyle>
                  {loadMoreLabel}
                </button>
          }
        : React.null}
        {!hasNext && filtered->Array.length > 0
          ? <div
              className="flex items-center justify-center gap-2 py-4 mb-4 font-mono text-[10px] font-bold uppercase tracking-widest text-gray-400 dark:text-gray-500">
              <Lucide.CheckCircle2 size={14} className="text-[#65a30d] dark:text-[#bdf25d]" />
              {t`All players loaded`}
            </div>
          : React.null}
      </div>
    </>
  </Layout.Container>
}

@genType
let default = make
