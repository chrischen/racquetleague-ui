/* @sourceLoc AIAssistantModal.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type chatInput = RelaySchemaAssets_graphql.input_ChatInput
  @live type actionResultInput = RelaySchemaAssets_graphql.input_ActionResultInput
  @tag("__typename") type response_chat_messages = 
    | @live AgentMessage(
      {
        @live __typename: [ | #AgentMessage],
        content: string,
      }
    )
    | @live @as("__unselected") UnselectedUnionMember(string)

  @live
  type rec response_chat = {
    error: option<string>,
    messages: array<response_chat_messages>,
    suggestedEvents: option<array<string>>,
  }
  @live
  type response = {
    chat: response_chat,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: chatInput,
  }
}

@live
let unwrap_response_chat_messages: Types.response_chat_messages => Types.response_chat_messages = RescriptRelay_Internal.unwrapUnion(_, ["AgentMessage"])
@live
let wrap_response_chat_messages: Types.response_chat_messages => Types.response_chat_messages = RescriptRelay_Internal.wrapUnion
module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"chatInput":{"actionResult":{"r":"actionResultInput"}},"actionResultInput":{},"__root":{"input":{"r":"chatInput"}}}`
  )
  @live
  let variablesConverterMap = ()
  @live
  let convertVariables = v => v->RescriptRelay.convertObj(
    variablesConverter,
    variablesConverterMap,
    Js.undefined
  )
  @live
  type wrapResponseRaw
  @live
  let wrapResponseConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"chat_messages":{"u":"response_chat_messages"}}}`
  )
  @live
  let wrapResponseConverterMap = {
    "response_chat_messages": wrap_response_chat_messages,
  }
  @live
  let convertWrapResponse = v => v->RescriptRelay.convertObj(
    wrapResponseConverter,
    wrapResponseConverterMap,
    Js.null
  )
  @live
  type responseRaw
  @live
  let responseConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"chat_messages":{"u":"response_chat_messages"}}}`
  )
  @live
  let responseConverterMap = {
    "response_chat_messages": unwrap_response_chat_messages,
  }
  @live
  let convertResponse = v => v->RescriptRelay.convertObj(
    responseConverter,
    responseConverterMap,
    Js.undefined
  )
  type wrapRawResponseRaw = wrapResponseRaw
  @live
  let convertWrapRawResponse = convertWrapResponse
  type rawResponseRaw = responseRaw
  @live
  let convertRawResponse = convertResponse
}
module Utils = {
  @@warning("-33")
  open Types
}

type relayOperationNode
type operationType = RescriptRelay.mutationNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "input"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "input",
        "variableName": "input"
      }
    ],
    "concreteType": "ChatResponse",
    "kind": "LinkedField",
    "name": "chat",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": null,
        "kind": "LinkedField",
        "name": "messages",
        "plural": true,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "__typename",
            "storageKey": null
          },
          {
            "kind": "InlineFragment",
            "selections": [
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "content",
                "storageKey": null
              }
            ],
            "type": "AgentMessage",
            "abstractKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "suggestedEvents",
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "error",
        "storageKey": null
      }
    ],
    "storageKey": null
  }
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "AIAssistantModalChatMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "AIAssistantModalChatMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "81a73e327cfb865bbdc12f76c8514803",
    "id": null,
    "metadata": {},
    "name": "AIAssistantModalChatMutation",
    "operationKind": "mutation",
    "text": "mutation AIAssistantModalChatMutation(\n  $input: ChatInput!\n) {\n  chat(input: $input) {\n    messages {\n      __typename\n      ... on AgentMessage {\n        content\n      }\n    }\n    suggestedEvents\n    error\n  }\n}\n"
  }
};
})() `)


