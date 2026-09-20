%%raw("import { t } from '@lingui/macro'")
open LangProvider.Router

module ClubLeaderboardFragment = %relay(`
  fragment ClubPage_leaderboard on Query
  @argumentDefinitions(
    activitySlug: { type: "String!" }
    namespace: { type: "String!" }
    clubSlug: { type: "String" }
    first: { type: "Int", defaultValue: 5 }
  ) {
    ratings(
      activitySlug: $activitySlug
      namespace: $namespace
      clubSlug: $clubSlug
      first: $first
    ) {
      edges {
        node {
          id
          ordinal
          mu
          user {
            id
            fullName
            lineUsername
            picture
          }
        }
      }
    }
  }
`)

module Query = %relay(`
  query ClubPageQuery(
    $slug: String!
  ) {
    ...ClubPage_leaderboard
      @arguments(
        activitySlug: "pickleball"
        namespace: "doubles:comp"
        clubSlug: $slug
        first: 5
      )
    club(slug: $slug) {
      id
      slug
      name
      description
      shareLink
      chargesEnabled
      exemptMembersFromPayment
      viewerMembership { status isAdmin isOwner }
      stats {
        totalMembers
        activeParticipants
        topPlayersMedianSkill
        retentionRate
      }
      events(first: 3) {
        edges {
          node {
            id
            title
            startDate
            endDate
            timezone
            deleted
            price
            minRating
            location { id name }
            maxRsvps
            rsvps(first: 100) {
              edges { node { id listType } }
            }
          }
        }
      }
    }
    viewer {
      user { id }
    }
  }
  `)

module JoinClubMutation = %relay(`
  mutation ClubPageJoinClubMutation(
    $connections: [ID!]!
    $input: JoinClubInput!
  ) {
    joinClub(input: $input) {
      errors { message }
      club {
        viewerMembership @appendNode(connections: $connections, edgeTypeName: "MembershipEdge") {
          status
        }
      }
    }
  }
`)

module RemoveUserFromClubMutation = %relay(`
  mutation ClubPageRemoveUserFromClubMutation(
    $input: RemoveUserFromClubInput!
  ) {
    removeUserFromClub(input: $input) {
      errors { message }
      membershipIds
      club {
        viewerMembership {
          status
        }
      }
    }
  }
`)

// Owner-only: the club's payment settings. Selecting the field back lets Relay
// update the club record in place.
module UpdateClubPaymentsMutation = %relay(`
  mutation ClubPageUpdateClubPaymentsMutation($input: UpdateClubInput!) {
    updateClub(input: $input) {
      errors { message }
      club {
        id
        exemptMembersFromPayment
      }
    }
  }
`)

type loaderData = ClubPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

// Shared chrome from the club home design, so the header actions, cards and
// section links read as one set instead of drifting per call site.
let primaryAction = "inline-flex items-center gap-1.5 rounded-lg bg-[#bdf25d] px-4 py-2 text-xs font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] disabled:bg-gray-200 disabled:text-gray-500 dark:disabled:bg-[#2a2b30] dark:disabled:text-gray-500"

let secondaryAction = "inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-2 text-xs font-semibold text-gray-700 transition-colors hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] disabled:opacity-60 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:text-gray-200 dark:hover:bg-[#2a2b30]"

let dangerAction = "inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-white px-3 py-2 text-xs font-semibold text-red-600 transition-colors hover:bg-red-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-red-300 disabled:opacity-60 dark:border-red-900/50 dark:bg-[#1e1f23] dark:text-red-400 dark:hover:bg-red-950/30"

let statusChip = "inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-xs font-semibold text-gray-600 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:text-gray-300"

let cardClass = "overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-[#3a3b40] dark:bg-[#1e1f23]"

// Same control as the event form's checkboxes.
let checkboxClass = "mt-0.5 h-5 w-5 flex-shrink-0 rounded border-gray-300 accent-[#bdf25d] focus:ring-[#94c93a] dark:border-[#3a3b40]"

