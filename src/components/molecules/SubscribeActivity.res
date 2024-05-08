%%raw("import { t } from '@lingui/macro'")
module SubscribeActivityMutation = %relay(`
 mutation SubscribeActivityMutation(
    $input: CreateActivitySubscriptionInput!
  ) {
    createActivitySubscription(input: $input) {
      activity {
        id
        sub {
          id
        }
      }
      errors {
        message
      }
    }
  }
`)
module SubscribeActivityDeleteMutation = %relay(`
 mutation SubscribeActivityDeleteMutation(
    $input: DeleteActivitySubscriptionInput!
  ) {
    deleteActivitySubscription(input: $input) {
      activity {
        id
        sub {
          id
        }
      }
      errors {
        message
      }
    }
  }
`)
module Fragment = %relay(`
  fragment SubscribeActivity_activity on Activity {
		id
    name
		sub {
      id
    }
  }
`)
@genType @react.component
let make = (~activity) => {
  open Lingui.Util
  let td = Lingui.UtilString.dynamic
  let {id, name, sub} = Fragment.use(activity)

  let (commitMutationSubscribe, _isMutationInFlight) = SubscribeActivityMutation.use()
  let (commitMutationUnsubscribe, _isMutationInFlight) = SubscribeActivityDeleteMutation.use()
  let activityName = name->Option.map(name => td(name))->Option.getOr("")
  switch sub {
  | Some(sub) =>
    <>
      <a
        href="#"
        onClick={e => {
          e->JsxEventU.Mouse.preventDefault
          commitMutationUnsubscribe(~variables={input: {subscriptionId: sub.id}})->ignore
        }}>
        {"<- "->React.string}{t`unsubscribe from ${activityName} events`}{" "->React.string}
      </a>
        {t`you will receive email notifications for new events`}
    </>
  | None =>
    <>
      <a
        href="#"
        onClick={e => {
          e->JsxEventU.Mouse.preventDefault
          commitMutationSubscribe(~variables={input: {activityId: id}})->ignore
        }}>
        {"-> "->React.string}
        {t`subscribe to all ${activityName} events`}
      </a>
    </>
  }
}

let td = Lingui.UtilString.td
@live
td({id: "Badminton"})->ignore
@live
td({id: "Table Tennis"})->ignore
@live
td({id: "Pickleball"})->ignore
@live
td({id: "Futsal"})->ignore
