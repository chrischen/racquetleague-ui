%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// The viewer's events as a subscribable calendar feed: the webcal link opens
// the device's calendar app (Apple Calendar, Outlook); Google needs its own
// add-by-URL page. Also offered by the New plan modal (NewPlanChooserModal).
type provider = {label: string, url: string, initials: string}
let providers = userId => {
  let ts = Lingui.UtilString.t
  let feedUrl = "webcal://www.pkuru.com/cal-feed/" ++ userId
  [
    {label: ts`Apple iCal`, url: feedUrl, initials: "I"},
    {
      label: ts`Google Calendar`,
      url: "https://calendar.google.com/calendar/u/0/r?cid=" ++ Util.encodeURIComponent(feedUrl),
      initials: "G",
    },
  ]
}

module ProvidersMenu = {
  @react.component
  let make = (~userId: string) => {
    open Dropdown
    <DropdownMenu className="min-w-80 lg:min-w-64" anchor="bottom start">
      {providers(userId)
      ->Array.map(a =>
        <React.Fragment key={a.label}>
          <DropdownItem href=a.url>
            <Avatar slot="icon" initials=a.initials className="bg-purple-500 text-white" />
            <DropdownLabel> {a.label->React.string} </DropdownLabel>
          </DropdownItem>
          <DropdownDivider />
        </React.Fragment>
      )
      ->React.array}
    </DropdownMenu>
  }
}
module Anchor = {
  @react.component
  let make = (~children: React.element) => {
    <a href="#" onClick={e => e->JsxEventU.Mouse.preventDefault} className=""> {children} </a>
  }
}
@genType @react.component
let make = (~children: option<React.element>=?) => {
  open Dropdown
  let viewer = GlobalQuery.useViewer()

  <WaitForMessages>
    {() =>
      viewer.user
      ->Option.map(user =>
        <div className="items-center lg:text-sm inline-block">
          <Dropdown>
            {switch children {
            | Some(child) =>
              <DropdownButton \"as"={Navbar.NavbarItem.make}> {child} </DropdownButton>
            | None =>
              <DropdownButton \"as"={Navbar.NavbarItem.make}>
                <Lucide.CalendarPlus
                  className="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-500" \"aria-hidden"="true"
                />
                {t`sync calendar`}
              </DropdownButton>
            }}
            <ProvidersMenu userId=user.id />
          </Dropdown>
        </div>
      )
      ->Option.getOr(React.null)}
  </WaitForMessages>
}