let sectionLink = "text-xs font-semibold text-[#4d6f12] hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-[#bdf25d]"

// The card's footer action. The home page only lists the next few events, so
// this is the way through to the rest of them.
let cardFooterAction = "flex items-center justify-center gap-1.5 border-t border-gray-200 px-4 py-3.5 text-sm font-semibold text-[#4d6f12] transition-colors hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[#94c93a] dark:border-[#3a3b40] dark:text-[#bdf25d] dark:hover:bg-[#222326]"

let emptyState = "rounded-xl border border-dashed border-gray-300 bg-gray-50 px-5 py-10 text-center dark:border-[#3a3b40] dark:bg-[#1e1f23]"

// Community stats, refreshed by the league stats job. `topPlayersMedianSkill`
// is an openskill ordinal, so it goes through ordinalToDupr to land on the
// scale players actually recognise.
module StatsGrid = {
  @react.component
  let make = (~stats: ClubPageQuery_graphql.Types.response_club_stats) => {
    let ts = Lingui.UtilString.t

    let tiles = [
      (ts`Total members`, stats.totalMembers->Int.toString),
      // Counts everyone who rsvp'd in the last 30 days, members or not, so it
      // can run ahead of the member count.
      (ts`Active players`, stats.activeParticipants->Int.toString),
      (
        ts`Club level`,
        stats.topPlayersMedianSkill
        ->Option.map(ordinal => ordinal->Rating.ordinalToDupr->Float.toFixed(~digits=1))
        ->Option.getOr("—"),
      ),
      (
        ts`Retention`,
        stats.retentionRate
        ->Option.map(rate => (rate *. 100.)->Float.toFixed(~digits=0) ++ "%")
        ->Option.getOr("—"),
      ),
    ]

    <dl
      className="grid grid-cols-2 gap-px overflow-hidden rounded-xl border border-gray-200 bg-gray-200 dark:border-[#3a3b40] dark:bg-[#3a3b40] sm:grid-cols-4">
      {tiles
      ->Array.map(((label, value)) =>
        <div key=label className="bg-white px-4 py-3 dark:bg-[#222326]">
          <dt
            className="font-mono text-[8px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
            {label->React.string}
          </dt>
          <dd className="mt-1 text-xl font-semibold text-gray-900 dark:text-gray-100">
            {value->React.string}
          </dd>
        </div>
      )
      ->React.array}
    </dl>
  }
}

