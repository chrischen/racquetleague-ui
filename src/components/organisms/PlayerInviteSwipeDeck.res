%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

// Tinder-style player review deck (ReScript port of the former
// PlayerInviteSwipeDeck.tsx). Two verdicts, one interaction: `Invite` reviews
// available players to invite, `Approve` reviews pending join requests. A right
// swipe commits the verdict, a left swipe leaves the player as they were.
//
// A card body renders from the plain `profile` record, so it serves both
// sources: invite candidates carry a Relay fragment the card reads itself,
// while pending RSVPs are built from data the host already holds (their rating
// hangs off the RSVP, which is activity-scoped without fragment arguments).

// ─── framer-motion drag bindings (local: only this deck drags) ───────────────

type motionValue
@module("framer-motion") external useMotionValue: float => motionValue = "useMotionValue"
@module("framer-motion")
external useTransform: (motionValue, array<float>, array<float>) => motionValue = "useTransform"

type cardMotionStyle = {x: motionValue, rotate: motionValue}
type fadeMotionStyle = {opacity: motionValue}
type dragConstraints = {left: int, right: int}
type panOffset = {x: float, y: float}
type panInfo = {offset: panOffset}

module MotionArticle = {
  @module("framer-motion") @scope("motion") @react.component
  external make: (
    ~custom: string=?,
    ~style: cardMotionStyle=?,
    ~drag: string=?,
    ~dragConstraints: dragConstraints=?,
    ~dragElastic: float=?,
    ~onDragEnd: (ReactEvent.Mouse.t, panInfo) => unit=?,
    ~variants: 'v=?,
    ~initial: string=?,
    ~animate: string=?,
    ~exit: string=?,
    ~className: string=?,
    ~\"aria-label": string=?,
    ~children: React.element=?,
  ) => React.element = "article"
}

module MotionFadeDiv = {
  @module("framer-motion") @scope("motion") @react.component
  external make: (
    ~style: fadeMotionStyle=?,
    ~className: string=?,
    ~\"aria-hidden": string=?,
    ~children: React.element=?,
  ) => React.element = "div"
}

// FramerMotion.AnimatePresence lacks `custom`, which is what forwards the exit
// direction to a child that unmounts in the same render it was decided.
module AnimatePresenceCustom = {
  @module("framer-motion") @react.component
  external make: (~custom: string=?, ~mode: string=?, ~children: React.element) => React.element =
    "AnimatePresence"
}

// Variant set for the card: exit slides toward the side the reviewer chose.
// The exit function receives AnimatePresence's `custom` ("left" | "right").
let cardVariants: {..} = %raw(`{
  initial: { scale: 0.96, opacity: 0 },
  animate: { scale: 1, opacity: 1 },
  exit: (direction) => ({
    x: direction === 'left' ? -500 : 500,
    opacity: 0,
    transition: { duration: 0.2 },
  }),
}`)

// ─── DOM bindings ────────────────────────────────────────────────────────────

type keyboardEv
@get external keyEvKey: keyboardEv => string = "key"
@val @scope("window")
external addKeyListener: (string, keyboardEv => unit) => unit = "addEventListener"
@val @scope("window")
external removeKeyListener: (string, keyboardEv => unit) => unit = "removeEventListener"
@val @scope(("window", "document")) external documentBody: Dom.element = "body"
@val @scope("document") external activeElement: Js.Nullable.t<Dom.element> = "activeElement"
@send external focusEl: Dom.element => unit = "focus"

// ─── Data ────────────────────────────────────────────────────────────────────

module UserFragment = %relay(`
  fragment PlayerInviteSwipeDeck_user on User
  @argumentDefinitions(activitySlug: {type: "String", defaultValue: "pickleball"}) {
    id
    lineUsername
    picture
    gender
    biography
    selfRating
    dupr {
      doubles
      doublesReliable
    }
    rating(activitySlug: $activitySlug) {
      id
      mu
    }
  }
`)

// What a right swipe means. Drives every label, the accept icon, and which
// context box the card shows.
type mode = Invite | Approve

// A card body's data, independent of where it came from.
type profile = {
  displayName: string,
  picture: option<string>,
  gender: option<RelaySchemaAssets_graphql.enum_Gender>,
  biography: option<string>,
  selfDupr: option<float>,
  // A linked DUPR rating, which outranks the self-report wherever both exist.
  duprDoubles: option<float>,
  duprReliable: bool,
  computedDupr: option<float>,
  // Approve mode: the note the requester left on their RSVP.
  note: option<string>,
}

