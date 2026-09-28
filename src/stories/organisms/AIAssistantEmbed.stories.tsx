import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as AIAssistantEmbedStory } from "./AIAssistantEmbedStory.gen";
import { pending } from "../support";

// The AI assistant band on the create-event form: describe an event, and the
// assistant asks a question, fills the form with one draft, offers a batch of
// drafts, or proposes an action to approve. Each turn is the component's
// `chat` mutation, answered here by Relay mocks in place of the LLM-backed
// backend. Saved history needs a signed-in session, so every story starts
// from an empty conversation and plays its turns.
type ChatInput = {
  message?: string;
  actionResult?: { proposalId: string; operationName: string; resultJson: string };
};

const user = (id: string, content: string, actionResult: object | null = null) => ({
  __typename: "UserMessage",
  id,
  content,
  actionResult,
});
const agent = (id: string, content: string, action: object | null = null) => ({
  __typename: "AgentMessage",
  id,
  content,
  action,
});

// The rows the backend persists for a typed turn: the prompt, then the replies.
const answer =
  (replies: object[], suggestedEvents: string[] | null = null) =>
  (_: unknown, { input }: { input: ChatInput }) => ({
    messages: [user("msg-user-1", input.message ?? ""), ...replies],
    suggestedEvents,
    error: null,
  });

const venue = "Minato Sports Center, 1-16-13 Shibaura, Minato City, Tokyo";
// CreateEventInput-shaped drafts, as the backend passes them through.
const draft = (title: string, startDate: string, endDate: string, extra: object = {}) =>
  JSON.stringify({
    title,
    startDate,
    endDate,
    address: venue,
    details: "Intermediate doubles (DUPR 3.0-4.0). Paddles available to borrow. ¥1,500 at the door.",
    maxRsvps: 16,
    price: 1500,
    timezone: "Asia/Tokyo",
    ...extra,
  });
const thursdays = ["2026-10-15", "2026-10-22", "2026-10-29", "2026-11-05"].map((day, i) =>
  draft(`Thursday Night Doubles #${i + 1}`, `${day}T10:00:00.000Z`, `${day}T12:00:00.000Z`),
);

const proposal = {
  operationName: "UpdateEventMutation",
  query: "mutation UpdateEventMutation($id: ID!, $input: UpdateEventInput!) { updateEvent(id: $id, input: $input) { event { id } } }",
  variables: JSON.stringify({ id: "evt-thu-1015", input: { maxRsvps: 20, courts: 4 } }),
  summary: "Raise Thursday Night Doubles (Oct 15) from 16 to 20 players and book a fourth court.",
};

const meta = {
  title: "Organisms/AIAssistantEmbed",
  component: AIAssistantEmbedStory,
  args: { onSingleEventSuggested: fn(), onEventsAccepted: fn() },
} satisfies Meta<typeof AIAssistantEmbedStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// Replies fade in (AIResponseCard's animate-in starts at opacity 0).
const settles = async (element: HTMLElement) => waitFor(() => expect(element).toBeVisible());

const prompt = (canvasElement: HTMLElement) => within(canvasElement).getByRole("textbox", { name: "Describe the event" });
const ask = async (canvasElement: HTMLElement, text: string) => userEvent.type(prompt(canvasElement), `${text}{Enter}`);

/** The resting band: one line to describe the event, history folded away. */
export const Collapsed: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: "Fill event form from description" })).toBeDisabled();
  },
};

/** Something typed: the send button lights up and the box grows with the text. */
export const PromptTyped: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(
      prompt(canvasElement),
      "Doubles at Minato Sports Center next Thursday 7-9pm, 16 players, ¥1,500, intermediate level. Paddles available to borrow.",
    );
    await expect(canvas.getByRole("button", { name: "Fill event form from description" })).toBeEnabled();
  },
};

/** The history opened before anything was asked. */
export const EmptyConversation: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Show AI chat history" }));
    await settles(await canvas.findByText(/Your conversation will appear here/));
  },
};

/** Waiting on the assistant: typing dots, a spinner in the send button, and
 * the prompt locked. */
export const Thinking: Story = {
  parameters: { relay: { mocks: { Mutation: { chat: () => pending() } } } },
  play: async ({ canvasElement }) => {
    await ask(canvasElement, "Doubles next Thursday evening at Minato");
    await waitFor(() => expect(prompt(canvasElement)).toBeDisabled());
  },
};

