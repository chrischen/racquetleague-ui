// Storybook support for AIAssistantEmbed.stories.tsx; the app never imports
// this. The assistant band at the top of the create-event form, hosted as
// CreateEventPage hosts it: bled to the card's edges with the form panel's
// rounded top overlapping its foot. Every turn goes through the component's
// own `chat` mutation, which the story's Relay mocks answer. Chat history
// only loads for a signed-in better-auth session, which Storybook doesn't
// have, so each story starts from an empty conversation.

@genType @react.component
let make = (
  // The callbacks report the drafts' titles, which is what the Actions panel
  // can usefully show.
  ~onSingleEventSuggested: string => unit=_ => (),
  ~onEventsAccepted: array<string> => unit=_ => (),
) =>
  <div
    className="max-w-2xl overflow-hidden rounded-2xl border border-gray-200 bg-white px-4 pt-4 dark:border-[#3a3b40] dark:bg-[#1e1f23]">
    <section className="-mx-4 -mt-4 overflow-x-clip">
      <AIAssistantEmbed
        onSingleEventSuggested={event => onSingleEventSuggested(event.title)}
        onEventsAccepted={events => onEventsAccepted(events->Array.map(event => event.title))}
      />
      <div
        className="relative z-10 -mt-3 min-w-0 space-y-3 rounded-t-2xl bg-white px-4 pb-6 pt-4 dark:bg-[#1e1f23]">
        // A stand-in for the form the assistant fills.
        <div className="h-3 w-24 rounded bg-gray-200 dark:bg-[#34353a]" />
        <div className="h-10 rounded-lg border border-gray-200 dark:border-[#3a3b40]" />
        <div className="h-3 w-32 rounded bg-gray-200 dark:bg-[#34353a]" />
        <div className="h-10 rounded-lg border border-gray-200 dark:border-[#3a3b40]" />
      </div>
    </section>
  </div>
