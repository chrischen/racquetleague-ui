// %%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
module Fragment = %relay(`
  fragment RsvpOptions_rsvp on Rsvp {
    user {
      id
    }
  }
`)

module RsvpOptionsDeleteMutation = %relay(`
 mutation RsvpOptionsDeleteMutation($connections: [ID!]!, $id: ID!, $userId: ID!) {
   deleteRsvpFromEvent(eventId: $id, userId: $userId) {
     eventIds @deleteEdge(connections: $connections)
     errors {
       message
     }
   }
 }
`)

@react.component
let make = (~rsvp, ~__id) => {
  let (commitMutationDeleteRsvp, _isMutationInFlight) = RsvpOptionsDeleteMutation.use()
  let rsvp = Fragment.use(rsvp)

  let onDeleteRsvp = userId => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      __id,
      "EventRsvps_event_rsvps",
      (),
    )
    commitMutationDeleteRsvp(
      ~variables={
        id: __id->RescriptRelay.dataIdToString,
        userId,
        connections: [connectionId],
      },
    )->RescriptRelay.Disposable.ignore
  }
  let (isOpen, setIsOpen) = React.useState(() => false)

  rsvp.user
  ->Option.map(user => {
    open Dropdown
    <>
      <Dropdown>
        <DropdownButton outline=true>
          <HeroIcons.ChevronDownIcon />
        </DropdownButton>
        <DropdownMenu>
          <DropdownItem
            onClick={e => {
              e->JsxEventU.Mouse.stopPropagation
              setIsOpen(_ => true)
            }}>
            {t`Remove from event`}
          </DropdownItem>
        </DropdownMenu>
      </Dropdown>
      <ConfirmDialog
        title={t`Remove this RSVP`}
        description={t`Are you sure you want to remove this person from the event?`}
        // confirmText={t`Leave`}
        // cancelText={t`Cancel`}
        setIsOpen
        isOpen
        onConfirmed={_ => {
          onDeleteRsvp(user.id)
        }}

        // Optional: specify confirm button color if default red is not desired
        // confirmButtonColor=#zinc
      />
    </>
  })
  ->Option.getOr(React.null)
}
