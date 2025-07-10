%%raw("import { t } from '@lingui/macro'")

@react.component
let make = () => {
  open Lingui.Util
  open LangProvider.Router

  <WaitForMessages>
    {_ =>
      <div className="bg-white px-6 py-14 sm:py-14 lg:px-8">
        <div className="mx-auto max-w-2xl">
          <div className="text-lg leading-8 text-gray-600">
            <h1 className="mt-2 text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
              {t`How to Play Pickleball in Tokyo`}
            </h1>
            <p className="mt-6">
              {t`Japan does not really have public drop in courts or games. Most pickleball games happen indoors at community center and school gymnasiums (multi-use gyms) or on private tennis/pickleball courts and these all require reservations for court time, or reservations to join the events. Many of the public facilities do not allow groups to advertise to the public, which makes it difficult for new players or visitors to drop in on sessions.`}
            </p>
            <p className="mt-8">
              {t`So, how can one play pickleball in Tokyo then as a tourist, recent transplant, or a beginner?`}
            </p>
            <ol className="mt-8 space-y-4 list-decimal list-inside">
              <li>
                {t`Join any public events on Pkuru.com (this website). If you find an event without the 'lock' icon and which has a join button, then you can join.`}
              </li>
              <li> {t`Book a court and find the players yourself.`} </li>
              <li> {t`Message @japanpickle on Instagram for referrals or questions`} </li>
            </ol>
            <h2 className="mt-8 text-2xl font-semibold"> {t`Where to Book Courts in Tokyo`} </h2>
            <ol className="mt-4 space-y-4 list-decimal list-inside">
              <li>
                {t`KPI Park in Kanagawa/Yokohama`}
                <p className="mt-1 text-sm text-gray-500">
                  {t`The courts require reservations but there are 10 courts and it's generally available last minute. Therefore you can book the courts just-in-time once you've already gathered the players.`}
                </p>
                <div className="mt-4">
                  <Link to={"/events/create/Location_504589b2-9827-11ef-ac7c-43e61917aa71"}>
                    <Button.Button target="_blank" rel="noopener noreferrer">
                      {t`Create an Event at KPI Park`}
                    </Button.Button>
                  </Link>
                  <Link
                    className="ml-4 text-sm font-semibold leading-6 text-indigo-600 hover:text-indigo-500"
                    to={"https://labola.jp/r/shop/3302/calendar_week/2025/7/9/?tab_name=ピックルボールコート"}
                    rel="noopener noreferrer"
                    target="_blank">
                    {t`Book the Court`}
                  </Link>
                </div>
              </li>
              <li>
                {t`Pacific Pickle Club at Ariake`}
                <p className="mt-1 text-sm text-gray-500">
                  {t`The courts require reservations but there are only 2 courts so you will need to book in advance. They also hold open play sessions but the level may be low to complete beginner.`}
                </p>
                <div className="mt-4">
                  <Link to={"/events/create/Location_a5fdf9fc-8152-11ef-8bf7-fb8fc45779c3"}>
                    <Button.Button target="_blank" rel="noopener noreferrer">
                      {t`Create an Event at Pacific Pickle Club`}
                    </Button.Button>
                  </Link>
                  <Link
                    className="ml-4 text-sm font-semibold leading-6 text-indigo-600 hover:text-indigo-500"
                    to={"https://pacificpickleclub.resv.jp"}
                    rel="noopener noreferrer"
                    target="_blank">
                    {t`Book the Court`}
                  </Link>
                </div>
              </li>
              <li>
                {t`Tokyo Tower Pickleball`}
                <p className="mt-1 text-sm text-gray-500">
                  {t`Two courts are available. Conditions may be windy.`}
                </p>
                <div className="mt-4">
                  <Link to={"/events/create/Location_c90c6b20-5ae8-11f0-932c-f75ab31d2681"}>
                    <Button.Button target="_blank" rel="noopener noreferrer">
                      {t`Create an Event at Tokyo Tower Pickleball`}
                    </Button.Button>
                  </Link>
                  <Link
                    className="ml-4 text-sm font-semibold leading-6 text-indigo-600 hover:text-indigo-500"
                    to={"http://tokyotower-pickleball.jp/calendar.html"}
                    rel="noopener noreferrer"
                    target="_blank">
                    {t`Book the Court`}
                  </Link>
                </div>
              </li>
              <li>
                {t`Hilton Tokyo Tennis Courts (painted lines)`}
                <p className="mt-1 text-sm text-gray-500">
                  {t`Two courts are available. More expensive than other courts and the conditions can be windy.`}
                </p>
                <div className="mt-4">
                  <Link to={"/events/create/Location_721dd0be-e90b-11ef-94f2-b7fe1b506e52"}>
                    <Button.Button target="_blank" rel="noopener noreferrer">
                      {t`Create an Event at Hilton Tokyo Tennis Courts`}
                    </Button.Button>
                  </Link>
                  <Link
                    className="ml-4 text-sm font-semibold leading-6 text-indigo-600 hover:text-indigo-500"
                    to={"https://tokyo.hiltonjapan.co.jp/pdf/facilities/pickleball-price-list.pdf"}
                    rel="noopener noreferrer"
                    target="_blank">
                    {t`Book the Court`}
                  </Link>
                </div>
              </li>
            </ol>
            <h2 className="mt-8 text-2xl font-semibold"> {t`How to Find Players in Tokyo`} </h2>
            <ol className="mt-4 space-y-4 list-decimal list-inside">
              <li>
                {t`Create an event at one of the locations above (use the buttons above). Make the event public so people can join you.`}
              </li>
              <li>
                {t`Post it to the Yokosuka (US navy base) pickleball group on Facebook:`}
                {" "->React.string}
                <Link to="https://www.facebook.com/groups/24408666593863959" target="_blank">
                  {"https://www.facebook.com/groups/24408666593863959"->React.string}
                </Link>
              </li>
              <li>
                {t`Post it to the JPAA group on Facebook (mostly Japanese)`}
                {" "->React.string}
                <Link to="https://www.facebook.com/groups/picklejp" target="_blank">
                  {"https://www.facebook.com/groups/picklejp"->React.string}
                </Link>
              </li>
            </ol>
            <h2 className="mt-8 text-2xl font-semibold"> {t`How to Find Public Games`} </h2>
            <p className="mt-6">
              {t`As mentioned above, public games are not really a thing in Japan. However, you can find some public games on the home page of this website. They will tend to be full with a waitlist so just join the waitlist and cross your fingers. 5-6 spots tend to open up the day of the event as people cancel last minute. `}
            </p>
            <p className="mt-4">
              {t`Some events are restricted by level. If you are restricted, just type in your DUPR rating as a comment with your RSVP.`}
            </p>
            <p className="mt-4">
              <strong>
                {t`Please do not show up to any events without permission and only if you are in the confirmed going list. Indoor events always require a set of clean indoor only court shoes. They are really serious about this stuff in Japan.`}
              </strong>
            </p>
          </div>
        </div>
      </div>}
  </WaitForMessages>
}
