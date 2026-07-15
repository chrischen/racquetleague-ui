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
  let (isCollapsed, setIsCollapsed) = React.useState(() => false)
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
  let hasPendingProposal = turns->Array.some(turn =>
    switch turn {
    | ProposalTurn({status: Pending}) => true
    | _ => false
    }
  )

  <div
    className="relative overflow-hidden rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#1a1a1a] transition-colors">
    {if isCollapsed {
      <button
        type_="button"
        onClick={_ => setIsCollapsed(_ => false)}
        className="w-full p-4 hover:bg-gray-50 dark:hover:bg-[#222222] transition-colors flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-[#a3e635] flex items-center justify-center">
            <Lucide.Sparkles className="w-4 h-4 text-gray-900" />
          </div>
          <div className="text-left">
            <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">
              {t`AI Assistant`}
            </p>
            <p className="text-xs text-gray-600 dark:text-gray-400">
              {t`Form filled • Click to expand`}
            </p>
          </div>
        </div>
        <Lucide.ChevronDown className="w-5 h-5 text-gray-600" />
      </button>
    } else {
      <div className="p-6">
        <div className="flex items-start gap-4 mb-4">
          <div className="flex-shrink-0">
            <div className="w-10 h-10 rounded-full bg-[#a3e635] flex items-center justify-center">
              <Lucide.Sparkles className="w-5 h-5 text-gray-900" />
            </div>
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-base font-semibold text-gray-900 dark:text-gray-100 mb-1">
              {if hasHistory {
                t`AI Assistant`
              } else {
                t`Describe your event`
              }}
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              {if hasHistory {
                t`Continue the conversation`
              } else {
                t`Let AI help you fill out the details below`
              }}
            </p>
          </div>
          {hasHistory
            ? <button
                type_="button"
                onClick={_ => setIsCollapsed(_ => true)}
                className="flex-shrink-0 p-1 text-gray-400 hover:text-gray-600 transition-colors"
                title="Collapse">
                <Lucide.ChevronDown className="w-5 h-5" />
              </button>
            : React.null}
        </div>
        {if hasHistory || isLoading || isHydrating {
          <div
            ref={ReactDOM.Ref.domRef(chatContainerRef)}
            className="max-h-96 overflow-y-auto mb-4 space-y-3 pr-2 scrollbar-thin scrollbar-thumb-gray-300 dark:scrollbar-thumb-gray-600 scrollbar-track-transparent">
            {switch sessionUserId {
            | Some(_) if !hasHydratedRef.current =>
              <React.Suspense
                fallback={<div className="flex justify-center py-2">
                  <span className="text-xs text-gray-400 dark:text-gray-500">
                    {t`Loading conversation history...`}
                  </span>
                </div>}>
                <ChatHistoryLoader onLoaded=handleHistoryLoaded />
              </React.Suspense>
            | _ => React.null
            }}
            {turns
            ->Array.map(turn =>
              switch turn {
              | UserTurn({id, content}) =>
                <div key=id className="flex justify-end">
                  <div
                    className="max-w-[85%] bg-[#a3e635] text-gray-900 rounded-2xl px-4 py-3 text-sm leading-relaxed font-medium">
                    {content->React.string}
                  </div>
                </div>
              | AssistantTurn({id, response}) =>
                <div key=id className="flex justify-start gap-3">
                  <div className="flex-shrink-0">
                    <div
                      className="w-8 h-8 rounded-full bg-[#a3e635] flex items-center justify-center">
                      <Lucide.Sparkles className="w-3.5 h-3.5 text-gray-900" />
                    </div>
                  </div>
                  <div className="max-w-[90%]">
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
                      "text-amber-700 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/30 border-amber-200 dark:border-amber-700",
                    )
                  | Approved => (
                      ts`Approved`,
                      "text-blue-700 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/30 border-blue-200 dark:border-blue-700",
                    )
                  | Denied => (
                      ts`Denied`,
                      "text-gray-700 dark:text-gray-400 bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-600",
                    )
                  | Executed({wasSuccessful, details: _}) =>
                    wasSuccessful
                      ? (
                          ts`Executed`,
                          "text-emerald-700 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/30 border-emerald-200 dark:border-emerald-700",
                        )
                      : (
                          ts`Execution failed`,
                          "text-red-700 dark:text-red-400 bg-red-50 dark:bg-red-900/30 border-red-200 dark:border-red-700",
                        )
                  }

                  <div key=id className="flex justify-start gap-3">
                    <div className="flex-shrink-0">
                      <div
                        className="w-8 h-8 rounded-full bg-[#a3e635] flex items-center justify-center">
                        <Lucide.Sparkles className="w-3.5 h-3.5 text-gray-900" />
                      </div>
                    </div>
                    <div
                      className="w-full max-w-[90%] rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-[#222222] p-4 space-y-3">
                      <div className="flex items-center justify-between gap-2">
                        <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                          {t`Action proposal`}
                        </p>
                        <span
                          className={"text-xs font-medium px-2 py-1 rounded-full border " ++
                          statusClasses}>
                          {statusText->React.string}
                        </span>
                      </div>
                      <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
                        {action.summary->React.string}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
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
                            className="inline-flex items-center gap-2 px-3 py-2 rounded-lg bg-[#a3e635] text-gray-900 font-medium hover:bg-[#84cc16] transition-colors"
                            disabled=isLoading>
                            <Lucide.Check className="w-4 h-4" />
                            <span> {t`Approve`} </span>
                          </button>
                          <button
                            type_="button"
                            onClick={_ => handleDenyAction(~proposalId=id, ~action)}
                            className="inline-flex items-center gap-2 px-3 py-2 rounded-lg border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors"
                            disabled=isLoading>
                            <Lucide.X className="w-4 h-4" />
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
              ? <div className="flex justify-start">
                  <div className="flex-shrink-0 mr-3">
                    <div
                      className="w-8 h-8 rounded-full bg-[#a3e635] flex items-center justify-center">
                      <Lucide.Sparkles className="w-3.5 h-3.5 text-gray-900" />
                    </div>
                  </div>
                  <div
                    className="bg-white dark:bg-[#222222] border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                    <div className="flex items-center gap-2">
                      <div
                        className="w-2 h-2 bg-gray-400 dark:bg-gray-500 rounded-full animate-bounce"
                        style={ReactDOM.Style.make(~animationDelay="0ms", ())}
                      />
                      <div
                        className="w-2 h-2 bg-gray-400 dark:bg-gray-500 rounded-full animate-bounce"
                        style={ReactDOM.Style.make(~animationDelay="150ms", ())}
                      />
                      <div
                        className="w-2 h-2 bg-gray-400 dark:bg-gray-500 rounded-full animate-bounce"
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
        <div>
          <textarea
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
              ts`e.g., Weekly pickleball meetup at Central Park, Thursdays at 6pm, competitive play for 3.5+ players...`
            }}
            rows={hasHistory ? 2 : 3}
            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors resize-none bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500"
            disabled={isLoading || hasPendingProposal || isHydrating}
          />
          <div className="flex items-center justify-between mt-3">
            <span className="text-xs text-gray-500 dark:text-gray-400">
              {if hasHistory {
                t`Press ⌘+Enter to continue`
              } else {
                t`Press ⌘+Enter to generate`
              }}
            </span>
            <div className="flex items-center gap-2">
              {hasHistory
                ? <button
                    type_="button"
                    onClick={_ => handleReset()}
                    className="px-3 py-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 text-sm font-medium transition-colors">
                    {t`Reset`}
                  </button>
                : React.null}
              <button
                type_="button"
                onClick={_ => handleAsk()}
                disabled={String.trim(prompt) == "" ||
                isLoading ||
                hasPendingProposal ||
                isHydrating}
                className="inline-flex items-center gap-2 px-4 py-2 bg-[#a3e635] text-gray-900 rounded-lg font-medium hover:bg-[#84cc16] focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:ring-offset-2 dark:focus:ring-offset-[#1a1a1a] disabled:opacity-50 disabled:cursor-not-allowed transition-all">
                {if isLoading {
                  <>
                    <div
                      className="w-4 h-4 border-2 border-gray-900 border-t-transparent rounded-full animate-spin"
                    />
                    <span> {t`Generating...`} </span>
                  </>
                } else {
                  <>
                    <Lucide.Sparkles className="w-4 h-4" />
                    <span>
                      {if hasHistory {
                        t`Continue`
                      } else {
                        t`Fill with AI`
                      }}
                    </span>
                  </>
                }}
              </button>
            </div>
          </div>
        </div>
      </div>
    }}
  </div>
}
