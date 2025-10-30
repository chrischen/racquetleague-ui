/* @sourceLoc AIAssistantModal.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type chatInput = RelaySchemaAssets_graphql.input_ChatInput
  @live
  type rec response_chat_message = {
    content: string,
    messageType: RelaySchemaAssets_graphql.enum_MessageType,
  }
  @live
  and response_chat_suggestedEvents = {
    address: string,
    details: option<string>,
    endDate: Util.Datetime.t,
    maxRsvps: option<int>,
    startDate: Util.Datetime.t,
    timezone: option<string>,
    title: string,
  }
  @live
  and response_chat = {
    error: option<string>,
    message: option<response_chat_message>,
    suggestedEvents: option<array<response_chat_suggestedEvents>>,
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

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"chatInput":{},"__root":{"input":{"r":"chatInput"}}}`
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
    json`{"__root":{"chat_suggestedEvents_startDate":{"c":"Util.Datetime"},"chat_suggestedEvents_endDate":{"c":"Util.Datetime"}}}`
  )
  @live
  let wrapResponseConverterMap = {
    "Util.Datetime": Util.Datetime.serialize,
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
    json`{"__root":{"chat_suggestedEvents_startDate":{"c":"Util.Datetime"},"chat_suggestedEvents_endDate":{"c":"Util.Datetime"}}}`
  )
  @live
  let responseConverterMap = {
    "Util.Datetime": Util.Datetime.parse,
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
  @live
  external messageType_toString: RelaySchemaAssets_graphql.enum_MessageType => string = "%identity"
  @live
  external messageType_input_toString: RelaySchemaAssets_graphql.enum_MessageType_input => string = "%identity"
  @live
  let messageType_decode = (enum: RelaySchemaAssets_graphql.enum_MessageType): option<RelaySchemaAssets_graphql.enum_MessageType_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let messageType_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_MessageType_input> => {
    messageType_decode(Obj.magic(str))
  }
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
        "concreteType": "ChatMessage",
        "kind": "LinkedField",
        "name": "message",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "content",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "messageType",
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "SuggestedEvent",
        "kind": "LinkedField",
        "name": "suggestedEvents",
        "plural": true,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "title",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "startDate",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "endDate",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "timezone",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "address",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "details",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "maxRsvps",
            "storageKey": null
          }
        ],
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
    "cacheID": "ccd3e83b9b50cbe2343aea753cf052d2",
    "id": null,
    "metadata": {},
    "name": "AIAssistantModalChatMutation",
    "operationKind": "mutation",
    "text": "mutation AIAssistantModalChatMutation(\n  $input: ChatInput!\n) {\n  chat(input: $input) {\n    message {\n      content\n      messageType\n    }\n    suggestedEvents {\n      title\n      startDate\n      endDate\n      timezone\n      address\n      details\n      maxRsvps\n    }\n    error\n  }\n}\n"
  }
};
})() `)


