%%raw("import { t } from '@lingui/macro'")

// The mutation returns the rows persisted for this turn (real ids), each
// selected through the shared `AIChatMessage_entry` inline fragment - the exact
// same selection the history query uses, so live and reloaded turns decode
// through one code path. `suggestedEvents` is a transient, per-response
// enrichment (never persisted); it is attached to the turn's agent bubble.
module ChatMutation = %relay(`
  mutation AIAssistantEmbedChatMutation($input: ChatInput!) {
    chat(input: $input) {
      messages {
        ...AIChatMessage_entry
      }
      suggestedEvents
      error
    }
  }
`)

@module("../../entry/auth-client")
external authClient: BetterAuth.authClient = "authClient"

// Loads persisted chat history. The backend derives the session id from the
// authenticated user, so this query takes no session argument; we only need to
// know the viewer is logged in before mounting it (an anonymous `chatMessages`
// raises Unauthorized). Both this query and the mutation above spread the same
// `AIChatMessage_entry` fragment.
module ChatHistoryQuery = %relay(`
  query AIAssistantEmbedChatHistoryQuery($limit: Int) {
    chatMessages(limit: $limit) {
      ...AIChatMessage_entry
    }
  }
`)

// Suspends its own boundary (see usage in `make`) rather than the whole widget,
// and calls `onLoaded` exactly once per mount with the decoded messages.
module ChatHistoryLoader = {
  @react.component
  let make = (~onLoaded: array<AITypes.chatMessage> => unit) => {
    let data = ChatHistoryQuery.use(~variables={limit: 50})

    React.useEffect0(() => {
      let historyMessages =
        data.chatMessages->Belt.Array.keepMap(m => AIChatMessage.fromFragmentRef(m.fragmentRefs))
      onLoaded(historyMessages)
      None
    })

    React.null
  }
}

// `BetterAuth.useSessionReturn.data` is typed as `option<sessionData>`, but
// better-auth's client actually returns JS `null` (not `undefined`) before a
// session is resolved. ReScript's unboxed `option` FFI representation only
// treats `undefined` as `None` — a literal `null` is otherwise seen as
// `Some(null)`, which then crashes when we access `.user` on it. Reinterpret
// through `Js.Nullable` so both `null` and `undefined` correctly become `None`.
external unsafeSessionDataAsNullable: option<BetterAuth.sessionData> => Js.Nullable.t<
  BetterAuth.sessionData,
> = "%identity"

@get external scrollHeight: Dom.element => float = "scrollHeight"
@set external setScrollTop: (Dom.element, float) => unit = "scrollTop"

// The composer opens one line tall and grows with what is typed, up to a few
// lines, after which it scrolls. Measuring needs the real element, so it is
// done in plain JS rather than through a height binding.
let autoGrow: Dom.element => unit = %raw(`function (el) {
  el.style.height = "auto"
  el.style.height = Math.min(el.scrollHeight, 120) + "px"
}`)

