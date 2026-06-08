// Animated collapsible list of availability user rows.
// The caller is responsible for the toggle button; this renders only the body.

@react.component
let make = (
  ~userDays: array<AvailabilityUserRow.userDay>,
  ~open_: bool,
  ~innerClassName: string="space-y-1.5 px-3 pb-2.5",
) => {
  open_
    ? <FramerMotion.Div
        className="overflow-hidden"
        initial={{FramerMotion.height: "0px", opacity: 0.}}
        animate={{FramerMotion.height: "auto", opacity: 1.}}
        exit={{FramerMotion.height: "0px", opacity: 0.}}>
        <div className={innerClassName}>
          {userDays
          ->Array.map(ud => {
            let key = ud.user->Option.map(u => u.id)->Option.getOr(ud.id)
            <AvailabilityUserRow key userDay=ud />
          })
          ->React.array}
        </div>
      </FramerMotion.Div>
    : React.null
}
