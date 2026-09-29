// A chat turn the server answered with an error and no messages used to drop
// the prompt's optimistic bubble (the persisted echo that normally replaces it
// never came), and the textarea was already cleared, so what the user typed
// was gone. It now stays, with the error below it.
import { describe, expect, it } from "vitest";
import * as AIAssistantEmbed from "../../src/components/organisms/AIAssistantEmbed.re.mjs";

const user = (id: string, content: string) => ({ TAG: "UserMessage", id, content, actionResult: undefined });
const agent = (id: string, content: string) => ({ TAG: "AgentMessage", id, content, action: undefined });

describe("AIAssistantEmbed.afterChatTurn", () => {
  const history = [user("m1", "Doubles on Friday"), agent("m2", "Here is a draft.")];
  const prompt = user("local-1", "Doubles next Thursday evening");

  it("keeps the prompt's bubble and adds the error when nothing was persisted", () => {
    const next = AIAssistantEmbed.afterChatTurn([...history, prompt], [], "The assistant is unavailable.", () => "local-2");
    expect(next).toEqual([...history, prompt, agent("local-2", "The assistant is unavailable.")]);
  });

  it("replaces the optimistic echo with the persisted rows", () => {
    const persisted = [user("m3", "Doubles next Thursday evening"), agent("m4", "Which venue?")];
    const next = AIAssistantEmbed.afterChatTurn([...history, prompt], persisted, undefined, () => "unused");
    expect(next).toEqual([...history, ...persisted]);
  });

  it("ignores a server error that came with persisted messages", () => {
    const persisted = [user("m3", "Doubles next Thursday evening"), agent("m4", "Partial answer")];
    const next = AIAssistantEmbed.afterChatTurn([...history, prompt], persisted, "late error", () => "unused");
    expect(next).toEqual([...history, ...persisted]);
  });
});
