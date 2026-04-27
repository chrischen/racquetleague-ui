%%raw("import { t } from '@lingui/macro'")

type context = {
  activitySlug?: string,
  clubId?: string,
  locationAddress?: string,
}

module ChatMutation = %relay(`
  mutation AIAssistantEmbedChatMutation($input: ChatInput!) {
    chat(input: $input) {
      message {
        content
        messageType
      }
      suggestedEvents {
        title
        startDate
        endDate
        timezone
        address
        details
        maxRsvps
      }
      error
    }
  }
`)

@react.component
let make = (~context: context, ~onSingleEventSuggested: option<AITypes.eventDetails => unit>=?) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t

  let (prompt, setPrompt) = React.useState(() => "")
  let (isLoading, setIsLoading) = React.useState(() => false)
  let (response, setResponse) = React.useState((): option<AITypes.aiResponse> => None)
  let (isCollapsed, setIsCollapsed) = React.useState(() => false)
  let chatContainerRef = React.useRef(Nullable.null)

  let (chatMutate, _isChatMutating) = ChatMutation.use()

  let handleAsk = () => {
    if String.trim(prompt) == "" {
      ()
    } else {
      setIsLoading(_ => true)
      chatMutate(
        ~variables={
          input: {
            message: prompt,
          },
        },
        ~onCompleted=(result, _errors) => {
          let chatResponse = result.chat

          switch chatResponse.message {
          | Some(message) => {
              // Convert suggested events from GraphQL to our type
              let suggestedEvents = chatResponse.suggestedEvents->Option.map(events =>
                events->Array.map((event): AITypes.eventDetails => {
                  // Format dates using Util.Datetime
                  let startDateStr = event.startDate->Util.Datetime.toDate->Js.Date.toISOString
                  let endDateStr = event.endDate->Util.Datetime.toDate->Js.Date.toISOString

                  {
                    title: event.title,
                    date: startDateStr,
                    time: endDateStr, // Store endDate in the time field for now
                    location: Some(event.address),
                    description: event.details,
                    maxRsvps: event.maxRsvps,
                  }
                })
              )

              // Handle single event case
              switch (suggestedEvents, onSingleEventSuggested) {
              | (Some([singleEvent]), Some(callback)) => {
                  // Call the callback with the single event
                  callback(singleEvent)
                  // Don't show response card, clear prompt, collapse
                  setPrompt(_ => "")
                  setResponse(_ => None)
                  setIsCollapsed(_ => true)
                }
              | _ => {
                  // Multiple events or no callback - show response card
                  setResponse(_ => Some({
                    summary: message.content,
                    eventDetails: None,
                    suggestedEvents,
                  }))
                  setPrompt(_ => "")
                  // Auto-scroll to bottom after rendering
                  let _ = Js.Global.setTimeout(() => {
                    chatContainerRef.current
                    ->Nullable.toOption
                    ->Option.map(_elem => {
                      %raw(`chatContainerRef.current.scrollTop = chatContainerRef.current.scrollHeight`)
                    })
                    ->ignore
                  }, 100)
                }
              }
            }
          | None =>
            // Handle no message case
            setResponse(_ => Some({
              summary: chatResponse.error->Option.getOr(
                ts`I couldn't process that request. Please try again.`,
              ),
              eventDetails: None,
              suggestedEvents: None,
            }))
          }
          setIsLoading(_ => false)
        },
        ~onError=_error => {
          setResponse(_ => Some({
            summary: ts`An error occurred. Please try again.`,
            eventDetails: None,
            suggestedEvents: None,
          }))
          setIsLoading(_ => false)
        },
      )->ignore
    }
  }

  let handleReset = () => {
    setPrompt(_ => "")
    setResponse(_ => None)
  }

  let hasHistory = response->Option.isSome

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
        {response
        ->Option.map(resp => {
          <div
            ref={ReactDOM.Ref.domRef(chatContainerRef)}
            className="max-h-48 overflow-y-auto mb-4 space-y-3 pr-2 scrollbar-thin scrollbar-thumb-gray-300 dark:scrollbar-thumb-gray-600 scrollbar-track-transparent">
            <AIResponseCard
              response=resp
              activitySlug={context.activitySlug->Option.getOr("pickleball")}
              clubId=?context.clubId
              locationAddress=?context.locationAddress
            />
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
        })
        ->Option.getOr(React.null)}
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
              ts`Answer the questions or provide more details...`
            } else {
              ts`e.g., Weekly pickleball meetup at Central Park, Thursdays at 6pm, competitive play for 3.5+ players...`
            }}
            rows={hasHistory ? 2 : 3}
            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors resize-none bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500"
            disabled=isLoading
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
                disabled={String.trim(prompt) == "" || isLoading}
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
