%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
module ProvidersMenu = {
  type navItem = {label: string, url: string, initials?: string}
  let ts = Lingui.UtilString.t
  @react.component
  let make = (~userId: string) => {
    open Dropdown
    let activities = [
      {label: ts`Apple iCal`, url: "webcal://www.pkuru.com/cal-feed/" ++ userId, initials: "I"},
      {
        label: ts`Google Calendar`,
        url: "https://calendar.google.com/calendar/u/0/r?cid=" ++
        Util.encodeURIComponent("webcal://www.pkuru.com/cal-feed/" ++ userId),
        initials: "G",
      },
    ]
    <DropdownMenu className="min-w-80 lg:min-w-64" anchor="bottom start">
      {activities
      ->Array.map(a =>
        <React.Fragment key={a.label}>
          <DropdownItem href=a.url>
            {a.initials
            ->Option.map(initials =>
              <Avatar slot="icon" initials className="bg-purple-500 text-white" />
            )
            ->Option.getOr(React.null)}
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
  let make = (~href: string, ~children: React.element) => {
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
