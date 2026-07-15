/* @sourceLoc AIAssistantEmbed.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type chatInput = RelaySchemaAssets_graphql.input_ChatInput
  @live type actionResultInput = RelaySchemaAssets_graphql.input_ActionResultInput
  @live
  type rec response_chat_messages = {
    @live __typename: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #AIChatMessage_entry]>,
  }
  @live
  and response_chat = {
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
    json`{"__root":{"chat_messages":{"f":""}}}`
  )
  @live
  let wrapResponseConverterMap = ()
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
    json`{"__root":{"chat_messages":{"f":""}}}`
  )
  @live
  let responseConverterMap = ()
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
    "kind": "Variable",
    "name": "input",
    "variableName": "input"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "content",
  "storageKey": null
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "operationName",
  "storageKey": null
},
v6 = {
  "kind": "InlineFragment",
  "selections": [
    (v3/*: any*/),
    (v4/*: any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "AgentActionResult",
      "kind": "LinkedField",
      "name": "actionResult",
      "plural": false,
      "selections": [
        (v5/*: any*/),
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "proposalId",
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "resultJson",
          "storageKey": null
        }
      ],
      "storageKey": null
    }
  ],
  "type": "UserMessage",
  "abstractKey": null
},
v7 = {
  "kind": "InlineFragment",
  "selections": [
    (v3/*: any*/),
    (v4/*: any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "AgentClientAction",
      "kind": "LinkedField",
      "name": "action",
      "plural": false,
      "selections": [
        (v5/*: any*/),
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "query",
          "storageKey": null
        },
        {
          "alias": "variablesJson",
          "args": null,
          "kind": "ScalarField",
          "name": "variables",
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "summary",
          "storageKey": null
        }
      ],
      "storageKey": null
    }
  ],
  "type": "AgentMessage",
  "abstractKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "suggestedEvents",
  "storageKey": null
},
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "error",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "AIAssistantEmbedChatMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
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
              (v2/*: any*/),
              {
                "kind": "InlineDataFragmentSpread",
                "name": "AIChatMessage_entry",
                "selections": [
                  (v2/*: any*/),
                  (v6/*: any*/),
                  (v7/*: any*/)
                ],
                "args": null,
                "argumentDefinitions": []
              }
            ],
            "storageKey": null
          },
          (v8/*: any*/),
          (v9/*: any*/)
        ],
        "storageKey": null
      }
    ],
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "AIAssistantEmbedChatMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
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
              (v2/*: any*/),
              {
                "kind": "TypeDiscriminator",
                "abstractKey": "__isChatEntry"
              },
              (v6/*: any*/),
              (v7/*: any*/)
            ],
            "storageKey": null
          },
          (v8/*: any*/),
          (v9/*: any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "d1bf266cc547e6c609babd96b23ee9a3",
    "id": null,
    "metadata": {},
    "name": "AIAssistantEmbedChatMutation",
    "operationKind": "mutation",
    "text": "mutation AIAssistantEmbedChatMutation(\n  $input: ChatInput!\n) {\n  chat(input: $input) {\n    messages {\n      __typename\n      ...AIChatMessage_entry\n    }\n    suggestedEvents\n    error\n  }\n}\n\nfragment AIChatMessage_entry on ChatEntry {\n  __isChatEntry: __typename\n  __typename\n  ... on UserMessage {\n    id\n    content\n    actionResult {\n      operationName\n      proposalId\n      resultJson\n    }\n  }\n  ... on AgentMessage {\n    id\n    content\n    action {\n      operationName\n      query\n      variablesJson: variables\n      summary\n    }\n  }\n}\n"
  }
};
})() `)


