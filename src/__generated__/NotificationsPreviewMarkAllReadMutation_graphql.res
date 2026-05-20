/* @sourceLoc NotificationsPreview.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_markAllInboxRead_viewerMetadata = {
    @live id: string,
    unreadInboxCount: int,
  }
  @live
  and response_markAllInboxRead = {
    viewerMetadata: option<response_markAllInboxRead_viewerMetadata>,
  }
  @live
  type response = {
    markAllInboxRead: response_markAllInboxRead,
  }
  @live
  type rawResponse = response
  @live
  type variables = unit
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{}`
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
    json`{}`
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
    json`{}`
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
    "alias": null,
    "args": null,
    "concreteType": "MarkInboxReadResult",
    "kind": "LinkedField",
    "name": "markAllInboxRead",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "ViewerMetadata",
        "kind": "LinkedField",
        "name": "viewerMetadata",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "id",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "unreadInboxCount",
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "storageKey": null
  }
];
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "NotificationsPreviewMarkAllReadMutation",
    "selections": (v0/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "NotificationsPreviewMarkAllReadMutation",
    "selections": (v0/*: any*/)
  },
  "params": {
    "cacheID": "00c9dab8faa27a4391aa4ec23e4a4d19",
    "id": null,
    "metadata": {},
    "name": "NotificationsPreviewMarkAllReadMutation",
    "operationKind": "mutation",
    "text": "mutation NotificationsPreviewMarkAllReadMutation {\n  markAllInboxRead {\n    viewerMetadata {\n      id\n      unreadInboxCount\n    }\n  }\n}\n"
  }
};
})() `)


