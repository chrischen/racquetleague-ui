// Shared type definitions for AI Assistant feature
type eventDetails = {
  title: string,
  date: string,
  time: string,
  location: option<string>,
  description: option<string>,
  maxRsvps: option<int>,
}

type aiResponse = {
  summary: string,
  eventDetails: option<eventDetails>,
  suggestedEvents: option<array<eventDetails>>,
}