@react.component
let make = (
  ~onSingleEventSuggested: AITypes.eventDetails => unit,
  // A batch of drafts, accepted from its card as the form's schedule.
  ~onEventsAccepted: array<AITypes.eventDetails> => unit,
) => {
  open Lingui.Util
  open AITypes
  let ts = Lingui.UtilString.t

  let (prompt, setPrompt) = React.useState(() => "")
  let (isLoading, setIsLoading) = React.useState(() => false)
  // Single canonical, append-only message list. Everything the UI shows is
  // derived from this plus the two transient overlays below.
  let (messages, setMessages) = React.useState((): array<AITypes.chatMessage> => [])
  // In-flight Approve/Deny status keyed by proposalId, covering only the gap
  // between the click and the mutation completing (once the action-result row is
  // persisted, the derived status takes over and this entry is cleared).
  let (overlay, setOverlay) = React.useState(() => Belt.Map.String.empty)
  // suggestedEvents for a live turn, keyed by the agent message they belong to
  // (never persisted, so absent after reload — matching prior behavior).
  let (enrichments, setEnrichments) = React.useState(() => Belt.Map.String.empty)
  let (isHydrating, setIsHydrating) = React.useState(() => false)
  // Whether the chat history is hidden. The prompt row is always shown, so the
  // history starts hidden (even when there is some to load), opens itself on a
  // reply that needs reading, and closes once a draft has been handed to the
  // form.
  let (isCollapsed, setIsCollapsed) = React.useState(() => true)
  let chatContainerRef = React.useRef(Nullable.null)
  let promptRef = React.useRef(Nullable.null)
  // An IME (Japanese, Chinese, Korean) confirms a candidate with Enter; that
  // keystroke must not send the message.
  let isComposingRef = React.useRef(false)
  let stepCounterRef = React.useRef(0)
  let localIdCounterRef = React.useRef(0)
  let isExecutingRef = React.useRef(false)
  let hasHydratedRef = React.useRef(false)

  let (chatMutate, _isChatMutating) = ChatMutation.use()
  let session = authClient.useSession()

  let turns = React.useMemo3(
    () => AIChatMessage.deriveTurns(messages, ~overlay, ~enrichments),
    (messages, overlay, enrichments),
  )

  let nextLocalId = () => {
    localIdCounterRef.current = localIdCounterRef.current + 1
    "local-" ++ localIdCounterRef.current->Int.toString
  }

  let messageId = (m: AITypes.chatMessage) =>
    switch m {
    | UserMessage({id}) => id
    | AgentMessage({id}) => id
    }

  // Drop optimistic local rows (they get replaced by the server's real-id
  // echo). A no-op when there are none (e.g. an approve/deny turn).
  let keepNonLocal = msgs => msgs->Array.filter(m => !(messageId(m)->String.startsWith("local-")))

  let snapToBottom = () =>
    switch chatContainerRef.current->Nullable.toOption {
    | Some(elem) => elem->setScrollTop(elem->scrollHeight)
    | None => ()
    }

  let scrollToBottom = () => {
    let _ = Js.Global.setTimeout(snapToBottom, 60)
  }

  // suggestedEvents is now a list of JSON strings (CreateEventInput-shaped
  // drafts); parse via the shared converter into eventDetails (+ rawFields).
  let toSuggestedEvents = AIChatMessage.toSuggestedEvents

  let hasGraphQLErrors = json =>
    switch json->Js.Json.decodeObject {
    | Some(obj) =>
      switch Js.Dict.get(obj, "errors")->Option.flatMap(value => value->Js.Json.decodeArray) {
      | Some(errors) => errors->Array.length > 0
      | None => false
      }
    | None => false
    }

  // Hands a single draft to the create form and folds the helper away so the
  // form is in view. Runs when the draft arrives and again from its card.
  let fillForm = event => {
    onSingleEventSuggested(event)
    setIsCollapsed(_ => true)
  }
  // Hands a batch of drafts to the form the same way. Unlike a single draft it
  // never happens on arrival: the organizer accepts it from the card.
  let acceptEvents = events => {
    onEventsAccepted(events)
    setIsCollapsed(_ => true)
  }

  let serializeError = message =>
    Js.Dict.fromArray([("error", Js.Json.string(message))])
    ->Js.Json.object_
    ->Js.Json.stringifyAny
    ->Option.getOr("{\"error\":\"unknown error\"}")

  // The id of the last plain agent (non-proposal) message in a batch - the one a
  // response's suggestedEvents belong to.
  let lastAgentTextId = (msgs: array<AITypes.chatMessage>) =>
    msgs->Belt.Array.reduce(None, (acc, m) =>
      switch m {
      | AgentMessage({id, action: None}) => Some(id)
      | _ => acc
      }
    )

  // Single completion path for every `chat` mutation (ask, approve, deny). It
  // appends the persisted rows (replacing any optimistic local echo), records
  // the transient suggestedEvents enrichment, clears the in-flight overlay for a
  // resolved proposal, and surfaces a plain error bubble when the server
  // returned an error with no messages.
  let applyResponse = (
    response: AIAssistantEmbedChatMutation_graphql.Types.response,
    ~clearOverlayFor: option<string>,
  ) => {
    isExecutingRef.current = false
    let chat = response.chat
    let newMessages =
      chat.messages->Belt.Array.keepMap(m => AIChatMessage.fromFragmentRef(m.fragmentRefs))
    let suggestedEvents = toSuggestedEvents(chat.suggestedEvents)

    let finalNew = switch (chat.error, Array.length(newMessages)) {
    | (Some(err), 0) => [AgentMessage({id: nextLocalId(), content: err, action: None})]
    | _ => newMessages
    }

    setMessages(prev => Array.concat(keepNonLocal(prev), finalNew))

    switch clearOverlayFor {
    | Some(pid) => setOverlay(prev => prev->Belt.Map.String.remove(pid))
    | None => ()
    }

    switch suggestedEvents {
    | Some(events) =>
      switch lastAgentTextId(newMessages) {
      | Some(id) => setEnrichments(prev => prev->Belt.Map.String.set(id, events))
      | None => ()
      }
    | None => ()
    }

    // A single draft goes straight to the form, which folds the history away.
    // Anything else (a clarifying question, a proposal, a batch of events) is
    // read in the history, so open it.
    switch suggestedEvents {
    | Some([singleEvent]) => fillForm(singleEvent)
    | _ => setIsCollapsed(_ => false)
    }

    setIsLoading(_ => false)
    scrollToBottom()
  }

  let handleChatError = _error => {
    isExecutingRef.current = false
    setMessages(prev =>
      Array.concat(
        prev,
        [
          AgentMessage({
            id: nextLocalId(),
            content: ts`An error occurred. Please try again.`,
            action: None,
          }),
        ],
      )
    )
    setIsCollapsed(_ => false)
    setIsLoading(_ => false)
  }

  // Report an executed/denied proposal outcome back to the server, which builds
  // the `<action_result>` envelope and feeds it to the LLM. Capped at 5 chained
  // steps per user turn so an action loop can't run away.
  let sendActionResult = (~proposalId: string, ~operationName: string, ~resultJson: string) => {
    if stepCounterRef.current >= 5 {
      setMessages(prev =>
        Array.concat(
          prev,
          [
            AgentMessage({
              id: nextLocalId(),
              content: ts`Too many automated steps were requested. Please continue manually.`,
              action: None,
            }),
          ],
        )
      )
      setOverlay(prev => prev->Belt.Map.String.remove(proposalId))
      setIsLoading(_ => false)
    } else {
      stepCounterRef.current = stepCounterRef.current + 1
      chatMutate(
        ~variables={
          input: {
            actionResult: {proposalId, operationName, resultJson},
          },
        },
        ~onCompleted=(response, _errors) =>
          applyResponse(response, ~clearOverlayFor=Some(proposalId)),
        ~onError=error => {
          setOverlay(prev => prev->Belt.Map.String.remove(proposalId))
          handleChatError(error)
        },
      )->ignore
    }
  }

  let handleApproveAction = (~proposalId: string, ~action: AITypes.pendingAction) => {
    if isExecutingRef.current {
      ()
    } else {
      isExecutingRef.current = true
      setOverlay(prev => prev->Belt.Map.String.set(proposalId, Approved))
      setIsLoading(_ => true)

      let runAction = async () => {
        let actionResult = await AgentActionExecutor.execute(
          ~query=action.query,
          ~variablesJson=action.variablesJson,
        )

        let resultJson = switch actionResult {
        | Ok(json) =>
          let jsonBody = json->Js.Json.stringifyAny->Option.getOr("{}")
          let wasSuccessful = !hasGraphQLErrors(json)
          setOverlay(prev =>
            prev->Belt.Map.String.set(
              proposalId,
              Executed({
                wasSuccessful,
                details: wasSuccessful ? None : Some(ts`The action completed with GraphQL errors.`),
              }),
            )
          )
          jsonBody
        | Error(message) =>
          setOverlay(prev =>
            prev->Belt.Map.String.set(
              proposalId,
              Executed({wasSuccessful: false, details: Some(message)}),
            )
          )
          serializeError(message)
        }

        sendActionResult(~proposalId, ~operationName=action.operationName, ~resultJson)
      }

      runAction()->ignore
    }
  }

  let handleDenyAction = (~proposalId: string, ~action: AITypes.pendingAction) => {
    if isExecutingRef.current {
      ()
    } else {
      isExecutingRef.current = true
      setOverlay(prev => prev->Belt.Map.String.set(proposalId, Denied))
      setIsLoading(_ => true)
      let resultJson =
        Js.Dict.fromArray([("cancelled", Js.Json.boolean(true))])
        ->Js.Json.object_
        ->Js.Json.stringifyAny
        ->Option.getOr("{\"cancelled\":true}")
      sendActionResult(~proposalId, ~operationName=action.operationName, ~resultJson)
    }
  }

  let handleAsk = () => {
    let userMessage = String.trim(prompt)

    if userMessage == "" {
      ()
    } else {
      stepCounterRef.current = 0
      setMessages(prev =>
        Array.concat(
          prev,
          [UserMessage({id: nextLocalId(), content: userMessage, actionResult: None})],
        )
      )
      setPrompt(_ => "")
      setIsLoading(_ => true)
      scrollToBottom()

      chatMutate(
        ~variables={
          input: {
            message: AIChatMessage.LocalTime.prepend(userMessage),
          },
        },
        ~onCompleted=(response, _errors) => applyResponse(response, ~clearOverlayFor=None),
        ~onError=handleChatError,
      )->ignore
    }
  }

  let handleHistoryLoaded = (historyMessages: array<AITypes.chatMessage>) => {
    hasHydratedRef.current = true
    if historyMessages->Array.length > 0 {
      setMessages(prevMessages => prevMessages->Array.length == 0 ? historyMessages : prevMessages)
      scrollToBottom()
    }
    setIsHydrating(_ => false)
  }

  let sessionUserId =
    session.data
    ->unsafeSessionDataAsNullable
    ->Js.Nullable.toOption
    ->Option.map(sessionData => sessionData.user.id)

  React.useEffect1(() => {
    switch sessionUserId {
    | Some(_) if !hasHydratedRef.current => setIsHydrating(_ => true)
    | _ => ()
    }
    None
  }, [sessionUserId])

  let hasHistory = turns->Array.length > 0
  // The history pane unmounts while collapsed, so it remounts scrolled to the
  // top; snap it to the latest turn before the opened panel paints.
  React.useLayoutEffect1(() => {
    if !isCollapsed {
      snapToBottom()
    }
    None
  }, [isCollapsed])
  let hasPendingProposal = turns->Array.some(turn =>
    switch turn {
    | ProposalTurn({status: Pending}) => true
    | _ => false
    }
  )
  let canSend = String.trim(prompt) != "" && !isLoading && !hasPendingProposal && !isHydrating

  React.useEffect1(() => {
    promptRef.current->Nullable.toOption->Option.forEach(autoGrow)
    None
  }, [prompt])

  let avatar =
    <span
      className="mt-0.5 flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-md bg-[#bdf25d] text-[#365314]">
      <Lucide.Sparkles size=13 \"aria-hidden"="true" />
    </span>
  // Messages sit directly on the lime band: the user's on the prompt input's
  // own surface, the assistant's a deeper tint of the band.
  let assistantBubbleClass = "rounded-lg bg-[#bdf25d]/30 px-3 py-2 text-sm leading-relaxed text-gray-800 dark:bg-[#bdf25d]/[0.12] dark:text-gray-100"
  let replyCardClass = "space-y-2.5 rounded-xl border border-gray-200 bg-white p-3.5 dark:border-[#3a3b40] dark:bg-[#222326]"

  // The design's assistant band: a prompt row that is always ready to send,
  // with the conversation (clarifying questions, action proposals) above it,
  // shown and hidden by the row's toggle. Its host
  // bleeds it to the edges and overlaps its foot with the form, hence pb-5.
  <div className="bg-[#bdf25d]/15 px-4 pb-5 pt-3 dark:bg-[#bdf25d]/[0.07]">
    // History hydrates as soon as there is a session, collapsed or not: the
    // loader renders nothing itself, and `isHydrating` gates sending until it
    // is done.
    {switch sessionUserId {
    | Some(_) if !hasHydratedRef.current =>
      <React.Suspense fallback=React.null>
        <ChatHistoryLoader onLoaded=handleHistoryLoaded />
      </React.Suspense>
    | _ => React.null
    }}
    {isCollapsed
      ? React.null
      : <div
          id="event-ai-history"
          ref={ReactDOM.Ref.domRef(chatContainerRef)}
          ariaLive=#polite
          className="mb-3 max-h-52 space-y-3 overflow-y-auto">
          {if isHydrating {
            <p className="text-xs text-gray-600 dark:text-gray-400">
              {t`Loading conversation history...`}
            </p>
          } else if !hasHistory && !isLoading {
            <p className="text-xs text-gray-600 dark:text-gray-400">
              {t`Ask the assistant to fill in event details. Your conversation will appear here.`}
            </p>
          } else {
            React.null
          }}
          {turns
          ->Array.map(turn =>
            switch turn {
            | UserTurn({id, content}) =>
              <div
                key=id
                className="ml-8 whitespace-pre-wrap rounded-lg bg-white px-3 py-2 text-sm leading-relaxed text-gray-800 dark:bg-[#1e1f23] dark:text-gray-100">
                {content->React.string}
              </div>
            | AssistantTurn({id, response}) =>
              <div key=id className="mr-8 flex items-start gap-2">
                avatar
                <div className="min-w-0 flex-1">
                  <AIResponseCard
                    response
                    onFillForm=fillForm
                    onAcceptEvents=acceptEvents
                    summaryClassName=assistantBubbleClass
                  />
                </div>
              </div>
            | ProposalTurn({id, action, status}) => {
                let (statusText, statusClasses) = switch status {
                | Pending => (
                    ts`Awaiting approval`,
                    "border-amber-200 bg-amber-50 text-amber-700 dark:border-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
                  )
                | Approved => (
                    ts`Approved`,
                    "border-blue-200 bg-blue-50 text-blue-700 dark:border-blue-700 dark:bg-blue-900/30 dark:text-blue-400",
                  )
                | Denied => (
                    ts`Denied`,
                    "border-gray-200 bg-gray-50 text-gray-700 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-400",
                  )
                | Executed({wasSuccessful, details: _}) =>
                  wasSuccessful
                    ? (
                        ts`Executed`,
                        "border-emerald-200 bg-emerald-50 text-emerald-700 dark:border-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
                      )
                    : (
                        ts`Execution failed`,
                        "border-red-200 bg-red-50 text-red-700 dark:border-red-700 dark:bg-red-900/30 dark:text-red-400",
                      )
                }

                <div key=id className="mr-8 flex items-start gap-2">
                  avatar
                  <div className={"min-w-0 flex-1 " ++ replyCardClass}>
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                        {t`Action proposal`}
                      </p>
                      <span
                        className={"rounded-full border px-2 py-0.5 text-[10px] font-semibold " ++
                        statusClasses}>
                        {statusText->React.string}
                      </span>
                    </div>
                    <p className="text-sm leading-relaxed text-gray-700 dark:text-gray-300">
                      {action.summary->React.string}
                    </p>
                    <p className="font-mono text-[10px] text-gray-500 dark:text-gray-400">
                      {<>
                        {t`Operation:`}
                        {" "->React.string}
                        {action.operationName->React.string}
                      </>}
                    </p>
                    {switch status {
                    | Executed({wasSuccessful: _, details: Some(details)}) =>
                      <p className="text-xs text-gray-600 dark:text-gray-300">
                        {details->React.string}
                      </p>
                    | _ => React.null
                    }}
                    {switch status {
                    | Pending =>
                      <div className="flex items-center gap-2">
                        <button
                          type_="button"
                          onClick={_ => handleApproveAction(~proposalId=id, ~action)}
                          className="inline-flex items-center gap-1.5 rounded-lg bg-[#bdf25d] px-3 py-2 text-xs font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] disabled:opacity-50"
                          disabled=isLoading>
                          <Lucide.Check size=13 strokeWidth=2.5 \"aria-hidden"="true" />
                          <span> {t`Approve`} </span>
                        </button>
                        <button
                          type_="button"
                          onClick={_ => handleDenyAction(~proposalId=id, ~action)}
                          className="inline-flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-2 text-xs font-semibold text-gray-700 transition-colors hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] disabled:opacity-50 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:text-gray-200 dark:hover:bg-[#2a2b30]"
                          disabled=isLoading>
                          <Lucide.X size=13 strokeWidth=2.5 \"aria-hidden"="true" />
                          <span> {t`Deny`} </span>
                        </button>
                      </div>
                    | _ => React.null
                    }}
                  </div>
                </div>
              }
            }
          )
          ->React.array}
          {isLoading
            ? <div className="mr-8 flex items-start gap-2">
                avatar
                <div className="rounded-lg bg-[#bdf25d]/30 px-3 py-3 dark:bg-[#bdf25d]/[0.12]">
                  <div className="flex items-center gap-1.5">
                    <div
                      className="h-1.5 w-1.5 animate-bounce rounded-full bg-gray-400 dark:bg-gray-500"
                      style={ReactDOM.Style.make(~animationDelay="0ms", ())}
                    />
                    <div
                      className="h-1.5 w-1.5 animate-bounce rounded-full bg-gray-400 dark:bg-gray-500"
                      style={ReactDOM.Style.make(~animationDelay="150ms", ())}
                    />
                    <div
                      className="h-1.5 w-1.5 animate-bounce rounded-full bg-gray-400 dark:bg-gray-500"
                      style={ReactDOM.Style.make(~animationDelay="300ms", ())}
                    />
                  </div>
                </div>
              </div>
            : React.null}
        </div>}
    <div className="flex min-w-0 items-start gap-2.5">
      <span
        className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg bg-[#bdf25d] text-[#365314]">
        <Lucide.Sparkles size=17 \"aria-hidden"="true" />
      </span>
      <form
        className="min-w-0 flex-1"
        onSubmit={e => {
          ReactEvent.Form.preventDefault(e)
          if canSend {
            handleAsk()
          }
        }}>
        <label className="block min-w-0" htmlFor="event-ai-prompt">
          <span className="sr-only"> {t`Describe the event`} </span>
          <div
            className="flex min-w-0 items-end gap-2 rounded-lg border border-[#a3d949]/60 bg-white p-1.5 focus-within:border-[#94c93a] focus-within:ring-2 focus-within:ring-[#bdf25d]/40 dark:border-[#bdf25d]/25 dark:bg-[#1e1f23]">
            <textarea
              id="event-ai-prompt"
              ref={ReactDOM.Ref.domRef(promptRef)}
              rows=1
              value=prompt
              onChange={e => {
                let value = ReactEvent.Form.target(e)["value"]
                setPrompt(_ => value)
              }}
              onCompositionStart={_ => isComposingRef.current = true}
              onCompositionEnd={_ => isComposingRef.current = false}
              onKeyDown={e => {
                // Enter sends and Shift+Enter starts a line, except while an
                // IME is mid-composition, where Enter belongs to the candidate
                // (some browsers report it only as keyCode 229).
                let composing = isComposingRef.current || e->ReactEvent.Keyboard.keyCode == 229
                if (
                  e->ReactEvent.Keyboard.key == "Enter" &&
                  !(e->ReactEvent.Keyboard.shiftKey) &&
                  !composing
                ) {
                  e->ReactEvent.Keyboard.preventDefault
                  if canSend {
                    handleAsk()
                  }
                }
              }}
              placeholder={hasPendingProposal
                ? ts`Approve or deny the pending action to continue.`
                : ts`Describe your event and I’ll fill out the form…`}
              disabled={isLoading || hasPendingProposal}
              className="block max-h-[120px] min-h-9 w-full min-w-0 flex-1 resize-none border-0 bg-transparent px-2 py-2 text-base leading-5 text-gray-900 outline-none placeholder:text-gray-400 disabled:opacity-60 sm:text-sm dark:text-gray-100"
            />
            <button
              type_="submit"
              disabled={!canSend}
              ariaLabel={ts`Fill event form from description`}
              className="inline-flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-md bg-[#bdf25d] text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] disabled:cursor-not-allowed disabled:bg-gray-200 disabled:text-gray-400 dark:disabled:bg-[#34353a]">
              {isLoading
                ? <span
                    className="h-4 w-4 animate-spin rounded-full border-2 border-gray-500 border-t-transparent"
                  />
                : <Lucide.ArrowUp size=16 strokeWidth=2.5 \"aria-hidden"="true" />}
            </button>
          </div>
        </label>
      </form>
      <button
        type_="button"
        onClick={_ => setIsCollapsed(collapsed => !collapsed)}
        ariaExpanded={!isCollapsed}
        ariaControls="event-ai-history"
        ariaLabel={isCollapsed ? ts`Show AI chat history` : ts`Hide AI chat history`}
        className="inline-flex h-9 flex-shrink-0 items-center gap-1 rounded-lg border border-[#94c93a]/40 bg-white/70 px-2.5 text-xs font-semibold text-gray-600 transition-colors hover:bg-white focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:border-[#bdf25d]/20 dark:bg-[#1e1f23]/70 dark:text-gray-300 dark:hover:bg-[#1e1f23]">
        <Lucide.MessageSquare size=14 \"aria-hidden"="true" />
        <Lucide.ChevronDown
          size=13
          className={"transition-transform duration-200 ease-[cubic-bezier(0.23,1,0.32,1)]" ++ (
            isCollapsed ? "" : " rotate-180"
          )}
          \"aria-hidden"="true"
        />
      </button>
    </div>
  </div>
}
