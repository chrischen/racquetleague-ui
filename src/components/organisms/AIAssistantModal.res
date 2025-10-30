%%raw("import { t } from '@lingui/macro'")
type context = {
  activitySlug?: string,
  clubId?: string,
  locationAddress?: string,
}

module ChatMutation = %relay(`
  mutation AIAssistantModalChatMutation($input: ChatInput!) {
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
let make = (~open_: bool=false, ~onOpenChange: option<bool => unit>=?, ~context: context) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t

  let (prompt, setPrompt) = React.useState(() => "")
  let (isLoading, setIsLoading) = React.useState(() => false)
  let (response, setResponse) = React.useState((): option<AITypes.aiResponse> => None)

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

              setResponse(_ => Some({
                summary: message.content,
                eventDetails: None,
                suggestedEvents,
              }))
              setPrompt(_ => "")
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

  let handleExampleClick = example => {
    setPrompt(_ => example)
    setResponse(_ => None)
  }

  let handleReset = () => {
    setPrompt(_ => "")
    setResponse(_ => None)
  }
  let examplePrompts = [
    ts`Need 5 players for KPI Park tomorrow 6-9pm. Split the cost.`,
    ts`Badminton every thursday next month at Akabane Elementary 7-9pm.`,
  ]

  <Radix.Dialog.Root \"open"=open_ ?onOpenChange>
    <Radix.Dialog.Portal>
      <Radix.Dialog.Overlay
        className="fixed inset-0 bg-black/40 backdrop-blur-sm animate-in fade-in z-100"
      />
      <Radix.Dialog.Content
        className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[90vw] max-w-2xl max-h-[85vh] overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        <div
          className="relative bg-white/80 dark:bg-gray-900/80 backdrop-blur-2xl rounded-3xl shadow-2xl border border-white/20 dark:border-gray-700/30 flex flex-col max-h-[85vh]">
          <div
            className="flex items-center justify-between p-6 border-b border-gray-200/50 dark:border-gray-700/50 flex-shrink-0">
            <div className="flex items-center gap-3">
              <div
                className="w-10 h-10 rounded-2xl bg-gradient-to-br from-purple-500 to-blue-500 flex items-center justify-center">
                <Lucide.Sparkles className="w-5 h-5 text-white" />
              </div>
              <div>
                <Radix.Dialog.Title className="text-lg font-semibold text-gray-900 dark:text-white">
                  {t`AI Assistant`}
                </Radix.Dialog.Title>
                <Radix.Dialog.Description>
                  <span className="text-sm text-gray-500 dark:text-gray-400">
                    {t`Let me know when and where you'd like to play, and I'll help you create an event. You can continue talking to me in a conversation to refine any details.`}
                  </span>
                </Radix.Dialog.Description>
              </div>
            </div>
            <Radix.Dialog.Close>
              <button
                className="w-8 h-8 rounded-full bg-gray-100/80 dark:bg-gray-800/80 hover:bg-gray-200/80 dark:hover:bg-gray-700/80 flex items-center justify-center transition-colors">
                <Lucide.X className="w-4 h-4 text-gray-600 dark:text-gray-400" />
              </button>
            </Radix.Dialog.Close>
          </div>
          <div className="p-6 space-y-6 overflow-y-auto flex-1">
            {switch response {
            | None => <ExamplePrompts examples=examplePrompts onExampleClick=handleExampleClick />
            | Some(_) => React.null
            }}
            {response
            ->Option.map(resp => {
              let handleEventsCreated = onOpenChange->Option.map(fn => () => fn(false))
              <AIResponseCard
                response=resp
                activitySlug={context.activitySlug->Option.getOr("pickleball")}
                clubId=?context.clubId
                locationAddress=?context.locationAddress
                onEventsCreated=?handleEventsCreated
              />
            })
            ->Option.getOr(React.null)}
          </div>
          <div
            className="p-6 border-t border-gray-200/50 dark:border-gray-700/50 bg-white/60 dark:bg-gray-900/60 backdrop-blur-xl flex-shrink-0">
            <div className="space-y-3">
              <textarea
                value=prompt
                onChange={e => {
                  let value = ReactEvent.Form.target(e)["value"]
                  setPrompt(_ => value)
                }}
                placeholder={ts`Describe the event you want to create...`}
                rows=3
                className="w-full px-4 py-3 bg-gray-50/80 dark:bg-gray-800/80 backdrop-blur-sm border border-gray-200/50 dark:border-gray-700/50 rounded-2xl text-gray-900 dark:text-white placeholder-gray-400 dark:placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-purple-500/50 resize-none transition-all"
                disabled=isLoading
              />
              <div className="flex gap-2">
                <button
                  onClick={_ => handleAsk()}
                  disabled={String.trim(prompt) == "" || isLoading}
                  className="flex-1 px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 disabled:from-gray-300 disabled:to-gray-300 dark:disabled:from-gray-700 dark:disabled:to-gray-700 text-white rounded-2xl font-medium transition-all disabled:cursor-not-allowed shadow-lg shadow-purple-500/25">
                  {if isLoading {
                    <span className="flex items-center justify-center gap-2">
                      <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                        <circle
                          className="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          strokeWidth="4"
                          fill="none"
                        />
                        <path
                          className="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        />
                      </svg>
                      {t`Processing...`}
                    </span>
                  } else {
                    switch response {
                    | Some(_) => ts`Reply`
                    | None => ts`Ask`
                    }->React.string
                  }}
                </button>
                {response
                ->Option.map(_ => {
                  <button
                    onClick={_ => handleReset()}
                    className="px-6 py-3 bg-gray-100/80 dark:bg-gray-800/80 hover:bg-gray-200/80 dark:hover:bg-gray-700/80 text-gray-700 dark:text-gray-300 rounded-2xl font-medium transition-all backdrop-blur-sm border border-gray-200/50 dark:border-gray-700/50">
                    {t`New`}
                  </button>
                })
                ->Option.getOr(React.null)}
              </div>
            </div>
          </div>
        </div>
      </Radix.Dialog.Content>
    </Radix.Dialog.Portal>
  </Radix.Dialog.Root>
}
