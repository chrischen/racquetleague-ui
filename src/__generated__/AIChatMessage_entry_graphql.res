/* @sourceLoc AIChatMessage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_AgentMessage_action = {
    operationName: string,
    query: string,
    summary: string,
    variablesJson: string,
  }
  and fragment_UserMessage_actionResult = {
    operationName: string,
    proposalId: option<string>,
    resultJson: string,
  }
  @tag("__typename") type fragment = 
    | @live AgentMessage(
      {
        @live __typename: [ | #AgentMessage],
        action: option<fragment_AgentMessage_action>,
        content: string,
        @live id: string,
      }
    )
    | @live UserMessage(
      {
        @live __typename: [ | #UserMessage],
        actionResult: option<fragment_UserMessage_actionResult>,
        content: string,
        @live id: string,
      }
    )
    | @live @as("__unselected") UnselectedUnionMember(string)

}

@live
let unwrap_fragment: Types.fragment => Types.fragment = RescriptRelay_Internal.unwrapUnion(_, ["AgentMessage", "UserMessage"])
@live
let wrap_fragment: Types.fragment => Types.fragment = RescriptRelay_Internal.wrapUnion
module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"":{"u":"fragment"}}}`
  )
  @live
  let fragmentConverterMap = {
    "fragment": unwrap_fragment,
  }
  @live
  let convertFragment = v => v->RescriptRelay.convertObj(
    fragmentConverter,
    fragmentConverterMap,
    Js.undefined
  )
}

type t
type fragmentRef
external getFragmentRef:
  RescriptRelay.fragmentRefs<[> | #AIChatMessage_entry]> => fragmentRef = "%identity"

module Utils = {
  @@warning("-33")
  open Types
}

type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


let node: operationType = %raw(json` {
  "kind": "InlineDataFragment",
  "name": "AIChatMessage_entry"
} `)