module EventRow = {
  @react.component
  let make = (~event: ClubPageQuery_graphql.Types.response_club_events_edges_node) => {
    let ts = Lingui.UtilString.t
    let canceled = event.deleted->Option.isSome

    // Waitlisted rsvps (listType 1) don't take a seat, so only the main list
    // counts against maxRsvps.
    let confirmed =
      event.rsvps
      ->Option.flatMap(rsvps => rsvps.edges)
      ->Option.getOr([])
      ->Array.filterMap(edge => edge)
      ->Array.filterMap(edge => edge.node)
      ->Array.filter(rsvp => rsvp.listType == None || rsvp.listType == Some(0))
      ->Array.length

    let openSpots = event.maxRsvps->Option.map(max => Js.Math.max_int(0, max - confirmed))

    let spotsClass = switch openSpots {
    | Some(0) => "text-red-500"
    | Some(n) if n <= 2 => "text-amber-600 dark:text-amber-400"
    | _ => "text-emerald-600 dark:text-emerald-400"
    }

    let level =
      event.minRating
      ->Option.map(mu => mu->Rating.guessDupr->Float.toFixed(~digits=1) ++ "+")
      ->Option.getOr(ts`All levels`)

    let price = switch event.price {
    | Some(price) if price > 0 => "¥" ++ price->Int.toString
    | _ => ts`Free`
    }

    let duration =
      event.startDate
      ->Option.flatMap(startDate =>
        event.endDate->Option.map(endDate => {
          let minutes =
            endDate
            ->Util.Datetime.toDate
            ->DateFns.differenceInMinutes(startDate->Util.Datetime.toDate)
            ->Float.toInt
          let hours = minutes / 60
          let remainder = mod(minutes, 60)
          if hours > 0 && remainder > 0 {
            `${hours->Int.toString}h ${remainder->Int.toString}m`
          } else if hours > 0 {
            `${hours->Int.toString}h`
          } else {
            `${remainder->Int.toString}m`
          }
        })
      )
      ->Option.getOr("")

    <Link
      to={"/events/" ++ event.id}
      className={"grid gap-3 px-4 py-3 transition-colors hover:bg-gray-50 dark:hover:bg-[#222326] sm:grid-cols-[72px_1fr_auto] sm:items-center" ++ (
        canceled ? " opacity-60" : ""
      )}>
      <div>
        <p className="font-mono text-sm font-semibold text-gray-900 dark:text-gray-100">
          {event.startDate
          ->Option.map(startDate =>
            switch event.timezone {
            | Some(tz) =>
              <ReactIntl.FormattedTime value={startDate->Util.Datetime.toDate} timeZone={tz} />
            | None => <ReactIntl.FormattedTime value={startDate->Util.Datetime.toDate} />
            }
          )
          ->Option.getOr(React.null)}
        </p>
        <p className="mt-0.5 font-mono text-[9px] text-gray-400"> {duration->React.string} </p>
      </div>
      <div className="min-w-0">
        <h4
          className={"truncate text-sm font-semibold " ++ (
            canceled
              ? "text-gray-400 line-through dark:text-gray-500"
              : "text-gray-900 dark:text-gray-100"
          )}>
          {event.title->Option.getOr("")->React.string}
        </h4>
        <div
          className="mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 font-mono text-[9px] text-gray-500 dark:text-gray-400">
          {event.location
          ->Option.map(location =>
            <span className="inline-flex items-center gap-1">
              <Lucide.MapPin size=10 \"aria-hidden"="true" />
              {location.name->Option.getOr("")->React.string}
            </span>
          )
          ->Option.getOr(React.null)}
          <span> {level->React.string} </span>
        </div>
      </div>
      <div className="flex items-center justify-between gap-3 sm:justify-end">
        <div className="text-right">
          {switch openSpots {
          | Some(n) =>
            <p className={"text-xs font-semibold " ++ spotsClass}>
              {(n == 0 ? ts`Full` : ts`${n->Int.toString} open`)->React.string}
            </p>
          | None => React.null
          }}
          <p className="mt-0.5 inline-flex items-center gap-1 font-mono text-[9px] text-gray-400">
            <Lucide.Users size=10 \"aria-hidden"="true" />
            {(confirmed->Int.toString ++
              event.maxRsvps
              ->Option.map(max => "/" ++ max->Int.toString)
              ->Option.getOr(""))->React.string}
          </p>
        </div>
        <span
          className="min-w-[42px] text-right font-mono text-[10px] font-semibold text-gray-600 dark:text-gray-300">
          {price->React.string}
        </span>
      </div>
    </Link>
  }
}

