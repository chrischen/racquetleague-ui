// Shared type definitions for AI Assistant feature
type eventDetails = {
  title: string,
  date: string,
  time: string,
  location: option<string>,
  description: option<string>,
  maxRsvps: option<int>,
  // The full parsed suggested-event draft (a `CreateEventInput`-shaped object,
  // keys matching the mutation's fields). The display fields above are extracted
  // from it for rendering; `rawFields` carries everything else (minRating, price,
  // tags, cancelDeadline, listed, timezone, …) so new event fields reach the
  // create-form prefill with no per-field wiring here.
  rawFields?: Js.Dict.t<Js.Json.t>,
}

type aiResponse = {
  summary: string,
  eventDetails: option<eventDetails>,
  suggestedEvents: option<array<eventDetails>>,
}

type pendingAction = {
  operationName: string,
  query: string,
  variablesJson: string,
  summary: string,
}

// The outcome of an executed (or denied) proposal, decoded from the server's
// `AgentActionResult`. `proposalId` links it back to the proposal it resolves.
type actionResult = {
  operationName: string,
  proposalId: option<string>,
  resultJson: string,
}

// Client mirror of the wire union `ChatEntry`. A proposal IS an `AgentMessage`
// carrying `action`; a proposal outcome IS a `UserMessage` carrying
// `actionResult` — there are no separate proposal/result kinds. This is the
// single canonical state the chat UI holds; display turns are derived from an
// ordered list of these (see AIChatMessage.deriveTurns).
type chatMessage =
  | UserMessage({id: string, content: string, actionResult: option<actionResult>})
  | AgentMessage({id: string, content: string, action: option<pendingAction>})

type proposalStatus =
  | Pending
  | Approved
  | Denied
  | Executed({wasSuccessful: bool, details: option<string>})

type chatTurn =
  | UserTurn({id: string, content: string})
  | AssistantTurn({id: string, response: aiResponse})
  | ProposalTurn({id: string, action: pendingAction, status: proposalStatus})
