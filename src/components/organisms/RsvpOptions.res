// %%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
module Fragment = %relay(`
  fragment RsvpOptions_user on User {
      id
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
let make = (~user, ~eventId, ~eventActivitySlug, ~isAdmin=false, ~children) => {
  let (commitMutationDeleteRsvp, _isMutationInFlight) = RsvpOptionsDeleteMutation.use()
  let user = Fragment.use(user)
  let nav = LangProvider.Router.useNavigate()

  let onDeleteRsvp = userId => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      eventId->RescriptRelay.makeDataId,
      "RSVPSection_event_rsvps",
      (),
    )
    commitMutationDeleteRsvp(
      ~variables={
        id: eventId,
        userId,
        connections: [connectionId],
      },
    )->RescriptRelay.Disposable.ignore
  }
  let (isOpen, setIsOpen) = React.useState(() => false)

  open Dropdown
  <>
    <Dropdown>
      <DropdownButton \"as"={Router.Link.make}> {children} </DropdownButton>
      <DropdownMenu>
        <DropdownItem
          onClick={e => {
            nav("/league/" ++ eventActivitySlug ++ "/p/" ++ user.id, None)
          }}>
          {t`View Profile`}
        </DropdownItem>
        {isAdmin
          ? <DropdownItem
              onClick={e => {
                e->JsxEventU.Mouse.stopPropagation
                setIsOpen(_ => true)
              }}>
              {t`Remove from event`}
            </DropdownItem>
          : React.null}
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
}