type playerSource =
  | FromFragment(RescriptRelay.fragmentRefs<[#PlayerInviteSwipeDeck_user]>)
  | FromProfile(profile)

// One reviewable player. `id` is whatever the accept handler acts on — a user
// id when inviting, an RSVP id when approving. `name` backs the deck chrome
// (button labels, counters) so it renders before the card mounts.
type player = {
  id: string,
  name: string,
  source: playerSource,
}

type direction = Left | Right
let directionToString = d =>
  switch d {
  | Left => "left"
  | Right => "right"
  }

let initialsOf = (name: string): string =>
  name
  ->Js.String2.splitByRe(%re("/\s+/"))
  ->Array.filterMap(part => part)
  ->Array.filter(part => part != "")
  ->Array.slice(~start=0, ~end=2)
  ->Array.map(part => part->String.slice(~start=0, ~end=1)->String.toUpperCase)
  ->Array.join("")

// ─── Card ────────────────────────────────────────────────────────────────────

module ProfileCard = {
  @react.component
  let make = (
    ~profile: profile,
    ~mode: mode,
    ~eventTitle: string,
    ~eventVenue: option<string>,
    ~eventTimeLabel: option<string>,
    ~exitDirection: direction,
    ~onSwipe: direction => unit,
  ) => {
    let x = useMotionValue(0.)
    let rotate = useTransform(x, [-200., 200.], [-14., 14.])
    let acceptOpacity = useTransform(x, [0., 100.], [0., 1.])
    let skipOpacity = useTransform(x, [0., -100.], [0., 1.])

    let displayName = profile.displayName

    let selfDupr = profile.selfDupr
    let computedDupr = profile.computedDupr

    // The left tile shows what the player declares, which is their DUPR
    // rating when they have linked one and their own estimate otherwise.
    // EffectiveRating decides; the chip says which it picked.
    let declared = EffectiveRating.resolve(
      ~pkuruMu=None,
      ~duprDoubles=profile.duprDoubles,
      ~duprReliable=profile.duprReliable,
      ~selfMu=selfDupr->Option.map(Rating.duprToMu),
    )
    let declaredDupr = declared->Option.map(EffectiveRating.dupr)
    let selfLevel =
      declaredDupr
      ->Option.map(LevelPicker.nearest)
      ->Option.flatMap(v =>
        LevelPicker.options()->Array.find(o => LevelPicker.isSelected(Some(v), o.value))
      )

    // Ring around the avatar: strongest signal available, on a 0–5 DUPR axis.
    let visualRating = computedDupr->Option.orElse(declaredDupr)->Option.getOr(0.)
    let ringProgress = Js.Math.min_float(visualRating /. 5., 1.)
    let circumference = 2. *. Js.Math._PI *. 37.
    let ringColor = visualRating >= 4. ? "#7c3aed" : visualRating >= 3. ? "#ffb042" : "#94a3b8"

    let genderLabel = switch profile.gender {
    | Some(RelaySchemaAssets_graphql.Male) => ts`Male`
    | Some(Female) => ts`Female`
    | _ => ts`Gender not provided`
    }

    let handleDragEnd = (_event, info: panInfo) =>
      if info.offset.x > 100. {
        onSwipe(Right)
      } else if info.offset.x < -100. {
        onSwipe(Left)
      }

    <MotionArticle
      custom={exitDirection->directionToString}
      style={x, rotate}
      drag="x"
      dragConstraints={left: 0, right: 0}
      dragElastic=0.75
      onDragEnd=handleDragEnd
      variants=cardVariants
      initial="initial"
      animate="animate"
      exit="exit"
      className="absolute inset-0 flex cursor-grab touch-pan-y flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xl active:cursor-grabbing dark:border-[#3a3b40] dark:bg-[#1e1f23]"
      \"aria-label"=displayName>
      <MotionFadeDiv
        style={opacity: acceptOpacity}
        className="pointer-events-none absolute inset-0 z-10 flex items-center justify-center bg-[#bdf25d]/10"
        \"aria-hidden"="true">
        <span
          className="-rotate-12 rounded-xl border-4 border-[#84b62c] bg-white/90 px-5 py-2 text-3xl font-black tracking-widest text-[#648d1c] shadow-sm dark:bg-[#1e1f23]/90 dark:text-[#bdf25d]">
          {switch mode {
          | Invite => ts`INVITE`
          | Approve => ts`APPROVE`
          }->React.string}
        </span>
      </MotionFadeDiv>
      <MotionFadeDiv
        style={opacity: skipOpacity}
        className="pointer-events-none absolute inset-0 z-10 flex items-center justify-center bg-gray-500/10"
        \"aria-hidden"="true">
        <span
          className="rotate-12 rounded-xl border-4 border-gray-500 bg-white/90 px-5 py-2 text-3xl font-black tracking-widest text-gray-500 shadow-sm dark:bg-[#1e1f23]/90">
          {switch mode {
          | Invite => ts`SKIP`
          | Approve => ts`KEEP`
          }->React.string}
        </span>
      </MotionFadeDiv>
      <div className="flex flex-1 flex-col items-center overflow-y-auto p-7">
        // Avatar ringed by the rating meter
        <div className="relative h-20 w-20">
          <svg width="80" height="80" className="-rotate-90" ariaHidden=true>
            <circle
              cx="40"
              cy="40"
              r="37"
              fill="none"
              stroke="currentColor"
              strokeWidth="4"
              className="text-gray-200 dark:text-gray-700"
            />
            <circle
              cx="40"
              cy="40"
              r="37"
              fill="none"
              stroke=ringColor
              strokeWidth="4"
              strokeLinecap="round"
              strokeDasharray={circumference->Belt.Float.toString}
              strokeDashoffset={(circumference *. (1. -. ringProgress))->Belt.Float.toString}
            />
          </svg>
          <span
            className="absolute inset-2 flex items-center justify-center overflow-hidden rounded-full bg-gray-100 text-lg font-bold text-gray-700 dark:bg-[#2a2b30] dark:text-gray-200">
            {switch profile.picture {
            | Some(picture) if picture != "" =>
              <img src=picture alt="" className="h-full w-full object-cover" draggable=false />
            | _ => {
                let initials = initialsOf(displayName)
                (initials == "" ? "?" : initials)->React.string
              }
            }}
          </span>
        </div>
        <h3 className="mt-4 text-2xl font-semibold text-gray-900 dark:text-gray-100">
          {displayName->React.string}
        </h3>
        <p className="mt-1 text-xs font-medium text-gray-500 dark:text-gray-400">
          {genderLabel->React.string}
        </p>
        // Rating tiles: self-reported and computed
        <div className="mt-4 grid w-full grid-cols-2 gap-2">
          <div
            className="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2.5 dark:border-[#3a3b40] dark:bg-[#222326]">
            <p
              className="font-mono text-[9px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
              {(ts`Declared rating`)->React.string}
            </p>
            {switch selfLevel {
            | Some(level) =>
              <>
                <p className="mt-1 text-sm font-semibold text-gray-900 dark:text-gray-100">
                  {level.label->React.string}
                </p>
                <p className="mt-0.5 font-mono text-[10px] text-gray-500 dark:text-gray-400">
                  {level.range->React.string}
                </p>
                {switch declared {
                | Some(r) =>
                  <RatingSourceChip
                    className="mt-1"
                    source={EffectiveRating.source(r)}
                    reliable={EffectiveRating.reliable(r)}
                  />
                | None => React.null
                }}
              </>
            | None =>
              <p className="mt-1 text-sm font-semibold text-gray-900 dark:text-gray-100">
                {(ts`Not provided`)->React.string}
              </p>
            }}
          </div>
          <div
            className="rounded-lg border border-violet-200 bg-violet-50 px-3 py-2.5 dark:border-violet-900/50 dark:bg-violet-950/20">
            <p
              className="font-mono text-[9px] uppercase tracking-wider text-violet-500 dark:text-violet-400">
              {(ts`Computed rating`)->React.string}
            </p>
            {switch computedDupr {
            | Some(dupr) =>
              <>
                <p className="mt-1 text-sm font-semibold text-violet-950 dark:text-violet-100">
                  {("~DUPR " ++ dupr->Js.Float.toFixedWithPrecision(~digits=2))->React.string}
                </p>
                <p className="mt-0.5 text-[10px] text-violet-600 dark:text-violet-400">
                  {(ts`Based on recorded play`)->React.string}
                </p>
              </>
            | None =>
              <p className="mt-1 text-sm font-semibold text-violet-700/60 dark:text-violet-300/60">
                {(ts`Not yet rated`)->React.string}
              </p>
            }}
          </div>
        </div>
        // Biography
        {switch profile.biography {
        | Some(bio) if bio->String.trim != "" =>
          <div className="mt-4 w-full">
            <p
              className="font-mono text-[9px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
              {(ts`About`)->React.string}
            </p>
            <p className="mt-1.5 text-sm leading-relaxed text-gray-600 dark:text-gray-300">
              {bio->React.string}
            </p>
          </div>
        | _ => React.null
        }}
        // Context box: why this player is worth inviting, or what they said
        // when they asked to join.
        {switch mode {
        | Invite =>
          <div
            className="mt-4 w-full rounded-xl border border-violet-100 bg-violet-50/70 p-3 dark:border-violet-900/50 dark:bg-violet-950/20">
            <p className="text-xs font-semibold text-violet-900 dark:text-violet-200">
              {(ts`Available for the full event`)->React.string}
            </p>
            {switch (eventTimeLabel, eventVenue) {
            | (Some(time), Some(venue)) =>
              <p
                className="mt-1 font-mono text-[10px] leading-relaxed text-violet-700 dark:text-violet-400">
                {(time ++ " · " ++ venue)->React.string}
              </p>
            | _ => React.null
            }}
          </div>
        | Approve =>
          <div
            className="mt-4 w-full rounded-xl border border-amber-100 bg-amber-50/70 p-3 dark:border-amber-900/50 dark:bg-amber-950/20">
            <p className="text-xs font-semibold text-amber-900 dark:text-amber-200">
              {(ts`Waiting for approval to join`)->React.string}
            </p>
            {switch profile.note->Option.filter(n => n->String.trim != "") {
            | Some(note) =>
              <p className="mt-1.5 text-sm leading-relaxed text-amber-800 dark:text-amber-300">
                {note->React.string}
              </p>
            | None =>
              <p
                className="mt-1 font-mono text-[10px] leading-relaxed text-amber-700 dark:text-amber-400">
                {(ts`No message left with the request`)->React.string}
              </p>
            }}
          </div>
        }}
      </div>
      <footer
        className="flex-shrink-0 border-t border-gray-100 bg-gray-50 p-4 text-center text-xs font-medium text-gray-500 dark:border-[#3a3b40] dark:bg-[#2a2b30] dark:text-gray-400">
        {switch mode {
        | Invite => ts`Invite to ${eventTitle}`
        | Approve => ts`Approve for ${eventTitle}`
        }->React.string}
      </footer>
    </MotionArticle>
  }
}

// Invite candidates arrive as a fragment ref: read it here, then hand the card
// the same plain profile the approve path builds by hand.
module FragmentCard = {
  @react.component
  let make = (
    ~userRef: RescriptRelay.fragmentRefs<[#PlayerInviteSwipeDeck_user]>,
    ~fallbackName: string,
    ~mode: mode,
    ~eventTitle: string,
    ~eventVenue: option<string>,
    ~eventTimeLabel: option<string>,
    ~exitDirection: direction,
    ~onSwipe: direction => unit,
  ) => {
    let user = UserFragment.use(userRef)
    // Ratings live on the internal scale; the card speaks estimated DUPR.
    let profile = {
      displayName: user.lineUsername->Option.getOr(fallbackName),
      picture: user.picture,
      gender: user.gender,
      biography: user.biography,
      selfDupr: user.selfRating->Option.map(Rating.guessDupr),
      duprDoubles: user.dupr->Option.flatMap(d => d.doubles),
      duprReliable: user.dupr->Option.map(d => d.doublesReliable)->Option.getOr(false),
      computedDupr: user.rating->Option.flatMap(r => r.mu)->Option.map(Rating.guessDupr),
      note: None,
    }
    <ProfileCard profile mode eventTitle eventVenue eventTimeLabel exitDirection onSwipe />
  }
}

// ─── Deck ────────────────────────────────────────────────────────────────────

@react.component
let make = (
  ~players: array<player>,
  ~eventTitle: string,
  ~eventVenue: option<string>=?,
  ~eventTimeLabel: option<string>=?,
  ~mode: mode=Invite,
  ~onAccept: string => unit,
  ~onClose: unit => unit,
) => {
  let ts = Lingui.UtilString.t
  // Snapshot the queue at open so store updates from committed verdicts don't
  // reshuffle the remaining cards mid-review.
  let (reviewQueue, _) = React.useState(() => players)
  let (currentIndex, setCurrentIndex) = React.useState(() => 0)
  let (exitDirection, setExitDirection) = React.useState(() => Right)
  let closeButtonRef = React.useRef(Js.Nullable.null)
  let currentPlayer = reviewQueue[currentIndex]

  // Focus the close button on open; hand focus back on close.
  React.useEffect0(() => {
    let previouslyFocused = activeElement->Js.Nullable.toOption
    closeButtonRef.current->Js.Nullable.toOption->Option.forEach(focusEl)
    Some(
      () => {
        let _ = Js.Global.setTimeout(
          () => previouslyFocused->Option.forEach(focusEl),
          0,
        )
      },
    )
  })

  // Close on Escape
  let onCloseRef = React.useRef(onClose)
  onCloseRef.current = onClose
  React.useEffect0(() => {
    let onKey = (e: keyboardEv) =>
      if e->keyEvKey === "Escape" {
        onCloseRef.current()
      }
    addKeyListener("keydown", onKey)
    Some(() => removeKeyListener("keydown", onKey))
  })

  let handleSwipe = (direction: direction) =>
    switch currentPlayer {
    | None => ()
    | Some(player) => {
        setExitDirection(_ => direction)
        switch direction {
        | Right => onAccept(player.id)
        // Left is deliberately inert: skipping an invite, or leaving a request
        // pending, is the same "change nothing" verdict.
        | Left => ()
        }
        setCurrentIndex(index => index + 1)
      }
    }

  let total = reviewQueue->Array.length->Int.toString
  let counter = switch currentPlayer {
  | Some(_) => (currentIndex + 1)->Int.toString ++ "/" ++ total
  | None => total ++ "/" ++ total
  }

  ReactDOM.createPortal(
    <FramerMotion.DivCss
      role="dialog"
      \"aria-modal"="true"
      \"aria-labelledby"="player-invite-deck-title"
      initial={opacity: 0.}
      animate={opacity: 1.}
      transition={duration: 0.2}
      className="fixed inset-0 z-[70] flex flex-col bg-white dark:bg-[#222326]">
      <header
        className="flex flex-shrink-0 items-center justify-between gap-3 border-b border-gray-200 px-4 py-3 dark:border-[#2a2b30]">
        <button
          ref={ReactDOM.Ref.domRef(closeButtonRef)}
          type_="button"
          onClick={_ => onClose()}
          className="-ml-1 rounded-lg p-2 text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 dark:text-gray-400 dark:hover:bg-[#2a2b30] dark:hover:text-gray-100"
          ariaLabel={switch mode {
          | Invite => ts`Close swipe invitations`
          | Approve => ts`Close request review`
          }}>
          <Lucide.X size=19 \"aria-hidden"="true" />
        </button>
        <div className="min-w-0 text-center">
          <h2
            id="player-invite-deck-title"
            className="truncate text-sm font-semibold text-gray-900 dark:text-gray-100">
            {switch mode {
            | Invite => ts`Invite players`
            | Approve => ts`Review requests`
            }->React.string}
          </h2>
          <p className="truncate font-mono text-[10px] text-gray-500 dark:text-gray-400">
            {switch eventTimeLabel {
            | Some(time) => eventTitle ++ " · " ++ time
            | None => eventTitle
            }->React.string}
          </p>
        </div>
        <span
          className="w-12 text-right font-mono text-[10px] text-gray-400 dark:text-gray-500"
          ariaLive=#polite>
          {counter->React.string}
        </span>
      </header>
      <main className="flex flex-1 flex-col items-center justify-center overflow-hidden p-5">
        <div className="flex w-full max-w-[380px] flex-col items-center">
          <div className="relative aspect-[3/4] min-h-[380px] max-h-[520px] w-full">
            <AnimatePresenceCustom custom={exitDirection->directionToString} mode="wait">
              {switch currentPlayer {
              | Some({id, name, source: FromFragment(userRef)}) =>
                <FragmentCard
                  key=id
                  userRef
                  fallbackName=name
                  mode
                  eventTitle
                  eventVenue
                  eventTimeLabel
                  exitDirection
                  onSwipe=handleSwipe
                />
              | Some({id, source: FromProfile(profile)}) =>
                <ProfileCard
                  key=id
                  profile
                  mode
                  eventTitle
                  eventVenue
                  eventTimeLabel
                  exitDirection
                  onSwipe=handleSwipe
                />
              | None =>
                <FramerMotion.DivCss
                  key="complete"
                  initial={opacity: 0., scale: 0.94}
                  animate={opacity: 1., scale: 1.}
                  className="absolute inset-0 flex flex-col items-center justify-center rounded-2xl border border-gray-200 bg-gray-50 p-7 text-center dark:border-[#3a3b40] dark:bg-[#1e1f23]">
                  <span
                    className="mb-4 flex h-16 w-16 items-center justify-center rounded-full border border-violet-100 bg-white text-violet-500 shadow-sm dark:border-violet-900/50 dark:bg-[#2a2b30] dark:text-violet-300">
                    <Lucide.Check size=30 \"aria-hidden"="true" />
                  </span>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
                    {(ts`Everyone reviewed`)->React.string}
                  </h3>
                  <p
                    className="mt-2 max-w-xs text-sm leading-relaxed text-gray-500 dark:text-gray-400">
                    {switch mode {
                    | Invite => ts`Invited players have moved into the event's invited list.`
                    | Approve => ts`Approved players have moved into the confirmed list.`
                    }->React.string}
                  </p>
                  <button
                    type_="button"
                    onClick={_ => onClose()}
                    className="mt-6 rounded-lg border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700 transition-colors hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 dark:border-[#3a3b40] dark:bg-[#2a2b30] dark:text-gray-200 dark:hover:bg-[#353640]">
                    {(ts`Back to event`)->React.string}
                  </button>
                </FramerMotion.DivCss>
              }}
            </AnimatePresenceCustom>
          </div>
          {switch currentPlayer {
          | Some(player) =>
            <>
              <FramerMotion.DivCss
                initial={opacity: 0., y: 14.}
                animate={opacity: 1., y: 0.}
                className="mt-7 flex items-center gap-8">
                <button
                  type_="button"
                  onClick={_ => handleSwipe(Left)}
                  className="flex h-14 w-14 items-center justify-center rounded-full border-2 border-gray-200 bg-white text-gray-400 shadow-md transition-transform hover:scale-105 hover:border-red-300 hover:bg-red-50 hover:text-red-500 focus:outline-none focus-visible:ring-2 focus-visible:ring-red-400 active:scale-95 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:hover:border-red-700 dark:hover:bg-red-950/20"
                  ariaLabel={switch mode {
                  | Invite => ts`Skip ${player.name}`
                  | Approve => ts`Keep ${player.name} pending`
                  }}>
                  <Lucide.X size=25 strokeWidth=2.5 \"aria-hidden"="true" />
                </button>
                <button
                  type_="button"
                  onClick={_ => handleSwipe(Right)}
                  className="flex h-14 w-14 items-center justify-center rounded-full border-2 border-[#aee050] bg-[#bdf25d] text-black shadow-md transition-transform hover:scale-105 hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 active:scale-95"
                  ariaLabel={switch mode {
                  | Invite => ts`Invite ${player.name}`
                  | Approve => ts`Approve ${player.name}`
                  }}>
                  {switch mode {
                  | Invite => <Lucide.UserPlus size=25 strokeWidth=2.5 \"aria-hidden"="true" />
                  | Approve => <Lucide.Check size=25 strokeWidth=2.5 \"aria-hidden"="true" />
                  }}
                </button>
              </FramerMotion.DivCss>
              <p className="mt-3 font-mono text-[10px] text-gray-400 dark:text-gray-500">
                {switch mode {
                | Invite => ts`Swipe left to skip · right to invite`
                | Approve => ts`Swipe left to keep pending · right to approve`
                }->React.string}
              </p>
            </>
          | None => React.null
          }}
        </div>
      </main>
    </FramerMotion.DivCss>,
    documentBody,
  )
}
