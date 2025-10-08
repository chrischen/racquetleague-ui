%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
open LangProvider.Router

type joinedStatus = Pending | Going | Waitlisted
type notJoinedStatus = JoinWaitlist | Join | Login
type status = Joined(joinedStatus) | NotJoined(notJoinedStatus)

@react.component
let make = (~onClick, ~status: status, ~className: string, ~requireConfirmation: bool= false) => {
  let colorClassName = switch status {
  | Joined(Pending) => "bg-red-100 text-red-800"
  | Joined(Going) => "bg-green-600 text-white"
  | Joined(Waitlisted) => "bg-yellow-100 text-yellow-800"
  | NotJoined(JoinWaitlist) => "bg-yellow-100 text-yellow-800 hover:bg-yellow-200"
  | NotJoined(Join) => "bg-green-100 text-green-800 hover:bg-green-200"
  | NotJoined(Login) => "bg-blue-100 text-blue-800 hover:bg-blue-200"
  }

  let buttonText = switch status {
  | Joined(Pending) => t`RSVP Pending...`
  | Joined(Going) => t`You're Going`
  | Joined(Waitlisted) => t`You're Waitlisted`
  | NotJoined(JoinWaitlist) => t`Join Waitlist`
  | NotJoined(Join) => t`Join Event`
  | NotJoined(Login) => t`Login to Join`
  }

  let buttonClassName = `${className} ${colorClassName}`

  switch status {
  | NotJoined(Login) =>
    <Link to="/oauth-login" className=buttonClassName>
      <Lucide.Check size=16 />
      <span> {buttonText} </span>
    </Link>
  | Joined(Going) | Joined(Waitlisted) | Joined(Pending) =>
    requireConfirmation
    ? <ConfirmButton
        button={
          <button type_="button" className=buttonClassName>
            <Lucide.Check size=16 />
            <span> {buttonText} </span>
          </button>
        }
        title={t`You will lose your spot`}
        description={t`This event is full, so leaving the event will give your spot to someone on the waitlist. If you rejoin, you will join the waitlist. Are you sure you want to leave this event?`}
        onConfirmed={onClick}
      />
    : <button onClick={_ => onClick()} className=buttonClassName>
        <Lucide.Check size=16 />
        <span> {buttonText} </span>
      </button>
  | NotJoined(JoinWaitlist) | NotJoined(Join) =>
    <button onClick={_ => onClick()} className=buttonClassName>
      <Lucide.Check size=16 />
      <span> {buttonText} </span>
    </button>
  }
}