// Events grouped by day, using the same buckets as the full club schedule so
// "Today"/"Tomorrow" mean the same thing on both screens.
module EventList = {
  @react.component
  let make = (
    ~events: array<ClubPageQuery_graphql.Types.response_club_events_edges_node>,
    ~schedulePath: string,
  ) => {
    open Lingui.Util
    let ts = Lingui.UtilString.t
    let intl = ReactIntl.useIntl()
    let setup = EventsListUtils.makeBucketSetup()

    let formatDate = (date: Js.Date.t): string =>
      intl->ReactIntl.Intl.formatDateWithOptions(
        date,
        ReactIntl.dateTimeFormatOptions(~month=#short, ~day=#numeric, ()),
      )

    let bucketMeta = (key: string): (string, string) =>
      switch key {
      | "today" => (ts`Today`, formatDate(setup.dateFromOffset(0.)))
      | "tomorrow" => (ts`Tomorrow`, formatDate(setup.dateFromOffset(1.)))
      | _ =>
        let (isNextWeek, dayIndex, date) = EventsListUtils.getBucketDateDetails(~setup, key)
        let dayName = switch dayIndex {
        | 0 => ts`Sunday`
        | 1 => ts`Monday`
        | 2 => ts`Tuesday`
        | 3 => ts`Wednesday`
        | 4 => ts`Thursday`
        | 5 => ts`Friday`
        | 6 => ts`Saturday`
        | _ => ""
        }
        let offset = key->Int.fromString->Option.getOr(0)
        let label = if offset == -1 {
          ts`Yesterday`
        } else if isNextWeek {
          ts`Next ${dayName}`
        } else {
          dayName
        }
        (label, formatDate(date))
      }

    let bucketed = EventsListUtils.bucketEvents(
      ~setup,
      ~getStartDate={
        (event: ClubPageQuery_graphql.Types.response_club_events_edges_node) => event.startDate
      },
      ~filterByDate=None,
      events,
    )

    let groups = EventsListUtils.sortBucketKeys(bucketed->Js.Dict.keys)->Array.filterMap(key =>
      bucketed
      ->Js.Dict.get(key)
      ->Option.map(bucketEvents => (
        key,
        bucketEvents->Array.toSorted(
          (a, b) =>
            switch (a.startDate, b.startDate) {
            | (Some(a), Some(b)) =>
              a->Util.Datetime.toDate->Js.Date.getTime -. b->Util.Datetime.toDate->Js.Date.getTime
            | _ => 0.
            },
        ),
      ))
    )

    if groups->Array.length == 0 {
      <div className=emptyState>
        <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">
          {t`No upcoming events`}
        </p>
        <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
          {t`Check back when the club publishes its next schedule.`}
        </p>
        <Link to=schedulePath className={"mt-4 " ++ secondaryAction}>
          <Lucide.CalendarDays size=13 \"aria-hidden"="true" />
          {t`Full club schedule`}
        </Link>
      </div>
    } else {
      <div className=cardClass>
        {groups
        ->Array.mapWithIndex(((key, bucketEvents), index) => {
          let (label, dateDetails) = bucketMeta(key)
          <section
            key className={index > 0 ? "border-t border-gray-200 dark:border-[#3a3b40]" : ""}>
            <header
              className="flex items-baseline justify-between bg-gray-50 px-4 py-2 dark:bg-[#222326]">
              <h3 className="text-xs font-semibold text-gray-900 dark:text-gray-100">
                {label->React.string}
              </h3>
              <span className="font-mono text-[9px] text-gray-400">
                {dateDetails->React.string}
              </span>
            </header>
            <div className="divide-y divide-gray-100 dark:divide-[#2a2b30]">
              {bucketEvents
              ->Array.map(event => <EventRow key={event.id} event />)
              ->React.array}
            </div>
          </section>
        })
        ->React.array}
        <Link to=schedulePath className=cardFooterAction>
          {t`Full club schedule`}
          <Lucide.ArrowRight size=16 \"aria-hidden"="true" />
        </Link>
      </div>
    }
  }
}

module TopPlayers = {
  @react.component
  let make = (
    ~players: array<ClubPage_leaderboard_graphql.Types.fragment_ratings_edges_node>,
    ~leaguePath: string,
  ) => {
    open Lingui.Util

    <div className=cardClass>
      <header
        className="flex items-center justify-between border-b border-gray-200 px-4 py-3 dark:border-[#3a3b40]">
        <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">
          {t`Leaderboard`}
        </h3>
        <Link to=leaguePath className={"inline-flex items-center gap-1 " ++ sectionLink}>
          <Lucide.Trophy size=12 \"aria-hidden"="true" />
          {t`View All`}
        </Link>
      </header>
      {players->Array.length == 0
        ? <p className="px-4 py-8 text-center text-xs text-gray-500 dark:text-gray-400">
            {t`No ratings yet`}
          </p>
        : <ol className="divide-y divide-gray-100 dark:divide-[#2a2b30]">
            {players
            ->Array.mapWithIndex((player, index) => {
              let user = player.user
              let displayName =
                user
                ->Option.flatMap(user => user.lineUsername)
                ->Option.orElse(user->Option.flatMap(user => user.fullName))
                ->Option.getOr("Unknown")
              let initials = displayName->String.slice(~start=0, ~end=2)->String.toUpperCase
              let dupr =
                player.mu
                ->Option.map(mu => mu->Rating.guessDupr->Float.toFixed(~digits=2))
                ->Option.getOr("—")
              let ordinal =
                player.ordinal->Option.map(v => v->Float.toFixed(~digits=1))->Option.getOr("—")
              let userId = user->Option.map(user => user.id)->Option.getOr("")

              <li key={player.id}>
                <Link
                  to={leaguePath ++ "/p/" ++ userId}
                  className="flex items-center gap-3 px-4 py-2.5 transition-colors hover:bg-gray-50 dark:hover:bg-[#222326]">
                  <span
                    className="w-5 flex-shrink-0 font-mono text-sm font-bold italic text-gray-400 dark:text-gray-500">
                    {(index + 1)->Int.toString->React.string}
                  </span>
                  {switch user->Option.flatMap(user => user.picture) {
                  | Some(picture) =>
                    <img
                      className="h-8 w-8 flex-shrink-0 rounded-full object-cover"
                      src=picture
                      alt=displayName
                    />
                  | None =>
                    <span
                      className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-gray-100 text-[10px] font-semibold text-gray-600 dark:bg-[#2a2b30] dark:text-gray-300">
                      {initials->React.string}
                    </span>
                  }}
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-gray-900 dark:text-gray-100">
                      {displayName->React.string}
                    </p>
                    <p className="font-mono text-[9px] text-gray-400">
                      {("DUPR " ++ dupr)->React.string}
                    </p>
                  </div>
                  <span
                    className="font-mono text-sm font-semibold text-gray-900 dark:text-gray-100">
                    {ordinal->React.string}
                  </span>
                </Link>
              </li>
            })
            ->React.array}
          </ol>}
    </div>
  }
}

@react.component
let make = () => {
  let createHref = CreateEventLink.useHref()
  open Lingui.Util
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  let leaderboardData = ClubLeaderboardFragment.use(query.fragmentRefs)
  let (commitJoinClub, isJoinInFlight) = JoinClubMutation.use()
  let (commitRemoveUser, isRemoveInFlight) = RemoveUserFromClubMutation.use()
  let (commitUpdateClubPayments, isUpdateClubPaymentsInFlight) = UpdateClubPaymentsMutation.use()
  // The last failure from the Payments card, shown under the toggle.
  let (paymentsError, setPaymentsError) = React.useState(() => None)

  let handleToggleExemptMembers = (clubId: string, next: bool) => {
    setPaymentsError(_ => None)
    commitUpdateClubPayments(
      ~variables={input: {clubId, exemptMembersFromPayment: next}},
      ~onCompleted=({updateClub}, _errors) => {
        switch updateClub.errors {
        | None | Some([]) => ()
        | Some(errors) => setPaymentsError(_ => errors->Array.get(0)->Option.map(e => e.message))
        }
      },
    )->RescriptRelay.Disposable.ignore
  }

  let handleJoinClub = () => {
    query.club
    ->Option.map(club => {
      let membersConnectionId = RescriptRelay.ConnectionHandler.getConnectionID(
        RescriptRelay.makeDataId("client:root"),
        "ClubMembersPageMembersQuery_clubMembers",
        (),
      )
      commitJoinClub(
        ~variables={
          connections: [membersConnectionId],
          input: {clubId: club.id},
        },
        ~onCompleted=({joinClub}, _errors) => {
          switch joinClub.errors {
          | None | Some([]) => ()
          | Some(errors) => errors->Array.forEach(e => Js.Console.error(e.message))
          }
        },
      )->RescriptRelay.Disposable.ignore
    })
    ->Option.getOr()
  }

  let handleCancelRequest = () => {
    query.club
    ->Option.map(club => {
      switch query.viewer->Option.flatMap(v => v.user) {
      | Some(user) =>
        commitRemoveUser(
          ~variables={
            input: {clubId: club.id, userId: user.id},
          },
          ~onCompleted=({removeUserFromClub}, _errors) => {
            switch removeUserFromClub.errors {
            | None | Some([]) => ()
            | Some(errors) => errors->Array.forEach(e => Js.Console.error(e.message))
            }
          },
        )->RescriptRelay.Disposable.ignore
      | None => ()
      }
    })
    ->Option.getOr()
  }

  <WaitForMessages>
    {_ => {
      query.club
      ->Option.map(club => {
        let clubName = club.name->Option.getOr("?")
        let slug = club.slug->Option.getOr("")
        let clubPrefill = CreateEventLink.useClubPrefillParams(~slug=club.slug)
        let initials =
          clubName
          ->String.split(" ")
          ->Array.filterMap(w => w->String.get(0))
          ->Array.map(String.make)
          ->Array.join("")
          ->String.slice(~start=0, ~end=2)
          ->String.toUpperCase
        let leaguePath = "/league/pickleball/" ++ slug
        let viewerIsAdmin =
          club.viewerMembership->Option.flatMap(m => m.isAdmin)->Option.getOr(false)
        let viewerIsOwner =
          club.viewerMembership->Option.flatMap(m => m.isOwner)->Option.getOr(false)
        let events =
          club.events.edges
          ->Option.getOr([])
          ->Array.filterMap(edge => edge->Option.flatMap(edge => edge.node))
        let players =
          leaderboardData.ratings.edges
          ->Option.getOr([])
          ->Array.filterMap(edge => edge->Option.flatMap(edge => edge.node))

        <div className="min-h-full bg-gray-50 dark:bg-[#18191c]">
          <header
            className="border-b border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#222326]">
            <div className="mx-auto max-w-6xl px-4 py-5 md:px-6">
              <Link
                to="/clubs"
                className="inline-flex items-center gap-1.5 text-xs font-semibold text-gray-500 transition-colors hover:text-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-gray-400 dark:hover:text-gray-100">
                <Lucide.ArrowLeft size=14 \"aria-hidden"="true" />
                {t`All clubs`}
              </Link>
              <div className="mt-4 flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
                <div className="min-w-0">
                  <div className="flex items-center gap-2.5">
                    <span
                      className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg bg-[#bdf25d] text-xs font-bold text-black">
                      {initials->React.string}
                    </span>
                    <h1 className="text-2xl font-semibold text-gray-900 dark:text-gray-100">
                      {clubName->React.string}
                    </h1>
                  </div>
                  <p
                    className="mt-2 max-w-2xl text-sm leading-relaxed text-gray-600 dark:text-gray-300">
                    {club.description->Option.getOr("")->React.string}
                  </p>
                  <p className="mt-2 font-mono text-[10px] text-gray-400">
                    {("@" ++ slug)->React.string}
                  </p>
                </div>
                <div className="flex flex-wrap gap-2">
                  {switch query.viewer->Option.flatMap(v => v.user) {
                  | Some(_) =>
                    switch club.viewerMembership->Option.flatMap(m => m.status) {
                    | Some(Active) =>
                      viewerIsAdmin
                        ? React.null
                        : <>
                            <span className=statusChip>
                              <Lucide.Check size=13 \"aria-hidden"="true" />
                              {t`Member`}
                            </span>
                            <button
                              type_="button"
                              className=dangerAction
                              disabled={isRemoveInFlight}
                              onClick={_ => handleCancelRequest()}>
                              {t`Leave club`}
                            </button>
                          </>
                    | Some(Pending) =>
                      <>
                        <span className=statusChip>
                          <Lucide.Check size=13 \"aria-hidden"="true" />
                          {t`Request pending`}
                        </span>
                        <button
                          type_="button"
                          className=secondaryAction
                          disabled={isRemoveInFlight}
                          onClick={_ => handleCancelRequest()}>
                          {t`Cancel Request`}
                        </button>
                      </>
                    | _ =>
                      <button
                        type_="button"
                        className=primaryAction
                        disabled={isJoinInFlight}
                        onClick={_ => handleJoinClub()}>
                        <Lucide.Users size=13 \"aria-hidden"="true" />
                        {t`Request to join`}
                      </button>
                    }
                  | None =>
                    <Link
                      to={"/oauth-login?return=" ++ (slug == "" ? "/clubs" : "/clubs/" ++ slug)}
                      className=primaryAction>
                      <Lucide.Users size=13 \"aria-hidden"="true" />
                      {t`Join Club`}
                    </Link>
                  }}
                  {viewerIsAdmin
                    ? <Link to="./members" className=primaryAction>
                        <Lucide.Settings size=13 \"aria-hidden"="true" />
                        {t`Manage Members`}
                      </Link>
                    : React.null}
                </div>
              </div>
            </div>
          </header>
          <main className="mx-auto max-w-6xl space-y-6 px-4 py-5 pb-24 md:px-6 md:pb-10">
            {switch club.stats {
            | Some(stats) => <StatsGrid stats />
            | None => React.null
            }}
            // Payments: owner-only. Fees for this club's events always charge to
            // the owner's connected Stripe account; the one setting is whether
            // members are exempt. Without a connected account the club is in
            // platform mode, where members are exempt anyway, so the toggle
            // shows that state read-only.
            {viewerIsOwner
              ? <section className={cardClass ++ " p-4"}>
                  <h2 className="text-base font-semibold text-gray-900 dark:text-gray-100">
                    {t`Payments`}
                  </h2>
                  <label
                    className={club.chargesEnabled
                      ? "mt-3 flex cursor-pointer items-start gap-3"
                      : "mt-3 flex cursor-not-allowed items-start gap-3 opacity-70"}>
                    <input
                      id="exemptMembersFromPayment"
                      type_="checkbox"
                      checked={club.chargesEnabled ? club.exemptMembersFromPayment : true}
                      disabled={!club.chargesEnabled || isUpdateClubPaymentsInFlight}
                      onChange={_ =>
                        handleToggleExemptMembers(club.id, !club.exemptMembersFromPayment)}
                      className=checkboxClass
                    />
                    <span className="min-w-0">
                      <span
                        className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
                        {t`Exempt club members from event fees`}
                      </span>
                      <span
                        className="mt-1 block text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                        {club.chargesEnabled
                          ? t`Members join priced events without saving a card. Everyone else pays to your Stripe account as usual.`
                          : t`Your club has no connected Stripe account, so members always join without paying and other players' cards are only kept on file. Connect Stripe in your profile settings to charge event fees.`}
                      </span>
                    </span>
                  </label>
                  {switch paymentsError {
                  | Some(message) =>
                    <p className="mt-2 text-xs text-red-500 dark:text-red-400">
                      {message->React.string}
                    </p>
                  | None => React.null
                  }}
                </section>
              : React.null}
            <div className="grid gap-6 lg:grid-cols-[minmax(0,1.6fr)_minmax(280px,0.8fr)]">
              <section>
                <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
                  <h2 className="text-base font-semibold text-gray-900 dark:text-gray-100">
                    {t`Upcoming Events`}
                  </h2>
                  // Only admins can create club events (the create page's club
                  // picker offers admin clubs alone), so the button is gated
                  // like "Manage members" and just links there with the club set.
                  {viewerIsAdmin
                    ? <Link
                        to={createHref([("clubId", club.id)]->Array.concat(clubPrefill))}
                        className=primaryAction>
                        <Lucide.CalendarPlus size=13 \"aria-hidden"="true" />
                        {t`Add Court`}
                      </Link>
                    : React.null}
                </div>
                <EventList events schedulePath="./events" />
              </section>
              <section>
                <TopPlayers players leaguePath />
              </section>
            </div>
          </main>
        </div>
      })
      ->Option.getOr(<Layout.Container> {t`club not found`} </Layout.Container>)
    }}
  </WaitForMessages>
}
