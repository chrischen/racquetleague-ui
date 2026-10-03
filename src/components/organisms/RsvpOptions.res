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
    payment {
      id
      # Status values: 0 = Authorized (legacy hold), 1 = Charged, 2 = Refunded,
      # 3 = Charge failed (card still on file), 4 = Pending, 5 = Card on file
      status
      # Whether the row is in a state the server would charge (or capture);
      # whether the event can collect at all is Event.chargesEnabled.
      chargeable
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

// Charges the card the player saved (or captures a legacy hold). A declined
// charge returns the payment too, now status 3, together with the error.
module RsvpOptionsCapturePaymentMutation = %relay(`
  mutation RsvpOptionsCapturePaymentMutation($paymentId: ID!) {
    captureRsvpPayment(paymentId: $paymentId) {
      payment {
        id
        status
        chargeable
      }
      errors {
        message
      }
    }
  }
`)

module RsvpOptionsRefundPaymentMutation = %relay(`
  mutation RsvpOptionsRefundPaymentMutation($paymentId: ID!) {
    refundRsvpPayment(paymentId: $paymentId) {
      payment {
        id
        status
      }
      errors {
        message
      }
    }
  }
`)

@react.component
// chargesEnabled: the event's payment account can collect (Event.chargesEnabled).
// Without it the charge actions are hidden: a platform-mode event has nothing
// to charge to.
let make = (
  ~rsvp,
  ~eventId,
  ~eventActivitySlug,
  ~isAdmin=false,
  ~chargesEnabled=false,
  ~connectionKey="RSVPSection_event_rsvps",
  ~triggerClassName="w-full text-left",
  // The viewer's conversation with this person, when they have one about the
  // event (an invite's note): offered as a menu item.
  ~threadPath: option<string>=?,
  ~children,
) => {
  let (commitMutationDeleteRsvp, _isMutationInFlight) = RsvpOptionsDeleteMutation.use()
  let (
    commitMutationUpdateListType,
    _isUpdateMutationInFlight,
  ) = RsvpOptionsUpdateListTypeMutation.use()
  let (commitCapturePayment, _) = RsvpOptionsCapturePaymentMutation.use()
  let (commitRefundPayment, _) = RsvpOptionsRefundPaymentMutation.use()
  let rsvp = Fragment.use(rsvp)
  let nav = LangProvider.Router.useNavigate()

  let onDeleteRsvp = userId => {
    let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
      eventId->RescriptRelay.makeDataId,
      connectionKey,
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
  // The last charge/refund failure for this RSVP, shown under the trigger.
  let (paymentError, setPaymentError) = React.useState(() => None)

  let onChargePayment = paymentId => {
    setPaymentError(_ => None)
    commitCapturePayment(
      ~variables={paymentId: paymentId},
      ~onCompleted=(response, _) =>
        setPaymentError(_ =>
          response.captureRsvpPayment.errors
          ->Option.flatMap(errors => errors->Array.get(0))
          ->Option.map(e => e.message)
        ),
    )->RescriptRelay.Disposable.ignore
  }

  let onRefundPayment = paymentId => {
    setPaymentError(_ => None)
    commitRefundPayment(
      ~variables={paymentId: paymentId},
      ~onCompleted=(response, _) =>
        setPaymentError(_ =>
          response.refundRsvpPayment.errors
          ->Option.flatMap(errors => errors->Array.get(0))
          ->Option.map(e => e.message)
        ),
    )->RescriptRelay.Disposable.ignore
  }

  open Dropdown
  <>
    <Dropdown>
      <HeadlessUi.MenuButton className={triggerClassName}> {children} </HeadlessUi.MenuButton>
      <DropdownMenu className="z-[60]">
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
        {switch threadPath {
        | Some(path) =>
          <DropdownItem onClick={_ => nav(path, None)}> {t`View message thread`} </DropdownItem>
        | None => React.null
        }}
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
              {switch rsvp.payment {
              | Some({id: paymentId, status: 5, chargeable: true}) if chargesEnabled =>
                <DropdownItem onClick={_ => onChargePayment(paymentId)}>
                  {t`Charge payment`}
                </DropdownItem>
              | Some({id: paymentId, status: 3, chargeable: true}) if chargesEnabled =>
                <DropdownItem onClick={_ => onChargePayment(paymentId)}>
                  {t`Retry charge`}
                </DropdownItem>
              | Some({id: paymentId, status: 0, chargeable: true}) if chargesEnabled =>
                <DropdownItem onClick={_ => onChargePayment(paymentId)}>
                  {t`Capture payment`}
                </DropdownItem>
              | Some({id: paymentId, status: 1}) =>
                <DropdownItem onClick={_ => onRefundPayment(paymentId)}>
                  {t`Refund payment`}
                </DropdownItem>
              | _ => React.null
              }}
            </>
          : React.null}
      </DropdownMenu>
    </Dropdown>
    {switch paymentError {
    | Some(message) =>
      <span className="block font-mono text-[10px] text-red-500 dark:text-red-400 leading-tight">
        {message->React.string}
      </span>
    | None => React.null
    }}
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
