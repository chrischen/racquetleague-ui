%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

type joinedStatus = Pending | Going | Waitlisted
type notJoinedStatus = JoinWaitlist | Join

type status = Joined(joinedStatus) | NotJoined(notJoinedStatus)

@react.component
let make = (~status: status) => {
  let text = switch status {
  | Joined(Pending) => t`RSVP Pending...`
  | Joined(Going) => t`You're Going`
  | Joined(Waitlisted) => t`You're Waitlisted`
  | NotJoined(JoinWaitlist) => t`Join Waitlist`
  | NotJoined(Join) => t`Join Event`
  }

  <> {text} </>
}