/** The assistant needs more before it can draft anything. */
export const ClarifyingQuestion: Story = {
  parameters: {
    relay: {
      mocks: {
        Mutation: {
          chat: answer([
            agent(
              "msg-agent-1",
              "Happy to set that up. Which club should host it, and is there a fee per player? Also, is this a one-off or every Thursday?",
            ),
          ]),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await ask(canvasElement, "Doubles next Thursday 7-9pm at Minato Sports Center");
    await settles(await canvas.findByText(/Which club should host it/));
  },
};

/** One draft goes straight into the form and the band folds away; reopened,
 * its card offers to fill the form again. */
export const SingleDraft: Story = {
  parameters: {
    relay: {
      mocks: {
        Mutation: {
          chat: answer(
            [agent("msg-agent-1", "Here's your event. I've filled in the form below; check the details and create it.")],
            [thursdays[0]],
          ),
        },
      },
    },
  },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await ask(canvasElement, "Doubles next Thursday 7-9pm at Minato Sports Center, 16 players, ¥1,500");
    await waitFor(() => expect(args.onSingleEventSuggested).toHaveBeenCalledWith("Thursday Night Doubles #1"));
    await userEvent.click(canvas.getByRole("button", { name: "Show AI chat history" }));
    await settles(await canvas.findByRole("button", { name: "Fill form" }));
  },
};

/** A batch of drafts waits in the history until the organizer accepts it as
 * the form's schedule (accepting folds the band away; reopened, the batch is
 * still there). */
export const WeeklySchedule: Story = {
  parameters: {
    relay: {
      mocks: {
        Mutation: {
          chat: answer(
            [agent("msg-agent-1", "Four Thursdays from October 15, each 19:00-21:00 at Minato Sports Center.")],
            thursdays,
          ),
        },
      },
    },
  },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await ask(canvasElement, "Every Thursday 7-9pm for the next four weeks at Minato Sports Center");
    await userEvent.click(await canvas.findByRole("button", { name: "Accept 4 events" }));
    await expect(args.onEventsAccepted).toHaveBeenCalledWith(thursdays.map((d) => JSON.parse(d).title));
    await userEvent.click(canvas.getByRole("button", { name: "Show AI chat history" }));
    await settles(await canvas.findByRole("button", { name: "Accept 4 events" }));
  },
};

// A proposal turn, then the reply once the organizer answers it.
const proposalMocks = {
  Mutation: {
    chat: (_: unknown, { input }: { input: ChatInput }) =>
      input.actionResult
        ? {
            messages: [
              user("msg-user-2", "", input.actionResult),
              agent("msg-agent-3", "No problem, I left the event as it is: 16 players on three courts."),
            ],
            suggestedEvents: null,
            error: null,
          }
        : answer([agent("msg-agent-1", "", proposal)])(_, { input }),
  },
};

/** The assistant wants to change an existing event: nothing happens until the
 * organizer approves, and the prompt stays locked meanwhile. */
export const ActionProposal: Story = {
  parameters: { relay: { mocks: proposalMocks } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await ask(canvasElement, "Make the Oct 15 session 20 players and add a court");
    await settles(await canvas.findByText("Awaiting approval"));
    await expect(prompt(canvasElement)).toBeDisabled();
  },
};

/** Denied: the proposal is marked, the assistant acknowledges, and the prompt
 * opens again. */
export const ProposalDenied: Story = {
  parameters: { relay: { mocks: proposalMocks } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await ask(canvasElement, "Make the Oct 15 session 20 players and add a court");
    await userEvent.click(await canvas.findByRole("button", { name: "Deny" }));
    await settles(await canvas.findByText(/I left the event as it is/));
    await settles(canvas.getByText("Denied"));
  },
};

/** Proposals already carried out, as a reloaded conversation shows them: one
 * executed, one that came back with GraphQL errors. */
export const ResolvedProposals: Story = {
  parameters: {
    relay: {
      mocks: {
        Mutation: {
          chat: answer([
            agent("msg-agent-1", "", proposal),
            user("msg-result-1", "", {
              operationName: proposal.operationName,
              proposalId: "msg-agent-1",
              resultJson: JSON.stringify({ data: { updateEvent: { event: { id: "evt-thu-1015" } } } }),
            }),
            agent("msg-agent-2", "", {
              ...proposal,
              operationName: "CancelEventMutation",
              summary: "Cancel Thursday Night Doubles (Oct 22) and notify the 14 players who joined.",
            }),
            user("msg-result-2", "", {
              operationName: "CancelEventMutation",
              proposalId: "msg-agent-2",
              resultJson: JSON.stringify({ errors: [{ message: "Only the club's admins can cancel this event." }] }),
            }),
            agent("msg-agent-3", "The Oct 15 session now takes 20 players on four courts. I couldn't cancel Oct 22: only the club's admins can."),
          ]),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await ask(canvasElement, "Make Oct 15 bigger and cancel Oct 22");
    await settles(await canvas.findByText("Executed"));
    await expect(canvas.getByText("Execution failed")).toBeVisible();
  },
};

/** The backend answered with an error instead of a reply. The prompt's own
 * bubble disappears too: the component drops its optimistic copy and nothing
 * replaces it (and the typed text was already cleared). */
export const ServerError: Story = {
  parameters: {
    relay: {
      mocks: {
        Mutation: {
          chat: () => ({
            messages: [],
            suggestedEvents: null,
            error: "The assistant is unavailable right now. Please try again in a few minutes.",
          }),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await ask(canvasElement, "Doubles next Thursday evening");
    await settles(await canvas.findByText(/assistant is unavailable/));
  },
};
