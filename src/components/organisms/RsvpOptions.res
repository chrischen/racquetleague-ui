// %%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
module Fragment = %relay(`
  fragment RsvpOptions_rsvp on Rsvp {
    id
    listType
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

module RsvpOptionsUpdateListTypeMutation = %relay(`
 mutation RsvpOptionsUpdateListTypeMutation($input: UpdateRsvpListTypeInput!) {
   updateRsvpListType(input: $input) {
     rsvp {
       id
       listType
     }
     errors {
       message
     }
   }
 }
`)

@react.component
let make = (~rsvp, ~eventId, ~eventActivitySlug, ~isAdmin=false, ~children) => {
  let (commitMutationDeleteRsvp, _isMutationInFlight) = RsvpOptionsDeleteMutation.use()
  let (
    commitMutationUpdateListType,
    _isUpdateMutationInFlight,
  ) = RsvpOptionsUpdateListTypeMutation.use()
  let rsvp = Fragment.use(rsvp)
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

  let onUpdateListType = (rsvpId, listType) => {
    commitMutationUpdateListType(
      ~variables={
        input: {
          rsvpId,
          listType,
        },
      },
    )->RescriptRelay.Disposable.ignore
  }

  let (isOpen, setIsOpen) = React.useState(() => false)
  let (isUpdateDialogOpen, setIsUpdateDialogOpen) = React.useState(() => false)

  open Dropdown
  <>
    <Dropdown>
      <DropdownButton \"as"={Router.Link.make}> {children} </DropdownButton>
      <DropdownMenu>
        {rsvp.user
        ->Option.map(user =>
          <DropdownItem
            onClick={_ => {
              nav("/league/" ++ eventActivitySlug ++ "/p/" ++ user.id, None)
            }}>
            {t`View Profile`}
          </DropdownItem>
        )
        ->Option.getOr(React.null)}
        {isAdmin
          ? <>
              {switch rsvp.listType {
              | Some(1) =>
                <DropdownItem
                  onClick={_ => {
                    onUpdateListType(rsvp.id, 0)
                  }}>
                  {t`Approve RSVP`}
                </DropdownItem>
              | Some(0) | None =>
                <DropdownItem
                  onClick={e => {
                    e->JsxEventU.Mouse.stopPropagation
                    setIsUpdateDialogOpen(_ => true)
                  }}>
                  {t`Move to Pending List`}
                </DropdownItem>
              | _ => React.null
              }}
              <DropdownItem
                onClick={e => {
                  e->JsxEventU.Mouse.stopPropagation
                  setIsOpen(_ => true)
                }}>
                {t`Remove from event`}
              </DropdownItem>
            </>
          : React.null}
      </DropdownMenu>
    </Dropdown>
    {rsvp.user
    ->Option.map(user =>
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
    )
    ->Option.getOr(React.null)}
    <ConfirmDialog
      title={t`Move to Pending List`}
      description={t`This user will be removed from the Going/Waitlist. Their position will be lost if you move them back in. Are you sure you want to restrict their RSVP?`}
      setIsOpen={setIsUpdateDialogOpen}
      isOpen={isUpdateDialogOpen}
      onConfirmed={_ => {
        onUpdateListType(rsvp.id, 1)
      }}
    />
  </>
}
