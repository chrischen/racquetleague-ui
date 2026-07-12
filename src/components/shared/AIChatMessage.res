// Single shared decode + turn-derivation for the AI chat feature.
//
// The wire union `ChatEntry` is selected via ONE `@inline` fragment spread in
// both the `chat` mutation response and the `chatMessages` history query, so a
// live turn and a reloaded turn are decoded through exactly this code — there is
// no live-vs-persisted divergence. `fromFragmentRef` maps the union to the
// canonical `AITypes.chatMessage`; `deriveTurns` turns an ordered message list
// into the display turns the UI renders.

module Fragment = %relay(`
  fragment AIChatMessage_entry on ChatEntry @inline {
    __typename
    ... on UserMessage {
      id
      content
      actionResult {
        operationName
        proposalId
        resultJson
      }
    }
    ... on AgentMessage {
      id
      content
      action {
        operationName
        query
        variablesJson: variables
        summary
      }
    }
  }
`)

// Decode one inline-fragment ref into the canonical client message. Returns None
// for an unknown/unselected union member (forward-compatible with new members).
let fromFragmentRef = (fragmentRef): option<AITypes.chatMessage> => {
  switch Fragment.readInline(fragmentRef) {
  | UserMessage(u) =>
    let actionResult = u.actionResult->Belt.Option.map((ar): AITypes.actionResult => {
      operationName: ar.operationName,
      proposalId: ar.proposalId,
      resultJson: ar.resultJson,
    })
    Some(AITypes.UserMessage({id: u.id, content: u.content, actionResult}))
  | AgentMessage(a) =>
    let action = a.action->Belt.Option.map((ac): AITypes.pendingAction => {
      operationName: ac.operationName,
      query: ac.query,
      variablesJson: ac.variablesJson,
      summary: ac.summary,
    })
    Some(AITypes.AgentMessage({id: a.id, content: a.content, action}))
  | UnselectedUnionMember(_) => None
  }
}

// Classify an executed proposal's result JSON into a terminal status. Mirrors
// the semantics the approve/deny flow produces: `{"cancelled":true}` → Denied,
// a non-empty GraphQL `errors` array → failed execution, otherwise success.
let classifyResult = (resultJson: string): AITypes.proposalStatus => {
  switch Js.Json.parseExn(resultJson)->Js.Json.decodeObject {
  | Some(obj) =>
    let isCancelled =
      Js.Dict.get(obj, "cancelled")
      ->Option.flatMap(v => v->Js.Json.decodeBoolean)
      ->Option.getOr(false)
    if isCancelled {
      Denied
    } else {
      let hasErrors =
        Js.Dict.get(obj, "errors")
        ->Option.flatMap(v => v->Js.Json.decodeArray)
        ->Option.map(errors => errors->Array.length > 0)
        ->Option.getOr(false)
      Executed({wasSuccessful: !hasErrors, details: None})
    }
  | None => Executed({wasSuccessful: true, details: None})
  | exception _ => Executed({wasSuccessful: true, details: None})
  }
}

// Derive the display turns from the canonical ordered message list. Pure — the
// SAME function serves live turns and reloaded history.
//
// - A UserMessage carrying `actionResult` is a status carrier only (hidden); it
//   flips the matching proposal's derived status.
// - An AgentMessage carrying `action` is a ProposalTurn. Its status comes from
//   the transient `overlay` (in-flight Approve/Deny) if present, else from a
//   matching action-result message, else Pending (still actionable — the real
//   query/variables are on the message).
// - Plain UserMessage/AgentMessage become User/Assistant turns. `enrichments`
//   attaches a live turn's suggestedEvents (never persisted) to its agent bubble.
let deriveTurns = (
  messages: array<AITypes.chatMessage>,
  ~overlay: Belt.Map.String.t<AITypes.proposalStatus>,
  ~enrichments: Belt.Map.String.t<array<AITypes.eventDetails>>,
): array<AITypes.chatTurn> => {
  // proposalId -> resultJson, from every action-result message in the list.
  let resultsByProposal =
    messages->Belt.Array.reduce(Belt.Map.String.empty, (acc, message) =>
      switch message {
      | AITypes.UserMessage({actionResult: Some({proposalId: Some(pid), resultJson})}) =>
        acc->Belt.Map.String.set(pid, resultJson)
      | _ => acc
      }
    )

  messages->Belt.Array.keepMap(message =>
    switch message {
    | AITypes.UserMessage({actionResult: Some(_)}) => None // status carrier, hidden
    | AITypes.UserMessage({id, content}) => Some(AITypes.UserTurn({id, content}))
    | AITypes.AgentMessage({id, action: Some(action)}) =>
      let status = switch overlay->Belt.Map.String.get(id) {
      | Some(s) => s
      | None =>
        switch resultsByProposal->Belt.Map.String.get(id) {
        | Some(resultJson) => classifyResult(resultJson)
        | None => Pending
        }
      }
      Some(AITypes.ProposalTurn({id, action, status}))
    | AITypes.AgentMessage({id, content}) =>
      let suggestedEvents = enrichments->Belt.Map.String.get(id)
      Some(
        AITypes.AssistantTurn({
          id,
          response: {summary: content, eventDetails: None, suggestedEvents},
        }),
      )
    }
  )
}
