// Storybook support for RouteModal.stories.tsx; the app never imports this.
// RouteModal is only chrome (backdrop, header with eyebrow/title/back/close,
// scrolling body), so each preset fills it with content like the routes that
// open it: a plan chooser, a step in a flow, a long policy text, a short
// confirmation.

let optionCard = (~icon, ~title, ~body, ~primary=false) =>
  <button
    type_="button"
    className={primary
      ? "flex w-full items-center gap-3 rounded-xl border border-[#94c93a] bg-[#bdf25d] p-4 text-left text-black"
      : "flex w-full items-center gap-3 rounded-xl border border-gray-200 bg-white p-4 text-left text-gray-900 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-100"}>
    <span
      className={primary
        ? "flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-black/10"
        : "flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-gray-100 dark:bg-[#2a2b30]"}>
      icon
    </span>
    <span className="min-w-0 flex-1">
      <span className="block text-sm font-semibold"> {title->React.string} </span>
      <span
        className={primary
          ? "mt-0.5 block text-xs leading-relaxed text-black/65"
          : "mt-0.5 block text-xs leading-relaxed text-gray-500 dark:text-gray-400"}>
        {body->React.string}
      </span>
    </span>
    <Lucide.ArrowRight size=17 className="flex-shrink-0" \"aria-hidden"="true" />
  </button>

let venues = [
  ("Shibuya Sports Center", "Court 3 · 1-40-18 Jinnan, Shibuya", "¥1,200 / hr"),
  ("Meguro Pickleball Park", "Outdoor · 2-4-36 Meguro", "¥900 / hr"),
  ("Setagaya Gym Annex", "Badminton hall · Setagaya 4-21", "¥1,500 / hr"),
  ("Toyosu Riverside Courts", "Covered · Toyosu 6-1, Koto", "¥1,000 / hr"),
]

let rules = [
  (
    "Arrival",
    "Please arrive 10 minutes before the start time so we can set up nets and assign the first round. Late arrivals join from the next rotation.",
  ),
  (
    "Payment",
    "The court fee is collected at the venue in cash (¥1,500) or charged to the card you saved when you RSVP'd. We don't give change for ¥10,000 notes.",
  ),
  (
    "Cancellations",
    "Cancel by 18:00 the day before so the next person on the waitlist can take your spot. Late cancellations still pay the court fee.",
  ),
  (
    "Equipment",
    "Bring indoor shoes with non-marking soles. Paddles are available to borrow; balls are provided (Franklin X-40 outdoors, Onix Fuse indoors).",
  ),
  (
    "Rotations",
    "Games are to 11, win by 2. Winners split, losers stay on the next court down. The organiser may rebalance teams to keep games close.",
  ),
  (
    "Photos",
    "We sometimes take photos for the club's LINE group. Tell the organiser if you'd rather not appear in them.",
  ),
  (
    "Safety",
    "Call the ball out loud, don't run across a live court, and stop play immediately if a ball rolls onto your court.",
  ),
  (
    "Venue rules",
    "No food on the court floor. Drinks in closed bottles only. Leave the changing rooms by 21:30 when the building closes.",
  ),
]

@genType @react.component
let make = (
  ~state: [#planChooser | #flowStep | #longContent | #titleOnly]=#planChooser,
  ~onClose=() => (),
  ~onBack=() => (),
) =>
  switch state {
  | #planChooser =>
    <RouteModal
      eyebrow={"New plan"->React.string}
      title={"Create an event"->React.string}
      description={"Create an event yourself, or from a court booking email."->React.string}
      onClose>
      <div className="space-y-3">
        {optionCard(
          ~icon=<Lucide.CalendarPlus size=19 \"aria-hidden"="true" />,
          ~title="Create Event Manually",
          ~body="Enter the event details yourself or ask the assistant to fill them in.",
          ~primary=true,
        )}
        {optionCard(
          ~icon=<Lucide.Mail size=19 \"aria-hidden"="true" />,
          ~title="Forward a booking email",
          ~body="Forward your court confirmation to chris@pkuru.com and we'll turn it into an event.",
        )}
      </div>
    </RouteModal>
  | #flowStep =>
    <RouteModal
      eyebrow={"Step 2 of 3"->React.string} title={"Choose a venue"->React.string} onBack onClose>
      <ul className="divide-y divide-gray-100 dark:divide-[#2a2b30]">
        {venues
        ->Array.map(((name, address, price)) =>
          <li key=name className="flex items-center justify-between gap-3 py-3">
            <div className="min-w-0">
              <div className="truncate text-sm font-medium text-gray-900 dark:text-gray-100">
                {name->React.string}
              </div>
              <div className="truncate text-xs text-gray-500 dark:text-gray-400">
                {address->React.string}
              </div>
            </div>
            <span className="font-mono text-xs text-gray-600 dark:text-gray-300">
              {price->React.string}
            </span>
          </li>
        )
        ->React.array}
      </ul>
    </RouteModal>
  | #longContent =>
    <RouteModal
      eyebrow={"Shibuya Pickleball Club"->React.string}
      title={"Club rules for Thursday Night Doubles at Shibuya Sports Center"->React.string}
      onClose>
      <div className="space-y-5">
        {rules
        ->Array.map(((heading, body)) =>
          <section key=heading>
            <h3 className="text-sm font-semibold text-gray-900 dark:text-gray-100">
              {heading->React.string}
            </h3>
            <p className="mt-1 text-sm leading-relaxed text-gray-600 dark:text-gray-400">
              {body->React.string}
            </p>
            <p className="mt-2 text-sm leading-relaxed text-gray-600 dark:text-gray-400">
              {body->React.string}
            </p>
          </section>
        )
        ->React.array}
      </div>
    </RouteModal>
  | #titleOnly =>
    <RouteModal title={"Leave this club?"->React.string} onClose>
      <p className="text-sm text-gray-600 dark:text-gray-400">
        {"You'll stop getting invites to Shibuya Pickleball Club events. Your match history and rating stay on your profile."->React.string}
      </p>
      <div className="mt-4 flex justify-end gap-2">
        <button
          type_="button"
          className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-semibold text-gray-800 dark:border-gray-700 dark:text-gray-200">
          {"Stay"->React.string}
        </button>
        <button
          type_="button"
          className="rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white">
          {"Leave club"->React.string}
        </button>
      </div>
    </RouteModal>
  }
