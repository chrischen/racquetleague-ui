// Storybook support for EventStickyFooter.stories.tsx; the app never imports
// this. The footer is props-driven: PkEventPage works out the viewer's state
// from the event's RSVPs and passes flags. Each `state` below is one set of
// flags as the page would derive them. The query supplies what the footer
// still reads from Relay: the event's record id (its join and leave
// mutations update the RSVP connection under it), the viewer's profile for
// the join gate, and the activity feed for the chat row.
module Query = %relay(`
  query EventStickyFooterStoryQuery {
    ...UseProfileGate_query
    ...PkEventMessages_query @arguments(topic: "evt-story-1.updated")
    event(id: "evt-story-1") {
      __id
      id
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventStickyFooterStoryQuery_graphql.node->Obj.magic

@genType
type state = [
  | #signedOut
  | #notJoined
  | #notJoinedPriced
  | #invited
  | #full
  | #joined
  | #leaveWithWaitlist
  | #waitlisted
  | #pending
  | #unpaidNoCard
  | #unpaidSavedCard
  | #savedCardError
  | #deadlinePassed
  | #gracePeriod
  | #cancelled
  | #externalEvent
  | #chat
]

// Everything the page derives, for one state.
type preset = {
  signedIn: bool,
  isJoined: bool,
  isWaitlisted: bool,
  isPending: bool,
  isUnpaid: bool,
  savedCard: option<EventStickyFooter.savedCardShape>,
  savedCardError: option<string>,
  // How long ago the viewer joined; the leave button stays live for the
  // first 30 minutes even past the cancellation deadline.
  joinedMinutesAgo: option<float>,
  price: option<int>,
  isFull: bool,
  confirmedCount: int,
  waitlistCount: int,
  maxRsvps: int,
  // The cancellation deadline, in hours before the start.
  cancelDeadlineHours: option<int>,
  shadow: bool,
  externalUrl: option<string>,
  cancelled: bool,
  chat: bool,
  cardRequiredOnJoin: bool,
}

let visa: EventStickyFooter.savedCardShape = {brand: "visa", last4: "4242"}

// A free evening session for 12, nine going, cancellable until 24 hours
// before; the viewer has not joined.
let base = {
  signedIn: true,
  isJoined: false,
  isWaitlisted: false,
  isPending: false,
  isUnpaid: false,
  savedCard: None,
  savedCardError: None,
  joinedMinutesAgo: None,
  price: None,
  isFull: false,
  confirmedCount: 9,
  waitlistCount: 0,
  maxRsvps: 12,
  cancelDeadlineHours: Some(24),
  shadow: false,
  externalUrl: None,
  cancelled: false,
  chat: false,
  cardRequiredOnJoin: false,
}

let joined = {...base, isJoined: true, confirmedCount: 10, joinedMinutesAgo: Some(2. *. 24. *. 60.)}
let full = {...base, isFull: true, confirmedCount: 12, waitlistCount: 2}
let unpaid = {...joined, price: Some(1500), isUnpaid: true}

let presetOf = (state: state) =>
  switch state {
  | #signedOut => {...base, signedIn: false}
  | #notJoined => base
  // No card on file: the card form opens as soon as the join lands.
  | #notJoinedPriced => {...base, price: Some(1500), cardRequiredOnJoin: true}
  // An invite (listType 2) keeps the join call-to-action: joining accepts
  // it. This player already has a card on file.
  | #invited => {...base, price: Some(1500), savedCard: Some(visa)}
  | #full => full
  | #joined => joined
  | #leaveWithWaitlist => {...full, isJoined: true, joinedMinutesAgo: Some(2. *. 24. *. 60.)}
  | #waitlisted => {
      ...full,
      isJoined: true,
      isWaitlisted: true,
      waitlistCount: 3,
      joinedMinutesAgo: Some(90.),
    }
  | #pending => {...base, isJoined: true, isPending: true, joinedMinutesAgo: Some(45.)}
  | #unpaidNoCard => unpaid
  | #unpaidSavedCard => {...unpaid, savedCard: Some(visa)}
  | #savedCardError => {
      ...unpaid,
      savedCard: Some(visa),
      savedCardError: Some("Your card was declined. Use a different card to hold your spot."),
    }
  // The deadline was four days before the start, so it has passed.
  | #deadlinePassed => {...joined, cancelDeadlineHours: Some(96)}
  | #gracePeriod => {...joined, cancelDeadlineHours: Some(96), joinedMinutesAgo: Some(12.)}
  | #cancelled => {...joined, cancelled: true}
  | #externalEvent => {
      ...base,
      confirmedCount: 8,
      maxRsvps: 16,
      cancelDeadlineHours: None,
      shadow: true,
      externalUrl: Some("https://labola.jp/r/event/4821/"),
    }
  | #chat => {...joined, chat: true}
  }

@genType @react.component
let make = (
  ~state: state=#notJoined,
  // True on the event's own page (PkEventPage's route), where the bar meets
  // the viewport's edges; false inside the events drawer (rounded top).
  ~fullWidth=true,
  ~onPayClick=() => (),
  ~onUseSavedCard=() => (),
  ~onJoinedNeedsCard=(_: string) => (),
) => {
  let data = Query.use(~variables=())
  // Read once per mount, so the countdown and grace period stay put while the
  // story is open.
  let (now, _) = React.useState(() => Date.now())
  let p = presetOf(state)
  switch data.event {
  | Some(event) =>
    let start = StoryFixturesEventPage.tokyoEvening(now, 3)
    <div className="flex min-h-screen flex-col justify-end bg-gray-50 dark:bg-[#18191c]">
      <EventStickyFooter
        event={
          __id: event.__id,
          id: event.id,
          price: p.price,
          currency: p.price->Option.map(_ => "jpy"),
          startDate: Some(Date.fromTime(start)->Util.Datetime.fromDate),
          cancelDeadline: p.cancelDeadlineHours->Option.map(h => h * 60 * 60 * 1000),
          shadow: Some(p.shadow),
          externalUrl: p.externalUrl,
          deleted: p.cancelled
            ? Some(Date.fromTime(start -. 2. *. StoryFixturesEventPage.day)->Util.Datetime.fromDate)
            : None,
        }
        viewerUser={p.signedIn
          ? Some({
              EventStickyFooter.id: "user-1",
              lineUsername: Some("Chris"),
              email: Some("chris@example.com"),
            })
          : None}
        isJoined=p.isJoined
        isWaitlisted=p.isWaitlisted
        isPending=p.isPending
        isUnpaid=p.isUnpaid
        savedCard=?p.savedCard
        usingSavedCard=false
        savedCardError=?p.savedCardError
        onUseSavedCard
        viewerJoinTime={p.joinedMinutesAgo->Option.map(m =>
          now -. m *. StoryFixturesEventPage.minute
        )}
        isPaidEvent={p.price->Option.isSome}
        savedCardFlow=true
        isFull=p.isFull
        confirmedCount=p.confirmedCount
        waitlistCount=p.waitlistCount
        maxRsvps=p.maxRsvps
        tz="Asia/Tokyo"
        queryFragmentRefs=data.fragmentRefs
        hasComputedRating=true
        charging=false
        onPayClick
        cardRequiredOnJoin=p.cardRequiredOnJoin
        onJoinedNeedsCard
        chat={p.chat
          ? <PkEventMessages.FooterChat
              queryRef=data.fragmentRefs eventId=StoryFixturesEventPage.eventId
            />
          : React.null}
        fullWidth
      />
    </div>
  | None => React.null
  }
}
