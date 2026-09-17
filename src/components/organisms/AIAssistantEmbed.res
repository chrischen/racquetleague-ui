%%raw("import { t } from '@lingui/macro'")

type context = {
  activitySlug?: string,
  clubId?: string,
  locationAddress?: string,
}

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

@react.component
let make = (~context: context, ~onSingleEventSuggested: option<AITypes.eventDetails => unit>=?) => {
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
  // Collapsed until asked for, as in the design; opens itself on a clarifying
  // turn and closes once a draft has been handed to the form.
  let (isCollapsed, setIsCollapsed) = React.useState(() => true)
  let chatContainerRef = React.useRef(Nullable.null)
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

  let scrollToBottom = () => {
    let _ = Js.Global.setTimeout(() => {
      chatContainerRef.current
      ->Nullable.toOption
      ->Option.map(_elem => {
        %raw(`chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight`)
      })
      ->ignore
    }, 60)
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
      switch (events, onSingleEventSuggested) {
      | ([singleEvent], Some(callback)) =>
        callback(singleEvent)
        setIsCollapsed(_ => true)
      | _ => ()
      }
    | None => ()
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
            message: userMessage,
          },
        },
        ~onCompleted=(response, _errors) => applyResponse(response, ~clearOverlayFor=None),
        ~onError=handleChatError,
      )->ignore
    }
  }

  let handleReset = () => {
    setPrompt(_ => "")
    setMessages(_ => [])
    setOverlay(_ => Belt.Map.String.empty)
    setEnrichments(_ => Belt.Map.String.empty)
    stepCounterRef.current = 0
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
  React.useEffect1(() => {
    if hasHistory {
      setIsCollapsed(_ => false)
    }
    None
  }, [hasHistory])
  let hasPendingProposal = turns->Array.some(turn =>
    switch turn {
    | ProposalTurn({status: Pending}) => true
    | _ => false
    }
  )

  let canSend = String.trim(prompt) != "" && !isLoading && !hasPendingProposal && !isHydrating

  let avatar =
    <span
      className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-[#bdf25d] text-black">
      <Lucide.Sparkles size=13 \"aria-hidden"="true" />
    </span>
  let replyCardClass = "space-y-2.5 rounded-xl border border-gray-200 bg-white p-3.5 dark:border-[#3a3b40] dark:bg-[#222326]"

  // The design's "Help me fill this out" helper: a lime card that expands to
  // the prompt box. The conversation (clarifying questions, action proposals)
  // renders above the box when there is one.
  <section
    className="overflow-hidden rounded-xl border border-[#a3d949]/60 bg-[#bdf25d]/10 dark:border-[#bdf25d]/25 dark:bg-[#bdf25d]/5">
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
    <button
      type_="button"
      onClick={_ => setIsCollapsed(collapsed => !collapsed)}
      ariaExpanded={!isCollapsed}
      ariaControls="event-form-helper"
      className="flex w-full items-center gap-3 px-3.5 py-3 text-left transition-colors hover:bg-[#bdf25d]/10 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[#94c93a] dark:hover:bg-[#bdf25d]/10">
      <Lucide.Sparkles
        size=16 className="flex-shrink-0 text-[#4d6f12] dark:text-[#bdf25d]" \"aria-hidden"="true"
      />
      <span className="min-w-0 flex-1">
        <span className="block text-sm font-semibold text-gray-900 dark:text-gray-100">
          {t`Help me fill this out`}
        </span>
        <span className="mt-0.5 block text-xs text-gray-600 dark:text-gray-400">
          {if hasPendingProposal {
            t`Approve or deny the pending action to continue`
          } else if hasHistory {
            t`Continue the conversation`
          } else {
            t`Describe the event to generate a draft`
          }}
        </span>
      </span>
      <Lucide.ChevronDown
        size=16
        className={"flex-shrink-0 text-gray-500 transition-transform duration-200 ease-[cubic-bezier(0.23,1,0.32,1)]" ++ (
          isCollapsed ? "" : " rotate-180"
        )}
        \"aria-hidden"="true"
      />
    </button>
    {isCollapsed
      ? React.null
      : <div
          id="event-form-helper"
          className="space-y-3 border-t border-[#a3d949]/40 bg-white px-3.5 py-4 dark:border-[#bdf25d]/20 dark:bg-[#1e1f23]">
          {if hasHistory || isLoading || isHydrating {
            <div
              ref={ReactDOM.Ref.domRef(chatContainerRef)}
              className="max-h-96 space-y-3 overflow-y-auto pr-1">
              {isHydrating
                ? <div className="flex justify-center py-2">
                    <span className="text-xs text-gray-400 dark:text-gray-500">
                      {t`Loading conversation history...`}
                    </span>
                  </div>
                : React.null}
              {turns
              ->Array.map(turn =>
                switch turn {
                | UserTurn({id, content}) =>
                  <div key=id className="flex justify-end">
                    <div
                      className="max-w-[85%] rounded-2xl bg-[#bdf25d] px-3.5 py-2.5 text-sm font-medium leading-relaxed text-black">
                      {content->React.string}
                    </div>
                  </div>
                | AssistantTurn({id, response}) =>
                  <div key=id className="flex items-start gap-2.5">
                    avatar
                    <div className="min-w-0 max-w-[90%] flex-1">
                      <AIResponseCard
                        response
                        activitySlug={context.activitySlug->Option.getOr("pickleball")}
                        clubId=?context.clubId
                        locationAddress=?context.locationAddress
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

                    <div key=id className="flex items-start gap-2.5">
                      avatar
                      <div className={"min-w-0 max-w-[90%] flex-1 " ++ replyCardClass}>
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
                ? <div className="flex items-start gap-2.5">
                    avatar
                    <div
                      className="rounded-xl border border-gray-200 bg-white px-3.5 py-3 dark:border-[#3a3b40] dark:bg-[#222326]">
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
            </div>
          } else {
            React.null
          }}
          <label className="block" htmlFor="event-ai-prompt">
            <span className="sr-only"> {t`Describe the event`} </span>
            <div
              className="relative overflow-hidden rounded-xl border border-gray-200 bg-white focus-within:border-[#94c93a] focus-within:ring-2 focus-within:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#222326]">
              <textarea
                id="event-ai-prompt"
                value=prompt
                onChange={e => {
                  let value = ReactEvent.Form.target(e)["value"]
                  setPrompt(_ => value)
                }}
                onKeyDown={e => {
                  let key = ReactEvent.Keyboard.key(e)
                  let metaKey = ReactEvent.Keyboard.metaKey(e)
                  let ctrlKey = ReactEvent.Keyboard.ctrlKey(e)
                  if key == "Enter" && (metaKey || ctrlKey) {
                    ReactEvent.Keyboard.preventDefault(e)
                    handleAsk()
                  }
                }}
                placeholder={if hasHistory {
                  if hasPendingProposal {
                    ts`Approve or deny the pending action to continue.`
                  } else {
                    ts`Answer the questions or provide more details...`
                  }
                } else {
                  ts`Describe your event… For example: Tomorrow at 7pm at Central Park, need 3 more players around 3.5, ¥800 each.`
                }}
                rows={hasHistory ? 3 : 4}
                disabled={isLoading || hasPendingProposal || isHydrating}
                className="block w-full resize-none border-0 bg-transparent px-3.5 pb-12 pt-3 text-sm leading-relaxed text-gray-900 outline-none placeholder:text-gray-400 disabled:opacity-60 dark:text-gray-100"
              />
              <div
                className="pointer-events-none absolute bottom-2.5 left-3 flex items-center gap-1.5 text-[10px] text-gray-400">
                <Lucide.Sparkles size=12 \"aria-hidden"="true" />
                {hasHistory ? t`⌘+Enter to send` : t`Include whatever details you know`}
              </div>
              <button
                type_="button"
                onClick={_ => handleAsk()}
                disabled={!canSend}
                ariaLabel={hasHistory ? ts`Send` : ts`Fill event form from description`}
                className="absolute bottom-2 right-2 inline-flex h-8 w-8 items-center justify-center rounded-lg bg-[#bdf25d] text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] disabled:cursor-not-allowed disabled:bg-gray-200 disabled:text-gray-400 dark:disabled:bg-[#34353a]">
                {isLoading
                  ? <span
                      className="h-4 w-4 animate-spin rounded-full border-2 border-gray-500 border-t-transparent"
                    />
                  : <Lucide.ArrowUp size=15 strokeWidth=2.5 \"aria-hidden"="true" />}
              </button>
            </div>
          </label>
          <div className="flex items-center justify-between gap-3">
            <p className="text-xs leading-relaxed text-gray-500 dark:text-gray-400">
              {hasHistory
                ? t`Answer the questions or add details to refine the draft.`
                : t`We’ll turn your description into a draft you can review and edit.`}
            </p>
            {hasHistory
              ? <button
                  type_="button"
                  onClick={_ => handleReset()}
                  className="flex-shrink-0 text-xs font-semibold text-gray-500 transition-colors hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100">
                  {t`Reset`}
                </button>
              : React.null}
          </div>
        </div>}
  </section>
}
